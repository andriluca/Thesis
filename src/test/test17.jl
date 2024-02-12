# 1. Importare `System.csv`

using CSV, DataFrames
df = CSV.read("/home/luca/Thesis/src/input/System.csv", DataFrame);

# 2. Separare `df_alveoli` e `df_airways`
df_alveoli = df[df.Type .== "alveolus", :]
df_airways = df[df.Type .== "airway", :]

# 3. Istanziare un modello semplice (ad esempio utilizzando solo resistenze Ra)

vars = [Num("R_$i") for i in df_airways.Name]
vals = [i for i in df_airways.Name]
dic = vars .=> vals


# 3a. Usare serialize per salvare e leggere condizioni iniziali, funziona

using ModelingToolkit, Serialization

pair = (1, ModelingToolkit.num(2))

# Salvataggio in un file binario
open("pair.bin", "w") do file
    serialize(file, pair)
end

# Lettura dal file binario
loaded_pair = open("pair.bin", "r") do file
    deserialize(file)
end
