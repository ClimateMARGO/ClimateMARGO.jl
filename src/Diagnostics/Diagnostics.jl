module Diagnostics

using ClimateMARGO.Models
using ClimateMARGO.Utils

export
    t, future_mask, allow_control,
    ramp_emissions, emissions, effective_emissions,
    c, Flog, F, Tslow, Tfast, T,
    τd, B, F2x, ECS,
    discount, f, E,
    damage, cost, benefit,
    net_benefit, net_present_cost, net_present_benefit

include("utils.jl")
include("emissions.jl")
include("carbon.jl")
include("forcing.jl")
include("temperature.jl")
#include("damages.jl")

end