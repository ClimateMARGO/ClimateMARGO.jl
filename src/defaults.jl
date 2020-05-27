# Model domain
present_year = 2020. # [yr]
final_year = 2200. # [yr]
dt = 5. # [yr]
t = Array(present_year:dt:final_year); # [yr]
sec_per_year = (365. * 24. * 60. * 60.) # [s/yr]

## Physics
# Two-layer EBM (Gregory 2000) parameters from Geoffroy 2013
a = (6.9/2.)/log(2.); # F4xCO2/2 / log(2) [W m^-2]
B = 1.13 * sec_per_year; # Feedback parameter [J yr^-1 m^-2 K^-1]
Cu = 7.3 * sec_per_year; # Upper ocean heat capacity [J m^-2 K^-1]
Cd = 106 * sec_per_year; # Deep ocean heat capacity [J m^-2 K^-1]
κ = 0.73 * sec_per_year; # Heat exchange coefficient [J yr^-1 m^2 K^-1]
δT_init = 1.1 # [degC] Berkeley Earth Surface Temperature (Rohde 2013)

# Physical diagnostics
FCO₂_2x = a*log(2) # Forcing due to doubling CO2 (Geoffrey 2013)
sec_per_year = 60. * 60. * 24. * 365.25

ECS = (FCO₂_2x*sec_per_year)/B # [degC]
τd = (Cd/B) * (B+κ)/κ # [yr]

# Carbon model
CO₂_init = 460. # [ppm]
r = 0.5 # [1] fraction of emissions remaining after biosphere and ocean uptake (Solomon 2009)

## Economics
# Exogenous GWP
GWP0 = 100. # global world product at t0 [10^12$ yr^-1]
γ = 0.02 # economic growth rate
GWP(t) = GWP0 * (1. + γ).^(t .- t[1]) # global world product [10^12$ yr^-1], roughly equal to exp.((t .- t[1]) / 50.)

β = 0.02/(3.0)^2 # damages [%GWP / celsius^2]
utility_discount_rate = 0.01

# Costs of negative emissions technologies [US$/tCO2]
costs = Dict(
    "BECCS" => 150.,
    "DACCS" => 200.,
    "Forests" => 27.5,
    "Weathering" => 125.,
    "Biochar" => 70.,
    "Soils" => 50.
)
potentials = Dict(
    "BECCS" => 5.,
    "DACCS" => 5.,
    "Forests" => 3.6,
    "Weathering" => 4.,
    "Biochar" => 2.,
    "Soils" => 5.
)

mean_cost = sum(values(potentials) .* values(costs)) / sum(values(potentials)) # [$ tCO2^-1]
CDR_potential = sum(values(potentials)) / ppm_to_GtCO2(q0)

### Control technology cost scales, as fraction of GWP (cost scale is for full deployment, α=1.)

# Estimate cost from Fuss 2018 (see synthesis Figure 14)
remove_cost = (1. /2.)^(-2) * mean_cost * ppm_to_tCO2(q0/2.) * 1.e-12; # [10^12$ yr^-1]

# From Global Comission Report on Adaptation
adapt_cost = (1. /5.)^(-2) * 0.018/10. * GWP0; # [10^12$ yr^-1] 

# From AR5 on Mitigation
mitigate_cost = 0.02; # [% GWP]

# Reflecting costs of offsetting 8.5 W/m^2 of damages
geoeng_cost = β * ((8.5*sec_per_year)/(B+κ))^2; # [% of global world product]

"""
    Economics()

Create data structure for economic input parameters for `ClimateModel` struct with default values.

Default parameters are:
- `β`= 0.222 × 10^12 USD / (°C)^2
- `utility_discount_rate` = 0.0 (compare with Stern review median value of 1.4% and ~3% Nordhaus values)
- `mitigate_cost` = 1. × 10^12 USD
- `remove_cost` = 2. × 10^12 USD
- `geoeng_cost` = 5. × 10^12 USD
- `adapt_cost` = 3. × 10^12 USD
- `[control]_init` = 0.
- `baseline_emissions` = baseline_emissions(t::Array{Float64,1}, 10., 2080., 40.)

The default baseline emissions scenario corresponds to flat emissions of 10 ppm / year
from 2020 to 2080 and linearly decreasing from 10 ppm / year in 2080 to 0 ppm / year in 2120.

See also: [`ClimateModel`](@ref), [`baseline_emissions`](@ref)
"""
Economics(t) = Economics(
    GWP(t), β, utility_discount_rate,
    mitigate_cost, remove_cost, geoeng_cost, adapt_cost,
    0.1, 0., 0., nothing, # Initial condition on control deployments at t[1]
    baseline_emissions(t)
)

Economics() = Economics(t)

Physics() = Physics(CO₂_init, δT_init, a, B, Cd, κ, r)

ClimateModel(name::String) = ClimateModel(
    name,
    t,
    dt,
    present_year,
    Economics(),
    Physics(),
    init_zero_controls(t)
)

ClimateModel(;t::Array{Float64,1}, dt::Float64) = ClimateModel(
    "default",
    t,
    dt,
    present_year,
    Economics(t),
    Physics(),
    init_zero_controls(t)
)

ClimateModel() = ClimateModel("default")
