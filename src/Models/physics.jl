"""
    Physics(C0, T0, r, a, λ, Cu, Cd, κ, ϵ)

Create data structure for model physics.

See also: [`ClimateModel`](@ref)
"""
mutable struct Physics
    c0::Real  # initial CO2e concentration, relative to PI
    T0::Real  # initial temperature, relative to PI

    r::Real   # long-term airborne fraction of CO2e

    a::Real   # logarithmic CO2 forcing coefficient
    λ::Real   # feedback parameter
    
    Cu::Real  # upper ocean heat capacity
    Cd::Real  # deep ocean heat capacity
    κ::Real   # deep ocean heat uptake rate
    ϵ::Real  # heat uptake efficacy
end
Physics(C0, T0, r, a, λ, Cu, Cd, κ) = Physics(C0, T0, r, a, λ, Cu, Cd, κ, 1.)
Physics(C0, T0, r, a, λ, Cu) = Physics(C0, T0, r, a, λ, Cu, Cu, 1.e-8, 1.)