using ModelingToolkit
using ModelingToolkitStandardLibrary.Blocks
using ModelingToolkitStandardLibrary.Electrical
using OrdinaryDiffEq
using Plots

@mtkmodel Diode begin
    @parameters begin
        VFwdDrop = 0.5
        Rc       = 0.01
        Rn       = 1e6
    end
    @extend v, i = oneport = OnePort()
    @equations begin
        i ~ ifelse(v >= VFwdDrop,
                   v / Rc,  # on
                   v / Rn)
    end
end

@mtkmodel System begin
    @components begin
        # gen = Sine(amplitude = 3,
        #            frequency = 1)
        gen = Step(height = 2,
                   start_time = 1)
        source = Voltage()
        D = Diode()
        R = Resistor(R = 1)
        Gnd = Ground()
    end
    @equations begin
        connect(gen.output, source.V)
        connect(source.p, D.p)
        connect(D.n, R.p)
        connect(source.n, R.n, Gnd.g)
    end
end

@mtkbuild system = System()
prob = ODEProblem(system, [], (0, 3))
sol = solve(prob, dtmax = 1)
