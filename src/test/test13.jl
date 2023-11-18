using ModelingToolkit
using ModelingToolkitStandardLibrary.Blocks
using ModelingToolkitStandardLibrary.Electrical
using OrdinaryDiffEq
using Plots

@parameters t

@mtkmodel Diode begin
    @parameters begin
        Vin_th = 0.7, [description = "Diode threshold"]
    end
    @components begin
        Gnd = Ground()
    end
    @extend v, i = oneport = OnePort()
    @equations begin
        0 ~ ifelse(oneport.p.v >= Vin_th, v - Vin_th, oneport.p.i)
        0 ~ ifelse(oneport.p.v >= Vin_th, v - Vin_th, oneport.n.i)
        0 ~ ifelse(oneport.p.v >= Vin_th, oneport.p.i - oneport.n.i, v)
    end
end

@mtkmodel System begin
    @components begin
        V = Voltage()
        D = Diode()
        R = Resistor(R = 100)
        Gnd = Ground()
    end
    @equations begin
        V.V.u ~ 15 * sin(2*π*50*t)
        connect(V.p, D.p)
        connect(D.n, R.p)
        connect(V.n, R.n, Gnd.g)
    end
end

@mtkbuild system = System()
prob = ODEProblem(system, Pair[], (0/50, 1/50), saveat=1/50e2);
sol = solve(prob, Rodas4(), dtmax = 1.0e-3);
