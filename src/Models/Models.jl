module Models

export Domain, Physics, Controls, Economics, ClimateModelParameters, ClimateModel

include("domain.jl")
include("physics.jl")
include("controls.jl")
include("economics.jl")

mutable struct ClimateModelParameters
    name::String
    domain::Domain
    economics::Economics
    physics::Physics
end

"""
    ClimateModel(name, ClimateModelParameters})

Create a named instance of an extremely idealized multi-control climate model, with
economic input parameters (`economics`), physical climate parameters (`physics`),
and climate control policies (`controls`) on some spatial-temporal grid (`domain`).

See also: [`ClimateModelParameters`](@ref), [`Controls`](@ref),
[`optimize_controls!`](@ref)
"""
mutable struct ClimateModel
    name::String
    domain::Domain
    economics::Economics
    physics::Physics
    controls::Controls
end

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