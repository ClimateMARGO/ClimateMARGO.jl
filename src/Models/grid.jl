mutable struct Grid
    dt::Float64
    present_year::Float64
    initial_year::Float64
    final_year::Float64
end

Grid(dt::Float64, initial_year::Float64, final_year::Float64) = (
    Grid(dt, initial_year, initial_year, final_year)
)
Grid(dt::Float64) = Grid(dt, initial_year, final_year)