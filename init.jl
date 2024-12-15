# run at julia start; to be ran once.
# Tested on Julia 1.10.0
working_directory = @__DIR__
cd(working_directory)
if working_directory ∉ LOAD_PATH
    push!(LOAD_PATH, working_directory) 
end

using Pkg
Pkg.activate("./env")  

using Statistics # stuff such as mean, var, cov, etc
using LinearAlgebra
using Printf
using Revise
