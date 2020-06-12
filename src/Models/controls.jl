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
    mitigate::Array{Float64,1}
    remove::Array{Float64,1}
    geoeng::Array{Float64,1}
    adapt::Array{Float64,1}
end


"""
    init_zero_controls(t)

Return initial state of uniformly-zero climate controls.

See also: [`Controls`](@ref)
"""
function init_zero_controls(t::Array{Float64,1})
    c = Controls(
        zeros(size(t)),
        zeros(size(t)),
        zeros(size(t)),
        zeros(size(t))
    )
    return c
end