function step_forward!(m::ClimateModel, Δt::Float64)
    m.domain.present_year = m.domain.present_year + Δt
    m.name = string(Int64(round(m.domain.present_year)))
end

function add_emissions_bump!(m::ClimateModel, Δt::Float64, Δq::Float64; present_year = m.domain.present_year)
    
    present_idx = argmin(abs.(t(m) .- (present_year .+ Δt)))
    
    future = (t(m) .>= present_year)
    near_future = future .& (t(m) .<= present_year + Δt)
    near_future1 = near_future .& (t(m) .< present_year + Δt/2)
    near_future2 = near_future .& (t(m) .>= present_year + Δt/2)
    
    new_emissions = m.economics.baseline_emissions
    new_emissions[near_future1] .+= (
        Δq * (t(m) .- present_year) / (Δt/2.)
    )[near_future1]
    new_emissions[near_future2] .+= (
        Δq * (1. .- (t(m) .- (present_year .+ Δt/2.)) / (Δt/2.))
    )[near_future2]
    
    m.economics.baseline_emissions = new_emissions
end