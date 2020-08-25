module Models

export
    TemporalGrid, Economics, Physics, Controls,
    ClimateModelParameters, ClimateModel,

    CostBenefit, CostEffective,
    NetBudgetAllocation, AnnualBudgetAllocation,

    RampingEmissions, ramp_emissions,
    ExponentialGrowth, ExponentialDiscounting,
    PowerLawControls, PowerLawDamages,
    InitialConditions,
    FractionalEmissions,
    LogarithmicCO2Forcing,
    UpperLayerEBM, DeepLayerEBM, TwoLayerEBM

include("grid.jl")
include("physics.jl")
include("controls.jl")
include("economics.jl")
include("constraints.jl")

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
    grid::Grid
    economics::Economics
    physics::Physics
    constraints::Constraints
end

mutable struct ClimateModel
    name::String
    grid::Grid
    economics::Economics
    physics::Physics
    constraints::Constraints
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
    params.grid,
    params.economics,
    params.physics,
    params.constraints,
    controls
)

function ClimateModel(params::ClimateModelParameters)
    grid_ = params.grid
    t_ = collect(grid_.initial_year:grid_.dt:grid_.final_year)
    return ClimateModel(
        params,
        Controls(Dict(
            "M"=>zeros(size(t_)),
            "R"=>zeros(size(t_)),
            "G"=>zeros(size(t_)),
            "A"=>zeros(size(t_))
            ))
        )
end
    
end