t(t0, tf, dt) = t0:dt:tf
t(dom::Domain) = t(dom.initial_year,dom.final_year,dom.dt)
t(params::ClimateModelParameters) = t(params.domain)
t(m::ClimateModel) = t(m.domain)

future_mask(t, present_year) = t .<= present_year
future_mask(model) = future_mask(t(model), model.domain.present_year)