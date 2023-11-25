using ModelingToolkit
using ModelingToolkitStandardLibrary.Blocks
using ModelingToolkitStandardLibrary.Electrical
using OrdinaryDiffEq, DifferentialEquations
using DiffEqCallbacks
using Plots

@parameters t

# function smooth_step(x, δ, height, offset, start_time)
#     offset + height * (atan((x - start_time) / δ) / π + 0.5)
# end

# @mtkmodel Diode begin
#     @parameters begin
#         VFwdDrop = 1.5
#         Rc       = 0.01
#         Rn       = 1e6
#     end
#     @extend v, i = oneport = OnePort()
#     @equations begin
#         i ~ ifelse(v >= VFwdDrop,
#                    smooth_step(t, 1e-5, v / Rc, 0, 0),  # on
#                    smooth_step(t, 1e-5, v / Rn, 0, 0))
#     end
# end

function Diode(; name)
    @named op = OnePort()
    eqs = [
        0 ~ ifelse(op.v < 0, op.i, op.v)
    ]
    ODESystem(eqs, t, [op.v, op.i], [], systems=[op], continuous_event = [op.v ~ 0] => nothing)
end

@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @equations begin
	0 ~ ifelse(v < 0, i, v)
    end
end

function condition(u, t, integrator) # Event @ v = 0
    u.D.v ~ 0
end

function affect!(integrator)
    nothing
end

cb = ContinuousCallback(condition, affect!)

# @mtkmodel Diode begin
#     @components begin
#         p = Pin()
#         n = Pin()
#     end
#     @variables begin
#         v(t)
#         i(t)
#     end
#     @equations begin
#         v ~ p.v - n.v #Convenience
#         0 ~ p.i + n.i #in = -out
#         i ~ p.i #Positive current flows *into* p terminal
#         0 ~ IfElse.ifelse(v < 0, i, v)
#     end
# end

@mtkmodel System begin
    @components begin
        gen = Sine(amplitude = 2,
                   frequency = 1)
        # gen = Step(height = 2,
        #            start_time = 1)
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

prob = ODEProblem(system, [], (0, 2))
sol = solve(prob, callback = cb)
