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

        @test result_T ≈ [1.0682193356535885, 1.297612780324065, 1.453526247004754, 1.5062585038724643, 1.4285517554348575, 1.2572703815973132, 1.1794105896558098, 1.1028828321322799, 1.0328298013342352, 0.9703332767635697] rtol=1e-5
    end

    @testset "Optimization" begin
        model = ClimateModel(default_parameters(20))

        optimize_controls!(model, temp_goal=2.2)

        @test model.controls.mitigate ≈ [0.0, 0.2622327257259913, 0.3756069054925597, 0.5383017458771391, 0.7309812393611623, 0.904183223823383, 0.999999991007597, 0.0, 0.0, 0.0] rtol=1e-3
        @test model.controls.remove ≈ [0.0, 0.04017304516129229, 0.05754153344586193, 0.08246575725211311, 0.11198351460708776, 0.1385173926652173, 0.16224795528492542, 0.17802096041962337, 0.17336250309642975, 0.1274237589588297] rtol=1e-3
        @test model.controls.geoeng ≈ [0.0, 0.014090929105437192, 0.01532077112122306, 0.03991571838270348, 0.07566973390226892, 0.07983310361284779, 0.07662382450378728, 0.07333361345178593, 0.06934631662083496, 0.06706612802139787] rtol=1e-3
        @test model.controls.adapt ≈ [0.09378983273810226, 0.09378983273810226, 0.09378983273810226, 0.09378983273810226, 0.09378983273810226, 0.09378983273810226, 0.09378983273810226, 0.09378983273810226, 0.09378983273810226, 0.09378983273810226] rtol=1e-3
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