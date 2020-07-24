module IO

using JSON2
using ClimateMARGO.Models

export export_state, import_state,
    export_parameters, import_parameters,
    included_configurations

include("json_io.jl")

end