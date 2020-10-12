module ClimateMARGO

if VERSION < v"1.5"
    @error "ClimateMARGO requires Julia v1.5 or newer."
end

include("Models/Models.jl")
include("Utils/Utils.jl")
include("Diagnostics/Diagnostics.jl")
include("Optimization/Optimization.jl")
include("IO/IO.jl")
include("PolicyResponse/PolicyResponse.jl")
include("Plotting/Plotting.jl")

end
