t(t0, tf, dt) = t0:dt:tf
t(grid::TemporalGrid) = t(grid.initial_year,grid.final_year,grid.dt)
t(params::ClimateModelParameters) = t(params.grid)
t(m::ClimateModel) = t(m.grid)

future_mask(t, present_year) = t .<= present_year
future_mask(m::ClimateModel) = future_mask(t(m), m.grid.present_year)