f(α::Array; p=3.) = α.^p # shape of individual cost functions

E(t, E0, γ) = E0 * (1. .+ γ).^(t .- t[1])
E(m) = E(t(m), m.economics.E0, m.economics.γ)

discount(t, ρ, tp) = .~past_mask(t, tp) .* (1. .+ ρ) .^ (- (t .- tp))
discount(m::ClimateModel) = discount(t(m), m.economics.ρ, m.domain.present_year)

T_adapt(T, A) = T .* sqrt.(1 .- A)

T_adapt(m::ClimateModel; M=false, R=false, G=false, A=false) = T_adapt(
    T(m, M=M, R=R, G=G),
    m.controls.adapt .* (1. .- .~past_mask(m) * ~A),
)

damage(β, E, Ta; discount=1.) = (β .* E .* Ta.^2) .* discount

damage(m; discounting=false, M=false, R=false, G=false, A=false) = damage(
    m.economics.β,
    E(m),
    T_adapt(m, M=M, R=R, G=G, A=A),
    discount=1. .+ discounting * (discount(m) .- 1.)
)

cost(CM, CR, CG, CA, ϵCG, E, T_MRG, Tb, q, M, R, G, A; discount=1., p=3.) = (
    ( ppm_to_GtCO2(q).*CM.*f(M, p=p) +
      E.*(CG.*f(G, p=p) .+ ϵCG*(G.>1.e-3)) +
      CR*f(R, p=p) +
      E.*CA.*f(A, p=p)
    ) .* discount
)
cost(m::ClimateModel; discounting=false, p=3., M=false, R=false, G=false, A=false) = cost(
    m.economics.mitigate_cost,
    m.economics.remove_cost,
    m.economics.geoeng_cost, 
    m.economics.adapt_cost,
    m.economics.epsilon_cost,
    E(m),
    T(m, M=M, R=R, G=G),
    m.economics.Tb,
    m.economics.baseline_emissions,
    m.controls.mitigate .* M,
    m.controls.remove .* R,
    m.controls.geoeng .* G,
    m.controls.adapt .* A,
    discount=1. .+ discounting * (discount(m) .- 1.),
    p=p
)

function cost(m::ClimateModel, controls::String; discounting=false)
    vars = Dict("M"=>false, "R"=>false, "G"=>false, "A"=>false)
    for (key, value) in vars
        if occursin(key, controls)
            vars[key] = true
        end
    end
    return cost(m, discounting=discounting; M=vars["M"], R=vars["R"], G=vars["G"], A=vars["A"])
end

benefit(damage_baseline, damage) = damage_baseline .- damage
benefit(m::ClimateModel; discounting=false, M=false, R=false, G=false, A=false) = benefit(
    damage(m, discounting=discounting),
    damage(m, discounting=discounting, M=M, R=R, G=G, A=A)
)

net_benefit(benefit, cost) = benefit .- cost
net_benefit(m::ClimateModel; discounting=true, M=false, R=false, G=false, A=false) = net_benefit(
    benefit(m, discounting=discounting, M=M, R=R, G=G, A=A),
    cost(m, discounting=discounting, M=M, R=R, G=G, A=A)
)

net_present_cost(cost, dt) = sum(cost*dt)
function net_present_cost(
        m::ClimateModel;
        discounting=true, M=false, R=false, G=false, A=false
    )
    return net_present_cost(
        cost(m, discounting=discounting, M=M, R=R, G=G, A=A),
        m.domain.dt
    )
end

net_present_benefit(net_benefit, dt) = sum(net_benefit*dt)
net_present_benefit(m::ClimateModel; discounting=true, M=false, R=false, G=false, A=false) = net_present_benefit(
    net_benefit(m, discounting=discounting, M=M, R=R, G=G, A=A),
    m.domain.dt
)
