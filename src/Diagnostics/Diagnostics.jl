module Diagnostics

using ClimateMARGO.Models
using ClimateMARGO.Utils

export
    t, future_mask, allow_control, deferred,
    ramp_emissions, emissions, effective_emissions,
    c, F, T_mode, T,
    af, τf, as, τs, calc_λ, F2x, ECS,
    discount, f, E,
    damage, cost, benefit,
    net_benefit, net_present_cost, net_present_benefit

include("carbon.jl")
include("energy_balance.jl")
include("cost_benefit.jl")
include("utils.jl")

end