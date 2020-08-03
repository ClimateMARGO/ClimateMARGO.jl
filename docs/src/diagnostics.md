# Diagnostics

We refer to key model variables which depend only on 1) the values of the control variables and 2) the input parameters as *diagnostic* variables. Examples are the CO``_{2e}`` concentrations ``c_{M,R}(t)``, the temperature change ``T_{M,R,G,A}``, and the cost of mitigation ``\mathcal{C}_{M} M^{2}``.

In ClimateMARGO.jl, diagnostic variables are represented as julia *functions*, which are implemented using two separate *methods*, based on the type of the function arguments: the first method requires an explicit list of all the input parameters and control variables that determine the diagnostic variables; the second method leverages the `ClimateModel` struct to read in the required variables.

For example, here are the two methods that define the diagnostic function `T` for the temperature change:

```@meta
CurrentModule = ClimateMARGO.Diagnostics
```

```@docs
T
```
