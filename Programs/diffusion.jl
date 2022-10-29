using Engine
using GLPrograms
using ModernGL
using GLFW
using Shaders

# !!! THIS FILE IS OBSOLETE AND DEFUNCT !!!

# texture size
width = 1024; height = 1024; # width, height is actually more abstractly worksize_x, worksize_y
workgroupsize = (8,8)
n = 64

createWindow(width,height)

# Allocate texture where particles deposit pheromones
state1 = Texture(TYPE_RGB32F,2) 
state2 = Texture(TYPE_RGB32F,2) 
set(state1, zeros(Float32, 3, width, height)) # set state1 to zero
set(state2, zeros(Float32, 3, width, height)) # set state2 to zero

prog_diffusion = compile_file("Shaders/cs_diffusion.glsl")

initial_values = rand(Float32,3,width,height) # random initial values 
set(state1, initial_values)


## Testing a single diffusion iteration
# bind_image_unit(0, state1, GL_RGBA32F) # Last parameter gives format in the shader, could be different from image format.
# bind_image_unit(1, state2, GL_RGBA32F)
# execute(prog_diffusion,ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)

###
sprite1 = Sprite(state1.pointer)
sprite2 = Sprite(state2.pointer)

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
        if event.key == GLFW.KEY_R && event.action == GLFW.PRESS; scale = 1.0; center = [0.0, 0.0]; end
        if event.key == GLFW.KEY_P && event.action == GLFW.PRESS; iterating = !iterating; end
        if event.key == GLFW.KEY_SLASH && event.action == GLFW.PRESS
            println("Iteration = $iteration")
            println("scale = $scale")
            println("location = $center")
        end
    end 
    process_key_events.(poppedKeyEvents)

    (key_zoom_in>0) && (scale *= T(2.0^Δtime))
    (key_zoom_out>0) && (scale *= T(0.5^Δtime))

    function set_view(center, scale)
        loc = .-center .* scale
        vertices = [Vec2d(-1.0,1.0), Vec2d(1.0,1.0), Vec2d(-1.0,-1.0), Vec2d(1.0,-1.0)].*scale .+ [Vec2d(loc[1],loc[2])]
        shape!(sprite1, vertices...)
        shape!(sprite2, vertices...)
    end 
    set_view(center, scale)

    if iterating 
        bind_image_unit(mod(iteration,2), state1, GL_RGBA32F)
        bind_image_unit(mod(iteration+1,2), state2, GL_RGBA32F)
        execute(prog_diffusion,ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)
        glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT)
        iteration += 1 
    end

    clear(COLOR_DDGRAY)
    mod(iteration,2) == 0 ? draw(sprite1) : draw(sprite2)
end
loop(onUpdate)


##
free(state1)
free(state2)
destroyWindow()