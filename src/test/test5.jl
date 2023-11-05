using ModelingToolkit, Plots, DifferentialEquations
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant
using ModelingToolkitStandardLibrary.Blocks: Square

@mtkmodel Block begin
    @components begin
        in = Pin()
        out = Pin()
        resistor = Resistor(R = 1.0)
        capacitor = Capacitor(C = 1.0)
        ground = Ground()
    end
    @equations begin
        connect(in, resistor.p)
        connect(resistor.n, capacitor.p)
        connect(out, capacitor.p)
        connect(capacitor.n, ground.g)
    end
end

@mtkmodel Airway begin
    @components begin
        in       = Pin()
        out      = Pin()
        r_tube   = Resistor(R = 1.0)
        i_tube   = Inductor(L = 1.0)
        c_g      = Capacitor(C = 1.0)
        r_sw     = Resistor(R = 1.0)
        i_sw     = Inductor(L = 1.0)
        c_sw     = Capacitor(C = 1.0)
        r_tube_1 = Resistor(R = 1.0)
        i_tube_1 = Inductor(L = 1.0)
        ground   = Ground()
    end
    @equations begin
        connect(in, r_tube.p)
        connect(r_tube.n, i_tube.p)
        connect(i_tube.n, c_g.p, i_sw.p, r_tube_1.p)
        connect(i_sw.n, r_sw.p)
        connect(r_sw.n, c_sw.p)
        connect(r_tube_1.n, i_tube_1.p)
        connect(out, i_tube_1.n)
        connect(c_g.n, c_sw.n, ground.g)
    end
end

@mtkmodel Alveolo begin
    @components begin
        in     = Pin()
        out    = Pin()
        r_tube = Resistor(R = 1.0)
        i_tube = Inductor(L = 1.0)
        c_ga   = Capacitor(C = 1.0)
        i_t    = Inductor(L = 1.0)
        r_t    = Resistor(R = 1.0)
        c_t    = Capacitor(C = 1.0)
        r_s    = Resistor(R = 1.0)
        c_s    = Resistor(R = 1.0)
        ground   = Ground()
    end
    @equations begin
        connect(in, r_tube.p)
        connect(r_tube.n, i_tube.p)
        connect(i_tube.n, c_ga.p, i_t.p, out)
        connect(i_t.n, r_t.p)
        connect(r_t.n, c_t.p)
        connect(c_t.n, c_s.p, r_s.p)
        connect(c_ga.n, c_s.n, r_s.n, ground.g)
    end
end

@mtkmodel System1 begin
    @components begin
        block1 = Alveolo()
        constant = Square(frequency = 1.0, amplitude = 1.0, smooth = true)
        source = Voltage()
        ground = Ground()
    end
    @equations begin
        connect(constant.output, source.V)
        connect(source.p, block1.in)
        connect(source.n, ground.g)
    end
end

@mtkmodel System begin
    @components begin
        block1 = Block(resistor.R = 2.0)
        block2 = Block(resistor.R = 2.0)
        block3 = Block(resistor.R = 2.0)
        block4 = Block(resistor.R = 2.0)
        block5 = Block(resistor.R = 2.0)
        block6 = Block(resistor.R = 2.0)
        block7 = Block(resistor.R = 2.0)
        constant = Square(frequency = 1.0, amplitude = 1.0, smooth = true)
        source = Voltage()
        ground = Ground()
    end
    @equations begin
        connect(constant.output, source.V)
        connect(source.p, block1.in)
        connect(block1.out, block2.in, block5.in)
        connect(block2.out, block3.in, block4.in)
        connect(block5.out, block6.in, block7.in)
        connect(source.n, ground.g)
    end
end

@mtkbuild system = System()
@mtkbuild system = System1()

u0 = [
    system.block1.capacitor.v => 0.0
    system.block2.capacitor.v => 0.0
    system.block3.capacitor.v => 0.0
    system.block4.capacitor.v => 0.0
    system.block5.capacitor.v => 0.0
    system.block6.capacitor.v => 0.0
    system.block7.capacitor.v => 0.0
]

prob = ODEProblem(system, u0, (0, 10.0))
sol = solve(prob)
plot(sol, idxs = [system.block6.capacitor.v])
