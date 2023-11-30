using ModelingToolkit
using ModelingToolkitStandardLibrary.Blocks
using ModelingToolkitStandardLibrary.Electrical
using OrdinaryDiffEq
using Plots

@parameters t

exlin(x, max_x) = ifelse(x > max_x,
                         exp(max_x)*(1 + x - max_x),
                         exp(x))
@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ids     = 1e-6,
        [description = "Reverse-bias current"]
        max_exp = 15,
        [description = "Value after which linearization is applied"]
        R       = 1e8,
        [description = "Diode Resistance"]
        Vth     = 1e-3,
        [description = "Threshold voltage"]
        k = 1e3,
        [description = "Speed of exponential"]
    end
    @equations begin
        i ~ Ids * (exlin(k * (v - Vth) / Vth, max_exp) - 1) + (v / R)
    end
end

@mtkmodel System begin
    @components begin
        V = Voltage()
        D = Diode(Vth = 80)
        R = Resistor(R = 100)
        Gnd = Ground()
    end
    @equations begin
        V.V.u ~ (100) * sin(2*π*50*t)
        connect(V.p, D.p)
        connect(D.n, R.p)
        connect(V.n, R.n, Gnd.g)
    end
end

@mtkbuild system = System()
prob = ODEProblem(system, Pair[], (0/50, 2/50), saveat=1/50e2);
sol = solve(prob, Rodas4(), dtmax = 1.0e-4);
plot(sol, idxs = [system.D.v])
