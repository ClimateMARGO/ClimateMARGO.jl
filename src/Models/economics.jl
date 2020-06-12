"""
    Economics(
        GWP, β, utility_discount_rate, Finf,
        mitigate_cost, remove_cost, geoeng_cost, adapt_cost,
        mitigate_init, remove_init, geoeng_init, adapt_init,
        baseline_emissions,
        extra_CO₂
    )

Create data structure for economic input parameters for `ClimateModel` struct,
including a baseline emissions scenario.

### Arguments
- `GWP::Array{Float64,1}`: Gross World Product timeseries [10^12 USD / year]
- `β::Float64`: climate damage parameter [% GWP / (°C)^2].
- `utility_discount_rate::Float64`: typically denoted ρ in economic references [fraction].
- `Finf::Float64`: maximum SRM forcing
- `[control]_cost::Float64`: scaling cost of full control deployment [10^12 USD / year OR % of GWP].
- `[control]_init::Float64`: fixed initial condition for control deployment [10^12 USD / year].
- `baseline_emissions::Array{Float64,1}`: prescribed baseline CO₂ equivalent emissions [ppm / yr].
- `extra_CO₂::Array{Float64,1}`: optional additional CO₂ input that is used only for Social Cost of Carbon calculations [ppm].

See also: [`ClimateModel`](@ref), [`baseline_emissions`](@ref), [`GWP`](@ref).

"""
mutable struct Economics
    GWP::Array{Float64,1}
    β::Float64
    utility_discount_rate::Float64
    Finf::Float64
    
    mitigate_cost::Float64
    remove_cost::Float64
    geoeng_cost::Float64
    adapt_cost::Float64
    
    mitigate_init
    remove_init
    geoeng_init
    adapt_init
    
    baseline_emissions::Array{Float64,1}
    extra_CO₂::Array{Float64,1}
end

function Economics(GWP, β, utility_discount_rate, Finf, mitigate_cost, remove_cost, geoeng_cost, adapt_cost, mitigate_init, remove_init, geoeng_init, adapt_init, baseline_emissions)
    return Economics(
        GWP::Array{Float64,1},
        β::Float64,
        utility_discount_rate::Float64,
        Finf::Float64,
        mitigate_cost::Float64,
        remove_cost::Float64,
        geoeng_cost::Float64,
        adapt_cost::Float64,
        mitigate_init,
        remove_init,
        geoeng_init,
        adapt_init,
        baseline_emissions::Array{Float64,1},
        zeros(size(baseline_emissions))
    )
end