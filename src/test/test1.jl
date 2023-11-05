using Modia, Waveforms
using SignalTablesInterface_GLMakie
include("$(Modia.modelsPath)/AllModels.jl")
usePlotPackage("GLMakie")
@usingModiaPlot


# Sinusoidal voltage source
SquareVoltage = OnePort | Model( V = 1.0u"V", f = 1.0u"Hz", equations = :[ v = V*squarewave(2*3.14*f*time) ] )
SineVoltage = OnePort | Model( V = 1.0u"V", f = 1.0u"Hz", equations = :[ v = V*sin(2*3.14*f*time) ] )

EmptyBlock = Model(
    R1 = missing,
    C1 = missing,
    y = output | Var(:x),
    equations = :[]
)

AWTree = Model(
    R1 = Resistor | Map(R=5.0u"Ω"),
    R2 = Resistor | Map(R=10.0u"Ω"),
    R3 = Resistor | Map(R=15.0u"Ω"),
    R4 = Resistor | Map(R=20.0u"Ω"),
    R5 = Resistor | Map(R=25.0u"Ω"),
    C1 = Capacitor | Map(C=5.0u"F"),
    C2 = Capacitor | Map(C=5.0u"F"),
    C3 = Capacitor | Map(C=5.0u"F"),
    C4 = Capacitor | Map(C=5.0u"F"),
    C5 = Capacitor | Map(C=5.0u"F"),
    V = SineVoltage | Map(V=5.0u"V", f=1.5u"Hz"),
    ground = Ground,
    connect = :[
        (V.p, R1.p)
        (R1.n, C1.p, R2.p, R4.p)
        (R2.n, C2.p, R3.p)
        (R4.n, C4.p, R5.p)
        (R3.n, C3.p)
        (R5.n, C5.p)
        (ground.p, V.n, C1.n, C2.n, C3.n, C4.n, C5.n)
    ]
)

Block = Model(
    R = Resistor,
    C = Capacitor,
    ground = Ground,
    u = input,
    y = output,
    connect = :[
        (u.p, R.p)
        (R.n, C.p)
        (C.n, ground)
        (C.p, y.p)
    ]
)

System = Model(
    V = ConstantVoltage | Map(V=1.0u"V"),
    B1 = Block | Map(R = 1.0u"Ω", C=2.0u"F"),
    ground = Ground,
    connect = :[
        (V.p, B1.u)
        (V.n, ground)
    ]
)

Block = Model(
    r = missing,
    c = 1.0u"F",
    R = Resistor | Map(R=:r),
    C = Resistor | Map(C=:c),
    u = input,
    y = output | C.p
)

AWTree1 = Model(
    
)

awtree = @instantiateModel(AWTree)
simulate!(awtree, Tsit5(), stopTime = 3)
showInfo(awtree)  # print info about the result

system = @instantiateModel(System)
simulate!(system, Tsit5(), stopTime = 3)
showInfo(system)  # print info about the result

plot(system, "B1.C.p")

plot(awtree, ["V.v", "C1.v", "C2.v", "C3.v", "C4.v", "C5.v"],figure=1)

#=
InitialBlock = EmptyBlock | Map(R1 = 0.4, C1 = 10, equations = :[u = inputSignal(time/u"s"), R1*C1*der(x) + x = u])

initialblock = @instantiateModel(InitialBlock)

Block = EmptyBlock | Map(R1 = 10, C1 = 20, connect = :[(R1.p, initialblock.y)
                                                       (R1.n, C1.p)
                                                       (C1.n, ground.p)])

block = @instantiateModel(Block)

simulate!(initialblock, Tsit5(), stopTime = 50.0u"s", log=true)
simulate!(, Tsit5(), stopTime = 50.0u"s", log=true)

@usingModiaPlot
plot(initialblock, ["y"], figure=3)
=#


Filter = Model(
    V = SignalVoltage,
    R = Resistor | Map(R=0.5u"Ω"),
    C = Capacitor | Map(C=2.0u"F"),
 #   V = ConstantVoltage | Map(V=10.0u"V"),
    ground = Ground,
    connect = :[
      (V.p, R.p)
      (R.n, C.p)
      (C.n, V.n, ground.p)
    ]
)

System = Filter | Model(
    V = ConstantVoltage | Map(V=1.0u"V")
)

# Squarewave
Squarewave = Model(
    f = 20u"Hz",
    V = SignalVoltage | Map(v=:(squarewave(2*3.14u"rad"*f*time *u"(rad*s*Hz)^-1") *u"V"))
)

Filter = Model(
    u = input | ConstantVoltage | Map(V=1.0u"V"),
    R = Resistor | Map(R=0.5e-2u"Ω"),
    C = Capacitor | Map(C=2.0u"F"),
    ground = Ground,
    connect = :[
        (u.p, R.p)
        (R.n, C.p)
        (C.n, u.n, ground.p)
    ]
)

System = Model(
    V = SignalVoltage | Map(v=:(squarewave(2*3.14u"rad"*10u"Hz"*time *u"(rad*s*Hz)^-1") *u"V")),
    F1 = Filter,
    ground = Ground,
    connect = :[
        (V.p, F1.u)
        (V.n, ground)
    ]

)

V = SignalVoltage | Map(v=:(squarewave(2*3.14u"rad"*1u"Hz"*time *u"(rad*s*Hz)^-1") *u"V"))

SquareVoltage = SignalVoltage | Model(
    #                           frequency           phase
    v=:(squarewave( (2*3.14u"rad"*1.0u"Hz"*time + (0/2)*u"rad*Hz*s") *u"(rad*s*Hz)^-1") *u"V")
)



System = Model(
    RC1 = Filter | Map(u=)
)

AWTree = Model(
    R1 = Resistor | Map(R=3.109214e+02u"Ω"),
    R2 = Resistor | Map(R=4.012746e+02u"Ω"),
    R3 = Resistor | Map(R=4.759710e+02u"Ω"),
    R4 = Resistor | Map(R=2.282920e+02u"Ω"),
    R5 = Resistor | Map(R=2.017423e+02u"Ω"),
    R6 = Resistor | Map(R=3.097440e+01u"Ω"),
    R7 = Resistor | Map(R=3.554331e+01u"Ω"),
    C1 = Capacitor | Map(C=2.462271e-07u"F"),
    C2 = Capacitor | Map(C=2.461359e-07u"F"),
    C3 = Capacitor | Map(C=2.460874e-07u"F"),
    C4 = Capacitor | Map(C=2.463766e-07u"F"),
    C5 = Capacitor | Map(C=2.464514e-07u"F"),
    C6 = Capacitor | Map(C=5.722034e-10u"F"),
    C7 = Capacitor | Map(C=9.126539e-10u"F"),
    V = SquareVoltage,
    ground = Ground,
    connect = :[
        (V.p, R1.p)
        (R1.n, C1.p, R2.p, R4.p)
        (R2.n, C2.p, R3.p, R6.p)
        (R4.n, C4.p, R5.p, R7.p)
        (R3.n, C3.p)
        (R5.n, C5.p)
        (R6.n, C6.p)
        (R7.n, C7.p)
        (ground.p, V.n, C1.n, C2.n, C3.n, C4.n, C5.n, C6.n, C7.n)
    ]
)

system = @instantiateModel(AWTree)
simulate!(system, Tsit5(), stopTime = 0.5u"s")
plot(system, ["u.v", "C.v", "C.i"])
plot(system, ["v"])
plot(system, ["C1.i"])
showInfo(system)  # print info about the result
