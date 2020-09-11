abstract type EmissionsParams end

# Following RCP8.5 CO2e concentrations 
# Raw data at https://www.iiasa.ac.at/web-apps/tnt/RcpDb/dsd?Action=htmlpage&page=compare
#
# See below link for 2020 initial condition:
# https://www.eea.europa.eu/data-and-maps/indicators/atmospheric-greenhouse-gas-concentrations-6/assessment-1
function linear_ramp_emissions(t, q0::Float64, n::Float64, t1::Float64, t2::Float64)
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
function linear_ramp_emissions(t)
    return linear_ramp_emissions(t, 7.5, 3., 2100., 2150.)
end

function exp_ramp_emissions(t, q_max::Float64, Δt::Float64, t_max::Float64, t_decrease::Float64, t_netzero::Float64)
    q = q_max*ones(size(t));
    increase_idx = (t .<= t_max)
    decrease_idx = (t .>= t_decrease) .& (t .<= t_netzero)
    q[increase_idx] .= q_max*(exp.((t[increase_idx] .- t_max)/Δt))
    q[decrease_idx] .= q_max*(t_netzero .- t[decrease_idx]) / (t_netzero - t_decrease)
    q[t .> t_netzero] .= 0.
    return q
end
# Default follows RCP8.5 until 2100 and then is extending according to ECP85 scenario
# https://www.iiasa.ac.at/web-apps/tnt/RcpDb/dsd?Action=htmlpage&page=compare
exp_ramp_emissions(t) = exp_ramp_emissions(t, 33., 52., 2100., 2120., 2200.)

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