@mtkmodel System begin
    @variables begin
        x(t) = 1
        y(t) = 0
        vx(t) = 0
        vy(t) = 2
    end
    @equations begin
        D(x) ~ vx
        D(y) ~ vy
        D(vx) ~ -9.8 - 0.1 * vx # gravity + some small air resistance
        D(vy) ~ -0.1 * vy
    end
    @continuous_events begin
        [x ~ 0] => [vx ~ -vx]
        [y ~ -1.5, y ~ 1.5] => [vy ~ -vy]
    end
end

@mtkbuild system = System()
prob = ODEProblem(system, [], (0, 10))

sol = solve(prob)
@assert 0 <= minimum(sol[system.x]) <= 1e-10 # the ball never went through the floor but got very close
@assert minimum(sol[system.y]) > -1.5 # check wall conditions
@assert maximum(sol[system.y]) < 1.5  # check wall conditions

tv = sort([LinRange(0, 10, 200); sol.t])
plot(sol(tv)[system.y], sol(tv)[system.x], line_z = tv)
vline!([-1.5, 1.5],
       l = (:black, 3),
       primary = false)
hline!([0],
       l = (:black, 3),
       primary = false)
