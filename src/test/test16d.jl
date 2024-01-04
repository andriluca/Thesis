using DifferentialEquations
using ModelingToolkit
using ModelingToolkitStandardLibrary.Blocks
using ModelingToolkitStandardLibrary.Electrical
using Plots

@parameters t
D = Differential(t)

@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        threshold = 0, [description = "Voltage Threshold"]
    end
    @components begin
        input = RealInput()
    end
    @variables begin
        ∫i(t) = 0, [description = "Current integral"]
    end
    @equations begin
        D(∫i) ~ i
        0 ~ ifelse(input.u >= threshold,
                   v - threshold,
                   i)

        # 0 ~ ifelse(∫i <= 0,
        #            v,
        #            ifelse(i < 0,
        #                   i,
        #                   ifelse(input.u > threshold,
        #                          v - threshold,
        #                          i)
        #                   )
        #            )
    end
end

@mtkmodel System begin
    @components begin
        src = Sine(frequency = 1, amplitude = 2)
        control = Constant(k = 1)
        gen = Voltage()
        D1 = Diode(threshold = 0.5)
        R1 = Resistor(R = 1)
        C1 = Capacitor(C = 1)
        gnd = Ground()
    end
    @equations begin
        connect(src.output, gen.V)
        connect(src.output, D1.input)
        connect(gen.p, D1.p)
        connect(D1.n, R1.p)
        connect(R1.n, C1.p)
        connect(C1.n, gen.n, gnd.g)
    end
end

@mtkbuild System1 begin
    @components begin
        
    end
end

@mtkbuild system = System()
prob = ODAEProblem(system, [system.D1.∫i => 0.0], (0, 10))

function condition(u, t, integrator)
    integrator.u[2] - integrator.p[7]
end

function affect!(integrator)
    nothing
end

cb = ContinuousCallback(condition, affect!)
sol = solve(prob, Tsit5(),
#             reltol = 1e-5, abstol = 1e-5,
            callback = cb)

plot(sol, idxs = [system.C1.v, system.C1.i, system.src.output.u])
