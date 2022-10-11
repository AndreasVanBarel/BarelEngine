using Engine
using GLPrograms
using ModernGL
using GLFW

##
null = Ptr{Nothing}() # Note: same as C_NULL

# texture size
width = 2048; height = 2048; # width, height is actually more abstractly worksize_x, worksize_y
workgroupsize = (8,8)
format = GL_RGBA
type = GL_RGBA32F
# format = GL_RED
# type = GL_R32F

createWindow(width,height)

# Allocate texture name (textureP[1]) and bind it to GL_TEXTURE_2D
textureP = UInt32[0] # textureP[1] will contain pointer to texture memory
glGenTextures(1, textureP); textureP # sets textureP[1] (generates 1 as of then unused texture name; gets deallocated with glDeleteTextures)
glActiveTexture(GL_TEXTURE0) 
glBindTexture(GL_TEXTURE_2D, textureP[1]) # GL_TEXTURE_2D is then an 'alias' for textureP[1]
# Note: OpenGL 4.5+ might have glCreateTextures(GL_TEXTURE_2D, 1, textureP) to replace the two previous calls

# Texture interpolation and extrapolation options
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

# Initialize the texture with null values
glTexImage2D(GL_TEXTURE_2D, 0, type, width, height, 0, format, GL_FLOAT, null) # fills the texture with null values
glBindImageTexture(0, textureP[1], 0, GL_FALSE, 0, GL_READ_WRITE, type) # "bind a level of a texture to an image unit"
# First variable is binding index, 0 in this case. This corresponds to the "binding=0" part in the shader

# shader_code = open("cs_rgba32f_t.glsl") do io read(io, String) end
shader_code = open("cs_mandelbrot.glsl") do io read(io, String) end

prog = createComputeProg(shader_code)

# Use program and bind texture/memory
glUseProgram(prog)

# Dispatch (i.e., execute)
glDispatchCompute(ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)

glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT) # make sure writing to image has finished before read

# Sets values to currently bound GL_TEXTURE_2D
function set_values(values::Array{Float32}) #values is essentially a pointer to a Float32 array
    glActiveTexture(GL_TEXTURE0) 
    glTexImage2D(GL_TEXTURE_2D, 0, type, width, height, 0, format, GL_FLOAT, values)
end

# Gets values to currently bound GL_TEXTURE_2D
function get_values()::Array{Float32}
    glActiveTexture(GL_TEXTURE0) 
    data = Array{Float32,3}(undef, 4, width, height)
    # data = Array{Float32,3}(undef, 1, width, height)
    glGetTexImage(GL_TEXTURE_2D, 0, format, GL_FLOAT, data) 
    return data
end

# Copies values currently bound to GL_TEXTURE_2D in a given data structure. The user must make sure the data structure is of the correct type and size.
function get_values!(data)::Array{Float32}
    glActiveTexture(GL_TEXTURE0) 
    glGetTexImage(GL_TEXTURE_2D, 0, format, GL_FLOAT, data) 
    return data
end

# Utility functions for quickly setting integer and float uniforms
function set(identifier::String, values...)
    loc = glGetUniformLocation(prog, identifier)
    (loc == -1) && @warn("identifier not found in shader (loc=-1)")
    set(loc, values...)
end
set(loc::Integer, value::Real) = glUniform1f(loc,Float32(value))
set(loc::Integer, v1::Real, v2::Real) = glUniform2f(loc,v1,v2)
set(loc::Integer, v1::Real, v2::Real, v3::Real) = glUniform3f(loc,v1,v2,v3)
set(loc::Integer, v1::Real, v2::Real, v3::Real, v4::Real) = glUniform4f(loc,v1,v2,v3,v4)
set(loc::Integer, value::Integer) = glUniform1i(loc,Int32(value))
set(loc::Integer, v1::Integer, v2::Integer) = glUniform2i(loc,v1,v2)
set(loc::Integer, v1::Integer, v2::Integer, v3::Integer) = glUniform3i(loc,v1,v2,v3)
set(loc::Integer, v1::Integer, v2::Integer, v3::Integer, v4::Integer) = glUniform4i(loc,v1,v2,v3,v4)


### Setting colormap texture 
# Storing the color map to the GPU
cmapP = UInt32[0]
glGenTextures(1, cmapP)

function set_colormap(colormap, interpolate=false)
    colormap = UInt8.(colormap)
    glBindTexture(GL_TEXTURE_1D, cmapP[1])
    glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, length(colormap)÷4, 0, GL_RGBA, GL_UNSIGNED_BYTE, colormap)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST) #GL_LINEAR
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)

    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, interpolate ? GL_LINEAR : GL_NEAREST)
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, interpolate ? GL_LINEAR : GL_NEAREST)

    # Setting the color map as uniform in the compute shader
    glUseProgram(prog)
    cmap_location = glGetUniformLocation(prog, "colors")
    glActiveTexture(GL_TEXTURE1)
    glBindTexture(GL_TEXTURE_1D, cmapP[1])
    glUniform1i(cmap_location, 1) #NOTE: This 0 corresponds to the GL_TEXTURE0 that is active.
end

#define colormap
colormap = UInt8[   255,   0,   0, 255,
                    255, 255,   0, 255,
                      0, 255,   0, 255,
                      0, 255, 255, 255,
                      0,   0, 255, 255,
                    255,   0, 255, 255] # Fully saturated color map

colormap = UInt8[i for i in 0:255]'.*ones(UInt8,4); colormap[4,:].=0xff;  # Black & White color map
colormap = [0,0,255,255] .+ [i for i in 0:255]'.*[1,0,-1,0] # Red & Blue color map

set_colormap(colormap, false)
set_colormap(colormap, true)

###
sprite = Sprite(textureP[1])

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
    set("center", center.x, center.y)
    set("scale", scale)
    set("maxit", maxit)

    if cycling 
        cycling_state += Δtime
    end
    function getp(cycling_state)
        p1 = -cycling_state/10
        p2 = p1+1/3
        return p1,p2
    end
    p1,p2 = getp(cycling_state)
    set("p1", p1)
    set("p2", p2)

    draw(sprite)

    glUseProgram(prog)
    glUniform1f(t_loc,Float32(t_elapsed))
    glDispatchCompute(ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT)
end
loop(onUpdate)

glDeleteTextures(1,textureP)
glDeleteTextures(1,cmapP)
destroyWindow()




