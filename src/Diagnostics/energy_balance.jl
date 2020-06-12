function F(a, c0, Finf, c, G)
    a .* log.( c/c0 ) .- G*Finf
end

function F(model; M=false, R=false, G=false)
    return F(
        model.physics.a, model.physics.c0, model.economics.Finf,
        c(model, M=M, R=R),
        model.controls.geoeng .* (1. .- .~future_mask(model) * ~G),
    )
end

F2x(a::Float64) = a*log(2)
F2x(model::ClimateModel) = F2x(model.physics.a)

ECS(a, B) = F2x(a)/B
ECS(model) = ECS(model.physics.a, model.physics.B)

B(a::Float64, ECS::Float64) = F2x(a)/ECS
B(model::ClimateModel; ECS=ECS(model)) = B(model.physics.a, ECS)

τd(Cd, B, κ) = (Cd/B) * (B+κ)/κ
τd(phys::Physics) = τd(phys.Cd, phys.B, phys.κ)
τd(model::ClimateModel) = τd(model.physics)


# δT_baseline(model::ClimateModel) = (
#     model.physics.δT_init .+
#     (FCO₂_baseline(model) .+ model.physics.κ / (model.physics.τd * model.physics.B) *  
#         (
#             exp.( -(model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#             cumsum(
#                 exp.( (model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#                 FCO₂_baseline(model)
#                 .* model.dt
#             )
#         )
#     ) ./ (model.physics.B + model.physics.κ)
# )

# δT_no_geoeng(model::ClimateModel) = (
#     model.physics.δT_init .+
#     (FCO₂_no_geoeng(model) .+ model.physics.κ / (model.physics.τd * model.physics.B) *  
#         (
#             exp.( - (model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#             cumsum(
#                 exp.( (model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#                 FCO₂_no_geoeng(model)
#                 .* model.dt
#             )
#         )
#     ) ./ (model.physics.B + model.physics.κ)
# )

# δT(model::ClimateModel) = ((
#         model.physics.δT_init .+
#         (FCO₂(model) .+ model.physics.κ / (model.physics.τd * model.physics.B) * 
#             (
#                 exp.( - (model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#                 cumsum(
#                     exp.( (model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#                     FCO₂(model)
#                     .* model.dt
#                 )
#             )
#         ) ./ (model.physics.B + model.physics.κ)
#     )
# )

# δT_adapt(model::ClimateModel) = ((
#         model.physics.δT_init .+
#         (FCO₂(model) .+ model.physics.κ / (model.physics.τd * model.physics.B) * 
#             (
#                 exp.( - (model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#                 cumsum(
#                     exp.( (model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#                     FCO₂(model)
#                     .* model.dt
#                 )
#             )
#         ) ./ (model.physics.B + model.physics.κ)
#     ) .* sqrt.(1. .- model.controls.adapt)
# )

# δT_fast(model::ClimateModel) = ((
#         FCO₂(model) ./ (model.physics.B + model.physics.κ)
#     )
# )

# δT_slow(model::ClimateModel) = (
#     (
#         model.physics.κ / (model.physics.τd * model.physics.B) * 
#             (
#                 exp.( - (model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#                 cumsum(
#                     exp.( (model.domain .- (model.domain[1] - model.dt)) / model.physics.τd ) .*
#                     FCO₂(model)
#                     .* model.dt
#                 )
#             )
#         ) ./ (model.physics.B + model.physics.κ)
# )
