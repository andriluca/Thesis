#      _                 _       _   _                _ _
#  ___(_)_ __ ___  _   _| | __ _| |_(_) ___  _ __    (_) |
# / __| | '_ ` _ \| | | | |/ _` | __| |/ _ \| '_ \   | | |
# \__ \ | | | | | | |_| | | (_| | |_| | (_) | | | |_ | | |
# |___/_|_| |_| |_|\__,_|_|\__,_|\__|_|\___/|_| |_(_)/ |_|
#                                                  |__/   

#================================================================
 DICHIARAZIONE PARAMETRI DI SISTEMA E SIMULAZIONE
 ================================================================#

# Istanzio il modello.
@mtkbuild system = System()

## genero un problema da risolvere nell'intervallo 0-10s.
prob = ODEProblem(system, [], tspan)
# [
#     # system.gen.frequency => resp_freq,
#     # system.gen.amplitude => resp_ampl
# ],

## modifico le tolleranze della soluzione.
sol = solve(prob,
#            reltol = 1.0e-7,
#            abstol = 1.0e-7,
            Rodas4(),
            dtmax = 1.0e-4)
