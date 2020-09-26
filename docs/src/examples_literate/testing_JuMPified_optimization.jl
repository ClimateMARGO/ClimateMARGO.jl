using JuMP, Ipopt

model = Model(Ipopt.Optimizer)
@variable(model, x, start = 0.0)
@variable(model, y, start = 0.0)

f(x,y) = (1 - x) ^ 2 + 100 * (y - x ^ 2) ^ 2

register(model, :f, 2, f, autodiff=true)
@NLobjective(model, Min, f(x,y))
#@NLobjective(model, Min, (1 - x) ^ 2 + 100 * (y - x ^ 2) ^ 2)

optimize!(model)
println("x = ", value(x), " y = ", value(y))

# adding a (linear) constraint
@constraint(model, x + y == 10)
optimize!(model)
println("x = ", value(x), " y = ", value(y))