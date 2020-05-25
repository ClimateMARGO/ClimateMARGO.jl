function optimize_controls!(
        model::ClimateModel;
        obj_option = "temp", temp_goal = 2.0, budget=10., expenditure = 0.5,
        max_deployment = Dict("mitigate"=>1., "remove"=>1., "geoeng"=>1., "adapt"=>0.4),
        maxslope = Dict("mitigate"=>1. /40., "remove"=>1. /40., "geoeng"=>1. /30., "adapt"=>0.),
        temp_final = nothing,
        start_deployment = Dict(
            "mitigate"=>model.domain[1],
            "remove"=>model.domain[1]+10,
            "geoeng"=> model.domain[1]+30,
            "adapt"=>model.domain[1]
        ),
        cost_exponent = 2.,
        mitigation_penetration = nothing,
        print_status = false, print_statistics = false, print_raw_status = true,
    )
    
    if print_status
        if print_statistics
            bool_str = "yes"
        else
            bool_str = "no"
        end
        print_int = 1
    else
        print_int = 0
        bool_str = "no"
    end
    
    if isnothing(temp_final)
        temp_final = temp_goal
    elseif temp_final >= temp_goal
        temp_final = temp_goal
    end
    
    for (key, item) in start_deployment
        if isnothing(item)
            start_deployment[key] = model.present_year
        end
    end
    
    if typeof(cost_exponent) in [Int64, Float64]
        cost_exponent = Dict(
            "mitigate"=>cost_exponent, "remove"=>cost_exponent, "geoeng"=>cost_exponent, "adapt"=>cost_exponent
        )
    end
    
    model_optimizer = Model(optimizer_with_attributes(Ipopt.Optimizer,
        "acceptable_tol" => 1.e-10, "max_iter" => Int64(1e7),
        "acceptable_constr_viol_tol" => 1.e-3, "constr_viol_tol" => 1.e-4,
        "print_frequency_iter" => 50,  "print_timing_statistics" => bool_str,
        "print_level" => print_int,
    ))

    function fM_JuMP(α)
        if α <= 0.
            return 100.
        else
            if isnothing(mitigation_penetration)
                return α ^ cost_exponent["mitigate"]
            else
                return α ^ cost_exponent["mitigate"] / (1. - exp( - (1. - α) / (1. - mitigation_penetration)))
            end
        end
    end
    register(model_optimizer, :fM_JuMP, 1, fM_JuMP, autodiff=true)

    function fA_JuMP(α)
        if α <= 0.
            return 1000.
        else
            return α ^ cost_exponent["adapt"]
        end
    end
    register(model_optimizer, :fA_JuMP, 1, fA_JuMP, autodiff=true)
    
    function fR_JuMP(α)
        if α <= 0.
            return 1000.
        else
            return α ^ cost_exponent["remove"]
        end
    end
    register(model_optimizer, :fR_JuMP, 1, fR_JuMP, autodiff=true)
    
    function fG_JuMP(α)
        if α <= 0.
            return 1000.
        else
            return α ^ cost_exponent["geoeng"]
        end
    end
    register(model_optimizer, :fG_JuMP, 1, fG_JuMP, autodiff=true)
    
    function log_JuMP(x)
        if x <= 0.
            return -1000.0
        else
            return log(x)
        end
    end
    register(model_optimizer, :log_JuMP, 1, log_JuMP, autodiff=true)

    function discounting_JuMP(t)
        if t < model.present_year
            return 0.
        else
            return (
                (1. + model.economics.utility_discount_rate) ^
                (-(t - model.present_year))
            )
        end
    end
    register(model_optimizer, :discounting_JuMP, 1, discounting_JuMP, autodiff=true)

    q = model.economics.baseline_emissions
    N = length(model.domain)

    # constraints on control variables
    @variables(model_optimizer, begin
            0. <= M[1:N] <= max_deployment["mitigate"]  # emissions reductions
            0. <= R[1:N] <= max_deployment["remove"]  # negative emissions
            0. <= G[1:N] <= max_deployment["geoeng"]  # geoengineering
            0. <= A[1:N] <= max_deployment["adapt"]  # adapt
    end)

    control_vars = Dict(
        "mitigate" => M,
        "remove" => R,
        "geoeng" => G,
        "adapt" => A
    )
    controls = Dict(
        "mitigate" => model.controls.mitigate,
        "remove" => model.controls.remove,
        "geoeng" => model.controls.geoeng,
        "adapt" => model.controls.adapt
    )
    
    domain_idx = (model.domain .> model.present_year) # don't update past or present
    if model.domain[1] == model.present_year
        domain_idx = (model.domain .>= model.present_year) # unless present is also first timestep
    end
    
    M₀ = model.economics.mitigate_init
    R₀ = model.economics.remove_init
    G₀ = model.economics.geoeng_init
    A₀ = model.economics.adapt_init
    
    control_inits = Dict(
        "mitigate" => M₀,
        "remove" => R₀,
        "geoeng" => G₀,
        "adapt" => A₀
    )
    
    for (key, control) in control_vars
        if control_inits[key] != nothing
            fix(control_vars[key][1], control_inits[key]; force = true)
            Nstart = 2
        else
            Nstart = 1
        end
        
        for idx in Nstart:N
            if idx <= length(model.domain[.~domain_idx])
                fix(control_vars[key][idx], controls[key][idx]; force = true)
            else
                if model.domain[idx] < start_deployment[key]
                    fix(control_vars[key][idx], control_inits[key]; force = true)
                end
            end
        end
    end

    # add integral function as a new variable defined by first order finite differences
    @variable(model_optimizer, cumsum_qMR[1:N]);
    for i in 1:N-1
        @constraint(
            model_optimizer, cumsum_qMR[i+1] - cumsum_qMR[i] ==
            (model.dt * (model.physics.r * q[i+1] * (1. - M[i+1]) - q[1] * R[i+1]))
        )
    end
    @constraint(
        model_optimizer, cumsum_qMR[1] == (model.dt * (model.physics.r * q[1] * (1. - M[1]) - q[1] * R[1]))
    );
    
    # add temperature kernel as new variable defined by first order finite difference
    @variable(model_optimizer, cumsum_KFdt[1:N]);
    for i in 1:N-1
        @NLconstraint(
            model_optimizer, cumsum_KFdt[i+1] - cumsum_KFdt[i] ==
            (
                model.dt *
                exp( (model.domain[i+1] - (model.domain[1] - model.dt)) / model.physics.τd ) * (
                    a * log_JuMP(
                        (model.physics.CO₂_init + cumsum_qMR[i+1]) /
                        (model.physics.CO₂_init)
                    ) - 8.5*G[i+1] )
                * (60. * 60. * 24. * 365.25)
            )
        )
    end
    @NLconstraint(
        model_optimizer, cumsum_KFdt[1] == (
            model.dt *
                exp( (model.dt) / model.physics.τd ) * (
                    a * log_JuMP(
                        (model.physics.CO₂_init + cumsum_qMR[1]) /
                        (model.physics.CO₂_init)
                    ) - 8.5*G[1] )
                * (60. * 60. * 24. * 365.25)
         )
    );

    # Add constraint of rate of changes
    present_idx = findmin(abs.(model.domain .- model.present_year))[2]
    if present_idx == 1
        present_idx = 0
    end
    if typeof(maxslope) == Float64
        @variables(model_optimizer, begin
                -maxslope <= dMdt[present_idx+1:N-1] <= maxslope
                -maxslope <= dRdt[present_idx+1:N-1] <= maxslope
                -maxslope <= dGdt[present_idx+1:N-1] <= maxslope
                -maxslope <= dAdt[present_idx+1:N-1] <= maxslope
        end);

    elseif typeof(maxslope) == Dict{String,Float64}
        @variables(model_optimizer, begin
                -maxslope["mitigate"] <= dMdt[present_idx+1:N-1] <= maxslope["mitigate"]
                -maxslope["remove"] <= dRdt[present_idx+1:N-1] <= maxslope["remove"]
                -maxslope["geoeng"] <= dGdt[present_idx+1:N-1] <= maxslope["geoeng"]
                -maxslope["adapt"] <= dAdt[present_idx+1:N-1] <= maxslope["adapt"]
        end);
    end

    for i in present_idx+1:N-1
        @constraint(model_optimizer, dMdt[i] == (M[i+1] - M[i]) / model.dt)
        @constraint(model_optimizer, dRdt[i] == (R[i+1] - R[i]) / model.dt)
        @constraint(model_optimizer, dGdt[i] == (G[i+1] - G[i]) / model.dt)
        @constraint(model_optimizer, dAdt[i] == (A[i+1] - A[i]) / model.dt)
    end
    
    if obj_option == "net_benefit"
        # in practice we solve the equivalent problem of minimizing the net cost (- net benefit)
        @NLobjective(model_optimizer, Min, 
            sum(
                (
                    (1 - A[i]) * model.economics.β *
                    model.economics.GWP[i] *
                    ((model.physics.δT_init + 
                        (
                             (model.physics.a * log_JuMP(
                                        (model.physics.CO₂_init + cumsum_qMR[i]) /
                                        (model.physics.CO₂_init)
                                    ) - 8.5*G[i] 
                            )* (60. * 60. * 24. * 365.25) +
                            model.physics.κ /
                            (model.physics.τd * model.physics.B) *
                            exp( - (model.domain[i] - (model.domain[1] - model.dt)) / model.physics.τd ) *
                            cumsum_KFdt[i]
                        ) / (model.physics.B + model.physics.κ)
                    )
                    )^2 +
                    model.economics.mitigate_cost * model.economics.GWP[i] *
                    fM_JuMP(M[i]) +
                    model.economics.adapt_cost * fA_JuMP(A[i]) +
                    model.economics.remove_cost * fR_JuMP(R[i]) +
                    model.economics.geoeng_cost * model.economics.GWP[i] *
                    fG_JuMP(G[i])
                ) *
                discounting_JuMP(model.domain[i]) *
                model.dt
            for i=1:N)
        )
        
    elseif obj_option == "temp"
        @NLobjective(model_optimizer, Min,
            sum(
                (
                    model.economics.mitigate_cost * model.economics.GWP[i] *
                    fM_JuMP(M[i]) +
                    model.economics.adapt_cost * fA_JuMP(A[i]) +
                    model.economics.remove_cost * fR_JuMP(R[i]) +
                    model.economics.geoeng_cost * model.economics.GWP[i] *
                    fG_JuMP(G[i])
                ) *
                discounting_JuMP(model.domain[i]) *
                model.dt
            for i=1:N)
        )
        
        for i in 1:N-1
            @NLconstraint(model_optimizer,
                (1 - A[i]) * model.economics.β *
                model.economics.GWP[i] *
                ((model.physics.δT_init + 
                    (
                        (model.physics.a * log_JuMP(
                                    (model.physics.CO₂_init + cumsum_qMR[i]) /
                                    (model.physics.CO₂_init)
                                ) - 8.5*G[i]
                        ) * (60. * 60. * 24. * 365.25) +
                        model.physics.κ /
                        (model.physics.τd * model.physics.B) *
                        exp( - (model.domain[i] - (model.domain[1] - model.dt)) / model.physics.τd ) *
                        cumsum_KFdt[i]
                    ) / (model.physics.B + model.physics.κ)
                )
                )^2 <= (
                    model.economics.β *
                    model.economics.GWP[i] *
                    temp_goal^2
                )
            )
        end
        i=N
        @NLconstraint(model_optimizer,
            (1 - A[i]) * model.economics.β *
            model.economics.GWP[i] *
            ((model.physics.δT_init + 
                (
                    (model.physics.a * log_JuMP(
                                (model.physics.CO₂_init + cumsum_qMR[i]) /
                                (model.physics.CO₂_init)
                            ) - 8.5*G[i]
                    ) * (60. * 60. * 24. * 365.25) +
                    model.physics.κ /
                    (model.physics.τd * model.physics.B) *
                    exp( - (model.domain[i] - (model.domain[1] - model.dt)) / model.physics.τd ) *
                    cumsum_KFdt[i]
                ) / (model.physics.B + model.physics.κ)
            )
            )^2 <= (
                model.economics.β *
                model.economics.GWP[i] *
                temp_final^2
            )
        )

    elseif obj_option == "budget"
        @NLobjective(model_optimizer, Min,
            sum(
                (1 - A[i]) * model.economics.β *
                model.economics.GWP[i] *
                ((model.physics.δT_init + 
                    (
                        (model.physics.a * log_JuMP(
                                    (model.physics.CO₂_init + cumsum_qMR[i]) /
                                    (model.physics.CO₂_init)
                                ) - 8.5*G[i]
                        ) * (60. * 60. * 24. * 365.25) +
                        model.physics.κ /
                        (model.physics.τd * model.physics.B) *
                        exp( - (model.domain[i] - (model.domain[1] - model.dt)) / model.physics.τd ) *
                        cumsum_KFdt[i]
                    ) / (model.physics.B + model.physics.κ)
                )
                )^2 *
                discounting_JuMP(model.domain[i]) *
                model.dt
            for i=1:N)
        )
        
        @NLconstraint(model_optimizer,
            sum(
                (
                    model.economics.mitigate_cost * model.economics.GWP[i] *
                    fM_JuMP(M[i]) +
                    model.economics.adapt_cost * fA_JuMP(A[i]) +
                    model.economics.remove_cost * fR_JuMP(R[i]) +
                    model.economics.geoeng_cost * model.economics.GWP[i] *
                    fG_JuMP(G[i])
                ) *
                discounting_JuMP(model.domain[i]) *
                model.dt
            for i=1:N) <= budget
        )
        
    elseif obj_option == "expenditure"
        @NLobjective(model_optimizer, Min,
            sum(
                (1 - A[i]) * model.economics.β *
                model.economics.GWP[i] *
                ((model.physics.δT_init + 
                    (
                        (model.physics.a * log_JuMP(
                                    (model.physics.CO₂_init + cumsum_qMR[i]) /
                                    (model.physics.CO₂_init)
                                ) - 8.5*G[i]
                        ) * (60. * 60. * 24. * 365.25) +
                        model.physics.κ /
                        (model.physics.τd * model.physics.B) *
                        exp( - (model.domain[i] - (model.domain[1] - model.dt)) / model.physics.τd ) *
                        cumsum_KFdt[i]
                    ) / (model.physics.B + model.physics.κ)
                )
                )^2 *
                discounting_JuMP(model.domain[i]) *
                model.dt
            for i=1:N)
        )
        
        for i in 1:N
            @NLconstraint(model_optimizer,
                (
                    model.economics.mitigate_cost * model.economics.GWP[i] *
                    fM_JuMP(M[i]) +
                    model.economics.adapt_cost * fA_JuMP(A[i]) +
                    model.economics.remove_cost * fR_JuMP(R[i]) +
                    model.economics.geoeng_cost * model.economics.GWP[i] *
                    fG_JuMP(G[i])
                ) <= expenditure * model.economics.GWP[i]
            )
        end
    end
    
    optimize!(model_optimizer)
    
    if print_raw_status
        print(raw_status(model_optimizer), "\n")
    end
    
    getfield(model.controls, :mitigate)[domain_idx] = value.(M)[domain_idx]
    getfield(model.controls, :remove)[domain_idx] = value.(R)[domain_idx]
    getfield(model.controls, :geoeng)[domain_idx] = value.(G)[domain_idx]
    getfield(model.controls, :adapt)[domain_idx] = value.(A)[domain_idx]
    
    return model_optimizer
end