# Creare un modulo avente una variabile che viene passata ad un secondo modulo

# Modello
using ModelingToolkit, ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant, Square
using DifferentialEquations

# Grafici
using Plots, PlotThemes, Plots.PlotMeasures

# Simboli per variabile temporale e differenziale (dt).
@parameters t
D = Differential(t)

# Componenti variabili
@mtkmodel CIDResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra,    [description = "Resistance when air-filled"]
        Rl,    [description = "Resistance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Dichiaro come variabile d'interesse anche la resistenza.
        R(t)  = Rl, [description = "Variable resistance"]
        ∫i(t),      [description = "Current integral"]
    end
    @equations begin
        R ~ min(Rl, max(Ra, (Ra + (Rl - Ra) * (1 - ∫i / V_FRC))))
        # Legge di Ohm per legare la corrente alla tensione sulla
        # resistenza.
        v ~ R * i
    end
end

@mtkmodel CIDInductor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        La,    [description = "Inductance when air-filled"]
        Ll,    [description = "Inductance when liquid-filled"]
        V_FRC, [description = "Airway Volume at FRC"]
    end
    @variables begin
        # Il valore di default altro non è che il valore
        # d'inizializzazione del sistema.
        L(t)  = Ll, [description = "Variable inductance"]
        ∫i(t),      [description = "Current integral"]
    end
    @equations begin
        # La <= L <= l
        L ~ min(Ll, max(La, (La + (Ll - La) * (1 - ∫i / V_FRC))))
        # d/dt (i(t)) = 1 / L * v(t), equazione dell'induttore
        D(i) ~ (1 / L) * v
    end
end

# Modelli di Via Respiratoria e di Alveolo
@mtkmodel Airway begin
    @parameters begin
        V_FRC
    end
    @components begin
        # Pin
        in       = Pin()
        out      = Pin()
        # Resistori
        r_sw     = Resistor()
        r_tube   = CIDResistor()
        r_tube_1 = CIDResistor()
        # Condensatori
        c_g      = Capacitor()
        c_sw     = Capacitor()
        # Induttori
        i_sw     = Inductor()
        i_tube   = CIDInductor()
        i_tube_1 = CIDInductor()
        ground   = Ground()
    end
    @variables begin
        ∫i(t)          = 0, [description = "Current integral"]
        trigger_in(t)  = 0, [description = "Air-Filling status of input airway"]
        trigger_out(t) = 0, [description = "Air-Filling status of output airway"]
        trigger_out_pvt(t) = 0, [description = "Air-Filling private status of output airway"]
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
        trigger_out_pvt ~ ifelse(trigger_out_pvt >= .8, 1, ∫i / V_FRC)
        D(∫i) ~ ifelse(trigger_out_pvt >= .8, 0, in.i)
        # D(∫i) ~ trigger_in * (1 - trigger_out) * in.i
        # 0 <= trigger_out <= 1
        trigger_out ~ ifelse(trigger_out_pvt >= .8, 1, 0)
#        trigger_out ~ max(0, min(1, ∫i / V_FRC))
        r_tube.∫i      ~ ∫i
        r_tube_1.∫i    ~ ∫i
        i_tube.∫i      ~ ∫i
        i_tube_1.∫i    ~ ∫i
    end
end

@mtkmodel Alveolus begin
    @parameters begin
        V_FRC
    end
    @components begin
        # Pin
        in     = Pin()
        out    = Pin()
        # Resistori
        r_tube = CIDResistor()
        r_t    = Resistor()
        r_s    = Resistor()
        # Condensatori
        c_ga   = Capacitor()
        c_s    = Capacitor()
        c_t    = Capacitor()
        # Induttori
        i_tube = CIDInductor()
        i_t    = Inductor()
        # Riferimenti
        ground = Ground()
    end
    @variables begin
        ∫i(t)      = 0, [description = "Current integral"]
        trigger_in(t),  [description = "Air-Filling status of input airway"]
        trigger_out(t) = 0, [description = "Air-Filling status of output airway"]
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
        D(∫i) ~ ifelse(trigger_out >= .8, 0, in.i)
        # D(∫i) ~ trigger_in * (1 - trigger_out) * in.i
        # 0 <= trigger_out <= 1
        trigger_out ~ ifelse(trigger_out >= .8, 1, ∫i / V_FRC)
        # D(∫i) ~ trigger_in * (1 - trigger_out) * in.i
        # 0 <= trigger_out <= 1
        # trigger_out ~ ∫i / V_FRC
#        trigger_out ~ max(0, min(1, ∫i / V_FRC))
        # D(∫i) ~ ifelse((trigger_in == 1) && (trigger_out == 0),
        #                0,
        #                i)
        # trigger_out ~ ifelse((∫i / V_FRC) >= 1,
        #                      1,
        #                      0)
        r_tube.∫i     ~ ∫i
        i_tube.∫i     ~ ∫i
    end
end

# Struttura circuitale (i.e. sottorete IA{D, E, F, G, H, I}, IB{L, A,
# B}).
@mtkmodel System begin
    @components begin
        # Sorgenti del segnale e ground.
        gen    = Square(smooth = 1e-3)
        source = Voltage()
        ground = Ground()
        # Elementi del modello.
        IAD = Airway()
        IAE = Alveolus()
        IAF = Airway()
        IAG = Alveolus()
        IAH = Airway()
        IAI = Alveolus()
        IBL = Airway()
        IBA = Alveolus()
        IBB = Alveolus()
    end
    @equations begin
        connect(gen.output, source.V)
        connect(source.p, IAD.in)
        IAD.trigger_in ~ 1
        connect(IAD.out, IAE.in, IAF.in)
        IAE.trigger_in ~ IAD.trigger_out
        IAF.trigger_in ~ IAD.trigger_out
        connect(IAF.out, IAG.in, IAH.in)
        IAG.trigger_in ~ IAF.trigger_out
        IAH.trigger_in ~ IAF.trigger_out
        connect(IAH.out, IAI.in, IBL.in)
        IAI.trigger_in ~ IAH.trigger_out
        IBL.trigger_in ~ IAH.trigger_out
        connect(IBL.out, IBA.in, IBB.in)
        IBA.trigger_in ~ IBL.trigger_out
        IBB.trigger_in ~ IBL.trigger_out
        connect(source.n, ground.g)
    end
end

#================================================================
 DICHIARAZIONE PARAMETRI DI SISTEMA E SIMULAZIONE
 ================================================================#

# Istanzio il modello (parametri esclusi).
@mtkbuild system = System()

sys_ps = [
    # Generatore di onda quadra
    system.gen.frequency  => 1.0,
    system.gen.amplitude  => 100.0e-3,

    # IAD
    ## Rtube
    system.IAD.r_tube.Ra      => (3.100029e+01) / 2,
    system.IAD.r_tube_1.Ra    => (3.100029e+01) / 2,
    system.IAD.r_tube.Rl      => (3.100029e+01 + 1.514023e+03) / 2,
    system.IAD.r_tube_1.Rl    => (3.100029e+01 + 1.514023e+03) / 2,
    system.IAD.r_tube.V_FRC   => 1.744963e-06,
    system.IAD.r_tube_1.V_FRC => 1.744963e-06,
    system.IAD.V_FRC   => 1.744963e-06,
    ## Itube
    system.IAD.i_tube.La      => (1.852803e-03) / 2,
    system.IAD.i_tube_1.La    => (1.852803e-03) / 2,
    system.IAD.i_tube_1.Ll    => (1.852803e-03 + 1.664949e+00) / 2,
    system.IAD.i_tube.Ll      => (1.852803e-03 + 1.664949e+00) / 2,
    system.IAD.i_tube.V_FRC   => 1.744963e-06,
    system.IAD.i_tube_1.V_FRC => 1.744963e-06,
    system.IAD.c_g.C          => 1.689219e-09,
    system.IAD.r_sw.R         => 4.186147e+06,
    system.IAD.i_sw.L         => 3.705082e-01,
    system.IAD.c_sw.C         => 3.503620e-10,
    # system.IAD.Vin_th     => 4.666378e+00, # -- tensione su primo diodo

    # IAE
    ## Rtube
    system.IAE.r_tube.Ra    => 3.109214e+02,
    system.IAE.r_tube.Rl    => 3.109214e+02 + 1.518509e+04,
    system.IAE.r_tube.V_FRC => 3.642283e-07,
    system.IAE.V_FRC => 3.642283e-07,
    ## Itube
    system.IAE.i_tube.La    => 6.440085e-03,
    system.IAE.i_tube.Ll    => 6.440085e-03 + 5.718839e+00,
    system.IAE.i_tube.V_FRC => 3.642283e-07,
    system.IAE.c_ga.C       => 2.462271e-07,
    system.IAE.r_t.R        => 1200,
    system.IAE.i_t.L        => 5.795540e-04,
    system.IAE.c_t.C        => 2.400000e-05,
    system.IAE.r_s.R        => 80000,
    system.IAE.c_s.C        => 2.100000e-05,
    # system.IAE.Vin_th   => 7.926677e+00,

    # IAF
    ## Rtube
    system.IAF.r_tube.Ra      => (2.231464e+01) / 2,
    system.IAF.r_tube_1.Ra    => (2.231464e+01) / 2,
    system.IAF.r_tube.Rl      => (2.231464e+01 + 1.089824e+03) / 2,
    system.IAF.r_tube_1.Rl    => (2.231464e+01 + 1.089824e+03) / 2,
    system.IAF.r_tube.V_FRC   => 8.396596e-07,
    system.IAF.r_tube_1.V_FRC => 8.396596e-07,
    system.IAF.V_FRC   => 8.396596e-07,
    ## Itube    
    system.IAF.i_tube.La      => (1.166141e-03) / 2,
    system.IAF.i_tube_1.La    => (1.166141e-03) / 2,
    system.IAF.i_tube.Ll      => (1.166141e-03 + 1.047907e+00) / 2,
    system.IAF.i_tube_1.Ll    => (1.166141e-03 + 1.047907e+00) / 2,
    system.IAF.i_tube.V_FRC   => 8.396596e-07,
    system.IAF.i_tube_1.V_FRC => 8.396596e-07,
    system.IAF.c_g.C          => 8.128360e-10,
    system.IAF.r_sw.R         => 9.257208e+06,
    system.IAF.i_sw.L         => 7.164089e-01,
    system.IAF.c_sw.C         => 1.584351e-10,
    # system.IAF.Vin_th     => 4.990351e+00,
    
    # IAG
    ## Rtube
    system.IAG.r_tube.Ra    => 4.012746e+02,
    system.IAG.r_tube.Rl    => 4.012746e+02 + 1.959785e+04,
    system.IAG.r_tube.V_FRC => 2.699475e-07,
    system.IAG.V_FRC => 2.699475e-07,
    ## Itube
    system.IAG.i_tube.La    => 6.908560e-03,
    system.IAG.i_tube.Ll    => 6.908560e-03 + 6.134848e+00,
    system.IAG.i_tube.V_FRC => 2.699475e-07,
    system.IAG.c_ga.C       => 2.461359e-07,
    system.IAG.r_t.R        => 1200,
    system.IAG.i_t.L        => 5.795540e-04,
    system.IAG.c_t.C        => 2.400000e-05,
    system.IAG.r_s.R        => 80000,
    system.IAG.c_s.C        => 2.100000e-05,
    # system.IAG.Vin_th   => 8.694383e+00,

    # IAH
    ## Rtube
    system.IAH.r_tube.Ra      => (3.554331e+01) / 2,
    system.IAH.r_tube.Rl      => (3.554331e+01 + 1.735899e+03) / 2,
    system.IAH.r_tube.V_FRC   => 9.427715e-07,
    system.IAH.V_FRC   => 9.427715e-07,
    ## Itube
    system.IAH.i_tube.La      => (1.653093e-03) / 2,
    system.IAH.i_tube.Ll      => (1.653093e-03 + 1.485488e+00) / 2,
    system.IAH.i_tube.V_FRC   => 9.427715e-07,
    system.IAH.c_g.C          => 9.126539e-10,
    system.IAH.r_sw.R         => 8.703449e+06,
    system.IAH.i_sw.L         => 5.994469e-01,
    system.IAH.c_sw.C         => 1.685156e-10,
    system.IAH.r_tube_1.Ra    => (3.554331e+01) / 2,
    system.IAH.r_tube_1.Rl    => (3.554331e+01 + 1.735899e+03) / 2,
    system.IAH.r_tube_1.V_FRC => 9.427715e-07,
    system.IAH.i_tube_1.La    => (1.653093e-03) / 2,
    system.IAH.i_tube_1.Ll    => (1.653093e-03 + 1.485488e+00) / 2,
    system.IAH.i_tube_1.V_FRC => 9.427715e-07,
    # system.IAH.Vin_th     => 5.289833e+00,

    # IAI
    ## Rtube
    system.IAI.r_tube.Ra    => 4.759710e+02,
    system.IAI.r_tube.Rl    => 4.759710e+02 + 2.324594e+04,
    system.IAI.r_tube.V_FRC => 2.198790e-07,
    system.IAI.V_FRC => 2.198790e-07,
    ## Itube
    system.IAI.i_tube.La    => 7.229610e-03,
    system.IAI.i_tube.Ll    => 7.229610e-03 + 6.419942e+00,
    system.IAI.i_tube.V_FRC => 2.198790e-07,
    system.IAI.c_ga.C       => 2.460874e-07,
    system.IAI.r_t.R        => 1200,
    system.IAI.i_t.L        => 5.795540e-04,
    system.IAI.c_t.C        => 2.400000e-05,
    system.IAI.r_s.R        => 80000,
    system.IAI.c_s.C        => 2.100000e-05,
    # system.IAI.Vin_th   => 9.256451e+00,

    # IBL
    ## Rtube
    system.IBL.r_tube.Ra      => (3.097440e+01) / 2,
    system.IBL.r_tube_1.Ra    => (3.097440e+01) / 2,
    system.IBL.r_tube.Rl      => (3.097440e+01 + 1.512758e+03) / 2,
    system.IBL.r_tube_1.Rl    => (3.097440e+01 + 1.512758e+03) / 2,
    system.IBL.r_tube.V_FRC   => 5.910861e-07,
    system.IBL.r_tube_1.V_FRC => 5.910861e-07,
    system.IBL.V_FRC => 5.910861e-07,
    ## Itube
    system.IBL.i_tube.La      => (1.290849e-03) / 2,
    system.IBL.i_tube_1.La    => (1.290849e-03) / 2,
    system.IBL.i_tube.Ll      => (1.290849e-03 + 1.159971e+00) / 2,
    system.IBL.i_tube_1.Ll    => (1.290849e-03 + 1.159971e+00) / 2,
    system.IBL.i_tube.V_FRC   => 5.910861e-07,
    system.IBL.i_tube_1.V_FRC => 5.910861e-07,
    system.IBL.c_g.C          => 5.722034e-10,
    system.IBL.r_sw.R         => 1.461035e+07,
    system.IBL.i_sw.L         => 9.016810e-01,
    system.IBL.c_sw.C         => 1.003855e-10,
    # system.IBL.Vin_th     => 5.588244e+00, 

    # IBA
    ## Rtube
    system.IBA.r_tube.Ra    => 2.017423e+02,
    system.IBA.r_tube.Rl    => 2.017423e+02 + 9.852891e+03,
    system.IBA.r_tube.V_FRC => 5.958497e-07,
    system.IBA.V_FRC => 5.958497e-07,
    ## Ltube
    system.IBA.i_tube.La    => 5.687354e-03,
    system.IBA.i_tube.Ll    => 5.687354e-03 + 5.050408e+00,
    system.IBA.i_tube.V_FRC => 5.958497e-07,
    system.IBA.c_ga.C       => 2.464514e-07,
    system.IBA.r_t.R        => 1200,
    system.IBA.i_t.L        => 5.795540e-04,
    system.IBA.c_t.C        => 2.400000e-05,
    system.IBA.r_s.R        => 80000,
    system.IBA.c_s.C        => 2.100000e-05,
    # system.IBA.Vin_th   => 6.794462e+00,

    # IBB
    ## Rtube
    system.IBB.r_tube.Ra    => 2.282920e+02,
    system.IBB.r_tube.Rl    => 2.282920e+02 + 1.114955e+04,
    system.IBB.r_tube.V_FRC => 5.185713e-07,
    system.IBB.V_FRC => 5.185713e-07,
    ## Itube
    system.IBB.i_tube.La    => 5.896531e-03,
    system.IBB.i_tube.Ll    => 5.896531e-03 + 5.236159e+00,
    system.IBB.i_tube.V_FRC => 5.185713e-07,
    system.IBB.c_ga.C       => 2.463766e-07,
    system.IBB.r_t.R        => 1200,
    system.IBB.i_t.L        => 5.795540e-04,
    system.IBB.c_t.C        => 2.400000e-05,
    system.IBB.r_s.R        => 80000,
    system.IBB.c_s.C        => 2.100000e-05,
    # system.IBB.Vin_th   => 7.098371e+00,
]

## genero un problema da risolvere nell'intervallo 0-10s.
prob = ODEProblem(system, sys_ps, (0, 5.0))
## genero un problema per testare l'onda quadra smooth.
# prob = ODEProblem(system, sys_ps, (0, 1600.0e-9))
## modifico le tolleranze della soluzione.
sol = solve(prob, reltol = 1.0e-10, abstol = 1.0e-8)

#===============================================================
 GENERAZIONE GRAFICI
 ===============================================================#

theme(:solarized)
al_volt_pl = plot(sol,
                  idxs = [system.IAE.out.v,
                          system.IAI.out.v,
                          system.IBB.out.v,
                          system.IAG.out.v,
                          system.IBA.out.v,],
                  title = "Tensioni (Alveoli)",
                  xlabel = "t [s]", ylabel = "Tensione [V]",
                  label = ["Vout di IAE" "Vout di IAI" "Vout di IBB" "Vout di IAG" "Vout di IBA"],
                  legend = :bottomright,
                  dpi = 300,
                  margin = 1cm,
                  size = (600, 600))

al_curr_pl = plot(sol,
                  idxs = [system.IAE.c_ga.p.i,
                          # O(2e-9)
                          system.IAI.c_ga.p.i,
                          system.IBB.c_ga.p.i,
                          system.IAG.c_ga.p.i,
                          system.IBA.c_ga.p.i,],
                  title = "Correnti (Alveoli)",
                  xlabel = "t [s]", ylabel = "Corrente [A]",
                  label = ["Iout di IAE" "Iout di IAI" "Iout di IBB" "Iout di IAG" "Iout di IBA"],
                  legend = :bottomright,
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

aw_volt_pl = plot(sol,
                  idxs = [system.IAD.out.v,
                          system.IAF.out.v,
                          system.IAH.out.v,
                          system.IBL.out.v],
                  title = "Tensioni (Vie Respiratorie)",
                  xlabel = "t [s]", ylabel = "Tensione [V]",
                  label = ["Vout di IAD" "Vout di IAF" "Vout di IAH" "Vout di IBL"],
                  legend = :bottomright,
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

aw_curr_pl = plot(sol,
                  idxs = [system.IAD.out.i,
                          system.IAF.out.i,
                          system.IAH.out.i,
                          system.IBL.out.i],
                  title = "Correnti (Vie Respiratorie)",
                  xlabel = "t [s]", ylabel = "Corrente [A]",
                  label = ["Iout di IAD" "Iout di IAF" "Iout di IAH" "Iout di IBL"],
                  legend = :bottomright,
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

tot_pl = plot(al_volt_pl, al_curr_pl, aw_volt_pl, aw_curr_pl, 
              plot_title = "Simulazione (A = 2.0e-3V, f = 0.5Hz)",
              dpi = 300,
              layout = (2, 2),
              size = (1920, 1080))

# plot(sol, idxs = [system.gen.output.u])

#===============================================================
 SALVATAGGIO IMMAGINI
 ===============================================================#

savefig(tot_pl, "volt_curr_non_const_2e-3_smooth.png")

@mtkmodel dummy begin
    @variables begin
        x(t) = true
        y(t) = false
    end
end

@mtkmodel System begin
    @components begin
        d1 = dummy()
        d2 = dummy()
    end
    @equations begin
        d2.x ~ d1.y
        d2.y ~ d1.x
    end
end

@mtkbuild system = System()
## genero un problema da risolvere nell'intervallo 0-10s.
prob = ODEProblem(system, sys_ps, (0, 5.0))
## genero un problema per testare l'onda quadra smooth.
# prob = ODEProblem(system, sys_ps, (0, 1600.0e-9))
## modifico le tolleranze della soluzione.
sol = solve(prob, reltol = 1.0e-8, abstol = 1.0e-8)
