module ParticleConfigs

export ParticleConfig, default_config

using Engine # for Color

mutable struct ParticleConfig 
    # general parameters
    width::Int
    height::Int
    n::Int # number of particles

    # World (i.e., pheromone diffusion) parameters
    μ::Float64
    λ::Float64

    # Particle parameters (general)
    pheromone_strength::Float64
    pheromone_max::Float64 # maximum pheromones in the world (note: 1 fully saturates the output color)
    sensor_length::Int # in pixels
    sensor_angle::Float64
    speed::Float64
    varspeed::Float64
    rot_speed::Float64

    # Particle parameters (colors)
    colors::NTuple{3, Color} # colors for the particles
    pheromone_colors::NTuple{3, Color} # colors for the pheromones
    pheromone_attractions::NTuple{3, Color} # colors for the attractions
end

default_colors = (COLOR_RED, COLOR_GREEN, COLOR_BLUE)
default_pheromone_colors = default_colors
default_attractions = (Color(127,255,0), Color(0,127,255), Color(255,0,127))

default_config = ParticleConfig(1920, 1080, 2^18, 5, 0.5, 1/4, 1, 60, π/6, 160, 60, 5π, default_colors, default_pheromone_colors, default_attractions)



# Here follow several nice configs for particles.jl

# Like in the vid kinda
width = 1080; height = 1080; # width, height is actually more abstractly worksize_x, worksize_y
n = 2^19 # number of particles

μ = 5
λ = 0.5

r = 1
pheromone_strength = 1
sensor_length = 11r # in pixels
sensor_angle = π/8
speed = 0.15
varspeed = 0.05
rot_speed = 5π/r

## Like in the vid kinda
width = 1440; height = 1440; # width, height is actually more abstractly worksize_x, worksize_y
n = 2^20 # number of particles

μ = 5
λ = 0.5

pheromone_strength = 0.2 # up to 1.0
sensor_length = 16 # in pixels
sensor_angle = π/8
speed = 0.15
varspeed = 0.05
rot_speed = 5π

## Like in the vid kinda
width = 1080; height = 1080; # width, height is actually more abstractly worksize_x, worksize_y
n = 2^19 # number of particles

μ = 5
λ = 0.1

r = 1
pheromone_strength = 1
sensor_length = 11r # in pixels
sensor_angle = π/8
speed = 0.15
varspeed = 0.05
rot_speed = 5π/r

##
width = 1080; height = 1080; # width, height is actually more abstractly worksize_x, worksize_y
n = 2^19 # number of particles

μ = 5
λ = 0.1

r = 1
pheromone_strength = 1
sensor_length = 11r # in pixels
sensor_angle = π/6
speed = 0.15
varspeed = 0.05
rot_speed = 5π/r

## uneventful then suddenly interesting
width = 1080; height = 1080; # width, height is actually more abstractly worksize_x, worksize_y
n = 2^19 # number of particles

μ = 5
λ = 0.25

pheromone_strength = 1
sensor_length = 12 # in pixels
sensor_angle = π/6
speed = 162
varspeed = 54
rot_speed = 5π

## Spaghetti
# model parameters
width = 1080; height = 1080; # width, height is actually more abstractly worksize_x, worksize_y
n = 2^19 # number of particles

μ = 5
λ = 0.5

pheromone_strength = 0.02
sensor_length = 10 # in pixels
sensor_angle = π/4
speed = 0.15
varspeed = 0.05
rot_speed = 1.5π

# model parameters (better than previous)
width = 1080; height = 1080; # width, height is actually more abstractly worksize_x, worksize_y
n = 2^19 # number of particles

μ = 5
λ = 0.25

pheromone_strength = 0.02
sensor_length = 10 # in pixels
sensor_angle = π/4
speed = 0.15
varspeed = 0.05
rot_speed = 1.5π

## long term behaviour based on stable small circular patterns
width = 1080; height = 1080; # width, height is actually more abstractly worksize_x, worksize_y
n = 2^19 # number of particles

μ = 5
λ = 0.25

pheromone_strength = 1
sensor_length = 11 # in pixels
sensor_angle = π/6
speed = 0.15
varspeed = 0.05
rot_speed = 4.5π

######
pheromone_strength = 0.001 # how much pheromone each particle adds to the world 
pheromone_max = 1 # maximum pheromones in the world (note: 1 fully saturates the output color)
sensor_length = 12 # in cells
sensor_angle = π/6
speed = 160 # in cells per second
varspeed = 60 # in cells per second
rot_speed = 5π*2 # 5π/2 

######

# width = 1920; height = 1080; # width, height is actually more abstractly worksize_x, worksize_y
# n = 2^20 # number of particles

# μ = 5
# λ = 0.1

# r = 1
# pheromone_strength = 0.1
# sensor_length = 16r # in pixels
# sensor_angle = π/8
# speed = 160
# varspeed = 50
# rot_speed = 5π/r


end