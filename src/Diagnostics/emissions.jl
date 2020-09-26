emissions(q; M=0.) = q .* (1. .- M)
emissions(tgrid::TemporalGrid, econ::Economics; M=0.) = emissions(
    econ.emissions.func(t(tgrid)),
    M=M
)
function emissions(m::ClimateModel; M=false)
    return emissions(
        m.grid,
        m.economics,
        M=m.controls.deployed["M"] .* allow_control(m, M)
    )
end