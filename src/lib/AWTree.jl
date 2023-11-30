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
using ModelingToolkit, ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant, Square
using DifferentialEquations

#===============================================================
 DEFINIZIONE COMPONENTI E MODELLI
 ===============================================================#

# Simboli per variabile temporale e differenziale (dt).
@parameters t
D = Differential(t)

#===============================================================
 COMPONENTI INFERIORI (alias a basso livello)
 ===============================================================#

# Componenti variabili
@mtkmodel CIDResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra,    [description = "Resistance when air-filled"]
        Rb,    [description = "Resistance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Dopo l'uguale ho i valori di inizializzazione delle
        # variabili
        ∫i(t) = 0,      [description = "Current integral"]
        # Dichiaro come variabile d'interesse anche la resistenza
        R(t) = Ra + Rb, [description = "Variable resistance"]
    end
    @equations begin
        # Ra <= R <= Rl: suppongo che i valori Ra ed Rl siano estremi da non superare
        R ~ min((Ra + Rb), max(Ra, (Ra + Rb * (1 - ∫i / V_FRC))))
        v ~ R * i
    end
end

@mtkmodel CIDInductor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        La,    [description = "Inductance when air-filled"]
        Lb,    [description = "Inductance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Il valore di default altro non è che il valore
        # d'inizializzazione del sistema
        ∫i(t) = 0,       [description = "Current integral"]
        L(t)  = La + Lb, [description = "Variable inductance"]
    end
    @equations begin
        # La <= L <= Ll
        L    ~ min((La + Lb), max(La, (La + Lb * (1 - ∫i / V_FRC))))
        # d/dt (i(t)) = 1 / L * v(t), equazione dell'induttore
        D(i) ~ (1 / L) * v
    end
end

# Modelli di Via Respiratoria e di Alveolo
@mtkmodel Airway begin
    @parameters begin
        # Resistori
        Ra,    [description = "Resistance when air-filled"]
        Rb,    [description = "Resistance when liquid-filled"]
        R_sw,  [description = "Resistance ..."]
        # Condensatori
        C_g,   [description = "Capacitance ..."]
        C_sw,  [description = "Capacitance ..."]
        # Induttori
        I_sw,  [description = "Inductance ..."]
        La,    [description = "Inductance when air-filled"]
        Lb,    [description = "Inductance when liquid-filled"]
        # Volume a FRC
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @components begin
        # Pin
        in       = Pin()
        out      = Pin()
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
        ground   = Ground()
    end
    @equations begin
        # Connessioni
        connect(in, r_tube.p)
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
    end
end

@mtkmodel Alveolus begin
    @parameters begin
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
        # Riferimenti
        ground = Ground()
    end
    @equations begin
        # Connessioni
        connect(in, r_tube.p)
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
    end
end
