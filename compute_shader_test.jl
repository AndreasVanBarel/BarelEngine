using Engine
using GLPrograms
using ModernGL


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
shader_code = open("Shaders/cs_mandelbrot.glsl") do io read(io, String) end

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

sprite = Sprite(textureP[1])

# GLFW.SetWindowTitle(Engine.window, "Barel Engine Compute Shader");
# draw(sprite)
# GLFW.SwapBuffers(Engine.window) # Swap front and back buffers
# err = glGetError()
# err == 0 || @error("GL Error code $err")

t_loc = glGetUniformLocation(prog,"t")

circle = Circle(Vec2d(0.0,0.0),0.25,COLOR_BLUE)

function onUpdate(t_elapsed)
    # clear(COLOR_DGRAY)
    draw(sprite)
    # draw(circle)
    # println(Float32(t_elapsed))

    glUseProgram(prog)
    glUniform1f(t_loc,Float32(t_elapsed))
    glDispatchCompute(ceil(Int,width/workgroupsize[1]), ceil(Int,height/workgroupsize[1]), 1)
    glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT)
end
loop(onUpdate)

glDeleteTextures(1,textureP)
destroyWindow()

##################



glUseProgram(prog)
glDispatchCompute(width, height, 1)

get_values()

glGetUniformLocation(prog,"data")
glUniform1i(glGetUniformLocation(prog,"data"), 0)

## Experiments

draw(circle)
draw(sprite)
Engine.GLFW.SwapBuffers(Engine.window)
clear(COLOR_RED)

Engine.GLFW.SwapBuffers(Engine.window) # Swap front and back buffers
err = glGetError()
err == 0 || @error("GL Error code $err")


shape!(sprite, points...)


Engine.GLFW.SetWindowShouldClose(Engine.window, false);
t_start = time_ns()
t_elapsed = 0
while !Engine.GLFW.WindowShouldClose(Engine.window)
    # FPS calculation and show in window title
    t = time_ns()
    Δt = (t-t_start-t_elapsed)
    fps = 1e9/Δt
    t_elapsed = t-t_start

    s_fps = fps==Inf ? "Inf" : string(round(Int,fps))
    Engine.GLFW.SetWindowTitle(Engine.window, "Barel Engine at "*s_fps*" fps");

    popMouseEvents()
    onUpdate(1e-9t_elapsed)

    Engine.GLFW.SwapBuffers(Engine.window) # Swap front and back buffers

    # Poll for and process events
    Engine.GLFW.PollEvents()
    err = glGetError()
    err == 0 || @error("GL Error code $err")
end




