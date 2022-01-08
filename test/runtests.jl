using Pkg

Pkg.activate("..")
Pkg.instantiate()

include("crypto_tests.jl")
include("colonyruntime_tests.jl")
