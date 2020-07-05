mutable struct Domain
    dt::Float64
    present_year::Float64
    initial_year::Float64
    final_year::Float64
end

Domain(dt::Float64, initial_year::Float64, final_year::Float64) = (
    Domain(dt, initial_year, initial_year, final_year)
)
Domain(dt::Float64) = Domain(dt, initial_year, final_year)