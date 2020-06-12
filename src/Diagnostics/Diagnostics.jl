module Diagnostics

using ClimateMARGO.Models

export t, future_mask, ramp_emissions, emissions, effective_emissions, c, F, T

include("carbon.jl")
include("energy_balance.jl")
include("cost_benefit.jl")
include("utils.jl")

end