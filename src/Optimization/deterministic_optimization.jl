
function optimize_controls!(
        m::ClimateModel;
        obj_option = "adaptive_temp", temp_goal = 1.5, budget=10., expenditure = 0.5,
        max_deployment = Dict("mitigate"=>1., "remove"=>1., "geoeng"=>1., "adapt"=>1.),
        max_slope = Dict("mitigate"=>1. /40., "remove"=>1. /40., "geoeng"=>1. /40., "adapt"=> 1. /40.),
        temp_overshoot = nothing,
        overshoot_year = 2100,
        delay_deployment = Dict(
            "mitigate"=>0,
            "remove"=>0,
            "geoeng"=>0,
            "adapt"=>0
        ),
        cost_exponent = 3.,
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
    Db = m.economics.β .* Earr .* m.economics.Tb^2
    N = length(tarr)
    
    # Set default temperature goal for end year
    if isnothing(temp_overshoot)
        temp_overshoot = temp_goal
        odx = N
    elseif temp_overshoot >= temp_goal
        odx = argmin(abs.(tarr .- overshoot_year)) # overshoot index
    elseif temp_overshoot < temp_goal
        temp_overshoot = temp_goal
        odx = N
    end
    
    # Set defaults for start_deployment
    start_deployment = Dict()
    for (key, item) in delay_deployment
        start_deployment[key] = t0 + delay_deployment[key]
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
            return 1000.
        else
            return α ^ cost_exponent["mitigate"]
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

    scale = 5.e-3
    function Hstep(α)
        if α <= 0.
            return 0.
        elseif 0. < α <= scale/2.
            return 2*(α/scale)^2
        elseif scale/2. < α <= scale
            return 1. - 2((α - scale)/scale)^2
        elseif α > scale
            return 1. 
        end
    end
    register(model_optimizer, :Hstep, 1, Hstep, autodiff=true)
    
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
    for (key, item) in max_deployment
        if item==0.
            max_deployment[key] = item+1.e-8
        end
    end
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
        if control_inits[key] !== nothing
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
                    if control_inits[key] !== nothing
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
    present_idx = argmin(abs.(tarr .- tp))

    @variables(model_optimizer, begin
            -max_slope["mitigate"] <= dMdt[present_idx:N-1] <= max_slope["mitigate"]
            -max_slope["remove"] <= dRdt[present_idx:N-1] <= max_slope["remove"]
            -max_slope["geoeng"] <= dGdt[present_idx:N-1] <= max_slope["geoeng"]
            -max_slope["adapt"] <= dAdt[present_idx:N-1] <= max_slope["adapt"]
    end);
    for i in present_idx:N-1
        @constraint(model_optimizer, dMdt[i] == (M[i+1] - M[i]) / dt)
    end
    for i in present_idx:N-1
        @constraint(model_optimizer, dRdt[i] == (R[i+1] - R[i]) / dt)
    end
    for i in present_idx:N-1
        @constraint(model_optimizer, dGdt[i] == (G[i+1] - G[i]) / dt)
    end
    for i in present_idx:N-1
        @constraint(model_optimizer, dAdt[i] == (A[i+1] - A[i]) / dt)
    end
    
    ## Optimization options

    # maximize net benefits
    if obj_option == "net_benefit"
        # (in practice we solve the equivalent problem of minimizing the net cost, i.e. minus the net benefit)
        @NLobjective(model_optimizer, Min, 
            sum(
                (
                    m.economics.β *
                    Earr[i] *
                    (
                        (m.physics.T0 + 
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
                        )^2
                    ) * ( (1 - A[i]) ) +
                    Earr[i] * m.economics.adapt_cost * fA_JuMP(A[i]) +
                    m.economics.mitigate_cost * qGtCO2[i] *
                    fM_JuMP(M[i]) +
                    m.economics.remove_cost * fR_JuMP(R[i]) +
                    Earr[i] * (
                        m.economics.geoeng_cost * fG_JuMP(G[i]) +
                        m.economics.epsilon_cost * Hstep(G[i])
                    )
                    
                ) *
                discounting_JuMP(tarr[i]) *
                dt
            for i=1:N)
        )

    # maximize net benefits subject to a temperature goal
    elseif obj_option == "temp"
        @NLobjective(model_optimizer, Min,
            sum(
                (
                    Earr[i] * m.economics.adapt_cost * fA_JuMP(A[i]) +
                    m.economics.mitigate_cost * qGtCO2[i] *
                    fM_JuMP(M[i]) +
                    m.economics.remove_cost * fR_JuMP(R[i]) +
                    Earr[i] * (
                        m.economics.geoeng_cost * fG_JuMP(G[i]) +
                        m.economics.epsilon_cost * Hstep(G[i])
                    )
                ) *
                discounting_JuMP(tarr[i]) *
                dt
            for i=1:N)
        )

        # Subject to temperature goal (during overshoot period)
        for i in 1:odx-1
            @NLconstraint(model_optimizer,
            (m.physics.T0 + 
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
            ) <= temp_overshoot
            )
        end
        # Subject to temperature goal (after temporary overshoot period)
        for i in odx:N
            @NLconstraint(model_optimizer,
            (m.physics.T0 + 
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
            ) <= temp_goal
            )
        end

    # minimize control costs subject to adaptative-temperature constraint
    elseif obj_option == "adaptive_temp"
        
        # minimize control costs
        @NLobjective(model_optimizer, Min,
            sum(
                (
                    Earr[i] * m.economics.adapt_cost * fA_JuMP(A[i]) +
                    m.economics.mitigate_cost * qGtCO2[i] *
                    fM_JuMP(M[i]) +
                    m.economics.remove_cost * fR_JuMP(R[i]) +
                    Earr[i] * (
                        m.economics.geoeng_cost * fG_JuMP(G[i]) +
                        m.economics.epsilon_cost * Hstep(G[i])
                    )
                ) *
                discounting_JuMP(tarr[i]) *
                dt
            for i=1:N)
        )
        
        # Subject to adaptive temperature goal (during overshoot period)
        for i in 1:odx-1
            @NLconstraint(model_optimizer,
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
            * sqrt(1. - A[i]) ) <=
                temp_overshoot
            )
        end
        # Subject to adaptive temperature goal (after temporary overshoot period)
        for i in odx:N
            @NLconstraint(model_optimizer,
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
            * sqrt(1. - A[i]) ) <=
                temp_goal
            )
        end

    # minimize damages subject to a total discounted budget constraint
    elseif obj_option == "budget"
        @NLobjective(model_optimizer, Min,
            sum(
                m.economics.β *
                Earr[i] *
                (
                    m.physics.T0 + 
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
                    )^2 * (1. - A[i]) *
                discounting_JuMP(t[i]) *
                dt
            for i=1:N)
        )
        
        @NLconstraint(model_optimizer,
            sum(
                (
                    Earr[i] * m.economics.adapt_cost * fA_JuMP(A[i]) +
                    m.economics.mitigate_cost * qGtCO2[i] *
                    fM_JuMP(M[i]) +
                    m.economics.remove_cost * fR_JuMP(R[i]) +
                    Earr[i] * (
                        m.economics.geoeng_cost * fG_JuMP(G[i]) +
                        m.economics.epsilon_cost * Hstep(G[i])
                    )
                ) *
                discounting_JuMP(tarr[i]) *
                dt
            for i=1:N) <= budget
        )
        
    # minimize damages subject to annual expenditure constraint (as % of GWP)
    elseif obj_option == "expenditure"
        @NLobjective(model_optimizer, Min,
            sum(
                m.economics.β *
                Earr[i] *
                (m.physics.T0 + 
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
                )^2 * (1-A[i]) *
                discounting_JuMP(t[i]) *
                dt
            for i=1:N)
        )
        
        for i in 1:N
            @NLconstraint(model_optimizer,
                (
                    Earr[i] * m.economics.adapt_cost * fA_JuMP(A[i]) +
                    m.economics.mitigate_cost * qGtCO2[i] *
                    fM_JuMP(M[i]) +
                    m.economics.remove_cost * fR_JuMP(R[i]) +
                    Earr[i] * (
                        m.economics.geoeng_cost * fG_JuMP(G[i]) +
                        m.economics.epsilon_cost * Hstep(G[i])
                    )
                ) <= expenditure * Earr[i]
            )
        end
    end
    
    optimize!(model_optimizer)
    
    if print_raw_status
        print(raw_status(model_optimizer), "\n")
    end

    mitigate_values = value.(M)[domain_idx]
    mitigate_values[q[domain_idx].==0.] .= 0.
    getfield(m.controls, :mitigate)[domain_idx] = mitigate_values
    getfield(m.controls, :remove)[domain_idx] = value.(R)[domain_idx]
    getfield(m.controls, :geoeng)[domain_idx] = value.(G)[domain_idx]
    getfield(m.controls, :adapt)[domain_idx] = value.(A)[domain_idx]
    
    return model_optimizer
end