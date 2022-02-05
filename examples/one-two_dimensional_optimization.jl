# # A simple two-dimensional optimization problem

# ## Loading ClimateMARGO.jl
using ClimateMARGO # Julia implementation of the MARGO model
using Plots # A basic plotting package

# Loading submodules for convenience
using ClimateMARGO.Models
using ClimateMARGO.Utils
using ClimateMARGO.Diagnostics
using ClimateMARGO.Optimization

# ## Loading the default MARGO configuration
params = deepcopy(ClimateMARGO.IO.included_configurations["default"])

# Slightly increasing the discount rate to 4% to be more comparable with other models
params.economics.ρ = 0.04

# ## Reducing the default problem's dimensionality from ``4N`` to ``2``.

# The default optimization problem consists of optimizing the values of each of the 4 controls for N timesteps, giving a total problem size of:
4*length(t(params))

# ### Modifying `ClimateModelParameters`
# Thanks to MARGO's flexibility, we can get rid of two of the controls and set the other two to have constant values, effectively reducing the problem size to 2.

# First, we have to remove initial conditions on the control variables, which would conflict with the constant-value constraint
params.economics.mitigate_init = nothing
params.economics.remove_init = nothing
params.economics.geoeng_init = nothing
params.economics.adapt_init = nothing

# ### Instanciating the `ClimateModel`
# Now that we've finished changing parameter values, we can create our MARGO model instance:
m = ClimateModel(params)

# ### Modifying keyword arguments for `optimize_controls!`
# We can make the controls constant in time by asserting a maximum deployment rate of zero
max_slope = Dict("mitigate"=>0., "remove"=>0., "geoeng"=>0., "adapt"=>0.);

# Now we get rid of geoengineering and adaptation options by setting their maximum deployment fraction to zero
max_deployment = Dict("mitigate"=>1.0, "remove"=>1.0, "geoeng"=>0., "adapt"=>0.);

# ### Run the optimization problem once to test
@time optimize_controls!(m, obj_option = "net_benefit", max_slope=max_slope, max_deployment=Dict("mitigate"=>1.0, "remove"=>0., "geoeng"=>0., "adapt"=>0.));

# ### Visualizing the results
p = ClimateMARGO.Plotting.plot_state(m)
plot!(p[4], ylim = (0, 1.2), yticks=([0.:0.2:1.0;], string.(0:20:100)))
# ## Comparing the two-dimensional optimization with the brute-force parameter sweep method

# ### Parameter sweep

# In the brute-force approach, we sweep through all possible values of **M**itigation and **R**emoval to map out the objective functions and constraints and visually identify the "optimal" solution in this 2-D space.
Ms = 0.:0.005:1.0;
Rs = 0.:0.005:1.0;

# We will also consider four different temperature thresholds and visualize these constraints in the 2-D space
temp_goals = [1.5, 2.0, 3.0, 4.0]

control_cost = zeros(length(Rs), length(Ms)) .+ 0. #
net_benefit = zeros(length(Rs), length(Ms)) .+ 0. #
max_temp = zeros(length(Rs), length(Ms)) .+ 0. # stores the maximum temperature acheived for each combination
min_temp = zeros(length(Rs), length(Ms)) .+ 0. # stores the minimum temperature acheived for each combination
optimal_controls = zeros(2, length(temp_goals), 2) # to hold optimal values computed using JuMP

for (o, option) = enumerate(["adaptive_temp", "net_benefit"])
    for (i, M) = enumerate(Ms)
        for (j, R) = enumerate(Rs)
            m.controls.mitigate = zeros(size(t(m))) .+ M
            m.controls.remove = zeros(size(t(m))) .+ R
            if minimum(c(m, M=true, R=true)) <= 100.
                continue
            end
            control_cost[j, i] = net_present_cost(m, discounting=true, M=true, R=true)
            net_benefit[j, i] = net_present_benefit(m, discounting=true, M=true, R=true)
            max_temp[j, i] = maximum(T(m, M=true, R=true))
            min_temp[j, i] = minimum(T(m, M=true, R=true))
        end
    end
    for (g, temp_goal) = enumerate(temp_goals)
        optimize_controls!(m, obj_option = option, temp_goal = temp_goal, max_slope=max_slope, max_deployment=max_deployment);
        optimal_controls[:, g, o] = deepcopy([m.controls.mitigate[1], m.controls.remove[1]])
    end
end

# ### Visualizing the one-dimensional mitigation optimization problem
# In the limit of zero-carbon dioxide removal, we can recover the 1D mitigation optimization problem from the 2D one.
col = (
    Colors.RGBA(1., 0.8, 0.),
    Colors.RGBA(0.8, 0.5, 0.),
    Colors.RGBA(0.7, 0.2, 0.),
    Colors.RGBA(0.6, 0., 0.),
)

p1 = plot(title="1D cost-effectivness optimization");
ind1 = argmin(abs.(max_temp[1,:] .- 1.5));
ind2 = argmin(abs.(max_temp[1,:] .- 2.));
ind3 = argmin(abs.(max_temp[1,:] .- 3.));
ind4 = argmin(abs.(max_temp[1,:] .- 4.));
plot!(p1, Ms, control_cost[1,:], color=:black);
plot!(p1, [Ms[ind1]], [control_cost[1,ind1]], marker=:circle, markercolor=col[1], markersize=10);
plot!(p1, [Ms[ind2]], [control_cost[1,ind2]], marker=:circle, markercolor=col[2], markersize=10);
plot!(p1, [Ms[ind3]], [control_cost[1,ind3]], marker=:circle, markercolor=col[3], markersize=10);
plot!(p1, [Ms[ind4]], [control_cost[1,ind4]], marker=:circle, markercolor=col[4], markersize=10);
for (g, temp_goal) = enumerate(temp_goals)
    plot!(p1, [NaN], [NaN], fillrange=[NaN], color=col[g], label=latexstring("\$\\max(T)>\$", temp_goal), alpha=0.5);
end
minM1 = Ms[ind1];
minM2 = Ms[ind2];
minM3 = Ms[ind3];
minM4 = Ms[ind4];
yl = deepcopy(ylims(p1));
plot!(p1, [minM2,minM1], [yl[1], yl[1]], fillrange=[yl[2],yl[2]], color=col[1], alpha=0.2);
plot!(p1, [minM3,minM2], [yl[1], yl[1]], fillrange=[yl[2],yl[2]], color=col[2], alpha=0.2);
plot!(p1, [minM4,minM3], [yl[1], yl[1]], fillrange=[yl[2],yl[2]], color=col[3], alpha=0.2);
plot!(p1, [0,minM4], [yl[1], yl[1]], fillrange=[yl[2],yl[2]], color=col[4], alpha=0.2);
plot!(p1, [minM1], seriestype = :vline, color=col[1]);
plot!(p1, [minM2], seriestype = :vline, color=col[2]);
plot!(p1, [minM3], seriestype = :vline, color=col[3]);
plot!(p1, [minM4], seriestype = :vline, color=col[4]);
plot!(p1, ylim=yl, xlim = (0,1), xticks = (0.:0.2:1.0, ["0%", "20%", "40%", "60%", "80%", "100%"]));
plot!(p1, xlabel = "Emissions mitigation level [% reduction]", ylabel="Net present cost of controls [trillion USD]");
plot!(p1, [NaN], [NaN], marker=:circle, color=:grey, label="lowest cost", markersize=10.);
plot!(p1, legend=:topleft);

p2 = plot(title="1D cost-benefit optimization");
plot!(p2, Ms, net_benefit[1,:], color=:black);
ind = argmax(net_benefit[1,:]);
plot!(p2, [Ms[ind]], [net_benefit[1,ind]], marker=:circle, color=:black, markersize=10, label="most benefits");
yl = ylims(p2);
plot!(p2, [minM1], seriestype=:vline, color=col[1]);
plot!(p2, [minM2], seriestype=:vline, color=col[2]);
plot!(p2, [minM3], seriestype=:vline, color=col[3]);
plot!(p2, [minM4], seriestype=:vline, color=col[4]);
plot!(p2, ylim = yl, xlim = (0,1), xticks = (0.:0.2:1.0, ["0%", "20%", "40%", "60%", "80%", "100%"]));
plot!(p2, xlabel = "Emissions mitigation level [% reduction]", ylabel = "Net present benefits, relative to baseline [trillion USD]");
plot!(p2, legend=:topleft);

p = plot(p1, p2, size=(1200, 500), margin=5Plots.Measures.mm)
##

# ### Visualizing the two-dimensional optimization problem

p1 = plot(title="2D cost-effectiveness optimization");
plot!(p1, Ms, Rs, control_cost, seriestype=:heatmap, clim=(0, 150), c=cgrad(:greys, rev=true));
plot!(p1, colorbar_title = "Net present cost of controls [trillion USD]");
control_cost[(min_temp .<= 0.)] .= NaN;

for (g, temp_goal) = enumerate(temp_goals)
    plot!(p1, Ms, Rs, max_temp, seriestype=:contour, seriescolor=col[g], levels=[temp_goal], linewidths=2.5);
    plot!(p1, [optimal_controls[1,g,1]], [optimal_controls[2,g,1]], marker=:o, color=col[g], markersize=10.);
    plot!(p1, [NaN], [NaN], fillrange=[NaN], color=col[g], label=latexstring("\$\\max(T)>\$", temp_goal), alpha=0.5);
end
plot!(p1, Ms, Rs, control_cost, levels=[10, 50], seriestype=:contour, seriescolor=:thermal, linewidths=2., alpha=0.8);
plot!(p1, [NaN], [NaN], marker=:circle, color=:gray, label="lowest cost", markersize=10.);
plot!(p1, legend=:topleft, xlabel="Emissions mitigation level [% reduction]", ylabel=L"CO$_{2e}$ removal rate [% of present-day emissions]");
plot!(p1, xticks=(0.:0.2:1.0, ["0%", "20%", "40%", "60%", "80%", "100%"]), yticks=(0.:0.2:1.0, ["0%", "20%", "40%", "60%", "80%", "100%"]));
annotate!(p1, 0.1, 0.05, text(L"$\max(T) > 4\degree$C", :darkred, 10));
annotate!(p1, 0.85, 0.85, text(L"$\min(T) < 0\degree$C", :darkblue, 10));
plot!(xlim=(0, 1.), ylim=(0., 1.));

p2 = plot(title="2D cost-benefit optimization");
plot!(p2, Ms, Rs, net_benefit, seriestype=:heatmap, clim=(0, 250), c=cgrad(:greys));
plot!(p2, colorbar_title = "Net present benefits, relative to baseline [trillion USD]");
plot!(p2, [optimal_controls[1,1,2]], [optimal_controls[2,1,2]], marker=:o, color=:black, markersize=10., label="most benefits");
for (g, temp_goal) = enumerate(temp_goals)
    plot!(p2, Ms, Rs, max_temp, seriestype=:contour, seriescolor=col[g], levels=[temp_goal], linewidths=2.5);
end
plot!(p2, Ms, Rs, net_benefit, seriestype=:contour, levels=[100, 200], seriescolor=:black, linewidths=0.5, alpha=0.8);
plot!(legend=:topright);
plot!(p2, xlabel="Emissions mitigation level [% reduction]", ylabel=L"CO$_{2e}$ removal rate [% of present-day emissions]");
plot!(xticks = (0.:0.2:1.0, ["0%", "20%", "40%", "60%", "80%", "100%"]), yticks=(0.:0.2:1.0, ["0%", "20%", "40%", "60%", "80%", "100%"]));
annotate!(p2, 0.85, 0.85, text(L"$\min(T) < 0\degree$C", :white, 10));
plot!(xlim=(0, 1.), ylim=(0., 1.));

p = plot(p1, p2, size=(1600, 550), margin=5Plots.Measures.mm)
