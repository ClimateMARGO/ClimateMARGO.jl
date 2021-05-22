using JuMP
using ClimateMARGO
using ClimateMARGO.Models, ClimateMARGO.Optimization, ClimateMARGO.Diagnostics
using Test


@testset "Temperature optimization" begin
    @testset "Temp goal: $(temp_goal)" for temp_goal in 1.5:0.5:4.0
        model = ClimateModel(deepcopy(ClimateMARGO.IO.included_configurations["default"]))
        status = optimize_controls!(model, temp_goal=temp_goal)
        @test raw_status(status) == "Solve_Succeeded"
        @test isapprox(
            maximum(T_adapt(model, M=true, R=true, G=true, A=true)),
            temp_goal,
            rtol=1.e-5
        )
    end
end
