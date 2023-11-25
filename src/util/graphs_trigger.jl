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
xlims_al = tspan
### Airways
xlims_aw = tspan

## Limiti su y
### Alveoli
ylims_al = (-2e-6, 2e-6)
### Airways
ylims_aw = (-5e-6, 5e-6)


## Alveoli
IAE_pl = plot(sol,
    idxs=[
        system.IAE.trigger_in,
        system.IAE.trigger_out,
        system.IAE.∫i,
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
        system.IAI.trigger_in,
        system.IAI.trigger_out,
        system.IAI.∫i,
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
        system.IBB.trigger_in,
        system.IBB.trigger_out,
        system.IBB.∫i,
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
        system.IAG.trigger_in,
        system.IAG.trigger_out,
        system.IAG.∫i,
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
        system.IBA.trigger_in,
        system.IBA.trigger_out,
        system.IBA.∫i,
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

l = @layout [a b; c d; e]

al_pl = plot(IAE_pl, IAI_pl, IBB_pl, IAG_pl, IBA_pl,
    plot_title="Simulazione [Alveoli] (A = $(resp_ampl)V)",
    dpi=300,
    layout=l,
    size=(1920, 1080))

## Airways

IBL_pl = plot(sol,
    idxs=[
        system.IBL.trigger_in,
        system.IBL.trigger_out,
        system.IBL.∫i,
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
        system.IAH.trigger_in,
        system.IAH.trigger_out,
        system.IAH.∫i,
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
        system.IAF.trigger_in,
        system.IAF.trigger_out,
        system.IAF.∫i,
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
        system.IAD.trigger_in,
        system.IAD.trigger_out,
        system.IAD.∫i,
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

l = @layout [a b; c d]

aw_pl = plot(IAD_pl, IAF_pl, IAH_pl, IBL_pl,
    plot_title="Simulazione [Airways] (A = $(resp_ampl)V)",
    dpi=300,
    layout=l,
    size=(1920, 1080))

#===============================================================
 SALVATAGGIO FIGURE
 ===============================================================#

savefig(al_pl,
        "$srcdir/output/trig_integ_al_$(resp_ampl)_tspan_$(tspan).png")
savefig(aw_pl,
        "$srcdir/output/trig_integ_aw_$(resp_ampl)_tspan_$(tspan).png")
