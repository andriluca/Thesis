#===============================================================
 MODELLI SUPERIORI (alias ad alto livello)
 ===============================================================#

# TODO: Ridefinire un po' di cose

@mtkmodel Airway begin
    @parameters begin
        # Diodo (sviluppo futuro)
        # Vin_th, [description = "Diode's Threshold"]
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
    end
    @components begin
        # Pin
        in = Pin()
        out = Pin()
        # Integratore
        i1 = Integrator(V_FRC = V_FRC)
        # Diodi (sviluppo futuro)
        # D1       = Diode(Vth         = Vin_th)
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
        # Switch (sviluppo futuro)
        # Sw       = Switch(V_FRC      = ParentScope(V_FRC))
        s1 = Switch()
        # Riferimenti
        ground = Ground()
    end
    @equations begin
        # Connessioni
        # connect(in, r_tube.p)
        # connect(in, D1.p, Sw.p)
        # connect(D1.n, Sw.n, r_tube.p)
        # connect(in, r_tube.p)
        connect(in, s1.p)
        connect(s1.n, r_tube.p)
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
        i1.integ.u ~ in.i
        r_tube.n∫i ~ i1.integ.y
        r_tube_1.n∫i ~ i1.integ.y
        i_tube.n∫i ~ i1.integ.y
        i_tube_1.n∫i ~ i1.integ.y
        s1.trigger_in ~ i1.trigger.u
        s1.trigger_out ~ i1.trigger.y
        # Sw.∫i          ~ ∫i
    end
end

# TODO: Ridefinire alveolo

@mtkmodel Alveolus begin
    @parameters begin
        # Diodo (sviluppo futuro)
        # Vin_th, [description = "Diode's Threshold"]
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
    end
    @components begin
        # Pin
        in = Pin()
        out = Pin()
        # Diodi (Sviluppo futuro)
        # D1     = Diode(Vth         = Vin_th)
        # Resistori
        i1 = Integrator(V_FRC = V_FRC)
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
        s1 = Switch()
        # Riferimenti
        ground = Ground()
    end
    @equations begin
        # Connessioni
        # connect(in, r_tube.p)
        # connect(in, r_tube.p)
        connect(in, s1.p)
        connect(s1.n, r_tube.p)
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
        i1.integ.u ~ r_tube.i
        r_tube.n∫i ~ i1.integ.y
        i_tube.n∫i ~ i1.integ.y
        s1.trigger_in ~ i1.trigger.u
        s1.trigger_out ~ i1.trigger.y
    end
end
