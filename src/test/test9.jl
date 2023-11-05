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

# Modelli di Via Respiratoria e di Alveolo
@mtkmodel Airway begin
    @components begin
        # Pin
        in       = Pin()
        out      = Pin()
        # Resistori
        r_sw     = Resistor()
        r_tube   = Resistor()
        r_tube_1 = Resistor()
        # Condensatori
        c_g      = Capacitor()
        c_sw     = Capacitor()
        # Induttori
        i_sw     = Inductor()
        i_tube   = Inductor()
        i_tube_1 = Inductor()
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
        r_tube = Resistor()
        r_t    = Resistor()
        r_s    = Resistor()
        # Condensatori
        c_ga   = Capacitor()
        c_s    = Capacitor()
        c_t    = Capacitor()
        # Induttori
        i_tube = Inductor()
        i_t    = Inductor()
        # Riferimenti
        ground   = Ground()
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
        gen    = Square()
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
 DICHIARAZIONE PARAMETRI DI SISTEMA, SIMULAZIONE E GRAFICI
 ================================================================#

# Istanzio il modello (parametri esclusi).
@mtkbuild system = System()

# Definisco parametri di Sistema
sys_ps = [
    # Generatore di onda quadra
    system.gen.frequency  => 0.5,
    system.gen.amplitude  => 2.0e-3,
    # IAD
    system.IAD.r_tube.R   => (3.100029e+01 + 1.514023e+03) / 2,
    system.IAD.i_tube.L   => (1.852803e-03 + 1.664949e+00) / 2,
    system.IAD.c_g.C      => 1.689219e-09,
    system.IAD.r_sw.R     => 4.186147e+06,
    system.IAD.i_sw.L     => 3.705082e-01,
    system.IAD.c_sw.C     => 3.503620e-10,
    system.IAD.r_tube_1.R => (3.100029e+01 + 1.514023e+03) / 2,
    system.IAD.i_tube_1.L => (1.852803e-03 + 1.664949e+00) / 2,
    # system.IAD.V_FRC      => 1.744963e-06, # -- V_FRC
    # system.IAD.Vin_th     => 4.666378e+00, # -- tensione su primo diodo

    # IAE
    system.IAE.r_tube.R => 3.109214e+02 + 1.518509e+04,
    system.IAE.i_tube.L => 6.440085e-03 + 5.718839e+00,
    system.IAE.c_ga.C   => 2.462271e-07,
    system.IAE.r_t.R    => 1200,
    system.IAE.i_t.L    => 5.795540e-04,
    system.IAE.c_t.C    => 2.400000e-05,
    system.IAE.r_s.R    => 80000,
    system.IAE.c_s.C    => 2.100000e-05,
    # system.IAE.V_FRC    => 3.642283e-07, 
    # system.IAE.Vin_th   => 7.926677e+00, 

    # IAF
    system.IAF.r_tube.R   => (2.231464e+01 + 1.089824e+03) / 2,
    system.IAF.i_tube.L   => (1.166141e-03 + 1.047907e+00) / 2,
    system.IAF.c_g.C      => 8.128360e-10,
    system.IAF.r_sw.R     => 9.257208e+06,
    system.IAF.i_sw.L     => 7.164089e-01,
    system.IAF.c_sw.C     => 1.584351e-10,
    system.IAF.r_tube_1.R => (2.231464e+01 + 1.089824e+03) / 2,
    system.IAF.i_tube_1.L => (2.231464e+01 + 1.089824e+03) / 2,
    # system.IAF.V_FRC      => 8.396596e-07,
    # system.IAF.Vin_th     => 4.990351e+00,
    
    # IAG
    system.IAG.r_tube.R => 4.012746e+02 + 1.959785e+04,
    system.IAG.i_tube.L => 6.908560e-03 + 6.134848e+00,
    system.IAG.c_ga.C   => 2.461359e-07,
    system.IAG.r_t.R    => 1200,
    system.IAG.i_t.L    => 5.795540e-04,
    system.IAG.c_t.C    => 2.400000e-05,
    system.IAG.r_s.R    => 80000,
    system.IAG.c_s.C    => 2.100000e-05,
    # system.IAG.V_FRC    => 2.699475e-07,
    # system.IAG.Vin_th   => 8.694383e+00,

    # IAH
    system.IAH.r_tube.R   => (3.554331e+01 + 1.735899e+03) / 2,
    system.IAH.i_tube.L   => (1.653093e-03 + 1.485488e+00) / 2,
    system.IAH.c_g.C      => 9.126539e-10,
    system.IAH.r_sw.R     => 8.703449e+06,
    system.IAH.i_sw.L     => 5.994469e-01,
    system.IAH.c_sw.C     => 1.685156e-10,
    system.IAH.r_tube_1.R => (3.554331e+01 + 1.735899e+03) / 2,
    system.IAH.i_tube_1.L => (1.653093e-03 + 1.485488e+00) / 2,
    # system.IAH.V_FRC      => 9.427715e-07,
    # system.IAH.Vin_th     => 5.289833e+00,

    # IAI
    system.IAI.r_tube.R => 4.759710e+02 + 2.324594e+04,
    system.IAI.i_tube.L => 7.229610e-03 + 6.419942e+00,
    system.IAI.c_ga.C   => 2.460874e-07,
    system.IAI.r_t.R    => 1200,
    system.IAI.i_t.L    => 5.795540e-04,
    system.IAI.c_t.C    => 2.400000e-05,
    system.IAI.r_s.R    => 80000,
    system.IAI.c_s.C    => 2.100000e-05,
    # system.IAI.V_FRC    => 2.198790e-07,
    # system.IAI.Vin_th   => 9.256451e+00,

    # IBL
    system.IBL.r_tube.R   => (3.097440e+01 + 1.512758e+03) / 2,
    system.IBL.i_tube.L   => (1.290849e-03 + 1.159971e+00) / 2,
    system.IBL.c_g.C      => 5.722034e-10,
    system.IBL.r_sw.R     => 1.461035e+07,
    system.IBL.i_sw.L     => 9.016810e-01,
    system.IBL.c_sw.C     => 1.003855e-10,
    system.IBL.r_tube_1.R => (3.097440e+01 + 1.512758e+03) / 2,
    system.IBL.i_tube_1.L => (1.290849e-03 + 1.159971e+00) / 2,
    # system.IBL.V_FRC      => 5.910861e-07,
    # system.IBL.Vin_th     => 5.588244e+00, 

    # IBA
    system.IBA.r_tube.R => 2.017423e+02 + 9.852891e+03,
    system.IBA.i_tube.L => 5.687354e-03 + 5.050408e+00,
    system.IBA.c_ga.C   => 2.464514e-07,
    system.IBA.r_t.R    => 1200,
    system.IBA.i_t.L    => 5.795540e-04 ,
    system.IBA.c_t.C    => 2.400000e-05,
    system.IBA.r_s.R    => 80000,
    system.IBA.c_s.C    => 2.100000e-05,
    # system.IBA.V_FRC    => 5.958497e-07, 
    # system.IBA.Vin_th   => 6.794462e+00, 

    # IBB
    system.IBB.r_tube.R => 2.282920e+02 + 1.114955e+04,
    system.IBB.i_tube.L => 5.896531e-03 + 5.236159e+00,
    system.IBB.c_ga.C   => 2.463766e-07,
    system.IBB.r_t.R    => 1200,
    system.IBB.i_t.L    => 5.795540e-04,
    system.IBB.c_t.C    => 2.400000e-05,
    system.IBB.r_s.R    => 80000,
    system.IBB.c_s.C    => 2.100000e-05,
    # system.IBB.V_FRC    => 5.185713e-07,
    # system.IBB.Vin_th   => 7.098371e+00,
]

## genero un problema da risolvere nell'intervallo 0-10s.
prob = ODEProblem(system, sys_ps, (0, 10.0))
## modifico le tolleranze della soluzione.
sol = solve(prob, reltol = 1e-10, abstol = 1e-8)

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
                  idxs = [system.IAE.out.i,
                          system.IAI.out.i,
                          system.IBB.out.i,
                          system.IAG.out.i,
                          system.IBA.out.i,],
                  title = "Correnti (Alveoli)",
                  xlabel = "t [s]", ylabel = "Corrente [A]",
                  label = ["Iout di IAE" "Iout di IAI" "Iout di IBB" "Iout di IAG" "Iout di IBA"],
                  legend = :bottomright,
                  ylims = (-0.5, 0.5),
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

#===============================================================
 SALVATAGGIO IMMAGINI
 ===============================================================#

savefig(tot_pl, "volt_curr_const_2e-3.png")
