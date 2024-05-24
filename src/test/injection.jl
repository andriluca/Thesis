Dₜ = Differential(t)

@parameters M tinject α

@mtkmodel System begin
    @parameters begin
        M
        tinject
        α
    end
    @variables begin
        N(t) = 0.0
    end
    @equations begin
        Dₜ(N) ~ α - N
    end
    @discrete_events begin
        # at time tinject we inject M cells
        ((t == tinject)) => [N ~ N + M]
    end
end

tspan = (0.0, 20.0)
p = [α => 100.0, tinject => 10.0, M => 50]

@mtkbuild system = System()
prob = ODEProblem(system, [], tspan, p)
sol = solve(prob, Tsit5(); tstops = 10.0)
plot(sol)
