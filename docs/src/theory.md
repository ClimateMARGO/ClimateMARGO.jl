# Theory

## The Causal Chain of Climate Damages

It is helpful to conceptualize climate change as a four step process that connects the human-caused emissions of greenhouse gases (GHGs) to the eventual climate suffering (or damages) that they cause. This four-step framing is helpful because it highlights the four major human interventions (or controls) which can break these links and reduce climate suffering: **M**itigation of GHG emissions (e.g. switching away from fossil fuels), **R**emoval of carbon dioxide from the atmosphere (e.g. by planting trees or storing biofuel emissions underground), **G**eoengineering by solar radiation management (e.g. injecting sulfate aerosols into the stratosphere to reduce incoming sunlight), or **A**dapting to the changed climate (e.g. relocating coastal communities displaced by rising seas or expanding indoor air condititiong to fight off intensifying heat waves).

```math
\text{Emissions}
\xrightarrow{\text{\textbf{M}}}
\text{GHGs}
\xrightarrow{\text{\textbf{R}}}
\text{Forcing}
\xrightarrow{\text{\textbf{G}}}
\text{Warming}
\xrightarrow{\text{\textbf{A}}}
\text{Damages}.
```

Letting climate change run rampant would cause a lot of damage; however, climate interventions that keep climate change under control are not free either. With MARGO, we allow users to explore the trade-offs between climate interventions and climate suffering by employing an optimization framework commonly used in the climate-economics community. In this section, we develop a simple theory– a set of mathematical equations– which capture the key aspects of the entire causal chain of climate damages.

## GHG emissions

CO``_{2e}`` is emitted at a rate ``q(t)``, with only a fraction ``r = 50\%`` remaining in the atmosphere after a few years, net of uptake by the ocean and terrestrial biosphere.

!!! info "Climate intervention: Mitigation" GHG emissions are reduced by a mitigation factor ``(1-M(t))``, becoming ``q(t)(1-M(t))``, where ``0\% < M(t) < 100\%``.

## GHG concentrations and carbon dioxide removal

CO``_{2e}`` accumulates in the atmosphere and concentrations ``c(t)`` increase as long as the emissions ``q(t)`` are non-zero, and are given by ``c(t) = c_{0} + \int_{t_{0}}^{t} rq(t)\text{ d}t``.

!!! warning "Climate intervention: Removal"

## Radiative forcing and solar radiation management

!!! danger "Climate intervention: Geo-engineering"

## Global warming and climate suffering

!!! tip "Climate intervention: Adaptation"

## The costs of climate intervention

## Optimization: what makes a climate "optimal"?
