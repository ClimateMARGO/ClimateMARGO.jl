module Utils

using ClimateMARGO.Models

export
    year, init_zero_controls,
    GtCO2_to_ppm, tCO2_to_ppm,
    ppm_to_GtCO2, ppm_to_tCO2

include("instantiate_models.jl")
include("unit_conversions.jl")

end