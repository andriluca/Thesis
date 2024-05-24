#      _                 _       _   _                _ _
#  ___(_)_ __ ___  _   _| | __ _| |_(_) ___  _ __    (_) |
# / __| | '_ ` _ \| | | | |/ _` | __| |/ _ \| '_ \   | | |
# \__ \ | | | | | | |_| | | (_| | |_| | (_) | | | |_ | | |
# |___/_|_| |_| |_|\__,_|_|\__,_|\__|_|\___/|_| |_(_)/ |_|
#                                                  |__/   

#================================================================
 DICHIARAZIONE PARAMETRI DI SIMULAZIONE
 ================================================================#

# Questi sono i pacchetti per effettuare la simulazione.
using DifferentialEquations, OrdinaryDiffEq

# Istanzio il modello di polmone.
@mtkbuild system = System()
# include("$srcdir/input/Parameters.jl")

## genero un problema da risolvere nell'intervallo 0-10s.
# prob = ODEProblem(system, ps, tspan)
tspan       = (0, 4)      # s
prob = ODEProblem(system, [], tspan, [])

## modifico le tolleranze della soluzione.
sol = solve(prob,
#            reltol = 1.0e-7,
            abstol = 1.0e-7,
            # Rodas4(),
            # Rodas5(),
            # QBDF1(),
            # QNDF1(),
            # FBDF(),
            Rodas4P2(),
            dtmax = 1.0e-5
            )
