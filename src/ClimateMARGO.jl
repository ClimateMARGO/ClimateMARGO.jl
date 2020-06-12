module ClimateMARGO

if VERSION < v"1.3"
    @error "ClimateMARGO requires Julia v1.3 or newer."
end

using PyPlot
using JuMP, Ipopt

export
    ClimateModel, Domain, Physics, Economics, Physics

include("Models/Models.jl")
include("Diagnostics/Diagnostics.jl")
include("Utils/Utils.jl")

end

