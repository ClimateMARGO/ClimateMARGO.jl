push!(LOAD_PATH,"../src/")

using Documenter, ClimateMARGO

makedocs(
    sitename="ClimateMARGO.jl",
    doctest = true,
    authors = "Henri F. Drake",
    push_preview = false,
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    pages = [
      "Home" => "index.md",
      "Installation instructions" => "installation_instructions.md",
      "Function index" => "function_index.md"
    ]
)

deploydocs(repo = "github.com/hdrake/ClimateMARGO.jl.git",)
