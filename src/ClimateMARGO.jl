module ClimateMARGO

if VERSION < v"1.3"
    @error "ClimateMARGO requires Julia v1.3 or newer."
end

using JuMP, Ipopt

export ClimateModel,
    Controls,
    Economics,
    Physics,
    optimize_controls!,
    step_forward!,
    add_emissions_bump!,
    GWP,
    deep_copy,
    deepcopy,
    init_zero_controls,
    baseline_emissions,
    effective_baseline_emissions,
    controlled_emissions,
    effective_emissions,
    CO₂_baseline,
    CO₂,
    FCO₂_baseline,
    FCO₂,
    FCO₂_no_geoeng,
    δT_baseline,
    δT,
    δT_no_geoeng,
    δT_adapt,
    f,
    δT_fast,
    δT_slow,
    discounting,
    damage_cost_baseline,
    discounted_damage_cost_baseline,
    damage_cost,
    discounted_damage_cost,
    control_cost,
    discounted_control_cost,
    discounted_total_control_cost,
    discounted_total_damage_cost,
    net_cost,
    discounted_net_cost,
    total_cost,
    discounted_total_cost,
    GtCO2_to_ppm,
    tCO2_to_ppm,
    ppm_to_GtCO2,
    ppm_to_tCO2

### Load code
include("model.jl")
include("diagnostics.jl")
include("defaults.jl")
include("optimization.jl")
include("steppingforward.jl")

end

