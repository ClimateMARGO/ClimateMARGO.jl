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
        m.controls.geoeng .* allow_control(m, G),
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

## Two-layer model
# Diagnostic constants
b(λ, κ, ϵ, Cu, Cd) = (λ+ϵ*κ)/Cu + κ/Cd
b(phys::Physics) = b(phys.λ, phys.κ, phys.ϵ, phys.Cu, phys.Cd)

δ(b_, λ, κ, Cu, Cd) = b_^2 - 4(λ*κ)/(Cu*Cd)
δ(phys::Physics) = δ(b(phys), phys.λ, phys.κ, phys.Cu, phys.Cd)

τf(b_, δ_, λ, κ, Cu, Cd) = Cu*Cd/(2*λ*κ)*(b_ - √δ_)
τf(phys::Physics) = τf(b(phys), δ(phys), phys.λ, phys.κ, phys.Cu, phys.Cd)

τs(b_, δ_, λ, κ, Cu, Cd) = Cu*Cd/(2*λ*κ)*(b_ + √δ_)
τs(phys::Physics) = τs(b(phys), δ(phys), phys.λ, phys.κ, phys.Cu, phys.Cd)

bϕ(λ, κ, ϵ, Cu, Cd) = (λ+ϵ*κ)/Cu - κ/Cd
bϕ(phys::Physics) = bϕ(phys.λ, phys.κ, phys.ϵ, phys.Cu, phys.Cd)

ϕf(bϕ_, δ_, κ, ϵ, Cu) = Cu/(2*ϵ*κ)*(bϕ_ - √δ_)
ϕf(phys::Physics) = ϕf(bϕ(phys), δ(phys), phys.κ, phys.ϵ, phys.Cu)

ϕs(bϕ_, δ_, κ, ϵ, Cu) = Cu/(2*ϵ*κ)*(bϕ_ + √δ_)
ϕs(phys::Physics) = ϕs(bϕ(phys), δ(phys), phys.κ, phys.ϵ, phys.Cu)

af(ϕs_, ϕf_, τf_, λ, Cu) = ϕs_*τf_ /(Cu*(ϕs_ - ϕf_))*λ
af(phys::Physics) = af(ϕs(phys), ϕf(phys), τf(phys), phys.λ, phys.Cu)

as(ϕs_, ϕf_, τs_, λ, Cu) = -ϕf_*τs_ /(Cu*(ϕs_ - ϕf_))*λ
as(phys::Physics) = as(ϕs(phys), ϕf(phys), τs(phys), phys.λ, phys.Cu)

# Diagnostic variables
"""
    T_mode(F, λ, am, τm, t, dt)
"""
function T_mode(F, λ, am, τm, t, dt)
    return (am/λ) .* (
        exp.( - (t .- t[1]) / τm) .*
        cumsum( exp.( (t .- t[1] ) / τm) .* F * dt ) / τm 
    )
end

"""
    T(T0, F, λ, af_, τf_, as_, τs_, t, dt; A=0.)

Returns the sum of the initial, fast mode, and slow mode temperature change.

# Arguments
- `T0::Float64`: warming relative to pre-industrial [°C]
- `F::Array{Float64}`: change in radiative forcing since the initial time ``t_{0}`` [W/m``{2}``]
- `λ::Float64`: feedback parameter [W m``^{2}`` K``^{-1}``]
- `af_::Float64`: fast mode fraction [1]
- `τf_::Float64`: fast mode timescale [years]
- `as_::Float64`: slow mode fraction [1]
- `τs_::Float64`: slow mode timescale [years]
- `t::Array{Float64}`: year [years]
- `dt::Float64`: timestep [years]
- `A::Float64`: adaptation control [fraction]

"""
function T(T0, F, λ, af_, τf_, as_, τs_, t, dt; A=0.)
    T_fast_mode = T_mode(F, λ, af_, τf_, t, dt)
    T_slow_mode = T_mode(F, λ, as_, τs_, t, dt)
    return (T0 .+ T_fast_mode .+ T_slow_mode) .* sqrt.(1. .- A)
end

T(grid::Grid, phys::Physics, F; A=0.) = T(
    phys.T0, F, phys.λ, af(phys), τf(phys), as(phys), τs(phys),
    t(grid), grid.dt,
    A=A
)

"""
    T(m::ClimateModel; M=false, R=false, G=false, A=false)
Returns the sum of the initial, fast mode, and slow mode temperature change,
as diagnosed from `m` and modified by the climate controls activated by the
Boolean kwargs.
"""
T(m::ClimateModel; M=false, R=false, G=false, A=false) = T(
    m.grid,
    m.physics,
    F(m, M=M, R=R, G=G),
    A=m.controls.adapt .* allow_control(m, A)
)