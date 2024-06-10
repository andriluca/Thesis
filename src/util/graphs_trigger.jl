#                        _            _        _                        _ _
#   __ _ _ __ __ _ _ __ | |__  ___   | |_ _ __(_) __ _  __ _  ___ _ __ (_) |
#  / _` | '__/ _` | '_ \| '_ \/ __|  | __| '__| |/ _` |/ _` |/ _ \ '__|| | |
# | (_| | | | (_| | |_) | | | \__ \  | |_| |  | | (_| | (_| |  __/ | _ | | |
#  \__, |_|  \__,_| .__/|_| |_|___/___\__|_|  |_|\__, |\__, |\___|_|(_)/ |_|
#  |___/          |_|            |_____|         |___/ |___/         |__/

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
# xlims_al = (0, .1)
xlims_al = tspan
### Airways
# xlims_aw = (0, .1)
xlims_aw = tspan

## Limiti su y
### Alveoli
ylims_al = (0, 1)
### Airways
ylims_aw = (0, 1)

l = (5, 1)
# l = @layout [a b; c d; e;]

## Alveoli
IAE_pl = plot(sol,
    idxs=[
        system.L.IAE.i1.trigger_in,
        system.L.IAE.i1.trigger_out,
        system.L.IAE.i1.n∫i,
    ],
    title="IAE",
    xlabel="t [s]", ylabel="",
    label=["Trigger_in" "Trigger_out" "Integrale corrente"],
    legend=:bottomright,
    xlims=xlims_al,
    ylims=ylims_al,
    dpi=300,
    margin=1cm,
    size=(600, 600))

IAI_pl = plot(sol,
    idxs=[
        system.L.IAI.i1.trigger_in,
        system.L.IAI.i1.trigger_out,
        system.L.IAI.i1.n∫i,
    ],
    title="IAI",
    xlabel="t [s]", ylabel="",
    label=["Trigger_in" "Trigger_out" "Integrale corrente"],
    legend=:bottomright,
    xlims=xlims_al,
    ylims=ylims_al,
    dpi=300,
    margin=1cm,
    size=(600, 600))

IBB_pl = plot(sol,
    idxs=[
        system.L.IBB.i1.trigger_in,
        system.L.IBB.i1.trigger_out,
        system.L.IBB.i1.n∫i,
    ],
    title="IBB",
    xlabel="t [s]", ylabel="",
    label=["Trigger_in" "Trigger_out" "Integrale corrente"],
    legend=:bottomright,
    xlims=xlims_al,
    ylims=ylims_al,
    dpi=300,
    margin=1cm,
    size=(600, 600))

IAG_pl = plot(sol,
    idxs=[
        system.L.IAG.i1.trigger_in,
        system.L.IAG.i1.trigger_out,
        system.L.IAG.i1.n∫i,
    ],
    title="IAG",
    xlabel="t [s]", ylabel="",
    label=["Trigger_in" "Trigger_out" "Integrale corrente"],
    legend=:bottomright,
    xlims=xlims_al,
    ylims=ylims_al,
    dpi=300,
    margin=1cm,
    size=(600, 600))

IBA_pl = plot(sol,
    idxs=[
        system.L.IBA.i1.trigger_in,
        system.L.IBA.i1.trigger_out,
        system.L.IBA.i1.n∫i,
    ],
    title="IBA",
    xlabel="t [s]", ylabel="",
    label=["Trigger_in" "Trigger_out" "Integrale corrente"],
    legend=:bottomright,
    xlims=xlims_al,
    ylims=ylims_al,
    dpi=300,
    margin=1cm,
    size=(600, 600))

al_trig_pl = plot(IAE_pl, IAI_pl, IBB_pl, IAG_pl, IBA_pl,
    plot_title="Simulazione [Alveoli] (A = $(resp_ampl)V)",
    dpi=300,
    layout=l,
    size=(1920, 1080))

## Airways

IBL_pl = plot(sol,
    idxs=[
        system.L.IBL.i1.trigger_in,
        system.L.IBL.i1.trigger_out,
        system.L.IBL.i1.n∫i,
    ],
    title="IBL",
    xlabel="t [s]", ylabel="",
    label=["Trigger_in" "Trigger_out" "Integrale corrente"],
    legend=:bottomright,
    xlims=xlims_aw,
    ylims=ylims_aw,
    dpi=300,
    margin=1cm,
    size=(600, 600))

IAH_pl = plot(sol,
    idxs=[
        system.L.IAH.i1.trigger_in,
        system.L.IAH.i1.trigger_out,
        system.L.IAH.i1.n∫i,
    ],
    title="IAH",
    xlabel="t [s]", ylabel="",
    label=["Trigger_in" "Trigger_out" "Integrale corrente"],
    legend=:bottomright,
    xlims=xlims_aw,
    ylims=ylims_aw,
    dpi=300,
    margin=1cm,
    size=(600, 600))

IAF_pl = plot(sol,
    idxs=[
        system.L.IAF.i1.trigger_in,
        system.L.IAF.i1.trigger_out,
        system.L.IAF.i1.n∫i,
    ],
    title="IAF",
    xlabel="t [s]", ylabel="",
    label=["Trigger_in" "Trigger_out" "Integrale corrente"],
    legend=:bottomright,
    xlims=xlims_aw,
    ylims=ylims_aw,
    dpi=300,
    margin=1cm,
    size=(600, 600))

IAD_pl = plot(sol,
    idxs=[
        system.L.IAD.i1.trigger_in,
        system.L.IAD.i1.trigger_out,
        system.L.IAD.i1.n∫i,
    ],
    title="IAD",
    xlabel="t [s]", ylabel="",
    label=["Trigger_in" "Trigger_out" "Integrale corrente"],
    legend=:bottomright,
    xlims=xlims_aw,
    ylims=ylims_aw,
    dpi=300,
    margin=1cm,
    size=(600, 600))

l = (4, 1)
# l = @layout [a b; c d]

aw_trig_pl = plot(IAD_pl, IAF_pl, IAH_pl, IBL_pl,
    plot_title="Simulazione [Airways] (A = $(resp_ampl)V)",
    dpi=300,
    layout=l,
    size=(1920, 1080))

#===============================================================
 SALVATAGGIO FIGURE
 ===============================================================#

savefig(al_trig_pl,
        "$srcdir/output/trig_integ_al_$(resp_ampl)_tspan_$(tspan).png")
savefig(aw_trig_pl,
        "$srcdir/output/trig_integ_aw_$(resp_ampl)_tspan_$(tspan).png")

display(al_trig_pl)
display(aw_trig_pl)
