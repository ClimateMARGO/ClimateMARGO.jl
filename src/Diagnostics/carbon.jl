## Effective CO2 emissions
effective_emissions(r, q; M=0., R=0.) = r*(emissions(q, M=M) .- q[1]*R)
function effective_emissions(
        tgrid::TemporalGrid, emissions::EmissionsParams, carbon::FractionalEmissions;
        M=0., R=0.
    )
    return effective_emissions(carbon.r, emissions.func(t(tgrid)), M=M, R=R)
end

function effective_emissions(m::ClimateModel; M=false, R=false)
    return effective_emissions(
        m.grid, m.economics.emissions, m.physics.carbon,
        M=controls.deployed["M"] .* allow_control(m, M),
        R=controls.deployed["R"] .* allow_control(m, R),
    )
end

## CO2 Concentrations
# Simple accumulation model w/ fixed airborne CO2 fraction
function c(c0, effective_emissions, dt)
    return c0 .+ cumsum(deferred(effective_emissions, n=0) * dt)
end

function c(
        tgrid::TemporalGrid, emissions::EmissionsParams,
        carbon::FractionalEmissions;
        M=0., R=0.
    )
    q_eff = effective_emissions(tgrid, emissions, carbon, M=M, R=R)
    return c(carbon.c0, q_eff, tgrid.dt)
end

function c(m::ClimateModel; M=false, R=false)
    return c(
        m.grid, m.economics.emissions,
        m.physics.carbon,
        M=m.controls.deployed["M"] .* allow_control(m, M),
        R=m.controls.deployed["R"] .* allow_control(m, R)
    )
end