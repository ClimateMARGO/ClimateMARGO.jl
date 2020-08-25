abstract type Constraints end

mutable struct CostBenefit <: Constraints
    max_deployment::Dict{String, }
    max_slope::Dict{String, }
    max_update::Dict{String, }
    delay_deployment::Dict{String, }
end

mutable struct CostEffective <: Constraints
    temp_goal::Real
    max_deployment::Dict{String, Real}
    max_slope::Dict{String, Real}
    max_update::Dict{String, Real}
    delay_deployment::Dict{String, Real}
end

mutable struct AnnualBudgetAllocation <: Constraints
    annual_budget::Real
    max_deployment::Dict{String, Real}
    max_slope::Dict{String, Real}
    max_update::Dict{String, Real}
    delay_deployment::Dict{String, Real}
end

mutable struct NetBudgetAllocation <: Constraints
    net_budget::Real
    max_deployment::Dict{String, Real}
    max_slope::Dict{String, Real}
    max_update::Dict{String, Real}
    delay_deployment::Dict{String, Real}
end
