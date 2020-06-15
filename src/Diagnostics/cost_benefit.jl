f(α::Array; p=2.) = α.^p # shape of individual cost functions

E(t, E0, γ) = E0 * (1. .+ γ).^(t .- t[1])
E(m) = E(t(m), m.economics.E0, m.economics.γ)

discount(t, ρ, tp) = .~future_mask(t, tp) .* (1. .+ ρ) .^ (- (t .- tp))
discount(m::ClimateModel) = discount(t(m), m.economics.ρ, m.domain.present_year)

D(β, E, T, A; discount=1.) = ((1. .- A) .* β .* E .* T.^2) .* discount

D(m; discounting=false, M=false, R=false, G=false, A=false) = D(
    m.economics.β,
    E(m),
    T(m, M=M, R=R, G=G, A=A),
    0.,
    discount=1. .+ discounting * (discount(m) .- 1.)
)

C(CM, CR, CG, CA, E, M, R, G, A; discount=1., p=2.) = (
    ( E.*(CM*f(M, p=p) + CG*f(G, p=p)) + CR*f(R, p=p) + + CA*f(A, p=p) ) .* discount
)

C(m::ClimateModel; discounting=false, p=2., M=false, R=false, G=false, A=false) = C(
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

function C(m::ClimateModel, controls::String; discounting=false)
    vars = Dict("M"=>false, "R"=>false, "G"=>false, "A"=>false)
    for (key, value) in vars
        if occursin(key, controls)
            vars[key] = true
        end
    end
    return C(m, discounting=discounting; M=vars["M"], R=vars["R"], G=vars["G"], A=vars["A"])
end

B(D_baseline, D) = D_baseline .- D
B(m::ClimateModel; discounting=false, M=false, R=false, G=false, A=false) = B(
    D(m, discounting=discounting),
    D(m, discounting=discounting, M=M, R=R, G=G, A=A)
)

NB(B, C) = B .- C
NB(m::ClimateModel; discounting=false, M=false, R=false, G=false, A=false) = NB(
    B(m, discounting=discounting, M=M, R=R, G=G, A=A),
    C(m, discounting=discounting, M=M, R=R, G=G, A=A)
)

NPC(C, dt) = sum(C*dt)
NPC(m::ClimateModel; discounting=false, M=false, R=false, G=false, A=false) = NPC(
    C(m, discounting=discounting, M=M, R=R, G=G, A=A),
    m.domain.dt
)
NPB(NB, dt) = sum(NB*dt)
NPB(m::ClimateModel; discounting=false, M=false, R=false, G=false, A=false) = NPB(
    NB(m, discounting=discounting, M=M, R=R, G=G, A=A),
    m.domain.dt
)
