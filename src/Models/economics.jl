"""
    Economics(
        E0, γ, β, ρ, Finf, Tb,
        mitigate_cost, remove_cost, geoeng_cost, adapt_cost,
        mitigate_init, remove_init, geoeng_init, adapt_init,
        baseline_emissions,
        extra_CO₂
    )

Create data structure for economic input parameters for `ClimateModel` struct,
including a baseline emissions scenario.

### Arguments
- `E0::Array{Float64,1}`: Gross World Product timeseries [10^12 USD / year]
- `γ::Float64`: economic growth rate [fraction]
- `β::Float64`: climate damage parameter [% GWP / (°C)^2].
- `ρ::Float64`: typically denoted ρ in economic references [fraction].
- `Finf::Float64`: maximum SRM forcing
- `[control]_cost::Float64`: scaling cost of full control deployment [10^12 USD / year OR % of GWP].
- `[control]_init::Float64`: fixed initial condition for control deployment [10^12 USD / year].
- `baseline_emissions::Array{Float64,1}`: prescribed baseline CO₂ equivalent emissions [ppm / yr].
- `extra_CO₂::Array{Float64,1}`: optional additional CO₂ input that is used only for Social Cost of Carbon calculations [ppm].

See also: [`ClimateModel`](@ref), [`baseline_emissions`](@ref), [`GWP`](@ref).

"""
mutable struct Economics
    E0::Float64
    γ::Float64
    β::Float64
    ρ::Float64
    Finf::Float64
    Tb::Float64

    mitigate_cost::Float64
    remove_cost::Float64
    geoeng_cost::Float64
    adapt_cost::Float64
    
    mitigate_init
    remove_init
    geoeng_init
    adapt_init
    
    baseline_emissions::Array{Float64,1}

    epsilon_cost::Float64
    extra_CO₂::Array{Float64,1}
end

# constructor without `extra_CO₂`, setting it to zero
function Economics(E0::Float64,
    γ::Float64,
    β::Float64,
    ρ::Float64,
    Finf::Float64,
    Tb::Float64,
    mitigate_cost::Float64,
    remove_cost::Float64,
    geoeng_cost::Float64,
    adapt_cost::Float64,
    mitigate_init,
    remove_init,
    geoeng_init,
    adapt_init,
    baseline_emissions::Array{Float64,1})
    return Economics(
        E0,
        γ,
        β,
        ρ,
        Finf,
        Tb,
        mitigate_cost,
        remove_cost,
        geoeng_cost,
        adapt_cost,
        mitigate_init,
        remove_init,
        geoeng_init,
        adapt_init,
        baseline_emissions,
        0.
    )
end

# constructor without `extra_CO₂`, setting it to zero
function Economics(E0::Float64,
    γ::Float64,
    β::Float64,
    ρ::Float64,
    Finf::Float64,
    Tb::Float64,
    mitigate_cost::Float64,
    remove_cost::Float64,
    geoeng_cost::Float64,
    adapt_cost::Float64,
    mitigate_init,
    remove_init,
    geoeng_init,
    adapt_init,
    baseline_emissions::Array{Float64,1},
    epsilon_cost::Float64)
    return Economics(
        E0,
        γ,
        β,
        ρ,
        Finf,
        Tb,
        mitigate_cost,
        remove_cost,
        geoeng_cost,
        adapt_cost,
        mitigate_init,
        remove_init,
        geoeng_init,
        adapt_init,
        baseline_emissions,
        epsilon_cost,
        zeros(size(baseline_emissions))
    )
end