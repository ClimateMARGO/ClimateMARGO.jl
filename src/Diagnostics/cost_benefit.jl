f(α::Array; p=2.) = α.^p # shape of individual cost functions

E(t, E0, γ) = E0 * (1. .+ γ).^(t .- t[1])
E(m) = E(t(m), m.economics.E0, m.economics.γ)

discount(t, ρ, tp) = .~future_mask(t, tp) .* (1. .+ ρ) .^ (- (t .- tp))
discount(m::ClimateModel) = discount(t(m), m.economics.ρ, m.domain.present_year)

damage(β, E, T, A; discount=1.) = ((1. .- A) .* β .* E .* T.^2) .* discount

damage(m; discounting=false, M=false, R=false, G=false, A=false) = damage(
    m.economics.β,
    E(m),
    T(m, M=M, R=R, G=G, A=A),
    0.,
    discount=1. .+ discounting * (discount(m) .- 1.)
)

cost(CM, CR, CG, CA, E, M, R, G, A; discount=1., p=2.) = (
    ( E.*(CM*f(M, p=p) + CG*f(G, p=p)) + CR*f(R, p=p) + + CA*f(A, p=p) ) .* discount
)
cost(m::ClimateModel; discounting=false, p=2., M=false, R=false, G=false, A=false) = cost(
    m.economics.mitigate_cost,
    m.economics.remove_cost,
    m.economics.geoeng_cost, 
    m.economics.adapt_cost,
    E(m),
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
net_benefit(m::ClimateModel; discounting=false, M=false, R=false, G=false, A=false) = net_benefit(
    benefit(m, discounting=discounting, M=M, R=R, G=G, A=A),
    cost(m, discounting=discounting, M=M, R=R, G=G, A=A)
)

net_present_cost(cost, dt) = sum(cost*dt)
function net_present_cost(
        m::ClimateModel;
        discounting=false, M=false, R=false, G=false, A=false
    )
    return net_present_cost(
        cost(m, discounting=discounting, M=M, R=R, G=G, A=A),
        m.domain.dt
    )
end

net_present_benefit(net_benefit, dt) = sum(net_benefit*dt)
net_present_benefit(m::ClimateModel; discounting=false, M=false, R=false, G=false, A=false) = net_present_benefit(
    net_benefit(m, discounting=discounting, M=M, R=R, G=G, A=A),
    m.domain.dt
)
