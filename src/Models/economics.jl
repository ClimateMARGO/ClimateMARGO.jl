abstract type EmissionsParams end

# Following RCP8.5 CO2e concentrations 
# Raw data at https://www.iiasa.ac.at/web-apps/tnt/RcpDb/dsd?Action=htmlpage&page=compare
#
# See below link for 2020 initial condition:
# https://www.eea.europa.eu/data-and-maps/indicators/atmospheric-greenhouse-gas-concentrations-6/assessment-1
function ramp_emissions(t, q0::Float64, n::Float64, t1::Float64, t2::Float64)
    t0 = t[1]
    Δt0 = t1 - t0
    Δt1 = t2 - t1
    q = zeros(size(t))
    increase_idx = (t .<= t1)
    decrease_idx = ((t .> t1) .& (t .<= t2))
    q[increase_idx] .= q0 * (1. .+ (n-1) .*(t[increase_idx] .- t0)/Δt0)
    q[decrease_idx] .= n * q0 * (t2 .- t[decrease_idx])/Δt1
    q[t .> t2] .= 0.
    return q
end
function ramp_emissions(t)
    return ramp_emissions(t, 7.5, 3., 2100., 2150.)
end

struct RampingEmissions <: EmissionsParams
    func::Function
end

abstract type GrowthParams end
mutable struct ExponentialGrowth <: GrowthParams
    E0::Real
    γ::Real
end

abstract type DiscountingParams end
mutable struct ExponentialDiscounting <: DiscountingParams
    ρ::Real
end

abstract type ControlCostParams end
mutable struct PowerLawControls <: ControlCostParams
    cost_ref::Dict{String, Real}
    cost_exp::Dict{String, Real}
end

abstract type DamageParams end
mutable struct PowerLawDamages <: DamageParams
    β::Real
    Finf::Real
end

mutable struct Economics
    emissions::EmissionsParams
    growth::GrowthParams
    discounting::DiscountingParams
    controlcosts::ControlCostParams
    damages::DamageParams
end