"""
    Physics(CO₂_init, δT_init, a, B, Cd, κ, r, ECS, τd)

Create data structure for model physics.

See also: [`ClimateModel`](@ref)
"""
mutable struct Physics
    CO₂_init::Float64
    δT_init::Float64
    a::Float64
    B::Float64
    Cd::Float64
    κ::Float64
    r::Float64
    
    ECS::Float64
    τd::Float64
    function Physics(CO₂_init, δT_init, a, B, Cd, κ, r)
        FCO₂_2x = a*log(2) # Forcing due to doubling CO2 (Geoffrey 2013)
        sec_per_year = 60. * 60. * 24. * 365.25
        
        ECS = (FCO₂_2x*sec_per_year)/B # [degC]
        τd = (Cd/B) * (B+κ)/κ # [yr]
        return new(CO₂_init, δT_init, a, B, Cd, κ, r, ECS, τd)
    end
end

"""
    Controls(mitigate, remove, geoeng, adapt)

Create data structure for climate controls.

# Examples
```jldoctest
a = zeros(4);
C = MARGO.Controls(a, a, a, a);
C.geoeng

# output
4-element Array{Float64,1}:
 0.0
 0.0
 0.0
 0.0
```

See also: [`ClimateModel`](@ref)
"""
mutable struct Controls
    mitigate::Array{Float64,1}
    remove::Array{Float64,1}
    geoeng::Array{Float64,1}
    adapt::Array{Float64,1}
end

"""
    Economics(
        GWP, β, utility_discount_rate,
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

function Economics(GWP, β, utility_discount_rate, mitigate_cost, remove_cost, geoeng_cost, adapt_cost, mitigate_init, remove_init, geoeng_init, adapt_init, baseline_emissions)
    return Economics(
        GWP::Array{Float64,1},
        β::Float64,
        utility_discount_rate::Float64,
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

"""
    init_zero_controls(t)

Return initial state of uniformly-zero climate controls.

See also: [`Controls`](@ref)
"""
function init_zero_controls(t::Array{Float64,1})
    c = Controls(
        zeros(size(t)),
        zeros(size(t)),
        zeros(size(t)),
        zeros(size(t))
    )
    return c
end


"""
    ClimateModel(name, domain, dt, present_year, economics, physics, controls)

Create instance of an extremely idealized multi-control climate model, starting from a given year (`present_year`), economic input parameters
(`economics`), physical climate parameters (`physics`), and climate control policies (`controls`) over some time frame (`domain`), with a given timestep (`dt`).

See also: [`Controls`](@ref), [`Economics`](@ref), [`CO₂`](@ref), [`δT`](@ref),
[`optimize!`](@ref)
"""
mutable struct ClimateModel
    name::String
    domain::Array{Float64,1}
    dt::Float64
    present_year::Float64
    economics::Economics
    physics::Physics
    controls::Controls
end