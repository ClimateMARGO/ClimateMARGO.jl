module IO

using JSON2
using ClimateMARGO.Models

export
    save_state, load_state,
    save_params, load_params

include("json_io.jl")

end