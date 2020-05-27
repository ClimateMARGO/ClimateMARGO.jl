module MARGO

if VERSION < v"1.1"
    @error "Margo requires Julia v1.1 or newer."
end

using PyPlot
using JuMP, Ipopt

### Load code
include("model.jl")
include("diagnostics.jl")
include("defaults.jl")
include("optimization.jl")
include("plotting.jl")
include("steppingforward.jl")

end

