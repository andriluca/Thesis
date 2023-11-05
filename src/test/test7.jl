using ModelingToolkit, Plots, DifferentialEquations
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant
using ModelingToolkitStandardLibrary.Blocks: Square

@parameters t
D = Differential(t)

# Prova 1 --- giusta
@mtkmodel VariableResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra, [description = "Resistance when air-filled"]
        Rl, [description = "Resistance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Il valore di default altro non è che il valore d'inizializzazione del sistema.
        R(t) = Rl, [description = "Variable resistance"]
    end
    @equations begin
        # Ho trasformato l'equazione integrale della resistenza in una
        # differenziale.
        D(R) ~ - ((Rl - Ra) / V_FRC) * i
        # Ra è il valore minimo che la resistenza variabile possa
        # assumere.  Rl è il valore massimo che la resistenza
        # variabile possa assumere.
        # Ra <= R <= Rl
        v ~ min(Rl, max(R, Ra)) * i
    end
end

# Prova 2
@mtkmodel VariableResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra, [description = "Resistance when air-filled"]
        Rl, [description = "Resistance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Il valore di default altro non è che il valore d'inizializzazione del sistema.
        R(t) = Rl, [description = "Variable resistance"]
    end
    @equations begin
        # Ho trasformato l'equazione integrale della resistenza in una
        # differenziale. In particolare ho considerato che i valori
        # estremi di resistenza siano Rl ed Ra, quindi ho limitato
        # l'incremento
        D(R) ~ ifelse(R > Ra,
                      - ((Rl - Ra) / V_FRC) * i,
                      0)
        v ~ R * i
    end
end

# Prova 3 --- da mostrare (approssimazione)
@mtkmodel VariableResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra, [description = "Resistance when air-filled"]
        Rl, [description = "Resistance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Il valore di default altro non è che il valore
        # d'inizializzazione del sistema.
        Rtemp(t) = Rl, [description = "Temporary resistance"]
        R(t) = Rl, [description = "Variable resistance"]
    end
    @equations begin
        # Ho trasformato l'equazione integrale della resistenza in una
        # differenziale.
        D(Rtemp) ~ - ((Rl - Ra) / V_FRC) * i
        # Ra è il valore minimo che la resistenza variabile possa
        # assumere.  Rl è il valore massimo che la resistenza
        # variabile possa assumere.
        # Ra <= R <= Rl
        R ~ min(Rl, max(Rtemp, Ra))
        v ~ R * i
    end
end

# Prova 4
@mtkmodel VariableResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra,    [description = "Resistance when air-filled"]
        Rl,    [description = "Resistance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Inizializzo il valore integrale del flusso a zero.
        ∫i(t) = 0, [description = "Current integral"]
        # Dichiaro come variabile d'interesse anche la resistenza.
        R(t) = Rl, [description = "Variable resistance"]
    end
    @equations begin
        # Ho trasformato l'equazione integrale della resistenza in una
        # differenziale.
        D(∫i) ~ i
        # Ra è il valore minimo che la resistenza variabile possa
        # assumere.  Rl è il valore massimo che la resistenza
        # variabile possa assumere.
        # TODO: Scrivere l'equazione della resistenza variabile
        # Ra <= R <= Rl
        # R ~ Ra + (Rl - Ra) * (1 - ∫i / V_FRC) # --> non funziona in questa forma
        R ~ min(Rl, max(Ra, (Ra + (Rl - Ra) * (1 - (∫i) / V_FRC))))
        v ~ R * i
    end
end

# Comportamento errato: la resistenza qui aumenta con l'integrale della corrente
# @mtkmodel VariableResistor begin
#     @extend v, i = oneport = OnePort()
#     @parameters begin
#         Ra, [description = "Resistance when air-filled"]
#         Rl, [description = "Resistance when liquid-filled"]
#         V_FRC, [description = "Airway Volume at FRC"]
#     end
#     @variables begin
#         R(t) = Ra, [description = "Variable resistance"]
#     end
#     @equations begin
#         D(R) ~ ((Rl - Ra) / V_FRC) * i
#         v ~ R * i
#     end
# end

@mtkmodel System begin
    @components begin
        vr = VariableResistor(Ra = 3.100029e+01, Rl = 3.100029e+01+1.514023e+03, V_FRC = 1.744963e-06)
        # constant = Constant(k = 1.0)
        constant = Square(frequency = 0.5, amplitude = 2.0e-3, smooth = true)
        source = Voltage()
        ground = Ground()
    end
    @equations begin
        connect(constant.output, source.V)
        connect(source.p, vr.p)
        connect(vr.n, source.n, ground.g)
    end
end

@mtkbuild system = System()
prob = ODEProblem(system, [], (0, 10.0))
sol = solve(prob, reltol = 1e-10, abstol = 1e-8)
plot(sol, idxs = [system.vr.i])
