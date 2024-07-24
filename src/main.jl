#                  _          _ _
#  _ __ ___   __ _(_)_ __    (_) |
# | '_ ` _ \ / _` | | '_ \   | | |
# | | | | | | (_| | | | | |_ | | |
# |_| |_| |_|\__,_|_|_| |_(_)/ |_|
#                          |__/   

## Managing packages.
using Pkg

## Path definitions.
### Local Repository.
repodir = "/home/luca/Thesis" # <- CHANGE IT!
### Julia source path.
srcdir  = "$repodir/src"      # <- LEAVE IT AS IS!
Pkg.activate(repodir)

## Including mechanical model library.
### Input (mechanical parameters) is updated using bash script
### `$srcdir/cir2jl/cir2jl`. Visit `$repodir/README.org` for more
### information.
include("$srcdir/lib/AWTree.jl")

## Start simulation.
include("$srcdir/util/simulation.jl")

## Plotting.
include("$srcdir/util/graphs.jl")
# include("$srcdir/util/graphs_trigger.jl")
include("$srcdir/util/graphs_thesis.jl")
