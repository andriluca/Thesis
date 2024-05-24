#= _     ___      ____            _
  | |   / _ \ _  / ___| _   _ ___| |_ ___ _ __ ___
  | |  | | | (_) \___ \| | | / __| __/ _ \ '_ ` _ \
  | |__| |_| |_   ___) | |_| \__ \ ||  __/ | | | | |
  |_____\___/(_) |____/ \__, |___/\__\___|_| |_| |_|
                        |___/

Questo livello incorpora un modello di generatore di tensione a cui è
connesso il modello polmonare implementato per realizzare il sistema
tramite cui è possibile avviare la simulazione.  Per testare parametri
di sistema è consigliato l'utilizzo di questo livello.

                '
               / \\         Livello
              /   \ \          0         - Generatore
             /=====/                     - Sistema (simulazione)


resp_freq   = 1.0        # Hz
resp_ampl   = 1.0        # V

@mtkmodel Generator begin
    @components begin
        src = Square(frequency = resp_freq,
                     amplitude = resp_ampl)
        gen = Voltage()
        gnd = Ground()
        out = Pin()
    end
    @equations begin
        connect(src.output, gen.V)
        connect(gen.p, out)
        connect(gen.n, gnd.g)
    end
end

@mtkmodel System begin
    @components begin
        G = Generator()
        L = Lungs()
    end
    @equations begin
        connect(G.out, L.in)
    end
end
