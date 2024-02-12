using DifferentialEquations
using ModelingToolkit
using Plots

@parameters t
D = Differential(t)

@mtkmodel System begin
    @variables begin
        x(t) = 1
        v(t) = 0
    end
    @equations begin
        D(x) ~ v
        D(v) ~ -9.81
    end
    @continuous_events begin
        [x ~ 0] => [v ~ -v]
    end
end

@mtkbuild system = System()
tspan = (0.0, 5.0)
prob = ODEProblem(system, [], tspan)
sol = solve(prob)
plot(sol, idxs = [system.x, system.v])
