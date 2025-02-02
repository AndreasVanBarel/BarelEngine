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
    pheromones::NTuple{3, Color} # colors for the pheromones
    attractions::NTuple{3, Color} # colors for the attractions
    draw_particles::Bool
end

default_colors = (COLOR_RED, COLOR_GREEN, COLOR_BLUE)
default_pheromones = default_colors
default_attractions = (Color(127,255,0), Color(0,127,255), Color(255,0,127))

default_config = ParticleConfig(1920, 1080, 2^18, 5, 0.5, 1/4, 1, 60, π/6, 160, 60, 5π, default_colors, default_pheromones, default_attractions, false)


###### Configurations ######
# [1] Default Configuration 
# general parameters
width = 1920; height = 1080; 
n = 2^18 # number of particles

# World (i.e., pheromone diffusion) parameters
μ = 5
λ = 0.5

# Particle parameters
pheromone_strength = 1/4
pheromone_max = 1 # maximum pheromones in the world (note: 1 fully saturates the output color)
sensor_length = 60 # in pixels
sensor_angle = π/6
speed = 160
varspeed = 60
rot_speed = 5π

# Particle parameters (colors)
colors = (COLOR_RED, COLOR_GREEN, COLOR_BLUE)
pheromones = colors
attractions = (Color(127,255,0), Color(0,127,255), Color(255,0,127))
drawn_particles = false
starting_distribution = "center"


# [2] Monochrome
width = 1080; height = 1080; 
n = 2^19 # number of particles

μ = 5
λ = 0.5

r = 1
pheromone_strength = 1
pheromone_max = 1
sensor_length = 11r # in pixels
sensor_angle = π/8
speed = 0.15*width
varspeed = 0.05*width
rot_speed = 5π/r

colors = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
pheromones = (COLOR_RED, COLOR_RED, COLOR_RED)
attractions = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
drawn_particles = true
starting_distribution = "random"


# [2.1] Monochrome alternative
width = 1920; height = 1080; 
n = 2^19 # number of particles

μ = 5*2
λ = 0.5/2

r = 1
pheromone_strength = 1
pheromone_max = 1
sensor_length = 11r # in pixels
sensor_angle = π/8
speed = 0.15*1080
varspeed = 0.05*1080
rot_speed = 5π/r #3π and 10π are also interesting 

colors = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
pheromones = (COLOR_RED, COLOR_RED, COLOR_RED)
attractions = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
drawn_particles = true
starting_distribution = "random"


# [3] Monochrome (high pheromone strength)
width = 1080; height = 1080; 
n = 2^19 # number of particles

μ = 5
λ = 0.1

r = 1
pheromone_strength = 1
pheromone_max = 1
sensor_length = 11r # in pixels
sensor_angle = π/8
speed = 0.15*width
varspeed = 0.05*width
rot_speed = 5π/r

colors = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
pheromones = (COLOR_RED, COLOR_RED, COLOR_RED)
attractions = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
drawn_particles = true
starting_distribution = "random"


# [3] Cyclical
width = 1920; height = 1080; 
n = 2^19 # number of particles

μ = 5*2
λ = 0.5*2

r = 1
pheromone_strength = 1/10
pheromone_max = 1
sensor_length = 22r # in pixels
sensor_angle = π/8
speed = 0.15*1080
varspeed = 0.20*1080
rot_speed = 5π/r

colors = (COLOR_RED, COLOR_GREEN, COLOR_BLUE)
pheromones = default_colors
attractions = (Color(255,0,0), Color(0,255,0), Color(0,0,255))

drawn_particles = true
starting_distribution = "random"


# [4] Monochrome; uneventful then suddenly interesting
width = 1080; height = 1080; 
n = 2^19 # number of particles

μ = 5
λ = 0.25

pheromone_strength = 1
pheromone_max = 1
sensor_length = 12 # in pixels
sensor_angle = π/6
speed = 162
varspeed = 54
rot_speed = 5π

colors = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
pheromones = (COLOR_RED, COLOR_RED, COLOR_RED)
attractions = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
drawn_particles = true
starting_distribution = "random"


# [5] Monoschromatic Spaghetti
# model parameters
width = 1080; height = 1080; 
n = 2^19 # number of particles

μ = 5
λ = 0.5

pheromone_strength = 0.1
pheromone_max = 1
sensor_length = 10 # in pixels
sensor_angle = π/6
speed = 0.15*width
varspeed = 0.05*width
rot_speed = 1.5π

colors = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
pheromones = (COLOR_RED, COLOR_RED, COLOR_RED)
attractions = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
drawn_particles = true
starting_distribution = "random"


# [5.1] Monochromatic Spaghetti alternative
# model parameters
width = 1920*2; height = 1080*2; 
n = 2^21 # number of particles

μ = 5
λ = 0.5

pheromone_strength = 0.1
pheromone_max = 1
sensor_length = 20 # in pixels
sensor_angle = π/6
speed = 300
varspeed = 100
rot_speed = 1.5π

colors = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
pheromones = (COLOR_RED, COLOR_RED, COLOR_RED)
attractions = (COLOR_WHITE, COLOR_WHITE, COLOR_WHITE)
drawn_particles = true
starting_distribution = "random"


# [5.2] Colorful spaghetti
width = 1920; height = 1080; 
n = 2^20 # number of particles

μ = 5
λ = 0.5

pheromone_strength = 1/20
pheromone_max = 1
sensor_length = 25 # in pixels
sensor_angle = π/8
speed = 0.15*1080
varspeed = 0.20*1080
rot_speed = 1π

colors = (COLOR_RED, COLOR_GREEN, COLOR_BLUE)
pheromones = default_colors
attractions = (Color(127,255,0), Color(0,127,255), Color(255,0,127))

drawn_particles = true
starting_distribution = "random"


# [6] Soapy
# general parameters
width = 1920; height = 1080; 
n = 2^18 # number of particles

# World (i.e., pheromone diffusion) parameters
μ = 5
λ = 0.5/5

# Particle parameters
pheromone_strength = 1/4
pheromone_max = 1 # maximum pheromones in the world (note: 1 fully saturates the output color)
sensor_length = 16 # in pixels
sensor_angle = π/8
speed = 160
varspeed = 60
rot_speed = 5π

# Particle parameters (colors)
colors = (COLOR_RED, COLOR_GREEN, COLOR_BLUE)
pheromones = colors
attractions = (Color(127,255,0), Color(0,127,255), Color(255,0,127))
drawn_particles = true
starting_distribution = "random"


# [7] Weird disco
width = 1920; height = 1080; 
n = 2^20 # number of particles

μ = 5
λ = 0.5

pheromone_strength = 1/5
pheromone_max = 1
sensor_length = -160 # in pixels
sensor_angle = π/8
speed = 0.15*1080
varspeed = 0.20*1080
rot_speed = 5π

colors = (COLOR_RED, COLOR_GREEN, COLOR_BLUE)
pheromones = default_colors
attractions = (Color(255,0,0), Color(0,255,0), Color(0,0,255))

drawn_particles = true
starting_distribution = "random"


# [7] Froggy spirals
# (For disabled left sensor in cs_update_particles.glsl)
# general parameters
width = 1920*2; height = 1080*2; 
n = 2^20 # number of particles

# World (i.e., pheromone diffusion) parameters
μ = 5*2
λ = 0.5

# Particle parameters
pheromone_strength = 1/10
pheromone_max = 1 # maximum pheromones in the world (note: 1 fully saturates the output color)
sensor_length = 60 # in pixels
sensor_angle = π/12
speed = 160
varspeed = 60
rot_speed = 3π

colors = (COLOR_RED, COLOR_GREEN, COLOR_BLUE)
pheromones = colors
attractions = (Color(255,127,0), Color(0,255,127), Color(127,0,255))
drawn_particles = true
starting_distribution = "center" 


# [7.1] Froggy spirals alternative
# general parameters
width = 1920*2; height = 1080*2; 
n = 2^20 # number of particles

# World (i.e., pheromone diffusion) parameters
μ = 5*2
λ = 0.5

# Particle parameters
pheromone_strength = 1/10
pheromone_max = 1 # maximum pheromones in the world (note: 1 fully saturates the output color)
sensor_length = 60 # in pixels
sensor_angle = π/16
speed = 160
varspeed = 60
rot_speed = 2π

colors = (COLOR_RED, COLOR_GREEN, COLOR_BLUE)
pheromones = colors
attractions = (Color(255,127,0), Color(0,255,127), Color(127,0,255))
drawn_particles = true
starting_distribution = "center" 

end