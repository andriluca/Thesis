using ModelingToolkit, DifferentialEquations, Plots  #=OrdinaryDiffEq=#
using ModelingToolkitStandardLibrary.Electrical
# using ModelingToolkitStandardLibrary.Blocks: Constant
using ModelingToolkitStandardLibrary.Blocks: Square

R1 = 1.0
R2 = 1.0
C1 = 1.0
C2 = 1.0
# V = 1.0

@variables t
@named r1 = Resistor(R = R1)
@named r2 = Resistor(R = R2)
@named c1 = Capacitor(C = C1, v = 0.0)
@named c2 = Capacitor(C = C2, v = 0.0)
@named source = Voltage()
# @named constant = Constant(k = V)

@named sq = Square(frequency = 1.0, amplitude = 2.0, smooth = true)
@named ground = Ground()

rc_eqs = [connect(sq.output, source.V)
          connect(source.p, r1.p)
          connect(r1.n, c1.p, r2.p)
          connect(r2.n, c2.p)
          connect(c1.n, c2.n, source.n, ground.g)]

@named rc_model = ODESystem(rc_eqs,
                            t,
                            systems = [r1,
                                       r2,
                                       c1,
                                       c2,
                                       sq,
                                       source, 
                                       ground]
                            )

sys = structural_simplify(rc_model)
prob = ODAEProblem(sys, Pair[], (0, 5.0))
sol = solve(prob, Tsit5())
plot(sol, idxs = [c2.v, r2.i, c1.v, r1.i],
    title = "RC Circuit Demonstration",
    labels = ["Capacitor2 Voltage" "Resistor2 Current" "Capacitor1 Voltage" "Resistor1 Current"])
# savefig("plot.png");
