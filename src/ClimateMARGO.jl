module ClimateMARGO

if VERSION < v"1.3"
    @error "ClimateMARGO requires Julia v1.3 or newer."
end

include("Models/Models.jl")
include("Diagnostics/Diagnostics.jl")
include("Optimization/Optimization.jl")
include("Utils/Utils.jl")
include("IO/IO.jl")
include("PolicyResponse/PolicyResponse.jl")
include("Plotting/Plotting.jl")

end
