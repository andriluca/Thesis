#                  _          _ _
#  _ __ ___   __ _(_)_ __    (_) |
# | '_ ` _ \ / _` | | '_ \   | | |
# | | | | | | (_| | | | | |_ | | |
# |_| |_| |_|\__,_|_|_| |_(_)/ |_|
#                          |__/   

## Gestione delle dipendenze.
using Pkg

## Definizione paths di interesse.
### Percorso della repository scaricata da GitHub.
repodir = "/home/luca/Thesis" # <- CHANGE IT!
### Percorso dei codici sorgente per Julia.
srcdir  = "$repodir/src"      # <- LEAVE IT AS IS!
Pkg.activate(repodir)

## Inclusione libreria del modello morfometrico.
### L'input (i.e. la struttura del polmone) viene generato eseguendo
### lo script bash in `$srcdir/cir2jl/cir2jl`, si consulti il README.
include("$srcdir/lib/AWTree.jl")

## Esecuzione della simulazione.
include("$srcdir/util/simulation.jl")

## Generazione dei grafici.
include("$srcdir/util/graphs.jl")
include("$srcdir/util/graphs_trigger.jl")
