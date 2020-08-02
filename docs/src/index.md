# ClimateMARGO.jl

A Julia implementation of **MARGO**, an idealized framework for the **O**ptimization of four climate change control strategies: **M**itigation, **A**daptation, **R**emoval of carbon dioxide, and **G**eoengineering by solar radiation management.

ClimateMARGO.jl couples together a very simple model of Earth's physical climate with a very simple economic model of climate damages (and the costs of controls that reduce those damages). Our design philosophy is for the MARGO model to be *as simple as possible* while still producing quasi-realistic climate trajectories over the next few hundred years.

Compared to more conventional *Integrated Assessment Models (IAMs)*, MARGO is:
* **Faster**: The algorithm solves convex optimization problems in less than 10 milliseconds (most use cases), meaning the model can be run interactively in real-time and that both large-ensemble, high-dimensional, and stochastic optimizations are all computationally feasible.
* **More accessible**: The ClimateMARGO.jl package is free to use and is accessible in several different forms depending on the user's programming experience and use case:
  * *An interactive web-app (Coming Soon)* – For code-free interactive exploration of climate storylines (and their sensitivity to model parameters)
  * *A browser-based binder tutorial* – For users with some programming experience who want to see (and run!) the *ClimateMARGO.jl* source code
  * *Importing ClimateMARGO.jl* – For users proficient in Julia who want to use the MARGO model for education or scientific research
  * *Forking ClimateMARGO.jl* – For users wanting to extend or fundamentally modify the MARGO model for scientific research
* **More interpretable**: The entire model algorithm is simple enough to be expressed in a single closed-form math equation and is determined by only a handful of intuitive free parameters (see also the MARGO flowchart below).
* **More transparent**: The MARGO model is developed as an entirely open-source Julia package, *ClimateMARGO.jl*, complete with documentation, in-depth tutorials, and publication-quality example simulations.
* **More general**: By including all four of the primary climate controls in the default configuration, more common configurations like "Mitigation-only" experiments are straight-forward to implement by simply turning unwanted features off.
* **More explicitly value-dependent**: Rather than burying important value-dependent choices in various obscure economic and social parameters, we abstract away many of the complexities to yield a small number of intuitive parameters, which can be easily modified by users.
* **More extendable**: The modular and interpretable nature of the Julia source implementation means that existing features can be easily modified and new features are easily added.

!!! warning "Don't take MARGO's results too seriously"
    The extreme simplicity of the MARGO model also means its *quantitative* results should be taken with a large pinch of salt. MARGO should instead be used to explore underlying *patterns* and *relative* climate outcomes.

## Getting help

If you are interested in using ClimateMARGO.jl or are trying to figure out how to use it, please feel free to ask us questions and get in touch! Please feel free to [open an issue](https://github.com/hdrake/ClimateMARGO.jl/issues/new) if you have any questions, comments, suggestions, etc!
