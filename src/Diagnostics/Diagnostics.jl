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

include("utils.jl")
include("emissions.jl")
include("carbon_cycle.jl")
include("energy_balance_exact.jl")
include("cost_benefit.jl")

end