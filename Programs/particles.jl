using Engine
using GLPrograms
using ModernGL
using GLFW
using Shaders

# texture size
width = 1024; height = 1024; # width, height is actually more abstractly worksize_x, worksize_y
workgroupsize = (8,8)
particle_wgsize = 128
n = 2^20 # number of particles

createWindow(width,height)

# Generate initial particle configuration 
function gen_particle() 
    pos = rand(Float32, 2)
    θ = rand().*2π
    vel = Float32[cos(θ), sin(θ)].*0.05f0 # Speed fixed, angle random
    return [pos; vel]
end
gen_particles(n) = hcat([gen_particle() for i = 1:n]...)
particles = gen_particles(n)

# Allocate buffers for the particles with position and velocity
# A particle is Float32[x, y, vx, vy]
buf = Buffer()
set(buf,particles)
# t = get(Float32, buf)

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
    bind_buffer_unit(2, buf) # particles buffer to read from
    set(prog_draw_particles, "width", Int32(s[1]))
    set(prog_draw_particles, "height", Int32(s[2]))
    execute(prog_draw_particles, ceil(Int,n/particle_wgsize), 1, 1)
end
draw_particles(particles_tex, clear=true)

### Update the particles with time step Δt 
function update_particles(Δt)
    bind_image_unit(0, world, GL_RGBA32F)
    bind_buffer_unit(2, buf)
    set(prog_update_particles, "dt", Float32(Δt))
    set(prog_update_particles, "width", Int32(width))
    set(prog_update_particles, "height", Int32(height))
    execute(prog_update_particles, ceil(Int,n/particle_wgsize), 1, 1)
end 
update_particles(1)

### Update the world with time step Δt 
function update_world(Δt)
    global world, world_out
    bind_image_unit(0, world, GL_RGBA32F)
    bind_image_unit(1, world_out, GL_RGBA32F)
    set(prog_update_world, "dt", Float32(Δt))
    set(prog_update_world, "mu", Float32(10))
    set(prog_update_world, "lambda", Float32(0.05))
    execute(prog_update_world, ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)
    world, world_out = world_out, world
    return
end 
update_world(1)

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
        vertices = [Vec2d(-1.0,-1.0), Vec2d(1.0,-1.0), Vec2d(1.0,1.0), Vec2d(-1.0,1.0)].*scale .+ [Vec2d(loc[1],loc[2])]
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

##
destroyWindow()

