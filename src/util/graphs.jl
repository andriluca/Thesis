#                        _            _ _
#   __ _ _ __ __ _ _ __ | |__  ___   (_) |
#  / _` | '__/ _` | '_ \| '_ \/ __|  | | |
# | (_| | | | (_| | |_) | | | \__ \_ | | |
#  \__, |_|  \__,_| .__/|_| |_|___(_)/ |_|
#  |___/          |_|              |__/   

#===============================================================
 PLOTS GENERATION
 ===============================================================#

# Plotting libraries.
using Plots, PlotThemes, Plots.PlotMeasures
gr()
# plotly()

# Plots' parameters
## Tema
# theme(:solarized)
theme(:default)

## x limits
### Common
xlims_al = xlims_aw = (.995, 1.09)

### Alveoli
# xlims_al = tspan
ylims_al = (0, .018)  # For small currents

### Airways
# xlims_aw = tspan
ylims_aw = (0, .03)  # For small currents

al_volt_pl = plot(sol,
                  idxs = [system.L.IAE.out.v,
                          system.L.IAI.out.v,
                          system.L.IBB.out.v,
                          system.L.IAG.out.v,
                          system.L.IBA.out.v,],
                  title = "Voltages (Alveoli)",
                  xlabel = "t [s]", ylabel = "Voltage [V]",
                  label = ["Vout (IAE)" "Vout (IAI)" "Vout (IBB)" "Vout (IAG)" "Vout (IBA)"],
                  legend = :bottomright,
                  xlims = xlims_al,
                  ylims = (0, resp_ampl + 1),
                  dpi = 300,
                  margin = 1cm,
                  size = (600, 600))

al_curr_pl = plot(sol,
                  idxs = [system.L.IAE.c_ga.i,
                          system.L.IAI.c_ga.i,
                          system.L.IBB.c_ga.i,
                          system.L.IAG.c_ga.i,
                          system.L.IBA.c_ga.i,],
                  title = "Currents (Alveoli)",
                  xlabel = "t [s]", ylabel = "Corrente [A]",
                  label = ["Iout (IAE)" "Iout (IAI)" "Iout (IBB)" "Iout (IAG)" "Iout (IBA)"],
                  legend = :bottomright,
                  xlims = xlims_al,
                  ylims = ylims_al,
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

aw_volt_pl = plot(sol,
                  idxs = [system.L.IAD.out.v,
                          system.L.IAF.out.v,
                          system.L.IAH.out.v,
                          system.L.IBL.out.v],
                  title = "Voltages (Airways)",
                  xlabel = "t [s]", ylabel = "Voltage [V]",
                  label = ["Vout (IAD)" "Vout (IAF)" "Vout (IAH)" "Vout (IBL)"],
                  legend = :bottomright,
                  xlims = xlims_aw,
                  ylims = (0, resp_ampl + 1),
                  # ylims = (-8, 8),
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

aw_curr_pl = plot(sol,
                  idxs = [system.L.IAD.i_tube_1.i,
                          system.L.IAF.i_tube_1.i,
                          system.L.IAH.i_tube_1.i,
                          system.L.IBL.i_tube_1.i],
                  title = "Currents (Airways)",
                  xlabel = "t [s]", ylabel = "Corrente [A]",
                  label = ["Iout (IAD)" "Iout (IAF)" "Iout (IAH)" "Iout (IBL)"],
                  legend = :bottomright,
                  xlims = xlims_aw,
                  ylims = ylims_aw,
                  dpi = 300,
                  margin = 1cm,
                  size = (800, 600))

tot_pl = plot(al_volt_pl, al_curr_pl, aw_volt_pl, aw_curr_pl, 
              plot_title = "Mechanical Simulation (A = $(resp_ampl)V)",
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
 SAVING FIGURES
 ===============================================================#

# savefig(tot_pl,
#         "$srcdir/output/ampl_$(resp_ampl)_tspan_$(tspan).png")

display(tot_pl)
