abstract type Grid end

mutable struct TemporalGrid <: Grid
    dt::Float64
    present_year::Float64
    initial_year::Float64
    final_year::Float64
end

TemporalGrid(dt::Float64, initial_year::Float64, final_year::Float64) = (
    TemporalGrid(dt, initial_year, initial_year, final_year)
)
TemporalGrid(dt::Float64) = TemporalGrid(dt, 2020., 2300.);