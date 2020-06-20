module Models

export Domain, Physics, Controls, Economics, ClimateModel

include("domain.jl")
include("physics.jl")
include("controls.jl")
include("economics.jl")

"""
    ClimateModel(name, domain, economics, physics, controls)

Create a named instance of an extremely idealized multi-control climate model, with
economic input parameters (`economics`), physical climate parameters (`physics`),
and climate control policies (`controls`) on some spatial-temporal grid (`domain`).

See also: [`domain`](@ref), [`Economics`](@ref), [`Physics`](@ref), [`Controls`](@ref),
[`optimize!`](@ref)
"""
mutable struct ClimateModel
    name::String
    domain::Domain
    economics::Economics
    physics::Physics
    controls::Controls
end

end