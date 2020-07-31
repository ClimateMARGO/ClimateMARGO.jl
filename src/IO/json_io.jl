"Export a [`ClimateModel`](@ref) instance to a `.json` file.

This `.json` file can be shared with others, you can import it using "
function export_state(filename::AbstractString, m::ClimateModel)
    open(filename, "w") do io
        JSON2.write(io, m)
    end
end

function import_state(filename::String)::ClimateModel
    open(filename, "r") do io
        return JSON2.read(io, ClimateModel)
    end
end

function export_parameters(filename::AbstractString, params::ClimateModelParameters)
    open(filename, "w") do io
        JSON2.write(io, params)
    end
end

function import_parameters(filename::AbstractString)::ClimateModelParameters
    open(filename, "r") do io
        return JSON2.read(io, ClimateModelParameters)
    end
end

"""The [`ClimateModelParameters`](@ref) included with this package.

Currently `included_configurations["default"]` is the only included set."""
const included_configurations = let
    # find the config dir relative to this .jl file
    config_dir = joinpath(@__DIR__, "..", "..", "configurations")
    config_files = [file for file in readdir(config_dir) if occursin(".json", file)]
    loaded = [import_parameters(joinpath(config_dir, file)) for file in config_files]
    Dict(p.name => p for p in loaded)
end