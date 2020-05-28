module MARGO

if VERSION < v"1.1"
    @error "Margo requires Julia v1.1 or newer."
end

using PyPlot
using JuMP, Ipopt

export
    ClimateModel,
    Controls,
    Economics,
    Physics,
    optimize_controls!,
    step_forward!,
    add_emissions_bump!,
    plot_state,
    deep_copy


### Load code
include("model.jl")
include("diagnostics.jl")
include("defaults.jl")
include("optimization.jl")
include("plotting.jl")
include("steppingforward.jl")

end

