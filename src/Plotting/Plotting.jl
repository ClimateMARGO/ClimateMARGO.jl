module Plotting

using PyPlot
using ClimateMARGO.Models
using ClimateMARGO.Diagnostics

export
    plot_controls, plot_emissions, plot_concentrations,
    plot_forcings, plot_temperatures,
    plot_benefits, plot_damages,
    plot_state

include("line_plots.jl")

end