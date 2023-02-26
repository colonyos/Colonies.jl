using Pkg

Pkg.activate("..")
Pkg.instantiate()

include("crypto_tests.jl")
include("colonies_tests.jl")
