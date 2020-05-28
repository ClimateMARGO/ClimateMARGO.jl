using MARGO, Test

function tests()
    @testset "Subset of tests" begin
        @test MARGO.f(1.) ≈ 1.
    end
end

tests()
