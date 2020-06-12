function F(a, c0, Finf, c, G)
    a .* log.( c/c0 ) .- G*Finf
end

function F(model; M=false, R=false, G=false)
    return F(
        model.physics.a, model.physics.c0, model.economics.Finf,
        c(model, M=M, R=R),
        model.controls.geoeng .* (1. .- .~future_mask(model) * ~G),
    )
end

F2x(a::Float64) = a*log(2)
F2x(model::ClimateModel) = F2x(model.physics.a)

ECS(a, B) = F2x(a)/B
ECS(model) = ECS(model.physics.a, model.physics.B)

B(a::Float64, ECS::Float64) = F2x(a)/ECS
B(model::ClimateModel; ECS=ECS(model)) = B(model.physics.a, ECS)

τd(Cd, B, κ) = (Cd/B) * (B+κ)/κ
τd(phys::Physics) = τd(phys.Cd, phys.B, phys.κ)
τd(model::ClimateModel) = τd(model.physics)

T_fast(F, κ, B; A=0.) = sqrt.(1. .- A) .* F/(κ + B)
T_fast(model::ClimateModel; M=false, R=false, G=false, A=false) = T_fast(
    F(model, M=M, R=R, G=G),
    model.physics.κ,
    model.physics.B,
    A=model.controls.adapt .* (1. .- .~future_mask(model) * ~A)
)

function T_slow(F, Cd, κ, B, t, dt; A=0.)
    τ = τd(Cd, κ, B)
    return sqrt.(1. .- A) .* (
        (κ/B) / (κ + B) *
        exp.( - (t .- (t[1] - dt)) / τ) .*
        cumsum( (exp.( (t .- (t[1] - dt)) / τ) / τ) .* F * dt)
    )
end
T_slow(model::ClimateModel; M=false, R=false, G=false, A=false) = T_slow(
    F(model, M=M, R=R, G=G),
    model.physics.Cd,
    model.physics.κ,
    model.physics.B,
    t(model),
    model.domain.dt,
    A=model.controls.adapt .* (1. .- .~future_mask(model) * ~A)
)

T(T0, F, Cd, κ, B, t, dt; A=0.) = sqrt.(1. .- A) .* (
    T0 .+
    T_fast(F, κ, B) .+
    T_slow(F, Cd, κ, B, t, dt)
)
T(model::ClimateModel; M=false, R=false, G=false, A=false) = T(
    model.physics.T0,
    F(model, M=M, R=R, G=G),
    model.physics.Cd,
    model.physics.κ,
    model.physics.B,
    t(model),
    model.domain.dt,
    A=model.controls.adapt .* (1. .- .~future_mask(model) * ~A)
)