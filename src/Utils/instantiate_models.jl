"""
    init_zero_controls(t)

Return initial state of uniformly-zero climate controls.

See also: [`Controls`](@ref)
"""
function init_zero_controls(t::Array{Float64,1})
    c = Controls(
        zeros(size(t)),
        zeros(size(t)),
        zeros(size(t)),
        zeros(size(t))
    )
    return c
end