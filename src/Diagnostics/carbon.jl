# Following RCP8.5 CO2e concentrations 
# Raw data at https://www.iiasa.ac.at/web-apps/tnt/RcpDb/dsd?Action=htmlpage&page=compare
#
# See below link for 2020 initial condition:
# https://www.eea.europa.eu/data-and-maps/indicators/atmospheric-greenhouse-gas-concentrations-6/assessment-1
function ramp_emissions(t, q0::Real, n::Real, t1::Real, t2::Real)
    t0 = t[1]
    Δt0 = t1 - t0
    Δt1 = t2 - t1
    q = zeros(size(t))
    increase_idx = (t .<= t1)
    decrease_idx = ((t .> t1) .& (t .<= t2))
    q[increase_idx] .= q0 * (1. .+ (n-1) .*(t[increase_idx] .- t0)/Δt0)
    q[decrease_idx] .= n * q0 * (t2 .- t[decrease_idx])/Δt1
    q[t .> t2] .= 0.
    return q
end
function ramp_emissions(grid::Grid)
    return ramp_emissions(t(grid), 7.5, 3., 2100., 2150.)
end

emissions(q, M) = q .* (1. .- M)
function emissions(m::ClimateModel; M=false)
    return emissions(
        m.economics.baseline_emissions,
        m.controls.mitigate .* allow_control(m, M),
    )
end

function effective_emissions(r, q, M, R)
    return r*(emissions(q, M) .- q[1]*R)
end
function effective_emissions(m; M=false, R=false)
    return effective_emissions(
        m.physics.r,
        m.economics.baseline_emissions,
        m.controls.mitigate .* allow_control(m, M),
        m.controls.remove .* allow_control(m, R)
    )
end

function c(c0, effective_emissions, dt)
    return c0 .+ cumsum(effective_emissions * dt)
end

function c(m; M=false, R=false)
    return c(
        m.physics.c0,
        effective_emissions(m, M=M, R=R),
        m.grid.dt
    )
end