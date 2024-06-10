#                        _            _ _
#   __ _ _ __ __ _ _ __ | |__  ___   (_) |
#  / _` | '__/ _` | '_ \| '_ \/ __|  | | |
# | (_| | | | (_| | |_) | | | \__ \_ | | |
#  \__, |_|  \__,_| .__/|_| |_|___(_)/ |_|
#  |___/          |_|              |__/   

#===============================================================
 GENERAZIONE GRAFICI
 ===============================================================#

# Librerie per grafici della soluzione
using Plots, PlotThemes, Plots.PlotMeasures
gr()

# Parametri per grafici
## Tema
theme(:solarized)

## Limiti su x
### Alveoli
xlims_al = tspan
### Airways
xlims_aw = tspan

al_volt_pl = plot(sol,
                  idxs = [system.L.IAE.out.v,
                          system.L.IAI.out.v,
                          system.L.IBB.out.v,
                          system.L.IAG.out.v,
                          system.L.IBA.out.v,],
                  title = "Tensioni (Alveoli)",
                  xlabel = "t [s]", ylabel = "Tensione [V]",
                  label = ["Vout di IAE" "Vout di IAI" "Vout di IBB" "Vout di IAG" "Vout di IBA"],
                  legend = :bottomright,
                  xlims = xlims_al,
                  ylims = (-resp_ampl - .5, resp_ampl + .5),
                  dpi = 300,
                  margin = 1cm,
                  size = (600, 600))

al_curr_pl = plot(sol,
                  idxs = [system.L.IAE.c_ga.i,
                          system.L.IAI.c_ga.i,
                          system.L.IBB.c_ga.i,
                          system.L.IAG.c_ga.i,
                          system.L.IBA.c_ga.i,],
                  title = "Correnti (Alveoli)",
                  xlabel = "t [s]", ylabel = "Corrente [A]",
                  label = ["Iout di IAE" "Iout di IAI" "Iout di IBB" "Iout di IAG" "Iout di IBA"],
                  legend = :bottomright,
                  xlims = xlims_al,
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

aw_volt_pl = plot(sol,
                  idxs = [system.L.IAD.out.v,
                          system.L.IAF.out.v,
                          system.L.IAH.out.v,
                          system.L.IBL.out.v],
                  title = "Tensioni (Vie Respiratorie)",
                  xlabel = "t [s]", ylabel = "Tensione [V]",
                  label = ["Vout di IAD" "Vout di IAF" "Vout di IAH" "Vout di IBL"],
                  legend = :bottomright,
                  xlims = xlims_aw,
                  ylims = (-resp_ampl - .5, resp_ampl + .5),
                  # ylims = (-8, 8),
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

aw_curr_pl = plot(sol,
                  idxs = [system.L.IAD.i_tube_1.i,
                          system.L.IAF.i_tube_1.i,
                          system.L.IAH.i_tube_1.i,
                          system.L.IBL.i_tube_1.i],
                  title = "Correnti (Vie Respiratorie)",
                  xlabel = "t [s]", ylabel = "Corrente [A]",
                  label = ["Iout di IAD" "Iout di IAF" "Iout di IAH" "Iout di IBL"],
                  legend = :bottomright,
                  xlims = xlims_aw,
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

tot_pl = plot(al_volt_pl, al_curr_pl, aw_volt_pl, aw_curr_pl, 
              plot_title = "Simulazione (A = $(resp_ampl)V)",
              dpi = 300,
              layout = (2, 2),
              size = (1920, 1080))

# plot(sol, idxs = [system.L.IAD.out.v
#                   system.L.IBL.out.v
#                   system.L.IAH.out.v
#                   system.L.IAF.out.v],
#      xlims = (0, 6),
#      ylims = (-1.5, 1.5))

# plot(sol, idxs = [system.L.IBB.out.v
#                   system.L.IBA.out.v
#                   system.L.IAE.out.v
#                   system.L.IAG.out.v
#                   system.L.IAI.out.v],
#      xlims = (0, 6),
#      ylims = (-1.5, 1.5))

#===============================================================
 SALVATAGGIO FIGURE
 ===============================================================#

savefig(tot_pl,
        "$srcdir/output/ampl_$(resp_ampl)_tspan_$(tspan).png")

display(tot_pl)
