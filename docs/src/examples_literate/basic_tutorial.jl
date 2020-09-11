## Loading modules
using Revise
using ClimateMARGO
using ClimateMARGO.Models
using ClimateMARGO.Diagnostics

## Creating data structures
testfunc(x) = x
fakedict = Dict("M"=>1., "R"=>2., "G"=>3., "A"=>4.)
timegrid = TemporalGrid(0.05, 2020., 3000.)
econ = Economics(
    RampingEmissions(linear_ramp_emissions),
    ExponentialGrowth(100., 0.02),
    ExponentialDiscounting(0.02),
    PowerLawControls(fakedict, fakedict),
    PowerLawDamages(1., 8.5)
)

ebm = TwoLayerEBM(1.1, 1.13, 0.73, 7.3, 106.)
ebm_ML = TwoLayerEBM(1.1, 1.13, 0.0001, 7.3, 106.)
phys = Physics(
    FractionalEmissions(460, 0.5),
    LogarithmicCO2Forcing(3.0, 5.0),
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
m.controls.deployed["M"] .+= 0.5;
m.controls.deployed["R"] .+= 0.2;
m.controls.deployed["G"] .+= 0.2;
m.controls.deployed["A"] .+= 0.1;
for (C, deployment) in m.controls.deployed;
    deployment[1] = 0.;
end

## Plotting
using PyPlot
fig = figure(1)
clf()
plot(t(m), emissions(m))
plot(t(m), emissions(m, M=true))
display(gcf())

fig = figure(2)
clf()
plot(t(m), c(m))
plot(t(m), c(m, M=true))
plot(t(m), c(m, M=true, R=true))
display(gcf())

fig = figure(3)
clf()
plot(t(m), F(m, F0=true), "k-")
plot(t(m), F(m, M=true, F0=true), "C0")
plot(t(m), F(m, M=true, R=true, F0=true), "C1")
plot(t(m), F(m, M=true, R=true, G=true, F0=true), "C3")
display(gcf())

## Compare w/ historical forcing 

fig = figure(4)
clf()
plot(t(m), ebm.T0 .+ F(m)/ebm.λ)
plot(t(m), T(m.grid, ebm_ML, F(m)), "r--")
plot(t(m), T(m), "k-")

ylim(0, 5)
xlim(2020, 2100)
display(gcf())