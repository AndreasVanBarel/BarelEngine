using Engine
using GLPrograms
using ModernGL
using GLFW
using Shaders

# general parameters
width = 1920*2; height = 1080*2; # note: width, height corresponds to worksize_x, worksize_y
n = 2^20 # number of particles

# World (i.e., pheromone diffusion) parameters
μ = 5
λ = 0.5

# Particle parameters
pheromone_strength = 1/4
pheromone_max = 1 # maximum pheromones in the world (note: 1 fully saturates the output color)
sensor_length = 60 # in pixels
sensor_angle = 1π/6
speed = 160
varspeed = 60
rot_speed = 2π/0.03 * 0.24
rot_speed = 5π

# GPU computing parameters
workgroupsize = (8,8)
particle_wgsize = 128

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
    # pos = Float32.(rand(2).*[width,height])
    # pos = pos.*0.5 .+ [width/4, height/4]
    pos = Float32.([width/2, height/2])
    θ = rand().*2π
    s = speed + varspeed*(rand()-0.5)
    vel = Float32.([cos(θ), sin(θ)].*s) # Speed fixed, angle random
    i = rand(1:3)
    c = [COLOR_RED, COLOR_GREEN, COLOR_BLUE]
    atr = [Color(127,255,0), Color(0,127,255), Color(255,0,127)]
    # atr = [Color(255,200,0), Color(0,255,200), Color(200,0,255)]
    # atr = [Color(255,0,0), Color(0,255,0), Color(0,0,255)]
    # atr = [Color(0,255,0), Color(0,0,255), Color(255,0,0)]
    # atr = [Color(255,127,0), Color(0,255,127), Color(127,0,255)]
    return Particle(pos..., vel..., COLOR_TRANSPARENT, c[i], atr[i])
    # return Particle(pos..., vel..., COLOR_WHITE, COLOR_RED, COLOR_WHITE)
    # return Particle(pos..., vel..., COLOR_WHITE, COLOR_RED, COLOR_WHITE)
end

#### Main code
createWindow(width,height)
gen_particles(n) = [gen_particle() for i = 1:n]
particles = gen_particles(n)

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
world = Texture(TYPE_RGB32F,2) 
world_out = Texture(TYPE_RGB32F,2) 
set(world, zeros(Float32, 3, width, height)) # set world to zero
set(world_out, zeros(Float32, 3, width, height)) # set world to zero

# Allocate texture where particles are drawn on 
particles_tex = Texture(TYPE_RGBA8, 2)
set(particles_tex, repeat(UInt8.([0, 0, 0, 0]), 1, width, height))

prog_draw_particles = compile_file("Shaders/cs_draw_particles.glsl") 
prog_update_particles = compile_file("Shaders/cs_update_particles.glsl")
prog_update_world = compile_file("Shaders/cs_diffusion.glsl")

### Draw particles on tex
# Draws particles on tex. If clear, other pixels will be set to transparent.
function draw_particles(tex::Texture; clear=false)
    s = shape(tex)
    clear && set(tex, repeat(UInt8.([0, 0, 0, 0]), 1, s[1], s[2])) # reset tex to fully transparent
    bind_image_unit(1, tex) # texture to draw on
    bind_buffer_unit(2, buf_posvel) # particles buffer to read from
    # set(prog_draw_particles, "width", Int32(s[1]))
    # set(prog_draw_particles, "height", Int32(s[2]))
    bind_buffer_unit(5, buf_color)
    execute(prog_draw_particles, ceil(Int,n/particle_wgsize), 1, 1)
end
draw_particles(particles_tex, clear=true)

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
    execute(prog_update_world, ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)
    world, world_out = world_out, world
    return
end 

###
world_sprite = Sprite(world.pointer)
particles_sprite = Sprite(particles_tex.pointer)

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

    ## Time etc 
    Δtime = (t_prev == -Inf ? 0 : t_elapsed - t_prev)
    t_prev = t_elapsed 
    Δtime = 0.03;

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
        end
    end 
    process_key_events.(poppedKeyEvents)

    (key_zoom_in>0) && (scale *= 2.0^Δtime)
    (key_zoom_out>0) && (scale *= 0.5^Δtime)

    function set_view(center, scale)
        loc = .-center .* scale
        vertices = [Vec2d(-1.0,-1.0), Vec2d(-1.0,1.0), Vec2d(1.0,-1.0), Vec2d(1.0,1.0)].*scale .+ [Vec2d(loc[1],loc[2])]
        shape!(world_sprite, vertices...)
        shape!(particles_sprite, vertices...)
    end 
    set_view(center, scale)

    if iterating 
        update_particles(Δtime)
        glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT)
        glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT) # Since world texture is being written

        update_world(Δtime)
        world_sprite.texture = world.pointer

        draw_particles(particles_tex; clear=true)
        glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT) # Since world texture is being written
    end

    clear(COLOR_BLACK)
    draw(world_sprite)
    draw(particles_sprite) # drawn on top; mostly transparent
end
loop(onUpdate)

destroyWindow()

## For quickly testing the shaders
# prog_update_particles = compile_file("Shaders/cs_update_particles.glsl")
# loop(onUpdate)
