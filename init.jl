# run at start
cd("C:\\Users\\Andreas\\BarelEngine")
push!(LOAD_PATH, pwd())
using Pkg
Pkg.activate("./env")  

using Statistics # stuff such as mean, var, cov, etc
using LinearAlgebra
using Printf
#using WebIO
#using Interact
using Revise

println("initalization complete.")
