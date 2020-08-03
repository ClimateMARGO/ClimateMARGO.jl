push!(LOAD_PATH,"../src/")

using ClimateMARGO
using Documenter, Literate

const EXAMPLES_DIR = joinpath(@__DIR__, "src/examples_literate")
const OUTPUT_DIR   = joinpath(@__DIR__, "src/generated")

print(@__DIR__)

examples = [
    "default_optimization.jl"
]

for example in examples
    example_filepath = joinpath(EXAMPLES_DIR, example)
    Literate.markdown(example_filepath, OUTPUT_DIR, documenter=true)
end

#### Organize page structure

example_pages = [
    "Optimization with default parameters" => "generated/default_optimization.md"
]

pages = [
    "Home" => "index.md",
    "Installation instructions" => "installation_instructions.md",
    "Theory" => "theory.md",
    "Examples" => example_pages,
    "Submodules" => [
        "Domain" => "Submodules/Domain.md",
        "Physics" => "Submodules/Physics.md",
        "Economics" => "Submodules/Economics.md",
        "Controls" => "Submodules/Controls.md",
    ],
    "Diagnostics" => "diagnostics.md",
    "Optimization" => "optimization.md",
    "Function index" => "function_index.md"
]

makedocs(
    sitename="ClimateMARGO.jl",
    doctest = true,
    authors = "Henri F. Drake",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    pages = pages
)

deploydocs(repo = "github.com/hdrake/ClimateMARGO.jl.git",)
