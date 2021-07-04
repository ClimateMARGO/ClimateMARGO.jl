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

        bump() = [0.0:0.2:0.9;  1.0:-0.2:0.1] # == [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 0.8, 0.6, 0.4, 0.2]
        slope() = 0.0:0.1:0.99
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

        @test model.controls.mitigate ≈ [0.0, 0.34155592593981776, 0.40866671938467536, 0.48895883633827536, 0.5808472484196244, 0.657200674586562, 0.7103250511748416, 0.0, 0.0, 0.0] rtol=1e-3
        @test model.controls.remove ≈ [0.0, 0.13368629053044218, 0.15995356527422552, 0.19138013832241746, 0.227345534872097, 0.2572305754920716, 0.27802450321611133, 0.28750461607474137, 0.279772185245111, 0.2360153970992968] rtol=1e-3
        @test model.controls.geoeng ≈ [0.0, 0.05564945021219023, 0.05802742074717397, 0.07068716375753736, 0.11995614472474693, 0.14057820114259145, 0.1420748387286812, 0.13535311036931555, 0.12785955642034164, 0.1212330250633784] rtol=1e-3
        @test model.controls.adapt ≈ [0.0, 0.0032013590596544315, 0.0028136983948875175, 0.0363100093738708, 0.10227102664309205, 0.12710472291911362, 0.13123600071297786, 0.12686291917650214, 0.12189243191164409, 0.11807121525025795] rtol=1e-3
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