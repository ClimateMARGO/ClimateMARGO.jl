module ClimateMARGO

if VERSION < v"1.3"
    @error "ClimateMARGO requires Julia v1.3 or newer."
end

using PyPlot
using JuMP, Ipopt

export ClimateModel, Domain, Physics, Economics, Physics, save, load

include("Models/Models.jl")
include("Optimization/Optimization.jl")
include("Diagnostics/Diagnostics.jl")
include("Utils/Utils.jl")
include("IO/IO.jl")

end