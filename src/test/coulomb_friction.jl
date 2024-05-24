using ModelingToolkit, OrdinaryDiffEq, Plots

@parameters t
D = Differential(t)

@mtkmodel UnitMassWithFriction begin
    @parameters begin
        k = 0.7
    end
    @variables begin
        x(t) = 0
        v(t) = 0
    end
    @equations begin
        D(x) ~ v
        D(v) ~ sin(t) - k * sign(v)
    end
    @continuous_events begin
        [v ~ 0] => Equation[]
    end
end

@mtkbuild m = UnitMassWithFriction()
prob = ODEProblem(m, Pair[], (0, 10pi))
sol = solve(prob, Tsit5())
plot(sol)
