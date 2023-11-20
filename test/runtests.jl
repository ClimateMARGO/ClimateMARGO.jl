try
    using Revise
catch
end
ENV["JULIA_MARGO_LOAD_PYPLOT"] = "no thank you"
using JuMP
using ClimateMARGO
using ClimateMARGO.Models, ClimateMARGO.Optimization, ClimateMARGO.Diagnostics
using Test
using BenchmarkTools


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




function default_parameters(dt=12)::ClimateModelParameters
    p = deepcopy(ClimateMARGO.IO.included_configurations["default"])

    p.domain = Domain(Float64(dt), 2020.0, 2200.0)
    p.economics.baseline_emissions = ramp_emissions(p.domain)
    p.economics.extra_CO₂ = zeros(size(p.economics.baseline_emissions))

    return p
end


@testset "Pinned results" begin
    # We generate results using ClimateMARGO.jl once, and then add a test to check that these same results are still generated. This allows us to "pin" a correct state of the model, and make internal changes with the guarantee that the outcome does not change.

    # In the future, to "pin" new results as the correct ones, run the tests, and copy the expected result from the test failure report.
    
    @testset "Forward" begin
        model = ClimateModel(default_parameters(20))

        bump() = collect([0.0:0.2:0.9;  1.0:-0.2:0.1]) # == [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 0.8, 0.6, 0.4, 0.2]
        slope() = collect(0.0:0.1:0.99)
        constant() = fill(1.0, size(slope())...)

        model.controls.mitigate = bump()
        model.controls.remove = 0.2 .* bump()
        model.controls.geoeng = 0.1 .* slope()
        model.controls.adapt = 0.3 .* constant()

        result_T = T_adapt(model; M=true, R=true, G=true, A=true)

        @test result_T ≈ [1.2767663110173484, 1.608852123606971, 1.8978258561722958, 2.108526090432568, 2.211931788367322, 2.1713210884072347, 2.158586858753497, 2.1224302958426446, 2.0894535810555555, 2.0607413902621032] rtol=1e-5
    end

    @testset "Optimization" begin
        model = ClimateModel(default_parameters(20))

        optimize_controls!(model, temp_goal=2.2)

        @test model.controls.mitigate ≈ [0.0, 0.3670584821282429, 0.4393272792260638, 0.5257940783265341, 0.6245380250211872, 0.7074912042403808, 0.7676867396677578, 0.0, 0.0, 0.0] rtol=1e-3
        @test model.controls.remove ≈ [0.0, 0.10882651060773696, 0.13025296274983308, 0.15588887768405002, 0.18516475517861308, 0.20975894242613452, 0.22760588089905764, 0.2367501073337253, 0.23175978166812158, 0.19659824324032557] rtol=1e-3
        @test model.controls.geoeng ≈ [0.0, 0.05049106345373785, 0.05264838036542512, 0.06460796652594906, 0.10819144740515446, 0.12584271884062354, 0.12767445817227918, 0.12318301615805025, 0.11794556458720538, 0.1132343245663971] rtol=1e-3
        @test model.controls.adapt ≈ [0.0, 0.0001537202313707738, 0.00015374376329529388, 0.03816957588616602, 0.10942294994448329, 0.13786594819465353, 0.14363875559967432, 0.14044599067883523, 0.1365010682189578, 0.13366455981096753] rtol=1e-3
    end

end


const RUN_BENCHMARKS = true

if RUN_BENCHMARKS
    @info "Running benchmark..."

    function go()
        model = ClimateModel(default_parameters(20))

        optimize_controls!(model; temp_goal=2.2, print_raw_status=false)
    end

    go()
    
    display(@benchmark go())
end