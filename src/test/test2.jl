using Modia, Waveforms
using SignalTablesInterface_GLMakie
include("$(Modia.modelsPath)/AllModels.jl")
usePlotPackage("GLMakie")
@usingModiaPlot

SquareVoltage = SignalVoltage | Model(
    #                           frequency           phase
    v=:(squarewave( (2*3.14u"rad"*1.0u"Hz"*time + (0/2)*u"rad*Hz*s") *u"(rad*s*Hz)^-1") *u"V")
)

Block = Model(
    V = input,
    R = Resistor,
    C = Capacitor,
    ground = Ground,
    connect = :[
        (V, R.p)
        (R.n, C.p)
        (C.n, ground.p)
    ]
)

System = Model(
    V = SquareVoltage,
    B = Block,
    connect = :[
        (V, B.V)
    ]
)

system = @instantiateModel(System)
simulate!(system, Tsit5(), stopTime = 0.5u"s")
