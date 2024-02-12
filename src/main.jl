#                  _          _ _
#  _ __ ___   __ _(_)_ __    (_) |
# | '_ ` _ \ / _` | | '_ \   | | |
# | | | | | | (_| | | | | |_ | | |
# |_| |_| |_|\__,_|_|_| |_(_)/ |_|
#                          |__/   

## Gestione delle dipendenze
using Pkg

## Definizione paths di interesse.
repodir = "/home/luca/Thesis"
srcdir  = "$repodir/src"
Pkg.activate(repodir)

## Definizione parametri.
### Generatore (di onda quadra "smussata", aka artan()).
# resp_freq   = 1.0       # Hz
resp_ampl   = 1.0        # V
tspan       = (0, 4)      # s

## Inclusione componenti inferiori (i.e. CIDResistor, CIDInductor) e
## superiori (i.e. Airway, Alveolus).
include("$srcdir/lib/AWTree.jl")

## (L'input (i.e. la struttura circuitale) viene generato eseguendo lo
## script bash in `$srcdir/cir2jl/cir2jl/`).
## Importazione dell'input (i.e. modello dei componenti superiori e
## delle loro connessioni).
include("$srcdir/input/System.jl")
# Istanzio il modello di polmone.
@mtkbuild system = System()
include("$srcdir/input/Parameters.jl")

## Esecuzione della simulazione.
include("$srcdir/util/simulation.jl")

## Generazione dei grafici.
include("$srcdir/util/graphs.jl")
include("$srcdir/util/graphs_trigger.jl")
