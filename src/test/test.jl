using Modia
using SignalTablesInterface_GLMakie
include("$(Modia.modelsPath)/Electric.jl")
usePlotPackage("GLMakie")

Pendulum = Model(
   L = 0.8u"m",
   m = 1.0u"kg",
   d = 0.5u"N*m*s/rad",
   g = 9.81u"m/s^2",
   phi = Var(init = 1.57*u"rad"),
   w   = Var(init = 0u"rad/s"),
   equations = :[
          w = der(phi)
        0.0 = m*L^2*der(w) + d*w + m*g*L*sin(phi)
          r = [L*cos(phi), -L*sin(phi)]
   ]
)

pendulum1 = @instantiateModel(Pendulum)
simulate!(pendulum1, Tsit5(), stopTime = 10.0u"s", log=true)

showInfo(pendulum1)  # print info about the result
writeSignalTable("pendulum1.json", pendulum1, indent=2, log=true)

@usingModiaPlot   # Use plot package defined with
                  # ENV["SignalTablesPlotPackage"] = "XXX" or with 
                  # usePlotPackage("XXX")
plot(pendulum1, [("phi", "w"); "r"], figure = 1)
