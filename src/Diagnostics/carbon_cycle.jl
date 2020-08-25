
function effective_emissions(r, q, M, R)
    return r*(emissions(q, M) .- q[1]*R)
end
function effective_emissions(m::ClimateModel; M=false, R=false)
    if typeof(m.physics.carbon) == FractionalEmissions
        return effective_emissions(
            m.physics.carbon.r,
            m.economics.emissions.func(t(m)),
            m.controls.deployed["M"] .* (1. .- .~future_mask(m) * ~M),
            m.controls.deployed["R"] .* (1. .- .~future_mask(m) * ~R)
        )
    else
        print("This diagnostic is not well defined for this model configuration.")
        return nothing
    end
end

function c(c0, effective_emissions, dt)
    return c0 .+ cumsum(effective_emissions * dt)
end

function c(m::ClimateModel; M=false, R=false)
    if typeof(m.physics.carbon) == FractionalEmissions
        return c(
            m.physics.initial.c0,
            effective_emissions(m, M=M, R=R),
            m.grid.dt
        )
    end
end