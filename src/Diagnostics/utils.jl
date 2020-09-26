t(t0, tf, dt) = t0:dt:tf
t(grid::Grid) = t(grid.initial_year,grid.final_year,grid.dt)
t(params::ClimateModelParameters) = t(params.grid)
t(m::ClimateModel) = t(m.grid)

future_mask(t, present_year) = t .<= present_year
future_mask(m::ClimateModel) = future_mask(t(m), model.grid.present_year)

allow_control(t_, present_year, C) = (1. .- .~future_mask(t_, present_year) * ~C)
allow_control(grid::Grid, C) = allow_control(t(grid), grid.present_year, C)
allow_control(m::ClimateModel, C) = allow_control(m.grid, C)

deferred(arr; n=1) = [zeros(n); arr[1:end-n]]