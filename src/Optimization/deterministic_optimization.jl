
function optimize_controls!(
        m::ClimateModel;
        obj_option = "temp", temp_goal = 2.0, budget=10., expenditure = 0.5,
        max_deployment = Dict("mitigate"=>1., "remove"=>1., "geoeng"=>1., "adapt"=>0.4),
        max_slope = Dict("mitigate"=>1. /40., "remove"=>1. /40., "geoeng"=>1. /20., "adapt"=>0.),
        max_update = Dict("mitigate"=>nothing, "remove"=>nothing, "geoeng"=>nothing, "adapt"=>0.1),
        temp_final = nothing,
        delay_deployment = Dict(
            "mitigate"=>0,
            "remove"=>10,
            "geoeng"=>30,
            "adapt"=>0
        ),
        cost_exponent = 2.,
        mitigation_penetration = nothing,
        print_status = false, print_statistics = false, print_raw_status = true,
    )
    
    # Translate JuMP printing options
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
    
    # Shorthands
    tarr = t(m)
    Earr = E(m)
    τ = τd(m)
    dt = m.domain.dt
    t0 = tarr[1]
    tp = m.domain.present_year
    q = m.economics.baseline_emissions
    qGtCO2 = ppm_to_GtCO2(q)
    N = length(tarr)
    
    # Set default temperature goal for end year
    if isnothing(temp_final)
        temp_final = temp_goal
    elseif temp_final >= temp_goal
        temp_final = temp_goal
    end
    
    # Set defaults for start_deployment
    start_deployment = Dict()
    for (key, item) in delay_deployment
        start_deployment[key] = t0 + delay_deployment[key]
    end
    
    max_slope_update = Dict()
    for (key, item) in max_update
        if isnothing(item)
            max_slope_update[key] = 0
            max_update[key] = Inf
        else
            max_slope_update[key] = 1
        end
    end
    
    if typeof(cost_exponent) in [Int64, Float64]
        cost_exponent = Dict(
            "mitigate"=>cost_exponent,
            "remove"=>cost_exponent,
            "geoeng"=>cost_exponent,
            "adapt"=>cost_exponent
        )
    end
    
    model_optimizer = Model(optimizer_with_attributes(Ipopt.Optimizer,
        "acceptable_tol" => 1.e-8, "max_iter" => Int64(1e8),
        "acceptable_constr_viol_tol" => 1.e-3, "constr_viol_tol" => 1.e-4,
        "print_frequency_iter" => 50,  "print_timing_statistics" => bool_str,
        "print_level" => print_int,
    ))

    function fM_JuMP(α)
        if α <= 0.
            return 100.
        else
            base_cost = α ^ cost_exponent["mitigate"]
            if isnothing(mitigation_penetration)
                return base_cost
            else
                penetration_factor = (
                    1. /(1. - exp( - (1. - α) / (1. - mitigation_penetration)))
                )
                return base_cost * penetration_factor
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
        if t < tp
            return 0.
        else
            return (
                (1. + m.economics.ρ) ^
                (-(t - tp))
            )
        end
    end
    register(model_optimizer, :discounting_JuMP, 1, discounting_JuMP, autodiff=true)

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
        "mitigate" => m.controls.mitigate,
        "remove" => m.controls.remove,
        "geoeng" => m.controls.geoeng,
        "adapt" => m.controls.adapt
    )
    
    domain_idx = (tarr .> tp) # don't update past or present
    if tarr[1] == tp
        domain_idx = (tarr .>= tp) # unless present is also first timestep
    end
    
    M₀ = m.economics.mitigate_init
    R₀ = m.economics.remove_init
    G₀ = m.economics.geoeng_init
    A₀ = m.economics.adapt_init
    
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
            if idx <= length(tarr[.~domain_idx])
                fix(control_vars[key][idx], controls[key][idx]; force = true)
            else
                if tarr[idx] < start_deployment[key]
                    if control_inits[key] != nothing
                        fix(control_vars[key][idx], control_inits[key]; force = true)
                    else
                        fix(control_vars[key][idx], 0.; force = true)
                    end
                end
            end
        end
    end

    # add integral function as a new variable defined by first order finite differences
    @variable(model_optimizer, cumsum_qMR[1:N]);
    for i in 1:N-1
        @constraint(
            model_optimizer, cumsum_qMR[i+1] - cumsum_qMR[i] ==
            (dt * (m.physics.r * (q[i+1] * (1. - M[i+1]) - q[1] * R[i+1])))
        )
    end
    @constraint(
        model_optimizer, cumsum_qMR[1] == (dt * (m.physics.r * (q[1] * (1. - M[1]) - q[1] * R[1])))
    );
    
    # add temperature kernel as new variable defined by first order finite difference
    @variable(model_optimizer, cumsum_KFdt[1:N]);
    for i in 1:N-1
        @NLconstraint(
            model_optimizer, cumsum_KFdt[i+1] - cumsum_KFdt[i] ==
            (
                dt *
                exp( (tarr[i+1] - (t0 - dt)) / τ ) * (
                    m.physics.a * log_JuMP(
                        (m.physics.c0 + cumsum_qMR[i+1]) /
                        (m.physics.c0)
                    ) - m.economics.Finf*G[i+1] )
            )
        )
    end
    @NLconstraint(
        model_optimizer, cumsum_KFdt[1] == 
        (
            dt *
            exp( dt / τ ) * (
                m.physics.a * log_JuMP(
                    (m.physics.c0 + cumsum_qMR[1]) /
                    (m.physics.c0)
                ) - m.economics.Finf*G[1] )
         )
    );

    # Add constraint of rate of changes
    present_idx = findmin(abs.(tarr .- tp))[2]

    @variables(model_optimizer, begin
            -max_slope["mitigate"] <= dMdt[present_idx+max_slope_update["mitigate"]:N-1] <= max_slope["mitigate"]
            -max_slope["remove"] <= dRdt[present_idx+max_slope_update["remove"]:N-1] <= max_slope["remove"]
            -max_slope["geoeng"] <= dGdt[present_idx+max_slope_update["geoeng"]:N-1] <= max_slope["geoeng"]
            -max_slope["adapt"] <= dAdt[present_idx+max_slope_update["adapt"]:N-1] <= max_slope["adapt"]
    end);
    for i in present_idx+max_slope_update["mitigate"]:N-1
        @constraint(model_optimizer, dMdt[i] == (M[i+1] - M[i]) / dt)
    end
    for i in present_idx+max_slope_update["remove"]:N-1
        @constraint(model_optimizer, dRdt[i] == (R[i+1] - R[i]) / dt)
    end
    for i in present_idx+max_slope_update["geoeng"]:N-1
        @constraint(model_optimizer, dGdt[i] == (G[i+1] - G[i]) / dt)
    end
    for i in present_idx+max_slope_update["adapt"]:N-1
        @constraint(model_optimizer, dAdt[i] == (A[i+1] - A[i]) / dt)
    end
    
    if present_idx > 1
        @variables(model_optimizer, begin
            -max_update["mitigate"] <= dM <= max_update["mitigate"]
            -max_update["remove"] <= dR <= max_update["remove"]
            -max_update["geoeng"] <= dG <= max_update["geoeng"]
            -max_update["adapt"] <= dA <= max_update["adapt"]
        end);
        @constraint(model_optimizer, dM == (M[present_idx+1] - M[present_idx]))
        @constraint(model_optimizer, dR == (R[present_idx+1] - R[present_idx]))
        @constraint(model_optimizer, dG == (G[present_idx+1] - G[present_idx]))
        @constraint(model_optimizer, dA == (A[present_idx+1] - A[present_idx]))
    end
    
    if obj_option == "net_benefit"
        # in practice we solve the equivalent problem of minimizing the net cost (- net benefit)
        @NLobjective(model_optimizer, Min, 
            sum(
                (
                    (1 - A[i]) * m.economics.β *
                    Earr[i] *
                    ((m.physics.T0 + 
                        (
                             (m.physics.a * log_JuMP(
                                        (m.physics.c0 + cumsum_qMR[i]) /
                                        (m.physics.c0)
                                    ) - m.economics.Finf*G[i] 
                            ) +
                            m.physics.κ /
                            (τ * m.physics.B) *
                            exp( - (tarr[i] - (t0 - dt)) / τ ) *
                            cumsum_KFdt[i]
                        ) / (m.physics.B + m.physics.κ)
                    )
                    )^2 +
                    m.economics.mitigate_cost * qGtCO2[i] *
                    fM_JuMP(M[i]) +
                    m.economics.adapt_cost * fA_JuMP(A[i]) +
                    m.economics.remove_cost * fR_JuMP(R[i]) +
                    m.economics.geoeng_cost * Earr[i] *
                    fG_JuMP(G[i])
                ) *
                discounting_JuMP(tarr[i]) *
                dt
            for i=1:N)
        )
        
    elseif obj_option == "temp"
        @NLobjective(model_optimizer, Min,
            sum(
                (
                    m.economics.mitigate_cost * qGtCO2[i] *
                    fM_JuMP(M[i]) +
                    m.economics.adapt_cost * fA_JuMP(A[i]) +
                    m.economics.remove_cost * fR_JuMP(R[i]) +
                    m.economics.geoeng_cost * Earr[i] *
                    fG_JuMP(G[i])
                ) *
                discounting_JuMP(tarr[i]) *
                dt
            for i=1:N)
        )
        
        for i in 1:N-1
            @NLconstraint(model_optimizer,
                (1 - A[i]) * m.economics.β *
                Earr[i] *
                ((m.physics.T0 + 
                    (
                        (m.physics.a * log_JuMP(
                                    (m.physics.c0 + cumsum_qMR[i]) /
                                    (m.physics.c0)
                                ) - 8.5*G[i]
                        ) +
                        m.physics.κ /
                        (τ * m.physics.B) *
                        exp( - (tarr[i] - (t0 - dt)) / τ ) *
                        cumsum_KFdt[i]
                    ) / (m.physics.B + m.physics.κ)
                )
                )^2 <= (
                    m.economics.β *
                    Earr[i] *
                    temp_goal^2
                )
            )
        end
        i=N
        @NLconstraint(model_optimizer,
            (1 - A[i]) * m.economics.β *
            Earr[i] *
            ((m.physics.T0 + 
                (
                    (m.physics.a * log_JuMP(
                                (m.physics.c0 + cumsum_qMR[i]) /
                                (m.physics.c0)
                            ) - 8.5*G[i]
                    ) +
                    m.physics.κ /
                    (τ * m.physics.B) *
                    exp( - (tarr[i] - (t0 - dt)) / τ ) *
                    cumsum_KFdt[i]
                ) / (m.physics.B + m.physics.κ)
            )
            )^2 <= (
                m.economics.β *
                Earr[i] *
                temp_final^2
            )
        )

    elseif obj_option == "budget"
        @NLobjective(model_optimizer, Min,
            sum(
                (1 - A[i]) * m.economics.β *
                Earr[i] *
                ((m.physics.T0 + 
                    (
                        (m.physics.a * log_JuMP(
                                    (m.physics.c0 + cumsum_qMR[i]) /
                                    (m.physics.c0)
                                ) - 8.5*G[i]
                        ) +
                        m.physics.κ /
                        (τ * m.physics.B) *
                        exp( - (tarr[i] - (t0 - dt)) / τ ) *
                        cumsum_KFdt[i]
                    ) / (m.physics.B + m.physics.κ)
                )
                )^2 *
                discounting_JuMP(t[i]) *
                dt
            for i=1:N)
        )
        
        @NLconstraint(model_optimizer,
            sum(
                (
                    m.economics.mitigate_cost * qGtCO2[i] *
                    fM_JuMP(M[i]) +
                    m.economics.adapt_cost * fA_JuMP(A[i]) +
                    m.economics.remove_cost * fR_JuMP(R[i]) +
                    m.economics.geoeng_cost * Earr[i] *
                    fG_JuMP(G[i])
                ) *
                discounting_JuMP(t[i]) *
                dt
            for i=1:N) <= budget
        )
        
    elseif obj_option == "expenditure"
        @NLobjective(model_optimizer, Min,
            sum(
                (1 - A[i]) * m.economics.β *
                Earr[i] *
                ((m.physics.T0 + 
                    (
                        (m.physics.a * log_JuMP(
                                    (m.physics.c0 + cumsum_qMR[i]) /
                                    (m.physics.c0)
                                ) - 8.5*G[i]
                        ) +
                        m.physics.κ /
                        (τ * m.physics.B) *
                        exp( - (tarr[i] - (t0 - dt)) / τ ) *
                        cumsum_KFdt[i]
                    ) / (m.physics.B + m.physics.κ)
                )
                )^2 *
                discounting_JuMP(t[i]) *
                dt
            for i=1:N)
        )
        
        for i in 1:N
            @NLconstraint(model_optimizer,
                (
                    m.economics.mitigate_cost * qGtCO2[i] *
                    fM_JuMP(M[i]) +
                    m.economics.adapt_cost * fA_JuMP(A[i]) +
                    m.economics.remove_cost * fR_JuMP(R[i]) +
                    m.economics.geoeng_cost * Earr[i] *
                    fG_JuMP(G[i])
                ) <= expenditure * Earr[i]
            )
        end
    end
    
    optimize!(model_optimizer)
    
    if print_raw_status
        print(raw_status(model_optimizer), "\n")
    end
    
    mitigate_values = value.(M)[domain_idx]
    mitigate_values[q.==0.] .= 0.
    getfield(m.controls, :mitigate)[domain_idx] = mitigate_values
    getfield(m.controls, :remove)[domain_idx] = value.(R)[domain_idx]
    getfield(m.controls, :geoeng)[domain_idx] = value.(G)[domain_idx]
    getfield(m.controls, :adapt)[domain_idx] = value.(A)[domain_idx]
    
    return model_optimizer
end