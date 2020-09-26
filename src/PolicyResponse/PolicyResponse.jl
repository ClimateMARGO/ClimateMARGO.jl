module PolicyResponse

using ClimateMARGO.Models
using ClimateMARGO.Diagnostics

export fastforward!, add_emissions_bump!

include("fastforwarding.jl")

end