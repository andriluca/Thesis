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
                  idxs = [system.IAE.out.v,
                          system.IAI.out.v,
                          system.IBB.out.v,
                          system.IAG.out.v,
                          system.IBA.out.v,],
                  title = "Tensioni (Alveoli)",
                  xlabel = "t [s]", ylabel = "Tensione [V]",
                  label = ["Vout di IAE" "Vout di IAI" "Vout di IBB" "Vout di IAG" "Vout di IBA"],
                  legend = :bottomright,
                  xlims = xlims_al,
                  dpi = 300,
                  margin = 1cm,
                  size = (600, 600))

al_curr_pl = plot(sol,
                  idxs = [system.IAE.c_ga.i,
                          system.IAI.c_ga.i,
                          system.IBB.c_ga.i,
                          system.IAG.c_ga.i,
                          system.IBA.c_ga.i,],
                  title = "Correnti (Alveoli)",
                  xlabel = "t [s]", ylabel = "Corrente [A]",
                  label = ["Iout di IAE" "Iout di IAI" "Iout di IBB" "Iout di IAG" "Iout di IBA"],
                  legend = :bottomright,
                  xlims = xlims_al,
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
                  xlims = xlims_aw,
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

aw_curr_pl = plot(sol,
                  idxs = [system.IAD.i_tube_1.i,
                          system.IAF.i_tube_1.i,
                          system.IAH.i_tube_1.i,
                          system.IBL.i_tube_1.i],
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

#===============================================================
 SALVATAGGIO FIGURE
 ===============================================================#

savefig(tot_pl,
        "$srcdir/output/ampl_$(resp_ampl)_tspan_$(tspan).png")
