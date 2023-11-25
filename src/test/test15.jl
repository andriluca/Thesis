using CSV
using DataFrames

# Leggere dataframe
file = CSV.File("/home/luca/Thesis/src/input/System.csv")
df = DataFrame(file)
