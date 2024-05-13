#===============================================================
 MODELLI INFERIORI (alias a basso livello)
 ===============================================================#
# TODO: Modificare il diodo

# Componenti variabili
@mtkmodel CIDInductor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        La, [description = "Inductance when air-filled"]
        Lb, [description = "Inductance delta (liquid - air)"]
    end
    @variables begin
        # Il valore di default altro non è che il valore
        # d'inizializzazione del sistema
        n∫i(t) = 0, [description = "Current integral"]
        L(t)  = La + Lb, [description = "Variable inductance"]
    end
    @equations begin
        L ~ La + Lb * (1 - n∫i)
        D(i) ~ (1 / L) * v
    end
end

@mtkmodel CIDResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra, [description = "Resistance when air-filled"]
        Rb, [description = "Resistance delta (liquid - air)"]
    end
    @variables begin
        n∫i(t) = 0, [description = "Current integral"]
        # Dichiaro come variabile d'interesse anche la resistenza
        R(t) = Ra + Rb, [description = "Variable resistance"]
    end
    @equations begin
        R ~ Ra + Rb * (1 - n∫i)
        v ~ R * i
    end
end

exlin(x, max_x) = ifelse(x > max_x, exp(max_x)*(1 + x - max_x), exp(x))

@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ids     = 1e-6, [description = "Reverse-bias current"]
        max_exp = 15, [description = "Value after which linearization is applied"]
        R       = 1e8, [description = "Diode Resistance"]
        Vth     = 1e-3, [description = "Threshold voltage"]
        k       = 1e3, [description = "Speed of exponential"]
    end
    @equations begin
        i ~ Ids * (exlin(k * (v - Vth) / (Vth), max_exp) - 1) + (v / R)
    end
end

@mtkmodel Integrator begin
    @components begin
        integ = SISO(y_start = 0)
        trigger = SISO(y_start = false)
    end
    @variables begin
        ∫i(t) = 0.0, [description = "State of Integrator."]
    end
    @parameters begin
        V_FRC = 1, [description = "Volume at FRC."]
    end
    @equations begin
        # u[1]     -> corrente.
        # u[2]     -> trigger_in.
        # y[1], ∫i -> integrale della corrente.
        # y[2]     -> trigger_out.

        # Quando l'integrale 1) sta per essere negativo, 2) sta per
        # superare V_FRC 3) trigger_in è false, l'integrazione non
        # viene effettuata.

        # Quando la corrente è negativa e l'integrale è negativo non devo integrare.
        # Quando l'integrale supera la threshold devo smettere di integrare.
        # Quando l'integrale è positivo o nullo posso integrare.
        # (Quando la corrente è positiva integro a prescindere.)

        D(∫i) ~ ifelse((((∫i < 0) & (integ.u < 0)) | (∫i >= V_FRC) | (trigger.u == false)),
                       0,
                       integ.u)

        # Normalizzo l'integrale per V_FRC.
        integ.y ~ ∫i / V_FRC
        D(trigger.y) ~ 0
    end
    
    @continuous_events begin
        [∫i ~ V_FRC] => [trigger.y ~ true]
    end
end

@mtkmodel Switch begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Rclosed = 1e-12, [description = "Switch Resistance when Closed"]
        Ropen = 1e12, [description = "Switch Resistance when Open"]
    end
    @variables begin
        R(t) = Rclosed, [description = "Switch Resistance"]
        trigger_in(t) = false, [description = "Flag: 1 when air fills previous airway completely, 0 otherwise"]
        trigger_out(t) = false, [description = "Flag: 1 when air fills current airway completely, 0 otherwise"]
    end
    @equations begin
        # Bassa all'inizio, alta quando gli arriva il segnale dalla cella precedente, bassa poi quando diventa 1
        # Trasformare in tan(x)
        # Never used
        # R ~ Rclosed + (Ropen - Rclosed) * (1 / 2) * (tanh(k * (1 + (∫i / V_FRC)) + 1))
        # Equazione di Chiara
        # R ~ Rclosed + trigger_in * Ropen * tanh(k*t - 3) - trigger_out * Ropen * tanh(-k*t + 3)
        R ~ Rclosed + (trigger_in - trigger_out) * (Ropen - Rclosed)
        v ~ R * i
    end
end
