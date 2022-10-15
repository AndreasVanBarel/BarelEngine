using Engine
using GLPrograms
using ModernGL
using GLFW
using Shaders

# texture size
width = 2048; height = 2048; # width, height is actually more abstractly worksize_x, worksize_y
workgroupsize = (8,8)

createWindow(width,height)

tex = Texture(TYPE_RGBA32F,2) # Allocate texture name
set_zeros(tex, width, height)
 
prog = compile_file("cs_mandelbrot.glsl")

# Use program and bind texture/memory
im_unit = 0 # (corresponds to binding in shader)
bind(tex,im_unit)

### Setting colormap texture 
# Storing the color map to the GPU
cmapP = UInt32[0]
glGenTextures(1, cmapP)

function set_colormap(colormap, interpolate=false)
    colormap = UInt8.(colormap)

    glActiveTexture(GL_TEXTURE1) # now making changes to texture unit 1
    glBindTexture(GL_TEXTURE_1D, cmapP[1]) # binds texture to texture unit 1

    glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, length(colormap)÷4, 0, GL_RGBA, GL_UNSIGNED_BYTE, colormap)

    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, interpolate ? GL_LINEAR : GL_NEAREST)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, interpolate ? GL_LINEAR : GL_NEAREST)

    # Setting the color map as uniform in the compute shader
    set(prog, "colors", 1) # "colors" will take its values from texture unit 1, i.e., "colors" is bound to texture unit 1
end

#define colormap
colormap = UInt8[   255,   0,   0, 255,
                    255, 255,   0, 255,
                      0, 255,   0, 255,
                      0, 255, 255, 255,
                      0,   0, 255, 255,
                    255,   0, 255, 255] # Fully saturated color map

# colormap = UInt8[i for i in 0:255]'.*ones(UInt8,4); colormap[4,:].=0xff;  # Black & White color map
# colormap = [0,0,255,255] .+ [i for i in 0:255]'.*[1,0,-1,0] # Red & Blue color map

set_colormap(colormap, true)

###
sprite = Sprite(tex.pointer)

center = Vec2d(-0.25,0.0)
scale = 1.5f0
maxit = 64

click_loc = mouse() #mouse location at moment of mouse click
click_center = center #center at moment of mouse click

key1 = 0 # 1 for pressed -> zooming in 
key2 = 0 # 1 for pressed -> zooming out

cycling = true
cycling_state = 0

t_prev = -Inf
function onUpdate(t_elapsed)
    global t_prev, click_loc, center, click_center, scale, key1, key2, maxit, cycling, cycling_state

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
        center = click_center + Vec2d(Δmouse.y*scale, -Δmouse.x*scale)
        # println(Δmouse)
    else
        # no click events to process
    end

    function process_key_events(event)
        if event.key == GLFW.KEY_PERIOD && event.action == GLFW.PRESS
            key1 = 1
        end
        if event.key == GLFW.KEY_PERIOD && event.action == GLFW.RELEASE
            key1 = 0
        end
        if event.key == GLFW.KEY_COMMA && event.action == GLFW.PRESS
            key2 = 1
        end
        if event.key == GLFW.KEY_COMMA && event.action == GLFW.RELEASE
            key2 = 0
        end
        if event.key == GLFW.KEY_EQUAL && event.action == GLFW.PRESS
            maxit = maxit*2
        end
        if event.key == GLFW.KEY_MINUS && event.action == GLFW.PRESS
            maxit = maxit÷2
        end
        if event.key == GLFW.KEY_SLASH && event.action == GLFW.PRESS
            cycling = !cycling
        end
    end 
    process_key_events.(poppedKeyEvents)
    
    (key1>0) && (scale *= 0.5^Δtime)
    (key2>0) && (scale *= 2.0^Δtime)

    #DEBUG (showing the input events)
    # for i=0:7
    #     mouse(i).pressed && println(i, mouse(i))
    # end
    (length(poppedKeyEvents)) > 0 && println(poppedKeyEvents)
|
    set(prog, "center", center.x, center.y)
    set(prog, "scale", scale)
    set(prog, "maxit", maxit)

    if cycling 
        cycling_state += Δtime
    end
    function getp(cycling_state)
        p1 = -cycling_state/10
        p2 = p1+1/3
        return p1,p2
    end
    p1,p2 = getp(cycling_state)
    set(prog, "p1", p1)
    set(prog, "p2", p2)

    execute(prog,ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT)
    draw(sprite)
end
loop(onUpdate)

glDeleteTextures(1,[tex.pointer])
glDeleteTextures(1,cmapP)
destroyWindow()




