"""
    Controls(mitigate, remove, geoeng, adapt)

Create data structure for climate controls.

# Examples
```jldoctest
a = zeros(4);
C = Controls(a, a, a, a);
C.geoeng

# output
4-element Array{Real,1}:
 0.0
 0.0
 0.0
 0.0
```

See also: [`ClimateModel`](@ref)
"""
mutable struct Controls
    deployed::Dict{String, Array{Float64,1}}
    init::Dict{String, Float64}
end
Controls(deployed) = Controls(
    deployed,
    Dict("M"=>0.03, "R"=>0., "G"=>0., "A"=>0.)
)