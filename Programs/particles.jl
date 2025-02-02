using Engine
using GLPrograms
using ModernGL
using GLFW
using Shaders


#### Particle parameters
# include("./ParticleConfigs.jl")
# using .ParticleConfigs

###### Configurations ######
# [6] Soapy
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
# attractions = (Color(127,255,0), Color(0,127,255), Color(255,0,127))
drawn_particles = true
starting_distribution = "center" 

# attractions = (Color(100,255,0), Color(0,100,255), Color(255,0,100))
# attractions = (Color(255,200,0), Color(0,255,200), Color(200,0,255))
# attractions = (Color(255,0,0), Color(0,255,0), Color(0,0,255))
# attractions = (Color(0,255,0), Color(0,0,255), Color(255,0,0))
attractions = (Color(255,127,0), Color(0,255,127), Color(127,0,255))
# attractions = (Color(127,255,0), Color(0,127,255), Color(255,0,127))
# starting_distribution = "random"


#### GPU computing parameters (changing here requires changing in the shaders)
# Don't change these unless you know what you are doing
use_tiled_diffusion = false
diffusion_wgsize = (8,8) # Update cs_diffusion.glsl
diffusion_tiled_wgsize = (16,16) # Update cs_diffusion_tiled.glsl
particle_wgsize = 256 # update cs_update_particles.glsl and cs_draw_particles.glsl


#### Particle definition and generation
mutable struct Particle 
    x::Float32 
    y::Float32 
    vx::Float32 
    vy::Float32 
    color::Color # display color of particle
    pheromone_color::Color 
    pheromone_attraction::Color
end

# Generates and returns a single particle
function gen_particle() 
    if starting_distribution == "center"
        pos = Float32.([width/2, height/2])
    elseif starting_distribution == "random"
        pos = Float32.(rand(2).*[width,height])
        # pos = pos.*0.5 .+ [width/4, height/4]
    else 
        error("Invalid starting distribution")
    end
    θ = rand().*2π
    s = speed + varspeed*(rand()-0.5)
    vel = Float32.([cos(θ), sin(θ)].*s) # Speed fixed, angle random
    i = rand(1:3)
    return Particle(pos..., vel..., colors[i], pheromones[i], attractions[i])
end

#### Main code
gen_particles(n) = [gen_particle() for i = 1:n]
particles = gen_particles(n)

createWindow(width,height)
vsync(false)
println(get_opengl_info())

# Allocate buffers for the particles with position and velocity
# A particle posvel is Float32[x, y, vx, vy]
buf_posvel = Buffer()
buf_color = Buffer()
buf_behaviour = Buffer()
function push_posvel(ps::Vector{Particle}) #pushes to GPU
    particle_positions = hcat([[ps[i].x, ps[i].y, ps[i].vx, ps[i].vy] for i = 1:n]...)
    set(buf_posvel,particle_positions)
end
function pull_posvel(ps::Vector{Particle}) #pulls from GPU
    particle_positions = reshape(get(Float32, buf_posvel),4,n)
    for (i,p) in enumerate(ps)
        p.x, p.y, p.vx, p.vy = particle_positions[:,i] 
    end
end
function push_color(ps::Vector{Particle}) #pushes to GPU
    particle_colors = [ps[i].color for i = 1:n]
    set(buf_color,particle_colors)
end
function pull_color(ps::Vector{Particle}) #pulls from GPU
    particle_colors = reshape(get(UInt8, buf_color),4,n)
    for (i,p) in enumerate(ps)
        p.color = Color(particle_colors[:,i]...) 
    end
end
function push_behaviour(ps::Vector{Particle}) #pushes to GPU
    particle_behaviours = hcat([[ps[i].pheromone_color, ps[i].pheromone_attraction] for i = 1:n]...)
    set(buf_behaviour,particle_behaviours)
end
function pull_behaviour(ps::Vector{Particle}) #pulls from GPU
    particle_behaviours = reshape(get(UInt8, buf_behaviour),4,2,n)
    for (i,p) in enumerate(ps)
        p.pheromone_color = Color(particle_behaviours[:,1,i]...)
        p.pheromone_attraction = Color(particle_behaviours[:,2,i]...)
    end
end
push_posvel(particles) 
push_color(particles)
push_behaviour(particles)

# Allocate texture where particles deposit pheromones
world = Texture(TYPE_RGBA32F,2) 
world_out = Texture(TYPE_RGBA32F,2) 
set(world, zeros(Float32, 4, width, height)) # set world to zero
set(world_out, zeros(Float32, 4, width, height)) # set world to zero
# Note that α channel is also set to 0 here, but the diffusion shader will set it to 1.0 each iteration

# Allocate texture where particles are drawn
particles_tex = Texture(TYPE_RGBA8, 2)
set(particles_tex, repeat(UInt8.([0, 0, 0, 0]), 1, width, height))

prog_draw_particles = compile_file("Shaders/cs_draw_particles.glsl") 
prog_update_particles = compile_file("Shaders/cs_update_particles.glsl")
if use_tiled_diffusion
    prog_update_world = compile_file("Shaders/cs_diffusion_tiled.glsl")
else
    prog_update_world = compile_file("Shaders/cs_diffusion.glsl")
end

### Draw particles on tex
# Draws particles on tex. If clear, other pixels will be set to transparent.
function draw_particles(tex::Texture; clear=false)
    s = shape(tex)
    clear && fill(tex, UInt8.([0, 0, 0, 0]))
    bind_image_unit(1, tex) # texture to draw on
    bind_buffer_unit(2, buf_posvel) # particles buffer to read from
    # set(prog_draw_particles, "width", Int32(s[1]))
    # set(prog_draw_particles, "height", Int32(s[2]))
    bind_buffer_unit(5, buf_color)
    execute(prog_draw_particles, ceil(Int,n/particle_wgsize), 1, 1)
end
draw_particles(particles_tex, clear=true) # initial particle drawing on the texture

### Update the particles with time step Δt 
function update_particles(Δt)
    bind_image_unit(0, world, GL_RGBA32F)
    bind_buffer_unit(1, buf_behaviour)
    bind_buffer_unit(2, buf_posvel)
    set(prog_update_particles, "dt", Float32(Δt))
    set(prog_update_particles, "width", Int32(width))
    set(prog_update_particles, "height", Int32(height))
    set(prog_update_particles, "pheromone_strength", Float32(pheromone_strength))   
    set(prog_update_particles, "pheromone_max", Float32(pheromone_max))   
    set(prog_update_particles, "sensor_length", Float32(sensor_length))
    set(prog_update_particles, "sensor_angle", Float32(sensor_angle))
    set(prog_update_particles, "rot_speed", Float32(rot_speed))
    execute(prog_update_particles, ceil(Int,n/particle_wgsize), 1, 1)
end 

### Update the world with time step Δt 
function update_world(Δt)
    global world, world_out
    bind_image_unit(0, world, GL_RGBA32F)
    bind_image_unit(1, world_out, GL_RGBA32F)
    set(prog_update_world, "dt", Float32(Δt))
    set(prog_update_world, "mu", Float32(μ))
    set(prog_update_world, "lambda", Float32(λ))

    if use_tiled_diffusion
        tile_size = (4,4)
        execute(prog_update_world, ceil(Int,width/diffusion_tiled_wgsize[1]/tile_size[1]), ceil(Int,height/diffusion_tiled_wgsize[2]/tile_size[2]), 1)    
    else
        execute(prog_update_world, ceil(Int,width/diffusion_wgsize[1]), ceil(Int,height/diffusion_wgsize[2]), 1)
    end
 
    world, world_out = world_out, world
    return
end 

### Define iteration procedure
world_sprite = Sprite(world.pointer)
particles_sprite = Sprite(particles_tex.pointer)
function iterate(Δt)
    update_particles(Δt)
    glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT)
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT) # Since world texture is being written

    drawn_particles && draw_particles(particles_tex; clear=true)

    update_world(Δt)
    world_sprite.texture = world.pointer
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT) # Since world texture is being written
end

### onUpdate function with window controls
iterating = false
iteration = 0
t_prev = -Inf

scale = 1.0 
center = [0.0, 0.0]

click_loc = VEC_ORIGIN #mouse location at moment of mouse click
click_center = center #center at moment of mouse click

key_zoom_in = 0 # 1 for pressed -> zooming in 
key_zoom_out = 0 # 1 for pressed -> zooming out

function onUpdate(t_elapsed)
    global t_prev, iterating, iteration, scale, center, click_center, click_loc, key_zoom_in, key_zoom_out
    global sensor_length, rot_speed

    ## Time etc 
    Δt = (t_prev == -Inf ? 0 : t_elapsed - t_prev)
    t_prev = t_elapsed 
    Δt = 0.03;

    ## Handle mouse dragging input 
    if mouse(0).pressed && mouse(0).mods < 128 #first click, update the starting mouse location
        # println("click")
        click_loc = mouse()
        click_center = center
    elseif mouse(0).pressed && mouse(0).mods >= 128 #still pressed
        mouse_loc = mouse()
        Δmouse = mouse_loc - click_loc
        center = click_center .- [Δmouse.x, Δmouse.y]./scale
        # println(Δmouse)
    end

    function process_key_events(event)
        if event.key == GLFW.KEY_PERIOD && event.action == GLFW.PRESS; key_zoom_in = 1; end
        if event.key == GLFW.KEY_PERIOD && event.action == GLFW.RELEASE; key_zoom_in = 0; end
        if event.key == GLFW.KEY_COMMA && event.action == GLFW.PRESS; key_zoom_out = 1; end
        if event.key == GLFW.KEY_COMMA && event.action == GLFW.RELEASE; key_zoom_out = 0; end
        if event.key == GLFW.KEY_P && event.action == GLFW.PRESS; iterating = !iterating; end
        if event.key == GLFW.KEY_Q && event.action == GLFW.PRESS; iterating = false; exitloop(); end
        if event.key == GLFW.KEY_F && event.action == GLFW.PRESS; toggle_fullscreen(); end
        if event.key == GLFW.KEY_R && event.action == GLFW.PRESS; scale = 1.0; center = [0.0, 0.0]; end
        if event.key == GLFW.KEY_SLASH && event.action == GLFW.PRESS
            println("Iteration = $iteration")
            println("scale = $scale")
            println("location = $center")
            # println("sensor_length = $sensor_length")
            println("rot_speed = $rot_speed")
        end
        if event.key == GLFW.KEY_EQUAL && event.action == GLFW.PRESS
            # sensor_length += 1
            # set(prog_update_particles, "sensor_length", Float32(sensor_length))
            rot_speed *= 1.25
            set(prog_update_particles, "rot_speed", Float32(rot_speed))
        end
        if event.key == GLFW.KEY_MINUS && event.action == GLFW.PRESS
            # sensor_length -= 1
            # set(prog_update_particles, "sensor_length", Float32(sensor_length))
            rot_speed /= 1.25
            set(prog_update_particles, "rot_speed", Float32(rot_speed))
        end
    end 
    process_key_events.(poppedKeyEvents)

    (key_zoom_in>0) && (scale *= 2.0^Δt)
    (key_zoom_out>0) && (scale *= 0.5^Δt)

    function set_view(center, scale)
        loc = .-center .* scale
        vertices = [Vec2d(-1.0,-1.0), Vec2d(-1.0,1.0), Vec2d(1.0,-1.0), Vec2d(1.0,1.0)].*scale .+ [Vec2d(loc[1],loc[2])]
        shape!(world_sprite, vertices...)
        shape!(particles_sprite, vertices...)
    end 
    set_view(center, scale)

    if iterating 
        iterate(Δt)
    end

    clear(COLOR_BLACK)
    draw(world_sprite)
    drawn_particles && draw(particles_sprite) # drawn on top; mostly transparent
end
loop(onUpdate)

destroyWindow()

## Snippet for quickly testing the shaders
# prog_update_particles = compile_file("Shaders/cs_update_particles.glsl")
# loop(onUpdate)
