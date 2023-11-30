using DifferentialEquations
using DifferentialEquations: callbacks_exists
using ModelingToolkit
using ModelingToolkit: continuous_events, default_toterm
using ModelingToolkitStandardLibrary.Blocks
using ModelingToolkitStandardLibrary.Electrical
using Plots

# Definisco Diodo
@parameters t

function condition(u,t,integrator) # Event @ v = 0
    u.D.v ~ 0
end

function affect!(integrator)
    nothing
end

cb = ContinuousCallback(condition, affect!)

@component function Diode(; name)
    @named p = Pin()
    @named n = Pin()
    @variables begin
        v(t) = 0
        i(t) = 0
    end
    eqs = [
        v ~ p.v - n.v #Convenience
        0 ~ p.i + n.i #in = -out
        i ~ p.i #Positive current flows *into* p terminal
        0 ~ ifelse(v < 0, i, v)
    ]
    return ODESystem(eqs,
                     t,
                     [v, i],
                     [],
                     defaults = Dict();
                     name=name,
                     systems=[p, n],
                     continuous_events = [v ~ 0])
end

# Definisco il sistema
@mtkmodel System begin
    @components begin
        gen = Sine(amplitude = 2,
                   frequency = 1)
        # gen = Step(height = 2,
        #            start_time = 1)
        source = Voltage()
        R = Resistor(R=100)
        D = Diode()
        Gnd = Ground()
    end
    @equations begin
        connect(gen.output, source.V)
        connect(source.p, D.p)
        connect(D.n, R.p)
        connect(source.n, R.n, Gnd.g)
    end
end

# Istanzio il modello e simulo
@mtkbuild system = System()

prob = ODEProblem(system, [], (0, 2))
sol = solve(prob)

# Mostro il grafico delle grandezze di interesse
gr()
plot(sol, idxs = [system.D.i])
