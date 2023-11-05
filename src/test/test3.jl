using ModelingToolkit, DifferentialEquations, Plots; gr()

function squarewave(x::Real, θ::Real)
    # x: sample number, θ: duty cycle
    ifelse(x % (2π) < 2π * θ, 1.0, 0.0)
end

freq = 50

@variables t

@mtkmodel AWTREE begin
    # Parameters and (Dependent) variables declarations.
    @parameters begin
        R1     # Parameters
        R2
        R3
        R4
        R5
        R6
        R7
        C1
        C2
        C3
        C4
        C5
        C6
        C7
    end
    @variables begin
        f(t)   # Input function (square-wave, sine-wave, constant)
        y1(t)  # Dependent variables
        y2(t)
        y3(t)
        y4(t)
        y5(t)
        y6(t)
        y7(t)
    end
    begin
        D = Differential(t)
    end
    @equations begin
        # Input function definition
        f ~ squarewave(2*pi*freq*t, .5) # Square wave
#        f ~ sin(2*pi*t) # Sine wave
#        f ~ 5 # Constant term
        
        # Equations definition
        # der = (in - out) /    τ
        D(y1) ~ ( f - y1) / (R1 * C1)
        D(y2) ~ (y1 - y2) / (R2 * C2)
        D(y3) ~ (y2 - y3) / (R3 * C3)
        D(y4) ~ (y2 - y4) / (R4 * C4)
        D(y5) ~ (y1 - y5) / (R5 * C5)
        D(y6) ~ (y5 - y6) / (R6 * C6)
        D(y7) ~ (y5 - y7) / (R7 * C7)
    end
end

# Building the model: Parameters and conditions.
@mtkbuild awtree = AWTREE()
prob = ODEProblem(awtree,
                   # Initial conditions
                   [awtree.y1 => 0.0, awtree.y2 => 0.0,
                    awtree.y3 => 0.0, awtree.y4 => 0.0,
                    awtree.y5 => 0.0, awtree.y6 => 0.0,
                    awtree.y7 => 0.0,
                    ],
                   # Time span [s]
                   (0.0, 100.0e-3),
                   # Parameters [Ω] or [F]
                   [awtree.R1 => 10.0,      awtree.C1 => 4.0e-4,
                    awtree.R2 => 2.0,       awtree.C2 => 4.0e-4,
                    awtree.R3 => 3.0,       awtree.C3 => 4.0e-4,
                    awtree.R4 => 4.0,       awtree.C4 => 4.0e-4,
                    awtree.R5 => 1.0,       awtree.C5 => 4.0e-4,
                    awtree.R6 => 10.0,      awtree.C6 => 4.0e-4,
                    awtree.R7 => 11.0,      awtree.C7 => 4.0e-4,
                    ]
                   )

# Solving the differential equations.
#                 Solver
sol = solve(prob, Tsit5())

# Plotting the solutions
p = plot(sol, idxs=[3,4,6,7], title="Tensioni ai nodi terminali", xlabel="t [s]", ylabel="Tensione [V]")

# Save Plots in png/svg files
# png("myplot.svg")
# Plots.svg(p, "myplot.svg")
# plot(sol, idxs=[1,2,5])
