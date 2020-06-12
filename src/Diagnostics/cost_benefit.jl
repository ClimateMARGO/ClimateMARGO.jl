f(α::Array; p=2.) = α.^p # shape of individual cost functions

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
function ramp_emissions(dom::Domain)
    return ramp_emissions(t(dom), 7.5, 3., 2100., 2150.)
end



# function discounting(model::ClimateModel)
#     discount = (1. .+ model.economics.utility_discount_rate) .^ (-(model.domain .- model.present_year))
#     discount[model.domain .< model.present_year] .= 0.
    
#     return discount
# end
    
# damage_cost_baseline(model::ClimateModel) = (
#     model.economics.β .* model.economics.GWP .* δT_baseline(model).^2
# )

# discounted_damage_cost_baseline(model::ClimateModel) = (
#     damage_cost_baseline(model) .* discounting(model)
# )

# damage_cost(model::ClimateModel) = (
#     (1. .- model.controls.adapt) .*
#     model.economics.β .* model.economics.GWP .* δT(model).^2
# )

# discounted_damage_cost(model::ClimateModel) = (
#     damage_cost(model) .* discounting(model)
# )

# control_cost(model::ClimateModel) = (
#     model.economics.mitigate_cost .* model.economics.GWP .*
#     f(model.controls.mitigate) .+
#     model.economics.geoeng_cost .* model.economics.GWP .*
#     f(model.controls.geoeng) .+
#     model.economics.adapt_cost .* f(model.controls.adapt) .+
#     model.economics.remove_cost .* f(model.controls.remove)
# )

# discounted_control_cost(model::ClimateModel) = (
#     control_cost(model) .* discounting(model)
# )

# discounted_total_control_cost(model::ClimateModel) = (
#     sum(discounted_control_cost(model) .* model.dt)
# )

# discounted_total_damage_cost(model::ClimateModel) = (
#     sum(discounted_damage_cost(model) .* model.dt)
# )

# net_cost(model::ClimateModel) = (
#     damage_cost(model) .+ control_cost(model)
# )

# discounted_net_cost(model::ClimateModel) = (
#     (damage_cost(model) .+ control_cost(model)) .* discounting(model)
# )

# total_cost(model::ClimateModel) = (
#     sum(net_cost(model) .* model.dt)
# )

# discounted_total_cost(model::ClimateModel) = (
#     sum(net_cost(model) .* discounting(model)  .* model.dt)
# )