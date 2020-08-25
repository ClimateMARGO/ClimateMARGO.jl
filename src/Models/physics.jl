mutable struct InitialConditions
    c0::Real  # initial CO2e concentration, relative to PI
    F0::Real  # initial radiative forcing, relative to PI
    T0::Real  # initial temperature, relative to PI
end

##
abstract type CarbonCycleParams end

mutable struct FractionalEmissions <: CarbonCycleParams
    r::Real
end

## 
abstract type RadiativeForcingParams end

mutable struct LogarithmicCO2Forcing <: RadiativeForcingParams
    a::Real
end

##
abstract type EBMParams end

mutable struct DeepLayerEBM <: EBMParams
    λ::Real   # feedback parameter
    Cd::Real  # deep ocean heat capacity
    κ::Real   # deep ocean heat uptake rate
end

mutable struct TwoLayerEBM <: EBMParams
    λ::Real   # feedback parameter
    κ::Real   # deep ocean heat uptake rate
    Cu::Real  # upper ocean heat capacity
    Cd::Real  # deep ocean heat capacity
    ϵ::Real   # heat uptake efficacy
end
TwoLayerEBM(λ, κ, Cu, Cd) = TwoLayerEBM(λ, κ, Cu, Cd, 1.)

UpperLayerEBM(λ, Cu) = TwoLayerEBM(λ, 0., Cu, Cu)

"""
    Physics(Initial, Carbon, Forcing, EBM)

Create data structure for physical model parameters.

See also: [`ClimateModel`](@ref)
"""
mutable struct Physics
    initial::InitialConditions
    carbon::CarbonCycleParams
    forcing::RadiativeForcingParams
    ebm::EBMParams
end