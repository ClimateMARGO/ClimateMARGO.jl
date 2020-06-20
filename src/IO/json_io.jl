function save(m::ClimateModel; config_path = "../configurations/")
    open("$(config_path)/$(m.name).json","w") do file
        write(file, JSON2.write(m));
    end
end

function load(name::String; config_path = "../configurations/")
    open("$(config_path)/$(m.name).json","r") do file
        return JSON2.read(read(file, String), ClimateModel)
    end
end