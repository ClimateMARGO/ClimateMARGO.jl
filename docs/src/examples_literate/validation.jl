##
using PyPlot, Statistics
using ClimateMARGO

##
using ClimateMARGO.Models
using ClimateMARGO.Diagnostics
using ClimateMARGO.Utils

##
# using Pkg
# Pkg.add("DataFrames")
# Pkg.add("CSV")

##
using DataFrames, CSV

## 
# data_path = "https://data.giss.nasa.gov/gistemp/graphs/graph_data/Global_Mean_Estimates_based_on_Land_and_Ocean_Data/graph.txt"
# run(`wget $data_path`)

##
local_path = "graph.txt"
data = DataFrame!(CSV.File(local_path, header=false, skipto=6, delim="     "));
T_obs = parse.(Float64, Array(data[:,2]));
t_obs = parse.(Float64, Array(data[:,1]));

## Creating data structures
costdict = Dict("M"=>1., "R"=>2., "G"=>3., "A"=>4.)
timegrid = TemporalGrid(0.05, 1800., 3000.)
econ = Economics(
    RampingEmissions(exp_ramp_emissions),
    ExponentialGrowth(100., 0.02),
    ExponentialDiscounting(0.02),
    PowerLawControls(costdict, costdict),
    PowerLawDamages(1., 8.5)
)

ebm = TwoLayerEBM(0., 1.13, 0.73, 7.3, 106.)
ebm_ML = TwoLayerEBM(0., 1.13, 0.0001, 7.3, 106.)
ebm_DML = TwoLayerEBM(0., 1.13, 0.0001, 45., 106.)
phys = Physics(
    FractionalEmissions(300., 0.5),
    LogarithmicCO2Forcing(0., 5.0),
    ebm
)

con = CostBenefit(
    Dict("M"=>1., "R"=>1., "G"=>1., "A"=>0.5),
    Dict("M"=>1/40., "R"=>1/40., "G"=>1/40., "A"=>1/40.),
    Dict("M"=>nothing, "R"=>nothing, "G"=>nothing, "A"=>0.1),
    Dict("M"=>0., "R"=>0., "G"=>0., "A"=>0.),
)

params = ClimateModelParameters(
    "test",
    timegrid,
    econ,
    phys,
    con
)

m = ClimateModel(params)

## Plotting
using PyPlot

offset=0.4
plot_atmos() = plot(t(m), ebm.T0 .+ F(m)/ebm.λ, "C3", lw=2., label="Atmosphere-only Climate Model")
plot_ml() = plot(t(m), T(m.grid, ebm_ML, F(m)), "C1-", lw=2., label=L"Atmosphere $\rightarrow$ Surface Ocean")
plot_deep() = plot(t(m), T(m), "k-", lw=2., label=L"Atmosphere $\rightarrow$ Surface Ocean $\rightarrow$ Deep Ocean")
af_ = ClimateMARGO.Diagnostics.af(ebm)
τf_ = ClimateMARGO.Diagnostics.τf(ebm)
Tslowmode = ClimateMARGO.Diagnostics.T_mode(F(m), ebm.λ, af_, τf_, t(m), m.grid.dt)
plot_obs(; style=".") = plot(t_obs, T_obs .+ offset, style, color="grey", label="Observations (NASA)")

function modefill()
    fill_between(t(m), Tslowmode.*0., Tslowmode, alpha=0.1, color="C0")
    fill_between(t(m), Tslowmode, T(m), alpha=0.25, color="C0")
end

function T_format()
    legend()
    ylim(-0.2, 2.25)
    xlim(1880, 2020)
    grid(true)
    xlabel("year")
    ylabel("Warming [°C]")
end

#
fig = figure(1)
clf()
plot(t(m), emissions(m))
xlim(1900, 2200)
display(gcf())

fig = figure(2)
clf()
plot(t(m), c(m), "k-", lw=2)
xlim(1875, 2200)
ylim(250, 2250)
xlabel("year")
ylabel(L"CO$_{2e}$ concentration [ppm]")
title("Greenhouse Gas stabilization by 2200...")
grid(true)
display(gcf())
savefig("figures/CO2.png", dpi=150., bbox_inches="tight")

fig = figure(3)
clf()
plot(t(m), F(m, F0=true), "k-")
xlim(1875, 2200)
ylim(0,10)
grid(true)
xlabel("year")
ylabel(L"Radiative forcing [W/m$^2$]")
title("...means radiative forcing stabilizes too.")
display(gcf())
savefig("figures/Forcing.png", dpi=150., bbox_inches="tight")

fig = figure()
plot_atmos()
T_format()
display(gcf())
savefig("figures/Temp1.png", dpi=150., bbox_inches="tight")

fig = figure()
plot_atmos()
plot_obs()
T_format()
display(gcf())
savefig("figures/Temp2.png", dpi=150., bbox_inches="tight")

fig = figure()
clf()
plot_atmos()
plot_ml()
plot_obs()
T_format()
display(gcf())
savefig("figures/Temp3.png", dpi=150., bbox_inches="tight")

fig = figure()
clf()
plot_atmos()
plot_ml()
plot_deep()
plot_obs()
T_format()
display(gcf())
savefig("figures/Temp4.png", dpi=150., bbox_inches="tight")

fig = figure()
clf()
plot_atmos()
plot_ml()
plot_deep()
plot_obs(style="-")
T_format()
xlim(1880, 2200)
ylim(-0.2, 9.)
display(gcf())
savefig("figures/Temp5.png", dpi=150., bbox_inches="tight")

fig = figure()
clf()
plot_atmos()
plot_ml()
plot_deep()
modefill()
plot_obs(style="-")
T_format()
xlim(1880, 3000)
ylim(-0.2, 9.)
savefig("")
display(gcf())
savefig("figures/Temp6.png", dpi=150., bbox_inches="tight")
