function deep_copy(economics::Economics)
    return Economics(
        deepcopy(economics.GWP),
        deepcopy(economics.β),
        deepcopy(economics.utility_discount_rate),
        deepcopy(economics.mitigate_cost),
        deepcopy(economics.remove_cost),
        deepcopy(economics.geoeng_cost),
        deepcopy(economics.adapt_cost),
        deepcopy(economics.mitigate_init),
        deepcopy(economics.remove_init),
        deepcopy(economics.geoeng_init),
        deepcopy(economics.adapt_init),
        deepcopy(economics.baseline_emissions),
    )
end

function deep_copy(physics::Physics)
    return Physics(
        deepcopy(physics.CO₂_init),
        deepcopy(physics.δT_init),
        deepcopy(physics.a),
        deepcopy(physics.B),
        deepcopy(physics.Cd),
        deepcopy(physics.κ),
        deepcopy(physics.r)
    )
end

function deep_copy(controls::Controls)
    return Controls(
        deepcopy(controls.mitigate),
        deepcopy(controls.remove),
        deepcopy(controls.geoeng),
        deepcopy(controls.adapt)
    )
end

function deep_copy(model::ClimateModel)
    return ClimateModel(
        deepcopy(model.name),
        deepcopy(model.domain),
        deepcopy(model.dt),
        deepcopy(model.present_year),
        deepcopy(model.economics),
        deepcopy(model.physics),
        deepcopy(model.controls),
    )
end

function step_forward!(model::ClimateModel, Δt::Float64)
    model.present_year = model.present_year + Δt
    model.name = string(Int64(round(model.present_year)))
end

function add_emissions_bump!(model::ClimateModel, Δt::Float64, Δq::Float64; present_year = model.present_year)
    
    present_idx = argmin(abs.(model.domain .- (present_year .+ Δt)))
    
    future = (model.domain .>= present_year)
    near_future = future .& (model.domain .<= present_year + Δt)
    near_future1 = near_future .& (model.domain .< present_year + Δt/2)
    near_future2 = near_future .& (model.domain .>= present_year + Δt/2)
    
    new_emissions = model.economics.baseline_emissions
    new_emissions[near_future1] .+= (
        Δq * (model.domain .- present_year) / (Δt/2.)
    )[near_future1]
    new_emissions[near_future2] .+= (
        Δq * (1. .- (model.domain .- (present_year .+ Δt/2.)) / (Δt/2.))
    )[near_future2]
    
    model.economics.baseline_emissions = new_emissions
end