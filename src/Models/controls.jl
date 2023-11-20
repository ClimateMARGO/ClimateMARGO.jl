"""
    Controls(mitigate, remove, geoeng, adapt)

Create data structure for climate controls.

# Examples
```jldoctest
a = zeros(4);
C = Controls(a, a, a, a);
C.geoeng

# output
4-element Array{Float64,1}:
 0.0
 0.0
 0.0
 0.0
```

See also: [`ClimateModel`](@ref)
"""
mutable struct Controls
    mitigate::Vector{<:Real}
    remove::Vector{<:Real}
    geoeng::Vector{<:Real}
    adapt::Vector{<:Real}
end