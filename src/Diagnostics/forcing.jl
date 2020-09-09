"""
    F(a, c0, Finf, c, G; F0=0.)
"""
function F(a, c0, Finf, c, G; F0=0.)
    F0 .+ a .* log.( c/c0 ) .- G*Finf
end

"""
    F(m::ClimateModel; M=false, R=false, G=false)
"""
function F(m; M=false, R=false, G=false, F0=0.)
    return F(
        m.physics.a, m.physics.c0, m.economics.Finf,
        c(m, M=M, R=R),
        m.controls.geoeng .* (1. .- .~future_mask(m) * ~G),
        F0=F0
    )
end

F2x(a::Float64) = a*log(2)
F2x(m::ClimateModel) = F2x(m.physics.a)

ECS(a, λ) = F2x(a)/λ
ECS(params::ClimateModelParameters) = ECS(params.physics.a, m.physics.λ)
ECS(m::ClimateModel) = ECS(m.physics.a, m.physics.λ)

calc_λ(a::Float64, ECS::Float64) = F2x(a)/ECS
calc_λ(params::ClimateModelParameters; ECS=ECS(params)) = calc_λ(params.physics.a, ECS)
calc_λ(m::ClimateModel; ECS=ECS(m)) = calc_λ(m.physics.a, ECS)

# Shallow thermocline approximation model

τd(Cd, λ, κ) = (Cd/λ) * (λ+κ)/κ
τd(phys::Physics) = τd(phys.Cd, phys.λ, phys.κ)
τd(m::ClimateModel) = τd(m.physics)

"""
    T_fast(F, κ, λ; A=0.)
"""
T_fast(F, κ, λ; A=0.) = sqrt.(1. .- A) .* F/(κ + λ)

"""
    T_fast(m::ClimateModel; M=false, R=false, G=false, A=false)
"""
T_fast(m::ClimateModel; M=false, R=false, G=false, A=false) = T_fast(
    F(m, M=M, R=R, G=G),
    m.physics.κ,
    m.physics.λ,
    A=m.controls.adapt .* (1. .- .~future_mask(m) * ~A)
)

"""
    T_slow(F, Cd, κ, λ, t, dt; A=0.)
"""
function T_slow(F, Cd, κ, λ, t, dt; A=0.)
    τ = τd(Cd, κ, λ)
    return sqrt.(1. .- A) .* (
        (κ/λ) / (κ + λ) *
        exp.( - (t .- (t[1] - dt)) / τ) .*
        cumsum( (exp.( (t .- (t[1] - dt)) / τ) / τ) .* F * dt)
    )
end

"""
    T_slow(m::ClimateModel; M=false, R=false, G=false, A=false)
"""
T_slow(m::ClimateModel; M=false, R=false, G=false, A=false) = T_slow(
    F(m, M=M, R=R, G=G),
    m.physics.Cd,
    m.physics.κ,
    m.physics.λ,
    t(m),
    m.domain.dt,
    A=m.controls.adapt .* (1. .- .~future_mask(m) * ~A)
)

"""
    T(T0, F, Cd, κ, λ, t, dt; A=0.)

Returns the sum of the initial, fast mode, and slow mode temperature change.

# Arguments
- `T0::Float64`: warming relative to pre-industrial [°C]
- `F::Array{Float64}`: change in radiative forcing since the initial time ``t_{0}`` [W/m``{2}``]
- `Cd::Float64`: deep ocean heat capacity [W yr m``^{2}`` K``^{-1}``]
- `κ::Float64`: ocean heat uptake rate [W m``^{2}`` K``^{-1}``]
- `λ::Float64`: feedback parameter [W m``^{2}`` K``^{-1}``]
- `t::Array{Float64}`: year [years]
- `dt::Float64`: timestep [years]
- `A::Float64`: Adaptation control [fraction]

"""
T(T0, F, Cd, κ, λ, t, dt; A=0.) = sqrt.(1. .- A) .* (
    T0 .+
    T_fast(F, κ, λ) .+
    T_slow(F, Cd, κ, λ, t, dt)
)

"""
    T(m::ClimateModel; M=false, R=false, G=false, A=false)

Returns the sum of the initial, fast mode, and slow mode temperature change,
as diagnosed from `m` and modified by the climate controls activated by the
Boolean kwargs.
"""
T(m::ClimateModel; M=false, R=false, G=false, A=false) = T(
    m.physics.T0,
    F(m, M=M, R=R, G=G),
    m.physics.Cd,
    m.physics.κ,
    m.physics.λ,
    t(m),
    m.domain.dt,
    A=m.controls.adapt .* (1. .- .~future_mask(m) * ~A)
)

## Two-layer model
# Dependent parameters definitions
b(λ, κ, ϵ, Cu, Cd) = (λ+ϵ*κ)/Cu - κ/Cd
b(phys::Physics) = b(phys.λ, phys.κ, phys.ϵ, phys.Cu, phys.Cd)
b(m::ClimateModel) = b(m.physics)

δ(b_, λ, κ, Cu, Cd) = b_^2 - 4(λ*κ)/(Cu*Cd)
δ(phys::Physics) = δ(b(phys), phys.λ, phys.κ, phys.Cu, phys.Cd)
δ(m::ClimateModel) = δ(m.physics)

τf(b_, δ_, λ, κ, Cu, Cd) = Cu*Cd/(2*λ*κ)*(b_ - √δ_)
τf(phys::Physics) = τf(b(phys), δ(phys), phys.λ, phys.κ, phys.Cu, phys.Cd)
τf(m::ClimateModel) = τf(m.physics)

τs(b_, δ_, λ, κ, Cu, Cd) = Cu*Cd/(2*λ*κ)*(b_ + √δ_)
τs(phys::Physics) = τs(b(phys), δ(phys), phys.λ, phys.κ, phys.Cu, phys.Cd)
τs(m::ClimateModel) = τs(m.physics)

bϕ(λ, κ, ϵ, Cu, Cd) = (λ+ϵ*κ)/Cu + κ/Cd
bϕ(phys::Physics) = bϕ(phys.λ, phys.κ, phys.ϵ, phys.Cu, phys.Cd)
bϕ(m::ClimateModel) = bϕ(m.physics)

ϕf(bϕ_, δ_, κ, ϵ, Cu) = Cu/(2*ϵ*κ)*(bϕ_ - √δ_)
ϕf(phys::Physics) = ϕf(b(phys), δ(phys), phys.κ, phys.ϵ, phys.Cu)
ϕf(m::ClimateModel) = ϕf(m.physics)

ϕs(bϕ_, δ_, κ, ϵ, Cu) = Cu/(2*ϵ*κ)*(bϕ_ + √δ_)
ϕs(phys::Physics) = ϕs(b(phys), δ(phys), phys.κ, phys.ϵ, phys.Cu)
ϕs(m::ClimateModel) = ϕs(m.physics)

af(ϕs_, ϕf_, τf_, λ, Cu) = ϕs_*τf_/(Cu*(ϕs_ - ϕf_))*λ
af(phys::Physics) = af(ϕs(phys), ϕf(phys), τf(phys), phys.λ, phys.Cu)
af(m::ClimateModel) = af(m.physics)

as(ϕs_, ϕf_, τs_, λ, Cu) = -ϕf_*τs_/(Cu*(ϕs_ - ϕf_))*λ
as(phys::Physics) = as(ϕs(phys), ϕf(phys), τs(phys), phys.λ, phys.Cu)
as(m::ClimateModel) = as(m.physics)

"""
    T_mode(F, λ, am, τm, t, dt; A=0.)
"""
function T_mode(F, λ, am, τm, t, dt)
    return (am * (F/λ)) .* (1. .-
        exp.( - (t .- (t[1] - dt)) / τm) .*
        cumsum( exp.( (t .- (t[1] - dt)) / τm) .* F * dt )
    )
end

function T(T0, F, λ, af_, τf_, as_, τs_, t, dt; A=0.)
    return sqrt.(1. .- A) .* (
        T0 .+
        T_mode(F, λ, af_, τf_, t, dt) .+
        T_mode(F, λ, as_, τs_, t, dt)
    )
end

"""
    T(m::ClimateModel; M=false, R=false, G=false, A=false)

Returns the sum of the initial, fast mode, and slow mode temperature change,
as diagnosed from `m` and modified by the climate controls activated by the
Boolean kwargs.
"""
T(m::ClimateModel; M=false, R=false, G=false, A=false) = T(
    m.physics.T0,
    F(m, M=M, R=R, G=G),
    af(m),
    τf(m),
    as(m),
    τs(m),
    t(m),
    m.domain.dt,
    A=m.controls.adapt .* (1. .- .~future_mask(m) * ~A)
)