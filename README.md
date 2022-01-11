<!-- Title -->
<h1 align="center">
  ClimateMARGO.jl
</h1>

<!-- description -->
<p align="center">
  <strong> A Julia implementation of <b>MARGO</b>, an idealized framework for optimization of climate change control strategies.</strong>
</p>

<!-- Information badges -->
<p align="center">
  <a href="https://mit-license.org">
    <img alt="MIT license" src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square">
  </a>
  <a href="https://github.com/ClimateMARGO/ClimateMARGO.jl/issues/new">
    <img alt="Ask us anything" src="https://img.shields.io/badge/Ask%20us-anything-1abc9c.svg?style=flat-square">
  </a>
  <a href="https://ClimateMARGO.github.io/ClimateMARGO.jl/dev/">
    <img alt="Documentation in development" src="https://img.shields.io/badge/docs-latest-blue.svg?style=flat-square">
  </a>
  <a href="https://travis-ci.com/ClimateMARGO/ClimateMARGO.jl">
    <img alt="Build status" src="https://travis-ci.com/ClimateMARGO/ClimateMARGO.jl.svg?branch=main">
  </a>
</p>

<!-- CI/CD badges -->

The MARGO model is described in full in an [accompanying Research Article](https://iopscience.iop.org/article/10.1088/1748-9326/ac243e/pdf), published *Open-Access* in the journal *Environmental Research Letters*. The julia scripts and jupyter notebooks that contain all of the paper's analysis are available in the [MARGO-paper](https://github.com/ClimateMARGO/MARGO-paper) repository (these are useful as advanced applications of MARGO to complement the minimal examples included in the documentation).

Try out the MARGO model by running our [web-app](https://margo.plutojl.org/introduction.html) directly in your browser!

![Gif of ClimateMARGO.jl being used interactively. The user's mouse cursor clicks on an emissions curve to drag the emissions down. A second panel shows how these emissions reductions result in less global warming, ultimately keeping global warming below a target of 2ºC.](https://raw.githubusercontent.com/hdrake/MARGO-gifs/main/MARGO_interactive_2degrees.gif)

ClimateMARGO.jl is currently in beta testing; basic model documentation is slowly being added. Substantial structural changes may still take place before the first stable release v1.0.0. Anyone interested in helping develop the model post an Issue here or contact the lead developer Henri Drake directly (henrifdrake `at` gmail.com), until explicit guidelines for contributing to the model are posted at a later date.


----
<small>README.md formatting inspired by [Oceananigans.jl](https://github.com/CliMA/Oceananigans.jl)</small>
