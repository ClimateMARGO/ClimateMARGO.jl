function save_state(m::ClimateModel; config_path = "../../configurations/")
    open("$(config_path)/$(m.name)_state.json","w") do file
        write(file, JSON2.write(m));
    end
end

function load_state(name::String; config_path = "../../configurations/")
    open("$(config_path)/$(m.name)_state.json","r") do file
        return JSON2.read(read(file, String), ClimateModel)
    end
end

function save_params(params::ClimateModelParameters; config_path = "../../configurations/")
    open("$(config_path)/$(params.name)_params.json","w") do file
        write(file, JSON2.write(params));
    end
end

function load_params(name::String; config_path = "../../configurations/")
    open("$(config_path)/$(name)_params.json","r") do file
        return JSON2.read(read(file, String), ClimateModelParameters)
    end
end