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

Create data structure for climate control arrays Arrays along time axis,
with bounded values ∈ [0,1].

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
        β, utility_discount_rate,
        mitigate_cost, remove_cost, geoeng_cost, adapt_cost,
        mitigate_init, remove_init, geoeng_init, adapt_init,
        baseline_emissions
    )

Create data structure for economic input parameters for `ClimateModel` struct,
including a baseline emissions scenario.

### Arguments
- `β::Float64`: climate damage parameter [10^12 USD / (°C)^2].
- `utility_discount_rate::Float64`: typically denoted ρ in economic references.
- `[control]_cost::Float64`: scaling cost of full control deployment [10^12 USD].
- `[control]_init::Float64`: fixed initial condition for control deployment [10^12 USD].
- `baseline_emissions::Array{Float64,1}`: prescribed baseline CO₂ equivalent emissions [ppm / yr].

See also: [`ClimateModel`](@ref), [`baseline_emissions`](@ref).

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

"Return a non-dimensional Array of size(t) which represents a linear increase from 0. to 1."
nondim_linear(t::Array) = (t .- t[1])/(t[end] - t[1]);

"""
    init_linear_controls(t)

Create physical (but arbitrary) initial guess of climate controls in which all controls increase
linearly with time.

See also: [`Controls`](@ref)
"""
function init_linear_controls(t::Array{Float64,1})
    c = Controls(
        nondim_linear(t)/3.,
        nondim_linear(t)/2.,
        nondim_linear(t)/8.,
        nondim_linear(t)/10.
    )
    return c
end

"""
    init_zero_controls(t)

Create initial guess of zero climate controls.

See also: [`Controls`](@ref)
"""
function init_zero_controls(t::Array{Float64,1})
    c = Controls(
        nondim_linear(t)*0.,
        nondim_linear(t)*0.,
        nondim_linear(t)*0.,
        nondim_linear(t)*0.
    )
    return c
end


"""
    ClimateModel(name, domain, dt, present_year, economics, physics, controls)

Create instance of an extremely idealized integrated-assessment
climate model, starting from a given year (`present_year`), economic input parameters
(`economics`), physical climate parameters (`physics`), and climate control policies (`controls`) over some time frame (`domain`) with a given timestep (`dt`).

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