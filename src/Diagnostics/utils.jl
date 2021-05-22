t(t0, tf, dt) = t0:dt:tf
t(dom::Domain) = t(dom.initial_year,dom.final_year,dom.dt)
t(params::ClimateModelParameters) = t(params.domain)
t(m::ClimateModel) = t(m.domain)

past_mask(t, present_year) = t .< present_year
past_mask(model) = past_mask(t(model), model.domain.present_year)