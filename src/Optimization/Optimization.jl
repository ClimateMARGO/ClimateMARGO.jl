module Optimization

using JuMP, Ipopt
using ClimateMARGO.Models
using ClimateMARGO.Diagnostics

export optimize_controls!

include("deterministic_optimization.jl")

end