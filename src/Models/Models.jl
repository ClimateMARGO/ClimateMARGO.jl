module Models

export Domain, Physics, Controls, Economics, ClimateModelParameters, ClimateModel

include("domain.jl")
include("physics.jl")
include("controls.jl")
include("economics.jl")

"""
    ClimateModelParameters(name, domain::Domain, economics::Economics, physics::Physics)

Create a named instance of the MARGO climate model parameters, which include
economic input parameters (`economics`), physical climate parameters (`physics`),
and climate control policies (`controls`) on some spatial-temporal grid (`domain`).

Use these to construct a [`ClimateModel`](@ref), which also contains the optimized 
controls.
"""
mutable struct ClimateModelParameters
    name::String
    domain::Domain
    economics::Economics
    physics::Physics
end

mutable struct ClimateModel
    name::String
    domain::Domain
    economics::Economics
    physics::Physics
    controls::Controls
end

"""
    ClimateModel(params::ClimateModelParameters[, controls::Controls])

Create an instance of an extremely idealized multi-control climate model. The 
returned object contains the [`ClimateModelParameters`](@ref), and will contain
the optimized [`Controls`](@ref). These can be computed using 
[`optimize_controls!`](@ref).
"""
ClimateModel(params::ClimateModelParameters, controls::Controls) = ClimateModel(
    params.name,
    params.domain,
    params.economics,
    params.physics,
    controls
)
function ClimateModel(params::ClimateModelParameters)
    dom = params.domain
    t = collect(dom.initial_year:dom.dt:dom.final_year)
    return ClimateModel(
        params,
        Controls(
            zeros(size(t)),
            zeros(size(t)),
            zeros(size(t)),
            zeros(size(t))
            )
        )
end
    
end