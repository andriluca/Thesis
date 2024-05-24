#     ___        _______                 _ _
#    / \ \      / /_   _| __ ___  ___   (_) |
#   / _ \ \ /\ / /  | || '__/ _ \/ _ \  | | |
#  / ___ \ V  V /   | || | |  __/  __/_ | | |
# /_/   \_\_/\_/    |_||_|  \___|\___(_)/ |_|
#                                     |__/   

#===============================================================
 DIPENDENZE
 ===============================================================#

# Questi sono i pacchetti per effettuare la generazione del modello.
using ModelingToolkit
using ModelingToolkitStandardLibrary.Blocks: Constant, Square, Step, Sine, SISO
using ModelingToolkitStandardLibrary.Electrical

#===============================================================
 INTERPRETAZIONE GERARCHICA DEI MODELLI
 ===============================================================

È possibile interpretare il modello morfometrico come costituito da
componenti gerarchicamente organizzati su più livelli per svolgere
diversi funzioni a seconda del livello di appartenenza.  La gerarchia
ha una struttura piramidale in cui gli strati superiori basano le loro
fondamenta (i.e. sono composti da elementi) negli strati inferiori.
Non solo una suddivisione di compiti ma anche una diversa visibilità
dei parametri: modelli di ordine superiore hanno uno scope più vasto
di quelli di ordine inferiore.

                '
               / \\
              / 0 \ \                     - Livello 0: Simulazione
             /=====/
              /```````/ \
            /=======/    \
           / livello \ '  \
          /     1     \   /               - Livello 1: Polmoni
         /=============\/ ``/\
          /              / '  \
        /===============\   ''  \
       /     livello     \' ' ' /
      /         2          ' '/``/\       - Livello 2: Moduli
     /=====================\/  /  ' \
      /                      /'   ' ' \
    /=======================\  '   '  /
   /         livello         \   '  /
  /             3             \'  /       - Livello 3: Componenti
 /=============================\/
                                                             =#

#===============================================================
 Livello 3: Componenti elettrici ed elettronici
 ===============================================================

Su questo livello esistono componenti elementari (e.g. resistenze,
condensatori, ...) con lo scopo di costituire dei moduli.

          /``````````````````````/\
        /                      /  ' \     - Induttori
      /                      /'   ' ' \   - Resistori
    /=======================\  '   '  /   - Condensatori
   /         livello         \   '  /     - Diodi
  /             3             \'  /       - Interruttori
 /=============================\/                             =#

include("$srcdir/lib/L3_components.jl")

#===============================================================
 Livello 2: Moduli respiratori (Alveoli e Vie Aeree)
 ===============================================================

La complessità aumenta in questo livello, in quanto elementi semplici
vengono connessi a creare veri e propri sottocircuiti che verranno
ripetuti per ottenere la struttura polmonare.

            /``````````````/\
          /              / '  \           - Alveoli
        /===============\   ''  \         - Vie Aeree
       /     livello     \' ' ' /                              
      /         2          ' '/    
     /=====================\/                                 =#

include("$srcdir/lib/L2_modules.jl")


#===============================================================
 Livello 1: Polmoni
 ===============================================================

Questo livello è generato da uno script (`src/cir2jl`).  Sconsigliata
la modifica diretta di questo file se non utilizzando lo script.
Questo livello collega i vari sottocircuiti per creare il modello
(passivo) del polmone.

              /```````/ \                 - Polmoni
            /=======/    \                              
           / livello \ '  \ 
          /     1     \   /     
         /=============\/                                      =#

# TODO: Ridirigere l'output dello script `cir2jl` su `lib/L1_lungs.jl`
include("$srcdir/input/System_prova1.jl")

#===============================================================
 Livello 0: Componenti di simulazione
 ===============================================================

Questo livello incorpora un modello di generatore di tensione a cui è
connesso il modello polmonare implementato per realizzare il sistema
tramite cui è possibile avviare la simulazione.  Per testare parametri
è consigliato l'utilizzo di questo livello.



                '                         - Generatore
               / \\                       - Sistema (per simulazione)
              / 0 \ \
             /=====/                                          =#

include("$srcdir/lib/L0_system.jl")
