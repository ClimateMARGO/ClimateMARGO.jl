## Loading modules
using Revise
using ClimateMARGO
using ClimateMARGO.Models
using ClimateMARGO.Diagnostics

## 
testfunc(x) = x
fakedict = Dict("M"=>1., "R"=>2., "G"=>3., "A"=>4.)
timegrid = TemporalGrid(1., 2020., 2200.)
econ = Economics(
    RampingEmissions(ramp_emissions),
    ExponentialGrowth(100., 0.02),
    ExponentialDiscounting(0.02),
    PowerLawControls(fakedict, fakedict),
    PowerLawDamages(1., 8.5)
)

phys = Physics(
    InitialConditions(460., 3.0, 1.1),
    FractionalEmissions(0.5),
    LogarithmicCO2Forcing(5.0),
    TwoLayerEBM(1.1, 0.5, 5., 100.)
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
m.controls.deployed["M"] .+= 0.5;

## Plotting
using PyPlot
fig = subplot()
clf()
plot(t(m), emissions(m))
plot(t(m), emissions(m, M=true))
display(gcf())

fig = subplot()
clf()
plot(t(m), c(m))
plot(t(m), c(m, M=true))
display(gcf())