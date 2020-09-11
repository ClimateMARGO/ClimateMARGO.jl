##
abstract type CarbonCycleParams end

mutable struct FractionalEmissions <: CarbonCycleParams
    c0::Real
    r::Real
end

## 
abstract type RadiativeForcingParams end

mutable struct LogarithmicCO2Forcing <: RadiativeForcingParams
    F0::Real # initial forcing relative to reference state
    a::Real # logarithmic CO2 forcing coefficient
end

##
abstract type EBMParams end

mutable struct DeepLayerEBM <: EBMParams
    T0::Real  # initial upper-layer temperature relative to reference state
    λ::Real   # feedback parameter
    Cd::Real  # deep ocean heat capacity
    κ::Real   # deep ocean heat uptake rate
end
mutable struct TwoLayerEBM <: EBMParams
    T0::Real  # initial upper-layer temperature relative to reference state
    λ::Real   # feedback parameter
    κ::Real   # deep ocean heat uptake rate
    Cu::Real  # upper ocean heat capacity
    Cd::Real  # deep ocean heat capacity
    ϵ::Real   # heat uptake efficacy
end
TwoLayerEBM(T0, λ, κ, Cu, Cd) = TwoLayerEBM(T0, λ, κ, Cu, Cd, 1.)
UpperLayerEBM(T0, λ, Cu) = TwoLayerEBM(T0, λ, 1.e-8, Cu, Cu)

"""
    Physics(Initial, Carbon, Forcing, EBM)

Create data structure for physical model parameters.

See also: [`ClimateModel`](@ref)
"""
mutable struct Physics
    carbon::CarbonCycleParams
    forcing::RadiativeForcingParams
    ebm::EBMParams
end