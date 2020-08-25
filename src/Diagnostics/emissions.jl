
emissions(q, M) = q .* (1. .- M)
function emissions(m::ClimateModel; M=false)
    return emissions(
        m.economics.emissions.func(t(m)),
        m.controls.deployed["M"] .* (1. .- .~future_mask(m) * ~M)
    )
end