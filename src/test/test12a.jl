#===============================================================
 LIBRERIE UTILIZZATE
 ===============================================================#

# Modello
using ModelingToolkit, ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant, Square
using DifferentialEquations

# Grafici
using Plots, PlotThemes, Plots.PlotMeasures

#===============================================================
 DEFINIZIONE COMPONENTI E MODELLI
 ===============================================================#

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
        # Dopo l'uguale ho i valori di inizializzazione delle
        # variabili.
        ∫i(t) = 0, [description = "Current integral"]
        # Dichiaro come variabile d'interesse anche la resistenza.
        R(t) = Rl, [description = "Variable resistance"]
    end
    @equations begin
        # Ho trasformato l'equazione integrale della resistenza in una
        # differenziale. La notazione `∫i` indica il nome di una
        # variabile che rappresenta l'integrale della corrente.
        D(∫i) ~ i
        # Ra <= R <= Rl: suppongo che i valori Ra ed Rl siano estremi da non superare.
        R ~ min(Rl, max(Ra, (Ra + (Rl - Ra) * (1 - ∫i / V_FRC))))
        # R ~ Ra + (Rl - Ra) * (1 - ∫i / V_FRC) # --> non funziona in
        # questa forma.
        # Legge di Ohm per legare la corrente alla
        # tensione sulla resistenza.
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
        ∫i(t) = 0, [description = "Current integral"]
        L(t)  = Ll, [description = "Variable inductance"]
    end
    @equations begin
        D(∫i) ~ i
        # La <= L <= l
        L ~ min(Ll, max(La, (La + (Ll - La) * (1 - ∫i / V_FRC))))
        # d/dt (i(t)) = 1 / L * v(t), equazione dell'induttore
        D(i) ~ (1 / L) * v
    end
end

# Modelli di Via Respiratoria e di Alveolo
@mtkmodel Airway begin
    @parameters begin
        Ra
        Rl
        La
        Ll
        V_FRC
    end
    @components begin
        # Pin
        in       = Pin()
        out      = Pin()
        # Resistori
        r_sw     = Resistor()
        r_tube   = CIDResistor(Ra=Ra, Rl=Rl, V_FRC=V_FRC)
        r_tube_1 = CIDResistor(Ra=Ra, Rl=Rl, V_FRC=V_FRC)
        # Condensatori
        c_g      = Capacitor()
        c_sw     = Capacitor()
        # Induttori
        i_sw     = Inductor()
        i_tube   = CIDInductor(La = La, Ll = Ll, V_FRC = V_FRC)
        i_tube_1 = CIDInductor(La = La, Ll = Ll, V_FRC = V_FRC)
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
    end
end

@mtkmodel Alveolus begin
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
    @equations begin
        # Connessioni
        connect(in, r_tube.p)
        connect(r_tube.n, i_tube.p)
        connect(i_tube.n, c_ga.p, i_t.p, out)
        connect(i_t.n, r_t.p)
        connect(r_t.n, c_t.p)
        connect(c_t.n, c_s.p, r_s.p)
        connect(c_ga.n, c_s.n, r_s.n, ground.g)
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
        connect(IAD.out, IAE.in, IAF.in)
        connect(IAF.out, IAG.in, IAH.in)
        connect(IAH.out, IAI.in, IBL.in)
        connect(IBL.out, IBA.in, IBB.in)
        connect(source.n, ground.g)
    end
end

#================================================================
 DICHIARAZIONE PARAMETRI DI SISTEMA E SIMULAZIONE
 ================================================================#

# Istanzio il modello (parametri esclusi).
@mtkbuild system = System()

# Definisco parametri di Sistema
sys_ps = [
    # Generatore di onda quadra (frequenza e smoothing factor più avanti)
    system.gen.frequency  => 1.0,
    system.gen.amplitude  => 1.0e-3,

    # IAD
    ## Rtube
    system.IAD.r_tube.Ra      => (3.100029e+01) / 2,
    system.IAD.r_tube.Rl      => (3.100029e+01 + 1.514023e+03) / 2,
    system.IAD.r_tube.V_FRC   => 1.744963e-06,
    ## Itube
    system.IAD.i_tube.La      => (1.852803e-03) / 2,
    system.IAD.i_tube.Ll      => (1.852803e-03 + 1.664949e+00) / 2,
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
    ## Itube
    system.IAE.i_tube.La    => 6.440085e-03,
    system.IAE.i_tube.Ll    => 6.440085e-03 + 5.718839e+00,
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
    system.IAF.r_tube.Rl      => (2.231464e+01 + 1.089824e+03) / 2,
    system.IAF.r_tube.V_FRC   => 8.396596e-07,
    ## Itube    
    system.IAF.i_tube.La      => (1.166141e-03) / 2,
    system.IAF.i_tube.Ll      => (1.166141e-03 + 1.047907e+00) / 2,
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
    ## Itube
    system.IAG.i_tube.La    => 6.908560e-03,
    system.IAG.i_tube.Ll    => 6.908560e-03 + 6.134848e+00,
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
    ## Itube
    system.IAH.i_tube.La      => (1.653093e-03) / 2,
    system.IAH.i_tube.Ll      => (1.653093e-03 + 1.485488e+00) / 2,
    system.IAH.c_g.C          => 9.126539e-10,
    system.IAH.r_sw.R         => 8.703449e+06,
    system.IAH.i_sw.L         => 5.994469e-01,
    system.IAH.c_sw.C         => 1.685156e-10,
    # system.IAH.Vin_th     => 5.289833e+00,

    # IAI
    ## Rtube
    system.IAI.r_tube.Ra    => 4.759710e+02,
    system.IAI.r_tube.Rl    => 4.759710e+02 + 2.324594e+04,
    system.IAI.r_tube.V_FRC => 2.198790e-07,
    ## Itube
    system.IAI.i_tube.La    => 7.229610e-03,
    system.IAI.i_tube.Ll    => 7.229610e-03 + 6.419942e+00,
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
    system.IBL.r_tube.Rl      => (3.097440e+01 + 1.512758e+03) / 2,
    system.IBL.r_tube.V_FRC   => 5.910861e-07,
    ## Itube
    system.IBL.i_tube.La      => (1.290849e-03) / 2,
    system.IBL.i_tube.Ll      => (1.290849e-03 + 1.159971e+00) / 2,
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
    ## Ltube
    system.IBA.i_tube.La    => 5.687354e-03,
    system.IBA.i_tube.Ll    => 5.687354e-03 + 5.050408e+00,
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
    ## Itube
    system.IBB.i_tube.La    => 5.896531e-03,
    system.IBB.i_tube.Ll    => 5.896531e-03 + 5.236159e+00,
    system.IBB.c_ga.C       => 2.463766e-07,
    system.IBB.r_t.R        => 1200,
    system.IBB.i_t.L        => 5.795540e-04,
    system.IBB.c_t.C        => 2.400000e-05,
    system.IBB.r_s.R        => 80000,
    system.IBB.c_s.C        => 2.100000e-05,
    # system.IBB.Vin_th   => 7.098371e+00,

    # fixing
    system.IAD.Ra    => (3.100029e+01) / 2,
    system.IAD.Rl    => (3.100029e+01 + 1.514023e+03) / 2,
    system.IAD.La    => (1.852803e-03) / 2,
    system.IAD.Ll    => (1.852803e-03 + 1.664949e+00) / 2,
    system.IAD.V_FRC => 1.744963e-06,

    system.IAD.i_tube.V_FRC => system.IAD.V_FRC,
    system.IAD.r_tube_1.Ra => system.IAD.Ra,
    system.IAD.r_tube_1.Rl => system.IAD.Rl,
    system.IAD.r_tube_1.V_FRC => system.IAD.V_FRC,
    system.IAD.i_tube_1.La => system.IAD.La,
    system.IAD.i_tube_1.Ll => system.IAD.Ll,
    system.IAD.i_tube_1.V_FRC => system.IAD.V_FRC,

    system.IAF.Ra    => (2.231464e+01) / 2,
    system.IAF.Rl    => (2.231464e+01 + 1.089824e+03) / 2,
    system.IAF.La    => (1.166141e-03) / 2,
    system.IAF.Ll    => (1.166141e-03 + 1.047907e+00) / 2,
    system.IAF.V_FRC => 8.396596e-07,

    system.IAF.i_tube.V_FRC => system.IAF.V_FRC,
    system.IAF.r_tube_1.Ra => system.IAF.Ra,
    system.IAF.r_tube_1.Rl => system.IAF.Rl,
    system.IAF.r_tube_1.V_FRC => system.IAF.V_FRC,
    system.IAF.i_tube_1.Ll => system.IAF.Ll,
    system.IAF.i_tube_1.La => system.IAF.La,
    system.IAF.i_tube_1.V_FRC => system.IAF.V_FRC,

    system.IAH.Ra    => (3.554331e+01) / 2,
    system.IAH.Rl    => (3.554331e+01 + 1.735899e+03) / 2,
    system.IAH.La    => (1.653093e-03) / 2,
    system.IAH.Ll    => (1.653093e-03 + 1.485488e+00) / 2,
    system.IAH.V_FRC => 9.427715e-07,

    system.IAH.i_tube.V_FRC => system.IAH.V_FRC,
    system.IAH.r_tube_1.Ra => system.IAH.Ra,
    system.IAH.r_tube_1.Rl => system.IAH.Rl,
    system.IAH.r_tube_1.V_FRC => system.IAH.V_FRC,
    system.IAH.i_tube_1.La => system.IAH.La,
    system.IAH.i_tube_1.Ll => system.IAH.Ll,
    system.IAH.i_tube_1.V_FRC => system.IAH.V_FRC,

    system.IBL.Ra    => (3.097440e+01) / 2,
    system.IBL.Rl    => (3.097440e+01 + 1.512758e+03) / 2,
    system.IBL.La    => (1.290849e-03) / 2,
    system.IBL.Ll    => (1.290849e-03 + 1.159971e+00) / 2,
    system.IBL.V_FRC => 5.910861e-07,

    system.IBL.i_tube.V_FRC => system.IBL.V_FRC,
    system.IBL.r_tube_1.Ra => system.IBL.Ra,
    system.IBL.r_tube_1.Rl => system.IBL.Rl,
    system.IBL.r_tube_1.V_FRC => system.IBL.V_FRC,
    system.IBL.i_tube_1.La => system.IBL.La,
    system.IBL.i_tube_1.Ll => system.IBL.Ll,
    system.IBL.i_tube_1.V_FRC => system.IBL.V_FRC,

    # Ridondanti
    system.IAE.i_tube.V_FRC => 3.642283e-07,
    system.IAG.i_tube.V_FRC => 2.699475e-07,
    system.IAI.i_tube.V_FRC => 2.198790e-07,
    system.IBA.i_tube.V_FRC => 5.958497e-07,
    system.IBB.i_tube.V_FRC => 5.185713e-07,
]

## genero un problema da risolvere nell'intervallo 0-10s.
prob = ODEProblem(system, sys_ps, (0, 5.0))
## genero un problema per testare l'onda quadra smooth.
# prob = ODEProblem(system, sys_ps, (0, 1600.0e-9))
## modifico le tolleranze della soluzione.
sol = solve(prob, reltol = 1.0e-8, abstol = 1.0e-8)

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
