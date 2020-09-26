
## Deep-layer model (shallow thermocline approximation)
# Diagnostic constants
τd(Cd, λ, κ) = (Cd/λ) * (λ+κ)/κ
τd(ebm::DeepLayerEBM) = τd(ebm.Cd, ebm.λ, ebm.κ)

# Diagnostic variables
"""
    T_fast(F, κ, λ)
"""
T_fast(F, κ, λ) = F/(κ + λ)

"""
    T_fast(ebm::DeepLayerEBM, F)
"""
T_fast(ebm::DeepLayerEBM, F) = T_fast(
    F,
    ebm.κ,
    ebm.λ,
)

"""
    T_fast(m::ClimateModel; M=false, R=false, G=false)
"""
T_fast(m::ClimateModel; M=false, R=false, G=false) = T_fast(
    m.physics.ebm,
    F(m, M=M, R=R, G=G)
)

"""
    T_slow(F, Cd, κ, λ, t, dt)
"""
function T_slow(F, Cd, κ, λ, t, dt)
    τ = τd(Cd, κ, λ)
    return (
        (κ/λ) / (κ + λ) *
        exp.( - (t .- (t[1] - dt)) / τ) .*
        cumsum( deferred( (exp.( (t .- (t[1] - dt)) / τ) / τ) .* F * dt ) )
    )
end

"""
    T_slow(tgrid::TemporalGrid, ebm::DeepLayerEBM, F)
"""
T_slow(tgrid::TemporalGrid, ebm::DeepLayerEBM, F) = T_slow(
    F,
    ebm.Cd,
    ebm.κ,
    ebm.λ,
    t(tgrid),
    tgrid.dt,
)
"""
    T_slow(m::ClimateModel; M=false, R=false, G=false)
"""
T_slow(m::ClimateModel; M=false, R=false, G=false) = T_slow(
    m.grid,
    m.physics.ebm,
    F(m, M=M, R=R, G=G),
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
T(tgrid::TemporalGrid, ebm::DeepLayerEBM, F; A=0.) = T(
    ebm.T0,
    F,
    ebm.Cd,
    ebm.κ,
    ebm.λ,
    t(tgrid),
    tgrid.dt,
    A=A
)

## Two-layer model
# Diagnostic constants
b(λ, κ, ϵ, Cu, Cd) = (λ+ϵ*κ)/Cu + κ/Cd
b(ebm::TwoLayerEBM) = b(ebm.λ, ebm.κ, ebm.ϵ, ebm.Cu, ebm.Cd)

δ(b_, λ, κ, Cu, Cd) = b_^2 - 4(λ*κ)/(Cu*Cd)
δ(ebm::TwoLayerEBM) = δ(b(ebm), ebm.λ, ebm.κ, ebm.Cu, ebm.Cd)

τf(b_, δ_, λ, κ, Cu, Cd) = Cu*Cd/(2*λ*κ)*(b_ - √δ_)
τf(ebm::TwoLayerEBM) = τf(b(ebm), δ(ebm), ebm.λ, ebm.κ, ebm.Cu, ebm.Cd)

τs(b_, δ_, λ, κ, Cu, Cd) = Cu*Cd/(2*λ*κ)*(b_ + √δ_)
τs(ebm::TwoLayerEBM) = τs(b(ebm), δ(ebm), ebm.λ, ebm.κ, ebm.Cu, ebm.Cd)

bϕ(λ, κ, ϵ, Cu, Cd) = (λ+ϵ*κ)/Cu - κ/Cd
bϕ(ebm::TwoLayerEBM) = bϕ(ebm.λ, ebm.κ, ebm.ϵ, ebm.Cu, ebm.Cd)

ϕf(bϕ_, δ_, κ, ϵ, Cu) = Cu/(2*ϵ*κ)*(bϕ_ - √δ_)
ϕf(ebm::TwoLayerEBM) = ϕf(bϕ(ebm), δ(ebm), ebm.κ, ebm.ϵ, ebm.Cu)

ϕs(bϕ_, δ_, κ, ϵ, Cu) = Cu/(2*ϵ*κ)*(bϕ_ + √δ_)
ϕs(ebm::TwoLayerEBM) = ϕs(bϕ(ebm), δ(ebm), ebm.κ, ebm.ϵ, ebm.Cu)

af(ϕs_, ϕf_, τf_, λ, Cu) = ϕs_*τf_ /(Cu*(ϕs_ - ϕf_))*λ
af(ebm::TwoLayerEBM) = af(ϕs(ebm), ϕf(ebm), τf(ebm), ebm.λ, ebm.Cu)

as(ϕs_, ϕf_, τs_, λ, Cu) = -ϕf_*τs_ /(Cu*(ϕs_ - ϕf_))*λ
as(ebm::TwoLayerEBM) = as(ϕs(ebm), ϕf(ebm), τs(ebm), ebm.λ, ebm.Cu)

# Diagnostic variables
"""
    T_mode(F, λ, am, τm, t, dt)
"""
function T_mode(F, λ, am, τm, t, dt)
    return (am/λ) .* (
        exp.( - (t .- t[1]) / τm) .*
        cumsum( deferred( exp.( (t .- t[1] ) / τm) .* F * dt ) ) / τm 
    )
end

function T(T0, F, λ, af_, τf_, as_, τs_, t, dt; A=0.)
    T_fast_mode = T_mode(F, λ, af_, τf_, t, dt)
    T_slow_mode = T_mode(F, λ, as_, τs_, t, dt)
    return (T0 .+ T_slow_mode .+ T_fast_mode)
end

"""
    T(m::ClimateModel; M=false, R=false, G=false, A=false)

Returns the sum of the initial, fast mode, and slow mode temperature change,
as diagnosed from `m` and modified by the climate controls activated by the
Boolean kwargs.
"""
T(tgrid::TemporalGrid, ebm::TwoLayerEBM, F; A=0.) = T(
    ebm.T0, F, ebm.λ, af(ebm), τf(ebm), as(ebm), τs(ebm),
    t(tgrid), tgrid.dt,
    A=A
)

## Generalized temperature diagnostic method
T(m::ClimateModel; M=false, R=false, G=false, A=false) = T(
    m.grid,
    m.physics.ebm,
    F(m, M=M, R=R, G=G),
    A=m.controls.deployed["A"] .* allow_control(m, A)
)