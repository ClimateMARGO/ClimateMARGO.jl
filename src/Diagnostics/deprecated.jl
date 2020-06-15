function discounting(model::ClimateModel)
    discount = (1. .+ model.economics.utility_discount_rate) .^ (-(model.domain .- model.present_year))
    discount[model.domain .< model.present_year] .= 0.
    
    return discount
end
    
damage_cost_baseline(model::ClimateModel) = (
    model.economics.β .* model.economics.GWP .* δT_baseline(model).^2
)

discounted_damage_cost_baseline(model::ClimateModel) = (
    damage_cost_baseline(model) .* discounting(model)
)

damage_cost(model::ClimateModel) = (
    (1. .- model.controls.adapt) .*
    model.economics.β .* model.economics.GWP .* δT(model).^2
)

discounted_damage_cost(model::ClimateModel) = (
    damage_cost(model) .* discounting(model)
)

control_cost(model::ClimateModel) = (
    model.economics.mitigate_cost .* model.economics.GWP .*
    f(model.controls.mitigate) .+
    model.economics.geoeng_cost .* model.economics.GWP .*
    f(model.controls.geoeng) .+
    model.economics.adapt_cost .* f(model.controls.adapt) .+
    model.economics.remove_cost .* f(model.controls.remove)
)

discounted_control_cost(model::ClimateModel) = (
    control_cost(model) .* discounting(model)
)

discounted_total_control_cost(model::ClimateModel) = (
    sum(discounted_control_cost(model) .* model.dt)
)

discounted_total_damage_cost(model::ClimateModel) = (
    sum(discounted_damage_cost(model) .* model.dt)
)

net_cost(model::ClimateModel) = (
    damage_cost(model) .+ control_cost(model)
)

discounted_net_cost(model::ClimateModel) = (
    (damage_cost(model) .+ control_cost(model)) .* discounting(model)
)

total_cost(model::ClimateModel) = (
    sum(net_cost(model) .* model.dt)
)

discounted_total_cost(model::ClimateModel) = (
    sum(net_cost(model) .* discounting(model)  .* model.dt)
)

GtCO2_to_ppm(GtCO2) = GtCO2 / (2.13 * (44. /12.))
tCO2_to_ppm(tCO2) = GtCO2_to_ppm(tCO2) * 1.e-9

ppm_to_GtCO2(ppm) = ppm * (2.13 * (44. /12.))
ppm_to_tCO2(ppm) = ppm_to_GtCO2(ppm) * 1.e9

function extra_ton(model::ClimateModel, year::Float64)
    
    econ = model.economics
    
    year_idx = argmin(abs.(model.domain .- year))
    
    extra_CO₂ = zeros(size(model.domain))
    extra_CO₂[year_idx:end] .= tCO2_to_ppm(1.)
    
    new_economics = Economics(
        econ.β, econ.utility_discount_rate,
        econ.mitigate_cost, econ.remove_cost,
        econ.geoeng_cost, econ.adapt_cost,
        econ.mitigate_init, econ.remove_init, econ.geoeng_init, econ.adapt_init,
        econ.baseline_emissions,
        extra_CO₂
    );
    
    return ClimateModel(
        model.name, model.domain, model.dt, model.present_year,
        new_economics, model.physics, model.controls
    )
end

extra_ton(model::ClimateModel) = extra_ton(model::ClimateModel, model.domain[1])

SCC(model::ClimateModel, year::Float64) = round((
     discounted_total_cost(extra_ton(model, year)) -
     discounted_total_cost(model)
)*1.e12, digits=2)

SCC(model::ClimateModel) = SCC(model::ClimateModel, model.domain[1])
