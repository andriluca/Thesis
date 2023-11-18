using ModelingToolkit
using ModelingToolkitStandardLibrary.Blocks
using ModelingToolkitStandardLibrary.Electrical
using OrdinaryDiffEq
using Plots

@mtkmodel Diode begin
    @parameters begin
        V_th = 0.7
    end
    @extend v, i = oneport = OnePort()
    @components begin
        MS = MultiSensor()
        Gnd = Ground()
    end
    @equations begin
        # Connetto il + del sensore di corrente al + del sensore di tensione
        connect(MS.pc, MS.pv, oneport.p)
        # Connetto il - del sensore di corrente a massa
        connect(Gnd.g, MS.nc)
        # Connetto il - del sensore di tensione al - del diodo
        connect(oneport.n, MS.nv)
        oneport.n.i ~ ifelse(MS.v >= V_th,
                             MS.i,
                             0)
        oneport.n.v ~ ifelse(MS.v >= V_th,
                             V_th,
                             0)
    end
end

@mtkmodel System begin
    @components begin
        gen = Step(height = 1,
                   start_time = 1,
                   duration = 3,
                   smooth = true)
        source = Voltage()
        V = Voltage()
        D = Diode()
        R = Resistor(R = 100)
        Gnd = Ground()
    end
    @equations begin
        connect(gen.output, source.V)
        R.p.v ~ D.n.i * R.R
        connect(source.p, D.p)
        connect(D.n, R.p)
        connect(source.n, R.n, Gnd.g)
    end
end

@mtkbuild system = System()
prob = ODEProblem(system, Pair[], (0, 3));
sol = solve(prob, dtmax = 1.0e-3);
