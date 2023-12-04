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

@mtkmodel Switch begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        V_FRC, [description = "Airway Volume at FRC"]
        Rclosed = 1e-12, [description = "Switch Resistance when Closed"]
        Ropen = 2.5e5, [description = "Switch Resistance when Open"]
        k = 1e3
    end
    @variables begin
        ∫i(t) = 0, [description = "Current integral"]
        R(t) = 0,  [description = "Switch Resistance"]
    end
    @equations begin
        R ~ Rclosed + (Ropen - Rclosed) * (1 / 2) * (tanh(k * (∫i / V_FRC) * (1 - (∫i / V_FRC))))
        v ~ R * i
    end
end

@mtkmodel System begin
    @components begin
        V = Voltage()
        D = Diode(Vth = 8)
        SW = Switch(V_FRC = 10)
        R1 = Resistor(R = 100)
        Gnd = Ground()
    end
    @equations begin
        V.V.u ~ (10) * sin(2*π*50*t)
        connect(V.p, D.p, SW.p)
        connect(D.n, R1.p, SW.n)
        connect(V.n, R1.n, Gnd.g)
        SW.∫i ~ 3 + 100*t
    end
end

@mtkbuild system = System()
prob = ODEProblem(system, Pair[], (0/50, 2/50), saveat=1/50e2);
sol = solve(prob, Rodas4(), dtmax = 1.0e-5);
plot(sol, idxs = [system.R1.v])
