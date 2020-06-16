# The engine responsible for drawing and input and output
module Engine

export createWindow, destroyWindow
export loop

export Vec2d, VEC_ORIGIN, VEC_EX, VEC_EY
export Color, COLOR_BLACK, COLOR_WHITE
export clear
export Triangle, Triangle!
export draw

import GLFW
using ModernGL
import GLPrograms

# State of the module
prog = nothing
window = nothing
function reset()
	global prog = nothing
	global window = nothing
end

function init()
	GLFW.Init() || @error("GLFW failed to initialize")

	# Specify OpenGL version
	GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3);
	GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3);
	GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE);
end
function finalize()
	GLFW.Terminate()
end

function createWindow(width::Int=640, height::Int=480, title::String="Barel Engine")
	init()
	# Create a window and its OpenGL context
	global window = GLFW.CreateWindow(width, height, title)
	if isnothing(window)
		@error("Window or context creation failed.")
		GLFW.Terminate()
		return
	end
	# Make the window's context current
	GLFW.MakeContextCurrent(window)
	glViewport(0, 0, width, height)
	#GLFW.SwapInterval(1); #Activate V-sync
	GLFW.SetErrorCallback(error_callback)
	GLFW.SetKeyCallback(window, key_callback)
	GLFW.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	global prog = GLPrograms.generatePrograms()
	return
end
function destroyWindow()
	global window
	GLFW.DestroyWindow(window)
	finalize()
	reset()
end

# Callback functions
function error_callback(error, description::String)
	@error(description)
	return nothing
end
function key_callback(window::GLFW.Window, key::GLFW.Key, scancode::Int32, action::GLFW.Action, mods::Int32)
    if (key == GLFW.KEY_ESCAPE && action == GLFW.PRESS)
        GLFW.SetWindowShouldClose(window, true);
	end
end
function framebuffer_size_callback(window::GLFW.Window, width, height)
    glViewport(0, 0, width, height);
	println("The window was resized to $width × $height")
	return nothing
end

# Main loop
function loop(onInit::Function, onUpdate::Function, onExit::Function)
	onInit()
	# Main render loop
	t_start = time_ns()
	t_elapsed = 0
	# Loop until the user closes the window
	while !GLFW.WindowShouldClose(window)
		# FPS calculation and show in window title
		t = time_ns()
		Δt = (t-t_start-t_elapsed)
		fps = 1e9/Δt
		t_elapsed = t-t_start

		t = time_ns()
		s_fps = fps==Inf ? "Inf" : string(round(Int,fps))
		GLFW.SetWindowTitle(window, "Barel Engine at "*s_fps*" fps");

		onUpdate(t_elapsed)

		# Swap front and back buffers
		GLFW.SwapBuffers(window)

		# Poll for and process events
		GLFW.PollEvents()
		err = glGetError()
		err == 0 || @error("GL Error code $err")
	end
	onExit()
end
loop(onUpdate::Function) = loop(()->nothing, onUpdate, ()->nothing)

struct Color
    r::UInt8
    g::UInt8
    b::UInt8
end
const COLOR_BLACK = Color(0,0,0)
const COLOR_WHITE = Color(255,255,255)

struct Vec2d
    x::Float32
    y::Float32
end
const VEC_ORIGIN = Vec2d(0,0)
const VEC_EX = Vec2d(1,0)
const VEC_EY = Vec2d(0,1)

function clear(r::AbstractFloat, g::AbstractFloat, b::AbstractFloat, α::AbstractFloat=1.0)
	glClearColor(r, g, b, α)
	glClear(GL_COLOR_BUFFER_BIT)
end
clear(c::Color,α::Real) = clear(c.r,c.g,c.b,α)
clear(r::Integer,g::Integer,b::Integer,α::Integer=255) = clear(r/255,g/255,b/255,α/255)
clear() = clear(0.0,0.0,0.0,1.0)

struct Triangle
    vao::UInt32 #Location on the GPU
	vbo::UInt32 #Location of data on the GPU
end
function Triangle(p1::Vec2d,p2::Vec2d,p3::Vec2d,c::Color,α) #TODO: Make this an inner constructor to enforce invariants.
	α = Float32(α)

	#Construct the triangle data
	# triangle_data = [p1.x, p1.y, c.r, c.g, c.b, α,
	# 				p2.x, p2.y, c.r, c.g, c.b, α,
	# 				p3.x, p3.y, c.r, c.g, c.b, α]
	triangle_data = [p1.x,p1.y,Float32(0),
					p2.x,p2.y,Float32(0),
					p3.x,p3.y,Float32(0)]

	#Store the triangle on the GPU
    vaoP = UInt32[0] # Vertex Array Object
    glGenVertexArrays(1, vaoP)
    glBindVertexArray(vaoP[1])

    vboP = UInt32[0] # Vertex Buffer Object
    glGenBuffers(1,vboP)
    glBindBuffer(GL_ARRAY_BUFFER, vboP[1])
    glBufferData(GL_ARRAY_BUFFER, sizeof(triangle_data), triangle_data, GL_STATIC_DRAW) #copy to the GPU

	#Specifiy the interpretation of the data
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3*sizeof(Float32), Ptr{Nothing}(0))

	println(vaoP[1], vboP[1])

	Triangle(vaoP[1],vboP[1])
end
function Triangle!(t::Triangle) #Destructor
	glDeleteVertexArrays(1, [t.vao])
	glDeleteBuffers(1,[t.vbo])
end
function draw(t::Triangle)
	glBindVertexArray(t.vao)
	glUseProgram(prog)
	glDrawArrays(GL_TRIANGLES, 0, 3)
end
show(t::Triangle,io::IO) = println("Triangle stored on GPU in VAO $(t.vao).")


# struct Pixel
#     c::Color
#     α::Uint8 # alpha
#     z::Uint8 # height of the pixel
# end
# Pixel() = Pixel(Color(0,0,0),0,0)
# Pixel(r,g,b,α=0,z=0) = Pixel(Color(r,g,b),α,z)
# Pixel(c::Color,α=0) = Pixel(c,α,0)
#
# # Serves as a buffer for the screen
# struct PixelArray
#     array::Matrix{Pixel}
# end
#
# struct Instance
#     width::Int
#     height::Int
#     P::PixelArray
#     canvas
#     window
# end
#
# function construct(width::Int,height::Int)
#     canvas = Gtk.@GtkCanvas()
#     window = Gtk.GtkWindow(canvas,"Canvas")
#     @guarded Gtk.draw(c) do widget
#         drawall(window)
#     end
#     P = PixelArray(width,height)
#     return Instance(width,height,P,canvas,window)
# end
#
# function drawall(w::Window)
#
# end
#
# function update(elapsed::Float64)
#
# end
#
# function destruct(i::Instance)
#
# end
#
# function draw_pixel()
#
# end


end
