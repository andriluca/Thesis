#= _     ___      ____            _
  | |   / _ \ _  / ___| _   _ ___| |_ ___ _ __ ___
  | |  | | | (_) \___ \| | | / __| __/ _ \ '_ ` _ \
  | |__| |_| |_   ___) | |_| \__ \ ||  __/ | | | | |
  |_____\___/(_) |____/ \__, |___/\__\___|_| |_| |_|
                        |___/

                '
               / \
              /   \                   _
             / lvl \             _.-'` |________________////  - Generatore
            /   0   \             `'-._|                \\\\  - Sistema (simulazione)
           /         \
          /===========\
         /             \
        /               \
       /                 \
      /         ↓         \
     /        order        \
    /                       \
   /                         \
  /                           \
 /=============================\

Questo livello incorpora un modello di generatore di tensione a cui è
connesso il modello polmonare implementato per realizzare il sistema
tramite cui è possibile avviare la simulazione.  Per testare parametri
di sistema è consigliato l'utilizzo di questo livello.  =#

# Parametri di simulazione

# resp_freq      = 1.0     # Hz
resp_ampl      = 10      # V
## Sotto soglia di alcuni alveoli.
# resp_ampl      = 8   # V
resp_start     = 1.0     # s
resp_duration  = Inf     # s
tspan          = (0, 5)  # s

@mtkmodel Generator begin
    @components begin
        # src = Square(frequency = resp_freq,
        #              amplitude = resp_ampl)
        src = Step(height = resp_ampl,
                   start_time = resp_start,
                   duration = resp_duration,
                   # smooth = 1e-4,
                   )
        gen = Voltage()
        gnd = Ground()
        out = Pin()
    end
    @equations begin
        connect(src.output, gen.V)
        connect(     gen.p,   out)
        connect(     gen.n, gnd.g)
    end
end

@mtkmodel System begin
    @components begin
        G = Generator()
        L = Lungs()
    end
    @variables begin
        trigger_in(t) = false
    end
    @equations begin
        D(trigger_in) ~ 0
        L.trigger_in  ~ trigger_in
        connect(G.out, L.in)
    end
    @continuous_events begin
        [t ~ resp_start] => [trigger_in ~ true]
    end
end
