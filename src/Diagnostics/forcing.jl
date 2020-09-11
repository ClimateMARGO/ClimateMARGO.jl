"""
    Flog(a, c0, Finf, c, G; F0=0.)
"""
function Flog(a, Finf, c0, c; G=0., F0=0.)
    F0 .+ a .* log.( c/c0 ) .- G*Finf
end

function F(forcing::LogarithmicCO2Forcing, Finf, c0, c; G=0., F0=false)
    return Flog(forcing.a,  Finf, c0, c, G=G, F0=F0*forcing.F0)
end

"""
    F(m::ClimateModel; M=false, R=false, G=false, F0=false)
"""
function F(m::ClimateModel; M=false, R=false, G=false, F0=false)
    return F(
        m.physics.forcing,
        m.economics.damages.Finf,
        m.physics.carbon.c0,
        c(m, M=M, R=R),
        G=m.controls.deployed["G"] .* allow_control(m.grid, G),
        F0=F0
    )
end

F2x(a::Float64) = a*log(2)
F2x(m::ClimateModel) = F2x(m.physics.a)

ECS(a, λ) = F2x(a)/λ
ECS(params::ClimateModelParameters) = ECS(params.physics.a, m.physics.λ)
ECS(m::ClimateModel) = ECS(m.physics.a, m.physics.λ)

calc_λ(a::Float64, ECS::Float64) = F2x(a)/ECS
calc_λ(params::ClimateModelParameters; ECS=ECS(params)) = calc_λ(params.physics.a, ECS)
calc_λ(m::ClimateModel; ECS=ECS(m)) = calc_λ(m.physics.a, ECS)