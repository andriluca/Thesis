#= _     ____      __  __           _       _
  | |   |___ \ _  |  \/  | ___   __| |_   _| | ___  ___
  | |     __) (_) | |\/| |/ _ \ / _` | | | | |/ _ \/ __|
  | |___ / __/ _  | |  | | (_) | (_| | |_| | |  __/\__ \
  |_____|_____(_) |_|  |_|\___/ \__,_|\__,_|_|\___||___/


                '
               / \
              /   \
             /     \
            /       \
           /    ↑    \
          /   order   \
         /             \
        /               \
       /=================\            _
      /        lvl        \      _.-'` |________________////  - Alveoli
     /          2          \      `'-._|                \\\\  - Vie Aeree
    /=======================\
   /            ↓            \
  /           order           \
 /=============================\

La complessità aumenta in questo livello, in quanto elementi semplici
vengono connessi a creare veri e propri sottocircuiti che verranno
ripetuti per ottenere la struttura polmonare.                 =#

# TODO: Ridefinire un po' di cose

@mtkmodel Airway begin
    @parameters begin
        # Diodo
        vin_th, [description = "Diode's Threshold"]
        # Resistori
        Ra, [description = "Resistance when air-filled"]
        Rb, [description = "ΔR (liquid - air)"]
        R_sw, [description = "Resistance of the soft tissues"]
        # Condensatori
        C_g, [description = "Shunt airway compliance due to gas"]
        C_sw, [description = "Compliance of the soft tissues"]
        # Induttori
        I_sw, [description = "Inertance of the soft tissues"]
        La, [description = "Inertance when air-filled"]
        Lb, [description = "ΔL (liquid-air)"]
        # Volume a FRC
        V_FRC, [description = "Airway Volume at FRC"]
        level = 1, [description = "Normalized air level (0 -> empty, 1 ->  full"]
    end
    @components begin
        # Pin
        in = Pin()
        out = Pin()
        # Integratore di corrente
        i1 = CurrentIntegrator(V_FRC = V_FRC, level = level)
        # Diodo
        D1 = Diode(vin_th = vin_th)
        # Resistori
        r_sw = Resistor(R = R_sw)
        r_tube = CIDResistor(Ra = 0.5 * Ra, Rb = 0.5 * Rb)
        r_tube_1 = CIDResistor(Ra = 0.5 * Ra, Rb = 0.5 * Rb)
        # Condensatori
        c_g = Capacitor(C = C_g)
        c_sw = Capacitor(C = C_sw)
        # Induttori
        i_sw = Inductor(L = I_sw)
        i_tube = CIDInductor(La = 0.5 * La, Lb = 0.5 * Lb)
        i_tube_1 = CIDInductor(La = 0.5 * La, Lb = 0.5 * Lb)
        # Switch
        # Sw       = Switch(V_FRC      = ParentScope(V_FRC))
        # s1 = Switch()
        # Riferimenti
        ground = Ground()
    end
    @equations begin
        # Connessioni
        # connect(in, r_tube.p)
        # connect(in, D1.p, Sw.p)
        # connect(D1.n, Sw.n, r_tube.p)
        # connect(in, r_tube.p)
        connect(in, D1.p)
        connect(D1.n, r_tube.p)
        connect(r_tube.n, i_tube.p)
        # connect(i_tube.n, c_g.p, i_sw.p, r_tube_1.p)
        connect(i_tube.n, c_g.p)
        connect(i_tube.n, i_sw.p)
        connect(i_tube.n, r_tube_1.p)
        connect(i_sw.n, r_sw.p)
        connect(r_sw.n, c_sw.p)
        connect(r_tube_1.n, i_tube_1.p)
        connect(i_tube_1.n, out)
        connect(c_g.n, ground.g)
        connect(c_sw.n, ground.g)

        # TODO: Dove collego l'integratore? Per ora lo collego alla
        # resistenza `r_tube`
        i1.current ~ in.i
        r_tube.n∫i ~ i1.n∫i
        r_tube_1.n∫i ~ i1.n∫i
        i_tube.n∫i ~ i1.n∫i
        i_tube_1.n∫i ~ i1.n∫i
        D1.trigger_in ~ i1.trigger_in
        D1.trigger_out ~ i1.trigger_out
        # s1.trigger_in ~ i1.trigger_in
        # s1.trigger_out ~ i1.trigger_out
        # Sw.∫i          ~ ∫i
    end
end

# TODO: Ridefinire alveolo

@mtkmodel Alveolus begin
    @parameters begin
        # Diodo
        vin_th, [description = "Diode's Threshold"]
        # Resistori
        Ra, [description = "Resistance when air-filled"]
        Rb, [description = "ΔR (liquid - air)"]
        R_t, [description = "Tissue resistance"]
        R_s, [description = "Tissue resistance related to stress relaxation"]
        # Condensatori
        C_g, [description = "Shunt terminal unit compliance due to gas"]
        C_s, [description = "Tissue compliance related to stress relaxation"]
        C_t, [description = "Tissue compliance"]
        # Induttori
        I_t, [description = "Tissue inertance"]
        La, [description = "Inertance when air-filled"]
        Lb, [description = "ΔL (liquid - air)"]
        # Volume a FRC
        V_FRC, [description = "Airway Volume at FRC"]
        level = 1, [description = "Normalized air level (0 -> empty, 1 ->  full"]
    end
    @components begin
        # Pin
        in = Pin()
        out = Pin()
        # Integratore di corrente
        i1 = CurrentIntegrator(V_FRC = V_FRC, level = level)
        # Diodo
        D1 = Diode(vin_th = vin_th)
        # Resistori
        r_tube = CIDResistor(Ra = Ra, Rb = Rb)
        r_t = Resistor(R = R_t)
        r_s = Resistor(R = R_s)
        # Condensatori
        c_ga = Capacitor(C = C_g)
        c_s = Capacitor(C = C_s)
        c_t = Capacitor(C = C_t)
        # Induttori
        i_tube = CIDInductor(La = La, Lb = Lb)
        i_t = Inductor(L = I_t)
        # Switch
        # Sw     = Switch(V_FRC      = ParentScope(V_FRC))
        # s1 = Switch()
        # Riferimenti
        ground = Ground()
    end
    @equations begin
        # Connessioni
        # connect(in, r_tube.p)
        # connect(in, r_tube.p)
        connect(in, D1.p)
        connect(D1.n, r_tube.p)
        connect(r_tube.n, i_tube.p)
        # connect(i_tube.n, c_ga.p, i_t.p, out)
        connect(i_tube.n, c_ga.p)
        connect(i_tube.n, i_t.p)
        connect(i_tube.n, out)
        connect(i_t.n, r_t.p)
        connect(r_t.n, c_t.p)
        connect(c_t.n, c_s.p)
        connect(c_t.n, r_s.p)
        connect(c_ga.n, ground.g)
        connect(c_s.n, ground.g)
        connect(r_s.n, ground.g)
        # Equazioni
        i1.current ~ in.i
        r_tube.n∫i ~ i1.n∫i
        i_tube.n∫i ~ i1.n∫i
        D1.trigger_in ~ i1.trigger_in
        D1.trigger_out ~ i1.trigger_out
        # s1.trigger_in ~ i1.trigger_in
        # s1.trigger_out ~ i1.trigger_out
    end
end
