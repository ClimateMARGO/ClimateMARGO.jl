module Diagnostics

using ClimateMARGO.Models
using ClimateMARGO.Utils

export
    t, future_mask,
    ramp_emissions, emissions, effective_emissions,
    c, F, Tslow, Tfast, T,
    τd, B, F2x, ECS,
    discount, f, E,
    damage, cost, benefit,
    net_benefit, net_present_cost, net_present_benefit

include("carbon.jl")
include("energy_balance.jl")
include("cost_benefit.jl")
include("utils.jl")

end