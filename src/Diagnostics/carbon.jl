emissions(q, M) = q .* (1. .- M)

function effective_emissions(r, q, M, R)
    return r*emissions(q, M) .- q[1]*R
end

function effective_emissions(model; M=false, R=false)
    return effective_emissions(
        model.physics.r,
        model.economics.baseline_emissions,
        model.controls.mitigate .* (1. .- .~future_mask(model) * ~M),
        model.controls.remove .* (1. .- .~future_mask(model) * ~R)
    )
end

function c(c0, effective_emissions, dt)
    return c0 .+ cumsum(effective_emissions * dt)
end

function c(model; M=false, R=false)
    return c(
        model.physics.c0,
        effective_emissions(model, M=M, R=R),
        model.domain.dt
    )
end