using DomainSets, ModelingToolkit, Plots, DifferentialEquations
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant
using ModelingToolkitStandardLibrary.Blocks: Square

Ii = Integral(t in DomainSets.ClosedInterval(0, t))

@mtkmodel VariableResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra, [description = "Resistance when air-filled"]
        Rl, [description = "Resistance when liquid-filled"]
        V_FRC, [description = "Volume at FRC"]
    end
    
    @equations begin
        v ~ i * (Ra + (Rl - Ra) * (1.0 - Ii(i)) / V_FRC)
    end
end

@mtkmodel System begin
    @components begin
        vr = VariableResistor(Ra = 0.5, Rl = 1.0, V_FRC = 1.0)
        c = Capacitor(C=1.0)
        constant = Square(frequency = 1.0, amplitude = 1.0, smooth = true)
        source = Voltage()
        ground = Ground()
    end
    @equations begin
        connect(constant.output, source.V)
        connect(source.p, vr.p)
        connect(vr.n, c.p)
        connect(c.n, source.n, ground.g)
    end
end

@mtkbuild system = System()

@mtkmodel Resistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        R, [description = "Resistance"]
    end
    @equations begin
        v ~ i * R
    end
end
