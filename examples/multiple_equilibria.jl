# # A simple two-dimensional optimization problem

# ## Loading ClimateMARGO.jl
using ClimateMARGO # Julia implementation of the MARGO model
using PyPlot # A basic plotting package

# Loading submodules for convenience
using ClimateMARGO.Models
using ClimateMARGO.Utils
using ClimateMARGO.Diagnostics

# ## Loading the default MARGO configuration
params = deepcopy(ClimateMARGO.IO.included_configurations["default"])

# Modify parameters to make geoengeering and mitigation costs similar
params.economics.geoeng_cost *= 0.1;
params.economics.mitigate_cost *= 5;

# ### Instanciating the `ClimateModel`
m = ClimateModel(params)

# ## Brute-force parameter sweep method to map out objective function

# ### Parameter sweep
Ms = 0.:0.005:1.0;
Gs = 0.:0.005:1.0;

net_benefit = zeros(length(Gs), length(Ms)) .+ 0.; #

for (o, option) = enumerate(["adaptive_temp", "net_benefit"])
    for (i, M) = enumerate(Ms)
        for (j, G) = enumerate(Gs)
            m.controls.mitigate[t(m) .<= 2100] = zeros(size(t(m)))[t(m) .<= 2100] .+ M
            m.controls.geoeng[t(m) .>= 2150] = zeros(size(t(m)))[t(m) .>= 2150] .+ G
            ### KEY CHANGE: Significantly decrease exponent of both control costs, so that costs are now concave rather than convex functions
            net_benefit[j, i] = net_present_benefit(m, discounting=true, p=0.6, M=true, G=true)
        end
    end
end

# ### Visualizing the two-dimensional optimization problem

fig = figure(figsize=(8, 6))

subplot()
q = pcolor(Ms, Gs, net_benefit, cmap="Greys_r")
cbar = colorbar(label="Net present benefits, relative to baseline [trillion USD]", extend="both")
contour(Ms, Gs, net_benefit, colors="k", levels=40, linewidths=0.5, alpha=0.4)
grid(true, color="k", alpha=0.25)

xlabel("Emissions mitigation level [% reduction]")
xticks(0.:0.2:1.0, ["0%", "20%", "40%", "60%", "80%", "100%"])
ylabel("Geoengineering rate [% of RCP8.5]")
yticks(0.:0.2:1.0, ["0%", "20%", "40%", "60%", "80%", "100%"])
title("Cost-benefit analysis")
gcf()