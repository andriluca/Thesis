## NON FUNZIONA IL DIODO

# Modello
using ModelingToolkit, ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant, Sine
using DifferentialEquations

# Grafici
using Plots, PlotThemes, Plots.PlotMeasures

exlin(x, max_x) = ifelse(x > max_x, exp(max_x)*(1 + x - max_x), exp(x))

@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        # Parametri che costituiscono il componente.
        Ids = 1e-6, [description = "Current flowing in the component"]
        Vt = 0.04, [description = "Threshold"]
        max_exp = 15
        R = 1e8
    end
    @equations begin
        i ~ Ids * (exlin(v / Vt, max_exp) - 1) + (v / R)
    end
end

@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        # Parametri che costituiscono il componente.
        V_th, [description = "Resistance when liquid-filled"]
    end
    @equations begin
       0 ~ ifelse(v < V_th, i, v)
    end
end

@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        # Parametri che costituiscono il componente.
        V_th, [description = "Resistance when liquid-filled"]
    end
    @equations begin
        0 ~ ifelse(v < V_th, i, v - V_th)
    end
end

@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        # Parametri che costituiscono il componente.
        V_th, [description = "Resistance when liquid-filled"]
        Rs = 1e8
    end
    @equations begin
        i ~ ifelse(v < V_th, 0, (v - V_th) / Rs)
    end
end

@mtkmodel System begin
    @components begin
        # Sorgenti del segnale e ground.
        gen    = Sine(frequency = .5)
        source = Voltage()
        ground = Ground()
        # Componenti
        R = Resistor(R = 1)
        D = Diode(V_th = 0.5)
    end
    @equations begin
        connect(gen.output, source.V)
        connect(source.p, D.p)
        connect(D.n, R.p)
        connect(R.n, source.n, ground.g)
    end
end

# Istanzio il modello (parametri esclusi).
@mtkbuild system = System()
## genero un problema da risolvere nell'intervallo 0-10s.
prob = ODEProblem(system, [], (0, 10.0))
## modifico le tolleranze della soluzione.
sol = solve(prob, reltol = 1e-10, abstol = 1e-8)

plot(sol, idxs = [system.D.i])
