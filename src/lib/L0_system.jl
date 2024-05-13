@mtkmodel Generator begin
    @components begin
        src = Square(frequency = 1)
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

@mtkbuild system = System()
prob = ODEProblem(system, [], (0, 10))
# sol = solve(prob, Rodas3())
# sol = solve(prob, Rodas5())
# sol = solve(prob, QBDF1())
# sol = solve(prob, QNDF1())
sol = solve(prob, Rodas4P2())
# sol = solve(prob, FBDF())
plot(sol, idxs = [system.L.IAD.out.v
                  system.L.IBL.out.v
                  system.L.IAH.out.v
                  system.L.IAF.out.v],
     xlims = (0, 6),
     ylims = (-1.5, 1.5))

plot(sol, idxs = [system.L.IBB.out.v
                  system.L.IBA.out.v
                  system.L.IAE.out.v
                  system.L.IAG.out.v
                  system.L.IAI.out.v],
     xlims = (0, 6),
     ylims = (-1.5, 1.5))
