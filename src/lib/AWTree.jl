#     ___        _______                 _ _
#    / \ \      / /_   _| __ ___  ___   (_) |
#   / _ \ \ /\ / /  | || '__/ _ \/ _ \  | | |
#  / ___ \ V  V /   | || | |  __/  __/_ | | |
# /_/   \_\_/\_/    |_||_|  \___|\___(_)/ |_|
#                                     |__/   

#===============================================================
 DIPENDENZE
 ===============================================================#

# Modello
using DifferentialEquations, OrdinaryDiffEq
using ModelingToolkit
using ModelingToolkitStandardLibrary.Blocks: Constant, Square, Step, Sine
using ModelingToolkitStandardLibrary.Electrical

#===============================================================
 DEFINIZIONE COMPONENTI E MODELLI
 ===============================================================#

# Simboli per variabile temporale e differenziale (dt).
@parameters t
D = Differential(t)

#===============================================================
 MODELLI INFERIORI (alias a basso livello)
 ===============================================================#

# Componenti variabili
@mtkmodel CIDResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra,    [description = "Resistance when air-filled"]
        Rb,    [description = "Resistance delta (liquid - air)"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        ∫i(t) = 0,      [description = "Current integral"]
        # Dichiaro come variabile d'interesse anche la resistenza
        R(t) = Ra + Rb, [description = "Variable resistance"]
    end
    @equations begin
        # R_air <= R <= R_liquid: suppongo che i valori R_air ed
        # R_liquid siano estremi da non superare.
        # R_liquid = Ra + Rb
        # R_air    = Ra
        # R ~ min((Ra + Rb), max(Ra, (Ra + Rb * (1 - ∫i / V_FRC))))
        R ~ Ra + Rb * (1 - ∫i / V_FRC)
        v ~ R * i
    end
end

@mtkmodel CIDInductor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        La,    [description = "Inductance when air-filled"]
        Lb,    [description = "Inductance delta (liquid - air)"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Il valore di default altro non è che il valore
        # d'inizializzazione del sistema
        ∫i(t) = 0,       [description = "Current integral"]
        L(t)  = La + Lb, [description = "Variable inductance"]
    end
    @equations begin
        # L_air <= L <= L_liquid
        # L_liquid = La + Lb
        # L_air    = La
        # L    ~ min((La + Lb), max(La, (La + Lb * (1 - ∫i / V_FRC))))
        L ~ La + Lb * (1 - ∫i / V_FRC)
        # d/dt (i(t)) = 1 / L * v(t), equazione dell'induttore
        D(i) ~ (1 / L) * v
    end
end

exlin(x, max_x) = ifelse(x > max_x, exp(max_x)*(1 + x - max_x), exp(x))

@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ids     = 1e-6, [description = "Reverse-bias current"]
        max_exp = 15,   [description = "Value after which linearization is applied"]
        R       = 1e8,  [description = "Diode Resistance"]
        Vth     = 1e-3, [description = "Threshold voltage"]
        k       = 1e3,  [description = "Speed of exponential"]
    end
    @equations begin
        i ~ Ids * (exlin(k * (v - Vth) / (Vth), max_exp) - 1) + (v / R)
    end
end

@mtkmodel Switch begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        V_FRC, [description = "Airway Volume at FRC"]
        Rclosed = 1e-6, [description = "Switch Resistance when Closed"]
        Ropen = 2.5e5, [description = "Switch Resistance when Open"]
        # Old value
        # k = 1e3
        k = 20e3
        # TODO: implementare trigger_in
        # TODO: implementare trigger_out
    end
    @variables begin
        ∫i(t) = 0, [description = "Current integral"]
        R(t) = 0,  [description = "Switch Resistance"]
    end
    @equations begin
        # Bassa all'inizio, alta quando gli arriva il segnale dalla cella precedente, bassa poi quando diventa 1
        # Trasformare in tan(x)
        # Never used
        # R ~ Rclosed + (Ropen - Rclosed) * (1 / 2) * (tanh(k * (1 + (∫i / V_FRC)) + 1))
        # Equazione di Chiara
        R ~ Rclosed + trigger_in * Ropen * tanh(k*t - 3) - trigger_out * Ropen * tanh(-k*t + 3)
        v ~ R * i
    end
end

#===============================================================
 MODELLI SUPERIORI (alias ad alto livello)
 ===============================================================#

@mtkmodel Airway begin
    @parameters begin
        # Diodo (sviluppo futuro)
        # Vin_th, [description = "Diode's Threshold"]
        # Resistori
        Ra,    [description = "Resistance when air-filled"]
        Rb,    [description = "Resistance when liquid-filled"]
        R_sw,  [description = "Resistance of the soft tissues"]
        # Condensatori
        C_g,   [description = "Shunt airway compliance due to gas"]
        C_sw,  [description = "Compliance of the soft tissues"]
        # Induttori
        I_sw,  [description = "Inertance of the soft tissues"]
        La,    [description = "Inertance when air-filled"]
        Lb,    [description = "Inertance when liquid-filled"]
        # Volume a FRC
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        ∫i(t)          = 0, [description = "Current integral"]
        trigger_in(t)  = 0, [description = "Flag: 1 when air fills previous airway completely, 0 otherwise"]
        trigger_out(t) = 0, [description = "Flag: 1 when air fills current airway completely, 0 otherwise"]
    end
    @components begin
        # Pin
        in       = Pin()
        out      = Pin()
        # Diodi (sviluppo futuro)
        # D1       = Diode(Vth         = Vin_th)
        # Resistori
        r_sw     = Resistor(R        = R_sw)
        r_tube   = CIDResistor(Ra    = 0.5 * Ra,
                               Rb    = 0.5 * Rb,
                               V_FRC = ParentScope(V_FRC))
        r_tube_1 = CIDResistor(Ra    = 0.5 * Ra,
                               Rb    = 0.5 * Rb,
                               V_FRC = ParentScope(V_FRC))
        # Condensatori
        c_g      = Capacitor(C       = C_g)
        c_sw     = Capacitor(C       = C_sw)
        # Induttori
        i_sw     = Inductor(L        = I_sw)
        i_tube   = CIDInductor(La    = 0.5 * La,
                               Lb    = 0.5 * Lb,
                               V_FRC = ParentScope(V_FRC))
        i_tube_1 = CIDInductor(La    = 0.5 * La,
                               Lb    = 0.5 * Lb,
                               V_FRC = ParentScope(V_FRC))
        # Switch (sviluppo futuro)
        # Sw       = Switch(V_FRC      = ParentScope(V_FRC))
        # Riferimenti
        ground   = Ground()
    end
    @equations begin
        # Connessioni
        connect(in, r_tube.p)
        # connect(in, D1.p, Sw.p)
        # connect(D1.n, Sw.n, r_tube.p)
        connect(r_tube.n, i_tube.p)
        connect(i_tube.n, c_g.p, i_sw.p, r_tube_1.p)
        connect(i_sw.n, r_sw.p)
        connect(r_sw.n, c_sw.p)
        connect(r_tube_1.n, i_tube_1.p)
        connect(out, i_tube_1.n)
        connect(c_g.n, c_sw.n, ground.g)
        # Equazioni
        D(∫i)       ~ trigger_in * (1.0 - trigger_out) * in.i
        trigger_out ~ ifelse(∫i / V_FRC >= 0.9,
                             1.0,
                             0.0)
        r_tube.∫i      ~ ∫i
        r_tube_1.∫i    ~ ∫i
        i_tube.∫i      ~ ∫i
        i_tube_1.∫i    ~ ∫i
        # Sw.∫i          ~ ∫i
    end
end

@mtkmodel Alveolus begin
    @parameters begin
        # Diodo (sviluppo futuro)
        # Vin_th, [description = "Diode's Threshold"]
        # Resistori
        Ra,    [description = "Resistance when air-filled"]
        Rb,    [description = "Resistance when liquid-filled"]
        R_t,   [description = "Tissue resistance"]
        R_s,   [description = "Tissue resistance related to stress relaxation"]
        # Condensatori
        C_g,   [description = "Shunt terminal unit compliance due to gas"]
        C_s,   [description = "Tissue compliance related to stress relaxation"]
        C_t,   [description = "Tissue compliance"]
        # Induttori
        I_t,   [description = "Tissue inertance"]
        La,    [description = "Inertance when air-filled"]
        Lb,    [description = "Inertance when liquid-filled"]
        # Volume a FRC
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        ∫i(t)          = 0, [description = "Current integral"]
        trigger_in(t)  = 0, [description = "Flag: 1 when air fills previous airway completely, 0 otherwise"]
        trigger_out(t) = 0, [description = "Flag: 1 when air fills current airway completely, 0 otherwise"]
    end
    @components begin
        # Pin
        in     = Pin()
        out    = Pin()
        # Diodi (Sviluppo futuro)
        # D1     = Diode(Vth         = Vin_th)
        # Resistori
        r_tube = CIDResistor(Ra    = ParentScope(Ra),
                             Rb    = ParentScope(Rb),
                             V_FRC = ParentScope(V_FRC))
        r_t    = Resistor(R        = R_t)
        r_s    = Resistor(R        = R_s)
        # Condensatori
        c_ga   = Capacitor(C       = C_g)
        c_s    = Capacitor(C       = C_s)
        c_t    = Capacitor(C       = C_t)
        # Induttori
        i_tube = CIDInductor(La    = ParentScope(La),
                             Lb    = ParentScope(Lb),
                             V_FRC = ParentScope(V_FRC))
        i_t    = Inductor(L        = I_t)
        # Switch
        # Sw     = Switch(V_FRC      = ParentScope(V_FRC))
        # Riferimenti
        ground = Ground()
    end
    @equations begin
        # Connessioni
        connect(in, r_tube.p)
        # connect(in, D1.p, Sw.p)
        # connect(D1.n, Sw.n, r_tube.p)
        connect(r_tube.n, i_tube.p)
        connect(i_tube.n, c_ga.p, i_t.p, out)
        connect(i_t.n, r_t.p)
        connect(r_t.n, c_t.p)
        connect(c_t.n, c_s.p, r_s.p)
        connect(c_ga.n, c_s.n, r_s.n, ground.g)
        # Equazioni
        D(∫i)       ~ trigger_in * (1.0 - trigger_out) * in.i
        trigger_out ~ ifelse(∫i / V_FRC >= 0.9,
                             1.0,
                             0.0)
        r_tube.∫i      ~ ∫i
        i_tube.∫i      ~ ∫i
        # Sw.∫i          ~ ∫i
    end
end
