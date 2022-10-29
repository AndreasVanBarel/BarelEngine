using Engine
using GLPrograms
using ModernGL
using GLFW
using Shaders

# texture size
width = 2048; height = 2048; # width, height is actually more abstractly worksize_x, worksize_y
workgroupsize = (8,8)

createWindow(width,height)

# Allocate texture names 
tex1 = Texture(TYPE_R8,2) 
tex2 = Texture(TYPE_R8,2)
show_tex = Texture(TYPE_RGBA8,2) # texture for showing on the screen

initial_values = (rand(width,height).>0.5).*UInt8(1) # random initial values 

set(tex1, initial_values)
allocate(tex2, width, height)
allocate(show_tex, width, height)
 
prog = compile_file("Shaders/cs_game_of_life.glsl")

bind_image_unit(0, tex1, GL_R8UI)
# glBindImageTexture(0, tex1.pointer, 0, GL_FALSE, 0, GL_READ_WRITE, GL_R8UI) # Last parameter gives format in the shader, could be different from image format.

bind_image_unit(1, tex2, GL_R8UI)
# glBindImageTexture(1, tex2.pointer, 0, GL_FALSE, 0, GL_READ_WRITE, GL_R8UI) # "bind a level of a texture to an image unit"
# set(prog, "out_tex", Int32(1))
bind_image_unit(2, show_tex)

execute(prog,ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)


###
sprite = Sprite(show_tex.pointer)

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
        click_loc = mouse()
        click_center = center
    elseif mouse(0).pressed && mouse(0).mods >= 128 #still pressed
        mouse_loc = mouse()
        Δmouse = mouse_loc - click_loc
        center = click_center .- [Δmouse.x, Δmouse.y]./scale
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
        vertices = [Vec2d(-1.0,-1.0), Vec2d(-1.0,1.0), Vec2d(1.0,-1.0), Vec2d(1.0,1.0)].*scale .+ [Vec2d(loc[1],loc[2])]
        shape!(sprite, vertices...)
    end 
    set_view(center, scale)

    if iterating 
        bind_image_unit(mod(iteration,2), tex1, GL_R8UI)
        bind_image_unit(mod(iteration+1,2), tex2, GL_R8UI)
        execute(prog,ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)
        glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT)
        iteration += 1 
    end

    clear(COLOR_DDGRAY)
    draw(sprite)
end
loop(onUpdate)

free(tex1)
free(tex2)
free(show_tex)
destroyWindow()

