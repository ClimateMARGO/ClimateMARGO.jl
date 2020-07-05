using JuMP
using ClimateMARGO
using ClimateMARGO.Models, ClimateMARGO.Optimization, ClimateMARGO.Diagnostics
using Test

function temperature_optimization_works(name::String, temp_goal::Float64)
    config_path = "../configurations"
    model = ClimateModel(ClimateMARGO.IO.load_params(name, config_path=config_path))
    status = optimize_controls!(model, temp_goal=temp_goal)
    return (
        (raw_status(status) == "Solve_Succeeded") & 
        isapprox(
            maximum(T(model, M=true, R=true, G=true, A=true)),
            temp_goal,
            rtol=1.e-5
        )
    )
end

function tests()
    @testset "Subset of tests" begin
        for temp_goal in 1.5:0.5:4.0
            @test temperature_optimization_works("default", temp_goal)
        end
    end
end

tests()
