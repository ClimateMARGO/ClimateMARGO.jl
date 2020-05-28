push!(LOAD_PATH,"../src/")

using Documenter, MARGO

makedocs(
    sitename="MARGO.jl",
    doctest = true,
    authors = "Henri F. Drake",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = [
      "Home" => "index.md",
      "Installation instructions" => "installation_instructions.md",
      "Function index" => "function_index.md"
    ]
)

deploydocs(repo = "github.com/hdrake/MARGO.jl.git")
