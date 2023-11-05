using ModelingToolkit, Plots, DifferentialEquations
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant
using ModelingToolkitStandardLibrary.Blocks: Square

# Definisco i simboli per tempo e differenziale (dt).
@parameters t
D = Differential(t)

# CID: Current Integral-Dependent
# Questo è il modello della soluzione senza variabile d'appoggio
@mtkmodel CIDResistor_not_app begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        # Parametri che costituiscono il componente
        Ra,    [description = "Resistance when air-filled"]
        Rl,    [description = "Resistance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Inizializzo il valore integrale della corrente a zero.
        # ∫i è la variabile che contiene l'integrale della corrente.
        ∫i(t) = 0, [description = "Current integral"]
        # Dichiaro come variabile d'interesse anche la resistenza.
        R(t),      [description = "Variable resistance"]
    end
    @equations begin
        # Ho trasformato l'equazione integrale della resistenza in una
        # differenziale.  Qui considero la derivata dell'integrale
        # uguale alla corrente.  NB: il simbolo `∫i` indica il nome di
        # una variabile e non un'operazione matematica.
        D(∫i) ~ i
        # Ra <= R <= Rl
        # R ~ Ra + (Rl - Ra) * (1 - ∫i / V_FRC) # --> non funziona in questa forma
        R ~ min(Rl, max(Ra, (Ra + (Rl - Ra) * (1 - ∫i / V_FRC))))
        v ~ R * i
    end
end

# Questo è il modello della soluzione con variabile d'appoggio.
@mtkmodel CIDResistor_app begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        # Parametri che costituiscono il componente.
        Ra, [description = "Resistance when air-filled"]
        Rl, [description = "Resistance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # A destra dell'uguale inserisco le inizializzazioni (in t = 0)
        # delle variabili.
        Rtemp(t) = Rl, [description = "Temporary resistance"]
        R(t)     = Rl, [description = "Variable resistance"]
    end
    @equations begin
        # Ho trasformato l'equazione integrale della resistenza in una
        # differenziale.  Derivo a destra e a sinistra dell'uguale e
        # ottengo l'equazione qui sotto:
        # d/dt (Rtemp(t)) = -(((Rl - Ra) / V_FRC) * i(t))
        D(Rtemp) ~ - ((Rl - Ra) / V_FRC) * i
        # Ra <= R <= Rl: Limito il range di valori che la resistenza
        # può assumere, facendola rimanere confinata tra questi due
        # estremi.
        R ~ min(Rl, max(Rtemp, Ra))
        v ~ R * i
    end
end

# Dichiaro la struttura circuitale (i.e. serie tra il generatore e la resistenza variabile).
@mtkmodel System begin
    @components begin
        # Dichiarazione dei componenti richiesti.
        # Ho utilizzato i valori di IAD come riferimento.
        vr = CIDResistor_not_app(Ra = 3.100029e+01,
                             Rl = 3.100029e+01 + 1.514023e+03,
                             V_FRC = 1.744963e-06)
        # Posso testare il circuito con una tensione costante.
        # gen = Constant(k = 1.0)
        # Posso testare il circuito con un'onda quadra.
        gen = Square(frequency = 0.5, amplitude = 1.0e-3, smooth = true)
        source = Voltage()
        ground = Ground()
    end
    @equations begin
        # Dichiarazione delle connessioni
        connect(gen.output, source.V)
        connect(source.p, vr.p)
        connect(vr.n, source.n, ground.g)
    end
end

# Eseguo la simulazione
@mtkbuild system = System()
## genero un problema da risolvere nell'intervallo 0-10s
prob = ODEProblem(system, [], (0, 10.0))
## modifico le tolleranze
sol = solve(prob, reltol = 1e-8, abstol = 1e-8)
## mostro il grafico
plot(sol, idxs = [system.vr.i])
