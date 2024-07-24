#= _     _____     ____                                             _
  | |   |___ /_   / ___|___  _ __ ___  _ __   ___  _ __   ___ _ __ | |_ ___
  | |     |_ (_) | |   / _ \| '_ ` _ \| '_ \ / _ \| '_ \ / _ \ '_ \| __/ __|
  | |___ ___) |  | |__| (_) | | | | | | |_) | (_) | | | |  __/ | | | |_\__ \
  |_____|____(_)  \____\___/|_| |_| |_| .__/ \___/|_| |_|\___|_| |_|\__|___/
                                      |_|

                '
               / \
              /   \
             /     \
            /       \
           /         \
          /           \
         /      ↑      \
        /     order     \
       /                 \
      /                   \
     /                     \
    /=======================\           _                       - Inductors
   /           lvl           \     _.-'` |________________////  - Resistors
  /             3             \     `'-._|                \\\\  - Capacitors
 /=============================\                                - Diodes
                                                                - Switches

Simple electrical components used to build modules.             =#

# Variable components
@mtkmodel CIDInductor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        La, [description = "Module Inductance when air-filled."]
        Lb, [description = "Module Inductance delta (liquid - air)."]
    end
    @variables begin
        # Variables and their default values.
        n∫i(t) = 0, [description = "Normalized Current Integral."]
        L(t)   = La + Lb, [description = "Variable inductance."]
    end
    @equations begin
        # Inductance in function of the normalized integral.
        L    ~ La + Lb * (1 - n∫i)
        # Device equation.
        D(i) ~ (1 / L) * v
    end
end

@mtkmodel CIDResistor begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ra, [description = "Module Resistance when air-filled."]
        Rb, [description = "Module Resistance delta (liquid - air)."]
    end
    @variables begin
        # Variables and their default values.
        n∫i(t) = 0, [description = "Normalized Current Integral."]
        R(t)   = Ra + Rb, [description = "Variable resistance."]
    end
    @equations begin
        # Resistance in function of the normalized integral.
        R ~ Ra + Rb * (1 - n∫i)
        # Device equation.
        v ~ R * i
    end
end

exlin(x, max_x) = ifelse(x > max_x, exp(max_x)*(1 + x - max_x), exp(x))

@mtkmodel old_Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Ids     = 1e-6, [description = "Reverse-bias current."]
        max_exp = 15,   [description = "Value after which linearization is applied."]
        R       = 1e8,  [description = "Diode Resistance."]
        vin_th  = 1e-3, [description = "Threshold voltage."]
        k       = 1e3,  [description = "Speed of exponential."]
    end
    @equations begin
        i ~ Ids * (exlin(k * (v - vin_th) / (vin_th), max_exp) - 1) + (v / R)
    end
end

@mtkmodel Diode begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        vin_th = .7
    end
    @variables begin
        # Variables and their default values.
        trigger_in(t)  = false
        trigger_out(t) = false
    end
    @equations begin
        # Device equation.
        # v ~ -(trigger_in) * (1 - trigger_out) * vin_th
        v ~ (trigger_in) * (1 - trigger_out) * vin_th
    end
end

@mtkmodel CurrentIntegrator begin
    @parameters begin
        V_FRC = 1, [description = "Volume at FRC."]
        level = 1, [description = "Normalized Fill-up level (0 → empty, 1 → full)."]
    end
    @variables begin
        # Variables and their default values.
        # Integration
        current(t)     = 0.0, [description = "Input current."]
        n∫i(t)         = 0.0, [description = "Output Normalized (by V_FRC) Current Integral.",
                               output = true]
        # Timing
        trigger_in(t)  = 0.0, [description = "Filling-up status of previous module."]
        trigger_out(t) = 0.0, [description = "Filling-up status of current module.", output = true]
    end
    @equations begin
        D(n∫i) ~ ifelse((((n∫i < 0) & (current < 0))  # If n∫i is close to being negative,
                         | (n∫i >= level)             # If n∫i is overcoming filling-up threshold,
                         | (trigger_in == false)),    # If previous module isn't filled up yet,
                        0,                         # -> Don't integrate.
                        current / V_FRC)              # -> Integrate.

        D(trigger_out) ~ 0                            # Necessary condition in order to use a callback.
    end
    @continuous_events begin
        [n∫i ~ level] => [trigger_out ~ true]         # When the threshold is reached, raise trigger_out.
    end
end

@mtkmodel Switch begin
    @extend v, i = oneport = OnePort()
    @parameters begin
        Rclosed = 1e-12, [description = "Switch Resistance when Closed"]
        Ropen   = 1e12,  [description = "Switch Resistance when Open"]
    end
    @variables begin
        # Variables and their default values.
        R(t)           = Rclosed, [description = "Switch Resistance"]
        trigger_in(t)  = false,   [description = "Flag: 1 when air fills previous airway completely, 0 otherwise"]
        trigger_out(t) = false,   [description = "Flag: 1 when air fills current airway completely, 0 otherwise"]
    end
    @equations begin
        # Never used
        # R ~ Rclosed + (Ropen - Rclosed) * (1 / 2) * (tanh(k * (1 + (∫i / V_FRC)) + 1))
        # Equazione di Chiara
        # R ~ Rclosed + trigger_in * Ropen * tanh(k*t - 3) - trigger_out * Ropen * tanh(-k*t + 3)
        R ~ Rclosed + (trigger_in - trigger_out) * (Ropen - Rclosed)
        v ~ R * i
    end
end
