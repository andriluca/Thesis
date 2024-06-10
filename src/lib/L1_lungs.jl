#= _     _     _
  | |   / |_  | |   _   _ _ __   __ _ ___
  | |   | (_) | |  | | | | '_ \ / _` / __|
  | |___| |_  | |__| |_| | | | | (_| \__ \
  |_____|_(_) |_____\__,_|_| |_|\__, |___/
                                |___/

                '
               / \
              /   \
             /  ↑  \
            / order \
           /         \
          /===========\               _
         /     lvl     \         _.-'` |________________////  - Polmoni
        /       1       \         `'-._|                \\\\
       /=================\
      /                   \
     /          ↓          \
    /         order         \
   /                         \
  /                           \
 /=============================\

Questo livello è generato da uno script (`src/cir2jl`).  Sconsigliata
la modifica diretta di questo file se non utilizzando lo script.
Questo livello collega i vari sottocircuiti per creare il modello
(passivo) del polmone.                                         =#

# TODO: Ripulire dalle cose che dipendono dal generatore
# TODO: Rivedere script per generazione del modello

@mtkmodel Lungs begin
    @variables begin
        trigger_in(t) = false, [description = "True when start current integrating."]
    end
    @components begin
        in = Pin()
        IBB = Alveolus(La=5.896531e-03, Lb=5.236159e+00,
                       Ra=2.282920e+02, Rb=1.114955e+04,
                       V_FRC=5.185713e-07,
                       C_g=2.463766e-07,
                       vin_th   = 7.098371e+00,
                       I_t=5.795540e-04,
                       R_t=1200,
                       C_t=2.400000e-05,
                       R_s=80000,
                       C_s=2.100000e-05
                       )
        IBA = Alveolus(La=5.687354e-03, Lb=5.050408e+00,
                       Ra=2.017423e+02, Rb=9.852891e+03,
                       V_FRC=5.958497e-07,
                       C_g=2.464514e-07,
                       vin_th   = 6.794462e+00,
                       I_t=5.795540e-04,
                       R_t=1200,
                       C_t=2.400000e-05,
                       R_s=80000,
                       C_s=2.100000e-05
                       )
        IBL = Airway(La=1.290849e-03, Lb=1.159971e+00,
                     Ra=3.097440e+01, Rb=1.512758e+03,
                     R_sw=1.461035e+07,
                     I_sw=9.016810e-01,
                     C_sw=1.003855e-10,
                     V_FRC=5.910861e-07,
                     C_g=5.722034e-10,
                     vin_th   = 5.588244e+00
                     )
        IAH = Airway(La=1.653093e-03, Lb=1.485488e+00,
                     Ra=3.554331e+01, Rb=1.735899e+03,
                     R_sw=8.703449e+06,
                     I_sw=5.994469e-01,
                     C_sw=1.685156e-10,
                     V_FRC=9.427715e-07,
                     C_g=9.126539e-10,
                     vin_th   = 5.289833e+00
                     )
        IAF = Airway(La=1.166141e-03, Lb=1.047907e+00,
                     Ra=2.231464e+01, Rb=1.089824e+03,
                     R_sw=9.257208e+06,
                     I_sw=7.164089e-01,
                     C_sw=1.584351e-10,
                     V_FRC=8.396596e-07,
                     C_g=8.128360e-10,
                     vin_th   = 4.990351e+00
                     )
        IAE = Alveolus(La=6.440085e-03, Lb=5.718839e+00,
                       Ra=3.109214e+02, Rb=1.518509e+04,
                       V_FRC=3.642283e-07,
                       C_g=2.462271e-07,
                       vin_th   = 7.926677e+00,
                       I_t=5.795540e-04,
                       R_t=1200,
                       C_t=2.400000e-05,
                       R_s=80000,
                       C_s=2.100000e-05
                       )
        IAG = Alveolus(La=6.908560e-03, Lb=6.134848e+00,
                       Ra=4.012746e+02, Rb=1.959785e+04,
                       V_FRC=2.699475e-07,
                       C_g=2.461359e-07,
                       vin_th   = 8.694383e+00,
                       I_t=5.795540e-04,
                       R_t=1200,
                       C_t=2.400000e-05,
                       R_s=80000,
                       C_s=2.100000e-05
                       )
        IAI = Alveolus(La=7.229610e-03, Lb=6.419942e+00,
                       Ra=4.759710e+02, Rb=2.324594e+04,
                       V_FRC=2.198790e-07,
                       C_g=2.460874e-07,
                       vin_th   = 9.256451e+00,
                       I_t=5.795540e-04,
                       R_t=1200,
                       C_t=2.400000e-05,
                       R_s=80000,
                       C_s=2.100000e-05
                       )
        IAD = Airway(La=1.852803e-03, Lb=1.664949e+00,
                     Ra=3.100029e+01, Rb=1.514023e+03,
                     R_sw=4.186147e+06,
                     I_sw=3.705082e-01,
                     C_sw=3.503620e-10,
                     V_FRC=1.744963e-06,
                     C_g=1.689219e-09,
                     vin_th   = 4.666378e+00
                     )
    end

    @equations begin
        connect(in,      IAD.in)
        IAD.i1.trigger_in ~ trigger_in
        connect(IAD.out, IAF.in)
        IAF.i1.trigger_in ~ IAD.i1.trigger_out
        connect(IAD.out, IAE.in)
        IAE.i1.trigger_in ~ IAD.i1.trigger_out
        connect(IAF.out, IAH.in)
        IAH.i1.trigger_in ~ IAF.i1.trigger_out
        connect(IAF.out, IAG.in)
        IAG.i1.trigger_in ~ IAF.i1.trigger_out
        connect(IAH.out, IBL.in)
        IBL.i1.trigger_in ~ IAH.i1.trigger_out
        connect(IAH.out, IAI.in)
        IAI.i1.trigger_in ~ IAH.i1.trigger_out
        connect(IBL.out, IBB.in)
        IBB.i1.trigger_in ~ IBL.i1.trigger_out
        connect(IBL.out, IBA.in)
        IBA.i1.trigger_in ~ IBL.i1.trigger_out
    end
end

