using MARGO, Test

function tests()
    @testset "Subset of tests" begin
        @test f(1.) ≈ 1.
    end
end

tests()
