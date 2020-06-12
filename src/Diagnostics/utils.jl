t(dom::Domain) = dom.initial_year:dom.dt:dom.final_year
t(m::ClimateModel) = t(m.domain)

future_mask(t, present_year) = t .<= present_year
future_mask(model) = future_mask(t(model), model.domain.present_year)