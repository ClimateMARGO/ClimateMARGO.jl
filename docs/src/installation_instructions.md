# Installation instructions



We recommend installing ClimateMARGO with the built-in Julia package manager, because this installs a stable, tagged release. You can install the latest version of ClimateMARGO using the built-in package manager (accessed by pressing `]` in the Julia command prompt) to add the package and instantiate/build all dependencies. It is recommended that you create a new self-contained julia environment to install ClimateMARGO in.

```julia
julia>]
(v1.7) pkg> activate .
(v1.7) pkg> add ClimateMARGO
(v1.7) pkg> instantiate
```

The command `activate .` will create (if not yet existent) and activate a new environment with the name of the parent folder.

ClimateMARGO.jl can be updated to the latest tagged release from the package manager by typing
```julia
(v1.7) pkg> update ClimateMARGO
```

In some cases, it may be useful to install versions of ClimateMARGO from a development branch named [Branch name], which can be done by typing
```julia
(v1.7) pkg> add https://github.com/ClimateMARGO/ClimateMARGO.jl#[Branch name]
```

At this time (and until ClimateMARGO v1.0.0), updating should be done with care, as ClimateMARGO is under rapid development and breaking changes to the user API occur often. But if anything does happen, please open an issue!

!!! warn "Use Julia 1.5 or newer"
    ClimateMARGO requires at least Julia v1.5 to run.
