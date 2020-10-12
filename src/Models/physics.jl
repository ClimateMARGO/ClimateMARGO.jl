"""
    Physics(C0, T0, a, B, Cd, κ, r)

Create data structure for model physics.

See also: [`ClimateModel`](@ref)
"""
mutable struct Physics
    c0::Float64  # initial CO2e concentration, relative to PI
    T0::Float64  # initial temperature, relative to PI
    
    a::Float64   # logarithmic CO2 forcing coefficient
    B::Float64   # feedback parameter
    
    Cd::Float64  # deep ocean heat capacity
    κ::Float64   # deep ocean heat uptake rate
    
    r::Float64   # long-term airborne fraction of CO2e
end