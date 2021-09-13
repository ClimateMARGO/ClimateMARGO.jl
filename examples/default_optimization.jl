# # Optimization of the default MARGO configuration

using Revise

## 

# ## Using `ClimateMARGO.jl`
using ClimateMARGO
using ClimateMARGO.Models
using ClimateMARGO.Optimization

# ## Loading preset configurations

# Load the pre-defined default MARGO parameters, which are described by the ClimateModelParameters struct
params = deepcopy(ClimateMARGO.IO.included_configurations["default"])

# Create a MARGO instance based on these parameters
m = ClimateModel(params);

# By default, the climate control timeseries are all set to zero.
m.controls

# ## Real-time climate optimization

# Let's optimize the controls with the default settings, which finds the cheapest combination of the control timeseries that keeps adapted temperatures below 2°C.
@time optimize_controls!(m, temp_goal=1.5);

# The optimization can be slow the first time since it has to compile.
# Let's re-initialize the model and see how fast it runs now that the the optimization routine has been precompiled.
m = ClimateModel(params);
@time optimize_controls!(m, temp_goal=1.5);

# ## Visualizing the results

# Finally, let's plot the resulting temperature timeseries
using PyPlot
fig, axes = ClimateMARGO.Plotting.plot_state(m, temp_goal=1.5);
gcf()