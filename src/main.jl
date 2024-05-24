#                  _          _ _
#  _ __ ___   __ _(_)_ __    (_) |
# | '_ ` _ \ / _` | | '_ \   | | |
# | | | | | | (_| | | | | |_ | | |
# |_| |_| |_|\__,_|_|_| |_(_)/ |_|
#                          |__/   

## Gestione delle dipendenze.
using Pkg

## Definizione paths di interesse.
repodir = "/home/luca/Thesis" # <- CHANGE IT!
srcdir  = "$repodir/src"
Pkg.activate(repodir)

## Inclusione libreria del modello morfometrico.
include("$srcdir/lib/AWTree.jl")

## (L'input (i.e. la struttura circuitale) viene generato eseguendo lo
## script bash in `$srcdir/cir2jl/cir2jl/`).
## Importazione dell'input (i.e. modello dei componenti superiori e
## delle loro connessioni).

# include("$srcdir/input/System1.jl")
# include("$srcdir/input/System.jl")

## Esecuzione della simulazione.
include("$srcdir/util/simulation.jl")

## Generazione dei grafici.
include("$srcdir/util/graphs.jl")
include("$srcdir/util/graphs_trigger.jl")
