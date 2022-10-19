using Engine
using GLPrograms
using ModernGL
using GLFW
using Shaders

# texture size
width = 2048; height = 2048; # width, height is actually more abstractly worksize_x, worksize_y
workgroupsize = (8,8)
double_precision = false

createWindow(width,height)

tex = Texture(TYPE_RGBA32F,2) # Generate texture name
allocate(tex, width, height) # Allocate memory
 
prog = double_precision ? compile_file("Shaders/cs_mandelbrot_double.glsl") : compile_file("Shaders/cs_mandelbrot.glsl")

# Use program and bind texture/memory
im_unit = 0 # (corresponds to binding in shader)
bind_image_unit(im_unit, tex)

### Setting colormap texture 
# Storing the color map to the GPU
cmap = Texture(TYPE_RGBA8,1)

function set_colormap(colormap::Matrix{UInt8}, interpolate=false)
    bind_texture_unit(1, cmap)

    set(cmap, colormap) # should call the below stuff
    # glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, length(colormap)÷4, 0, GL_RGBA, GL_UNSIGNED_BYTE, colormap)

    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, interpolate ? GL_LINEAR : GL_NEAREST)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, interpolate ? GL_LINEAR : GL_NEAREST)

    # Setting the color map as uniform in the compute shader
    set(prog, "colors", Int32(1)) # "colors" will take its values from texture unit 1, i.e., "colors" is bound to texture unit 1
end

#define colormap
colormap = collect(UInt8[   255   0   0 255
                            255 255   0 255
                              0 255   0 255
                              0 255 255 255
                              0   0 255 255
                            255   0 255 255]') # Fully saturated color map

# colormap = UInt8[i for i in 0:255]'.*ones(UInt8,4); colormap[4,:].=0xff; colormap  # Black & White color map
# colormap = UInt8.([0,0,255,255] .+ [i for i in 0:255]'.*[1,0,-1,0]) # Red & Blue color map

set_colormap(colormap, true)

###
sprite = Sprite(tex.pointer)

T = double_precision ? Float64 : Float32

center = T.([-0.4,0.0])
scale = T(1.75)
maxit = 64

click_loc = VEC_ORIGIN #mouse location at moment of mouse click
click_center = center #center at moment of mouse click

key_zoom_in = 0 # 1 for pressed -> zooming in 
key_zoom_out = 0 # 1 for pressed -> zooming out

cycling = true
cycling_state = 0

t_prev = -Inf

function onUpdate(t_elapsed)
    global t_prev, scale, center, click_center, click_loc, key_zoom_in, key_zoom_out, maxit, cycling, cycling_state, T

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
        center = click_center .+ [Δmouse.y*scale, -Δmouse.x*scale]
        # println(Δmouse)
    end

    function process_key_events(event)
        if event.key == GLFW.KEY_PERIOD && event.action == GLFW.PRESS; key_zoom_in = 1; end
        if event.key == GLFW.KEY_PERIOD && event.action == GLFW.RELEASE; key_zoom_in = 0; end
        if event.key == GLFW.KEY_COMMA && event.action == GLFW.PRESS; key_zoom_out = 1; end
        if event.key == GLFW.KEY_COMMA && event.action == GLFW.RELEASE; key_zoom_out = 0; end
        if event.key == GLFW.KEY_R && event.action == GLFW.PRESS; center = T.([-0.4,0.0]); scale = T(1.75); end
        if event.key == GLFW.KEY_SLASH && event.action == GLFW.PRESS
            println("Zoom scale is $scale")
            println("Iterations = $maxit")
        end
        if event.key == GLFW.KEY_EQUAL && event.action == GLFW.PRESS
            maxit = maxit*2
        end
        if event.key == GLFW.KEY_MINUS && event.action == GLFW.PRESS
            maxit = maxit÷2
        end
        if event.key == GLFW.KEY_P && event.action == GLFW.PRESS
            cycling = !cycling
        end
    end 
    process_key_events.(poppedKeyEvents)
    
    (key_zoom_in>0) && (scale *= T(0.5^Δtime))
    (key_zoom_out>0) && (scale *= T(2.0^Δtime))

    #DEBUG (showing the input events)
    # for i=0:7
    #     mouse(i).pressed && println(i, mouse(i))
    # end
    filteredKeyEvents = filter(e->e.action!=GLFW.REPEAT, poppedKeyEvents)
    length(filteredKeyEvents) > 0 && println(filteredKeyEvents)
|
    set(prog, "center", center[1], center[2])
    set(prog, "scale", scale)
    set(prog, "maxit", Int32(maxit))

    if cycling 
        cycling_state += Δtime
    end
    function getp(cycling_state)
        p1 = -cycling_state/10
        p2 = p1+1/3
        return Float32(p1), Float32(p2)
    end
    p1,p2 = getp(cycling_state)
    set(prog, "p1", p1)
    set(prog, "p2", p2)

    execute(prog,ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT)
    draw(sprite)
end
loop(onUpdate)

free(tex)
free(cmap)
destroyWindow()




