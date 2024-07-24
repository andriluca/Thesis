#      _                 _       _   _                _ _
#  ___(_)_ __ ___  _   _| | __ _| |_(_) ___  _ __    (_) |
# / __| | '_ ` _ \| | | | |/ _` | __| |/ _ \| '_ \   | | |
# \__ \ | | | | | | |_| | | (_| | |_| | (_) | | | |_ | | |
# |___/_|_| |_| |_|\__,_|_|\__,_|\__|_|\___/|_| |_(_)/ |_|
#                                                  |__/   

using DifferentialEquations, OrdinaryDiffEq

# Model Instantiation
print("Model Instantiation...\n")
@time @mtkbuild system = System()
# include("$srcdir/input/Parameters.jl")

# prob = ODEProblem(system, ps, tspan)
print("ODEProblem...\n")
prob = ODEProblem(system, [], tspan, [])

print("Mechanical Simulation...\n")
@time sol = solve(prob,
                  reltol = 1.0e-4,
                  # abstol = 1.0e-7,
                  # Rodas4(),
                  # Rodas5(),
                  # QBDF1(),
                  QNDF1(),
                  # FBDF(),
                  # Rodas4P2(),
                  # dtmax = 1.0e-5
                  )
