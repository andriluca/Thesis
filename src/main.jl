#                  _          _ _
#  _ __ ___   __ _(_)_ __    (_) |
# | '_ ` _ \ / _` | | '_ \   | | |
# | | | | | | (_| | | | | |_ | | |
# |_| |_| |_|\__,_|_|_| |_(_)/ |_|
#                          |__/   

## Definizione paths di interesse.
homedir = "/home/luca"
srcdir  = "$homedir/Thesis/src"

## Definizione parametri.
### Generatore (di onda quadra "smussata", aka artan()).
resp_freq   = 1.0       # Hz
resp_ampl   = 1.0e-3    # V

## Inclusione componenti inferiori (i.e. CIDResistor, CIDInductor) e
## superiori (i.e. Airway, Alveolus).
include("$srcdir/lib/AWTree.jl")

## (L'input (i.e. la struttura circuitale) viene generato eseguendo lo
## script bash in `$srcdir/cir2jl/cir2jl/`).
## Importazione dell'input (i.e. modello dei componenti superiori e
## delle loro connessioni).
include("$srcdir/input/System.jl")

## Esecuzione della simulazione.
include("$srcdir/util/simulation.jl")

## Generazione dei grafici.
include("$srcdir/util/graphs.jl")

## Salvataggio delle immagini.
savefig(tot_pl,
        "$srcdir/output/volt_curr_non_const_$(resp_ampl)_smooth.png")
