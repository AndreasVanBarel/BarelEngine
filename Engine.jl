# The engine responsible for drawing and input and output
module Engine

export createWindow, destroyWindow, n_to_p, p_to_n
export vsync, wireframe
export loop, exitloop

export windowed_mode, fullscreen_mode, toggle_fullscreen

export Vec2d, VEC_ORIGIN, VEC_EX, VEC_EY, norm, dot, dist
export Color, r, g, b, α
export COLOR_BLACK, COLOR_WHITE, COLOR_GRAY, COLOR_DGRAY, COLOR_DDGRAY
export COLOR_RED, COLOR_DRED, COLOR_DDRED, COLOR_GREEN, COLOR_DGREEN, COLOR_DDGREEN, COLOR_BLUE, COLOR_DBLUE, COLOR_DDBLUE
export COLOR_YELLOW, COLOR_DYELLOW, COLOR_DDYELLOW, COLOR_CYAN, COLOR_DCYAN, COLOR_DDCYAN, COLOR_MAGENTA, COLOR_DMAGENTA, COLOR_DDMAGENTA
export COLOR_TRANSPARENT
export Transform, inverse
export Camera, use, camera

# export Buffer, clear, isempty, isfull, items, pop!, push!, popall!

export InputEvent, resetinputbuffers
export MouseEvent, NO_MOUSE_EVENT, mouse, mouseEvents, popMouseEvents, poppedMouseEvents
export KeyEvent, keyEvents, popKeyEvents, poppedKeyEvents

export load_texture
export clear
export Graphical, Triangle, Quadrangle, Square, Ellipse, Circle, Sprite
export draw, free, drawfree
export center, loc, color!, α!, shape!, position!, translate!, rotate!, scale!

import Base: +,-,*,/,rand
import Base.pop!, Base.push!
import LinearAlgebra: norm, dot, inv

# External dependencies
import GLFW
using ModernGL
using LinearAlgebra

# Submodules
import GLPrograms
import Shaders
import Shaders.free #To extend this method
using ResourceIO

###########################
# Basic utility functions #
###########################

function bits(u::Integer)
   	res =BitVector(undef, sizeof(u)*8)
   	res.chunks[1] = u%UInt64
   	res
end
rotmatrix(θ::Real) = [cos(θ) -sin(θ); sin(θ) cos(θ)]

# Buffer
mutable struct Buffer{T}
	size::Int
	last::Int #last valable index (0 for empty buffer)
	data::Vector{T}
end
Buffer{T}(size::Int) where T = Buffer{T}(size,0,Vector{T}(undef,size))
clear(b::Buffer) = b.last = 0
isempty(b::Buffer) = b.last == 0
isfull(b::Buffer) = b.last == b.size
function pop!(b::Buffer{T})::T where T
	isempty(b) && return
	b.last -= 1
	return b.data[b.last+1]
end
function push!(b::Buffer{T}, item::T) where T
	isfull(b) && return
	b.last += 1
	b.data[b.last] = item
	return
end
# Copies items and returns them in a Vector{T}
items(b::Buffer{T}) where T = return b.data[1:b.last]
function popall!(b::Buffer{T})::Vector{T} where T 
	len = b.last 
	b.last = 0
	return b.data[1:len]
end 

#################################
# Window creation and main loop #
#################################

# State of the module
prog = nothing
window = nothing
function reset()
	global prog = nothing
	global window = nothing
	global camera = Camera()
	resetinputbuffers()
	resetgpulocations()
	nothing
end

# Initializes GLFW
function init()
	reset()
	GLFW.Init() || @error("GLFW failed to initialize")

	# Specify OpenGL version
	GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 4);
	GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3);
	GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE);
end
# Finalizes GLFW
function finalize()
	GLFW.Terminate()
end
# Create a window
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

	GLFW.SwapInterval(1) #Activate V-sync

	# Callback functions
	GLFW.SetErrorCallback(error_callback)
	GLFW.SetKeyCallback(window, key_callback)
	GLFW.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	# External input setup
	#GLFW.SetInputMode(window, GLFW.STICKY_MOUSE_BUTTONS, true);
	GLFW.SetMouseButtonCallback(window, mouse_button_callback)

	# Compile shader programs
	global prog = GLPrograms.generatePrograms()

	# Set Camera values on the gpu
	gpu_upload(camera)

	# Enable alpha blending
	glEnable(GL_BLEND)
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

	# Allocate buffers on the GPU
	gpu_allocate()

	return
end
function destroyWindow()
	isnothing(window) || GLFW.DestroyWindow(window)
	try gpu_free() catch e end #free buffers on the GPU
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
	# push key event to key event buffer for later handling by the user 
	keyEvent = KeyEvent(key, scancode, action, mods, time_ns())
	push!(keyEvents, keyEvent)
	return nothing
end
function framebuffer_size_callback(window::GLFW.Window, width, height)
    glViewport(0, 0, width, height);
	#println("The window was resized to $width × $height")
	return nothing
end

# Main loop
function loop(onInit::Function, onUpdate::Function, onExit::Function)
	GLFW.SetWindowShouldClose(window, false);
	resetinputbuffers()
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

		s_fps = fps==Inf ? "Inf" : string(round(Int,fps))
		GLFW.SetWindowTitle(window, "Barel Engine at "*s_fps*" fps");

		onUpdate(1e-9t_elapsed)

		GLFW.SwapBuffers(window) # Swap front and back buffers

		# Poll for and process events
		GLFW.PollEvents()
		err = glGetError()
		err == 0 || @error("GL Error code $err")

		popMouseEvents()
		popKeyEvents()
	end
	onExit()
	windowed_mode()
end
loop(onUpdate::Function) = loop(()->nothing, onUpdate, ()->nothing)
exitloop() = GLFW.SetWindowShouldClose(window, true);

# V-sync
function vsync(b::Bool)
	isnothing(window) && (@error("No window currently active"); return)
	b ? GLFW.SwapInterval(1) : GLFW.SwapInterval(0)
	return nothing
end

# Wireframe mode
function wireframe(b::Bool)
	isnothing(window) && (@error("No window currently active"); return)
	b ? glPolygonMode(GL_FRONT_AND_BACK, GL_LINE) : glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
	return nothing
end

# Pixel width and height of the window
width() = GLFW.GetWindowSize(window).width
height() = GLFW.GetWindowSize(window).height


#######################
# Windowed Fullscreen #
#######################
global windowed_size 
global windowed_position
global isfullscreen = false

toggle_fullscreen() = isfullscreen ? windowed_mode() : fullscreen_mode()

function fullscreen_mode() 
	global isfullscreen
	isfullscreen && return 

	# Store windowed parameters
	global windowed_size = GLFW.GetWindowSize(window)
	global windowed_position = GLFW.GetWindowPos(window)

	# Set to fullscreen
	monitor = GLFW.GetMonitors()[1] # Get the primary monitor
	vm = GLFW.GetVideoMode(monitor)
	GLFW.SetWindowAttrib(window, GLFW.DECORATED, false);
	GLFW.SetWindowSize(window, vm.width, vm.height)
	GLFW.SetWindowPos(window, 0, 0)
	GLFW.SetWindowAttrib(window, GLFW.FLOATING, true);
	vsync(true)

	# GLFW.SetWindowMonitor(window, monitor, 0, 0, vm.width-300, vm.height-300, vm.refreshrate)

	isfullscreen = true
end

function windowed_mode() 
	global isfullscreen
	!isfullscreen && return 

	# Set to windowed
	# monitor = GLFW.GetMonitors()[1] # Get the primary monitor
	# vm = GLFW.GetVideoMode(monitor)
	# GLFW.SetWindowMonitor(window, C_NULL, 
	# 	windowed_position.x, windowed_position.y, 
	# 	windowed_size.width, windowed_size.height, vm.refreshrate)
	
	# restore windowed parameters
	GLFW.SetWindowAttrib(window, GLFW.DECORATED, true);
	GLFW.SetWindowSize(window, windowed_size.width, windowed_size.height)
	GLFW.SetWindowPos(window, windowed_position.x, windowed_position.y)
	GLFW.SetWindowAttrib(window, GLFW.FLOATING, false);

	isfullscreen = false
end

##########################
# Low level data structs #
##########################

struct Color
    r::UInt8
    g::UInt8
    b::UInt8
	α::UInt8
end
Color(r,g,b) = Color(r,g,b,0xff)
Color(r::AbstractFloat,g::AbstractFloat,b::AbstractFloat,α::AbstractFloat=1.0) = Color(round(UInt8,255r),round(UInt8,255g),round(UInt8,255b),round(UInt8,255α))

function Color(tex::Array{UInt8,3},w=:, h=:) # size(tex,1) should be 3 or 4
	hasα = size(tex,1) > 3
	if hasα
		return Color.(r(tex)[w,h],g(tex)[w,h],b(tex)[w,h],α(tex)[w,h])
	else
		return Color.(r(tex)[w,h],g(tex)[w,h],b(tex)[w,h])
	end
end

const COLOR_BLACK = Color(0,0,0)
const COLOR_WHITE = Color(255,255,255)
const COLOR_GRAY = Color(127,127,127)
const COLOR_DGRAY = Color(63,63,63)
const COLOR_DDGRAY = Color(31,31,31)
const COLOR_RED = Color(255,0,0)
const COLOR_GREEN = Color(0,255,0)
const COLOR_BLUE = Color(0,0,255)
const COLOR_YELLOW = Color(255,255,0)
const COLOR_CYAN = Color(0,255,255)
const COLOR_MAGENTA = Color(255,0,255)
const COLOR_DRED = Color(127,0,0)
const COLOR_DGREEN = Color(0,127,0)
const COLOR_DBLUE = Color(0,0,127)
const COLOR_DYELLOW = Color(127,127,0)
const COLOR_DCYAN = Color(0,127,127)
const COLOR_DMAGENTA = Color(127,0,127)
const COLOR_DDRED = Color(63,0,0)
const COLOR_DDGREEN = Color(0,63,0)
const COLOR_DDBLUE = Color(0,0,63)
const COLOR_DDYELLOW = Color(63,63,0)
const COLOR_DDCYAN = Color(0,63,63)
const COLOR_DDMAGENTA = Color(63,0,63)
const COLOR_TRANSPARENT = Color(0,0,0,0)

f(x::Integer) = Float32(x/255)
rand(::Type{Color},args...) = Color.(rand(UInt8,args...),rand(UInt8,args...),rand(UInt8,args...))

struct Vec2d
    x::Float32
    y::Float32
end
+(a::Vec2d,b::Vec2d) = Vec2d(a.x+b.x,a.y+b.y)
-(a::Vec2d,b::Vec2d) = Vec2d(a.x-b.x,a.y-b.y)
-(a::Vec2d) = Vec2d(-a.x,-a.y)
*(c,a::Vec2d) = Vec2d(c*a.x,c*a.y)
*(a::Vec2d,c) = *(c,a)
/(a::Vec2d,c) = Vec2d(a.x/c,a.y/c)
norm(v::Vec2d) = sqrt(v.x*v.x+v.y*v.y)
dot(a::Vec2d,b::Vec2d) = a.x*b.x + a.y*b.y
dist(a::Vec2d,b::Vec2d) = norm(a-b)
const VEC_ORIGIN = Vec2d(0f0,0f0)
const VEC_EX = Vec2d(1f0,0f0)
const VEC_EY = Vec2d(0f0,1f0)

p_to_n(p::Vec2d) = Vec2d(2p.x/width()-1, -2p.y/height()+1) #pixel coordinates p to normalized device coordinates
n_to_p(n::Vec2d) = Vec2d((n.x+1)*width(), (1-n.y)*height()) #normalized device coordinates n to pixel coordinates

rand(::Type{Vec2d},args...) = Vec2d.(rand(args...).*2 .-1, rand(args...).*2 .-1)

struct Transform
	M::Matrix{Float32}
	function Transform(M::Matrix{Float32})
		size(M) == (3,3) || error("Invalid dimensions")
		M[end,:] == [0,0,1] || error("Last row must be [0 0 1]")
		new(M)
	end
end
Transform(M::Matrix) = Transform(Matrix{Float32}(M))
Transform(A::Matrix,b::Vector) = Transform([A b; 0 0 1])
Transform(A::Matrix,b::Vec2d) = Transform(A, [b.x, b.y])
*(t1::Transform,t2::Transform) = Transform(t1.M*t2.M)
(t::Transform)(v::Vec2d) = (p = t.M*[v.x, v.y, 1.0f0]; Vec2d(p[1],p[2]))
inv(t::Transform) = Transform(inv(t.M))

mutable struct Camera
	T::Transform
    Tinv::Transform
end
Camera(T::Transform) = Camera(T,inv(T))
Camera() = Camera(Transform(Matrix{Float32}(I,3,3)))
function translate!(cam::Camera,p::Vec2d)
	cam.T = Transform([1 0; 0 1],p)*cam.T
	cam.Tinv = cam.Tinv*Transform([1 0; 0 1],-p)
	update(cam)
end
function rotate!(cam::Camera,θ::Real)
	cam.T = Transform(rotmatrix(θ), [0,0])*cam.T
	cam.Tinv = cam.Tinv*Transform(rotmatrix(-θ), [0,0])
	update(cam)
end
function scale!(cam::Camera,c::Vec2d)
	cam.T = Transform([c.x 0; 0 c.y], [0,0])*cam.T
	cam.Tinv = cam.Tinv*Transform([1/c.x 0; 0 1/c.y], [0,0])
	update(cam)
end
scale!(cam::Camera,c::Real) = scale!(cam,Vec2d(c,c))
update(cam::Camera) = camera === cam && gpu_upload(cam)

camera = Camera() # stores the currently bound camera
use(cam::Camera) = (global camera = cam; gpu_upload(cam)) #to set the currently bound camera to the provided cam
function gpu_upload(cam::Camera)
	glUseProgram(prog.triangle); glUniformMatrix3fv(prog.triangle_camLoc, 1, false, cam.T.M);
	glUseProgram(prog.ellipse); glUniformMatrix3fv(prog.ellipse_camLoc, 1, false, cam.T.M);
	glUseProgram(prog.sprite); glUniformMatrix3fv(prog.sprite_camLoc, 1, false, cam.T.M);
end

##############
# User input #
##############

abstract type InputEvent end
struct MouseEvent <: InputEvent
	button::UInt8
	pressed::Bool #true: pressed, false: released
	mods::UInt8
	time::UInt64 #in nanoseconds
	x::Float64
	y::Float64
end
const NO_MOUSE_EVENT = MouseEvent(0,false,0,0,0,0)

mouseEvents = fill(NO_MOUSE_EVENT,8) #last mouseEvent for each of 8 mousebuttons
poppedMouseEvents = fill(NO_MOUSE_EVENT,8) #temporary fixed storage for mouseEvents
function mouse_button_callback(window::GLFW.Window, button, action, mods)
	global mouseEvents
	#println("debug: Mouse callback: $button, $pressed, $mods")
	button = UInt8(button)
	pressed = Bool(action)
	mods = UInt8(mods) # shows all modifier keys, or is 255 if this mouse event is a continuation of a previous event.
	pressed==false && return #we don't store key releases explicitly
	mouseEvents[button+1].pressed==true && return #already have a mouse press event stored.
	pos = mouse()
	mouseEvents[button+1] = MouseEvent(button,pressed,mods,time_ns(),pos.x,pos.y)
end
mouse() = camera.Tinv(p_to_n(Vec2d(GLFW.GetCursorPos(window)...)))
mouse(b::Integer) = poppedMouseEvents[b+1]
function rawmouse(b::Integer)
	GLFW.GetMouseButton(window, GLFW.MouseButton(b))
end
function popMouseEvents()
	pos = mouse()
	for i=1:8
		if mouseEvents[i].pressed==false
			if GLFW.GetMouseButton(window, GLFW.MouseButton(i-1)) #mouse still pressed
				poppedMouseEvents[i] = MouseEvent(i-1,true,128,time_ns(),pos.x,pos.y)
			else
				poppedMouseEvents[i] = mouseEvents[i]
			end
		else
			poppedMouseEvents[i] = mouseEvents[i]
		end
	end
	#poppedMouseEvents .= mouseEvents #copies the mouseEvents to create the snapshot poppedMouseEvents
	mouseEvents .= [NO_MOUSE_EVENT]
end

struct KeyEvent <: InputEvent
	key::GLFW.Key
	scancode::Int32
	action::GLFW.Action #true: pressed, false: released
	mods::Int32
	time::UInt64 #in nanoseconds
end
keyEvents = Buffer{KeyEvent}(1024)
poppedKeyEvents = KeyEvent[]

popKeyEvents() = global poppedKeyEvents = popall!(keyEvents)

function resetinputbuffers()
	global mouseEvents = fill(NO_MOUSE_EVENT,8)
	global poppedMouseEvents = fill(NO_MOUSE_EVENT,8)
	global keyEvents = Buffer{KeyEvent}(1024)
	global poppedKeyEvents = KeyEvent[]
end

#################################
# Graphical objects and drawing #
#################################

function clear(r::AbstractFloat, g::AbstractFloat, b::AbstractFloat, α::AbstractFloat=1.0f0)
	glClearColor(r, g, b, α)
	glClear(GL_COLOR_BUFFER_BIT)
end
clear(r::Integer,g::Integer,b::Integer,α::Integer=255) = clear(f(r),f(g),f(b),f(α))
clear(c::Color) = clear(c.r,c.g,c.b,c.α)
clear() = clear(0.0f0,0.0f0,0.0f0,1.0f0)

### Buffers on the GPU for the various objects
triangle_vao = UInt32(0)
triangle_vbo = UInt32(0)
quadrangle_vao = UInt32(0)
quadrangle_vbo = UInt32(0)
ellipse_vao = UInt32(0)
ellipse_vbo = UInt32(0)
sprite_vao = UInt32(0)
sprite_vbo = UInt32(0)
function resetgpulocations()
	global triangle_vao = UInt32(0)
	global triangle_vbo = UInt32(0)
	global quadrangle_vao = UInt32(0)
	global quadrangle_vbo = UInt32(0)
	global ellipse_vao = UInt32(0)
	global ellipse_vbo = UInt32(0)
	global sprite_vao = UInt32(0)
	global sprite_vbo = UInt32(0)
end
function gpu_allocate()
	### triangle ###
	vaoP = UInt32[0] # Vertex Array Object
    glGenVertexArrays(1, vaoP)
	glBindVertexArray(vaoP[1])

    vboP = UInt32[0] # Vertex Buffer Object
    glGenBuffers(1,vboP)
	glBindBuffer(GL_ARRAY_BUFFER, vboP[1])

	#Specifiy the interpretation of the data
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3*sizeof(Float32), Ptr{Nothing}(0))

	global triangle_vao = vaoP[1]
	global triangle_vbo = vboP[1]

	### quadrangle ###
	vaoP = UInt32[0] # Vertex Array Object
	glGenVertexArrays(1, vaoP)
	glBindVertexArray(vaoP[1])

	vboP = UInt32[0] # Vertex Buffer Object
	glGenBuffers(1,vboP)
	glBindBuffer(GL_ARRAY_BUFFER, vboP[1])
	glBufferData(GL_ARRAY_BUFFER, 72, C_NULL, GL_STREAM_DRAW) # allocate the buffer on the gpu
	# TODO: Do this everywhere and then use glBufferSubData to copy to the existing STREAM buffer. Might need multiple buffers though, with some deferred rendering...

	#Specifiy the interpretation of the data
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3*sizeof(Float32), Ptr{Nothing}(0))

	global quadrangle_vao = vaoP[1]
	global quadrangle_vbo = vboP[1]

	### ellipse ###
	vaoP = UInt32[0] # Vertex Array Object
	glGenVertexArrays(1, vaoP)
	glBindVertexArray(vaoP[1])

	vboP = UInt32[0] # Vertex Buffer Object
	glGenBuffers(1,vboP)
	glBindBuffer(GL_ARRAY_BUFFER, vboP[1])

	#Specifiy the interpretation of the data
	glEnableVertexAttribArray(0)
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5*sizeof(Float32), Ptr{Nothing}(0))
	glEnableVertexAttribArray(1)
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5*sizeof(Float32), Ptr{Nothing}(3*sizeof(Float32)))

	global ellipse_vao = vaoP[1]
	global ellipse_vbo = vboP[1]

	### sprite ###
	vaoP = UInt32[0] # Vertex Array Object
	glGenVertexArrays(1, vaoP)
	glBindVertexArray(vaoP[1])

	vboP = UInt32[0] # Vertex Buffer Object
	glGenBuffers(1,vboP)
	glBindBuffer(GL_ARRAY_BUFFER, vboP[1])

	#Specifiy the interpretation of the data
	glEnableVertexAttribArray(0)
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5*sizeof(Float32), Ptr{Nothing}(0))
	glEnableVertexAttribArray(1)
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5*sizeof(Float32), Ptr{Nothing}(3*sizeof(Float32)))

	global sprite_vao = vaoP[1]
	global sprite_vbo = vboP[1]
end
function gpu_free()
	glDeleteVertexArrays(3, [triangle_vao, quadrangle_vao, sprite_vao])
	glDeleteBuffers(3,[triangle_vbo, quadrangle_vbo, sprite_vbo])
	resetgpulocations()
end

abstract type Graphical end
free(g::Graphical) = nothing #fallback
drawfree(g::Graphical) = (draw(g); free(g))
color!(t::Graphical,c::Color) = t.color = c
loc(g::Graphical) = g.vertices[1]
position!(g::Graphical,pos::Vec2d,center::Vec2d=loc(g)) = g.vertices .+= [pos-center]
scale!(g::Graphical,factor::Real,center::Vec2d) = g.vertices .= factor.*(g.vertices.-center).+center
translate!(g::Graphical,v::Vec2d) = g.vertices .+= [v]
rotate!(g::Graphical,θ::Real,center::Vec2d=center(t)) = g.vertices .= rot.(vertices, θ, [center])
rot(v::Vec2d,θ::Real,center::Vec2d) = Vec2d(cos(θ)*v.x-sin(θ)*v.y, sin(θ)*v.x+cos(θ)*v.y)

mutable struct Triangle <: Graphical
	vertices::Vector{Vec2d}
	color::Color
end
Triangle(p1::Vec2d,p2::Vec2d,p3::Vec2d,c::Color) = Triangle([p1,p2,p3],c)
function draw(t::Triangle)
	glBindVertexArray(triangle_vao)
	glBindBuffer(GL_ARRAY_BUFFER, triangle_vbo)
	p1,p2,p3 = t.vertices
	data = [p1.x,p1.y,Float32(0),
			p2.x,p2.y,Float32(0),
			p3.x,p3.y,Float32(0)]
	glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW) #copy to the GPU
	glUseProgram(prog.triangle)
	glUniform4f(prog.triangle_colorLoc, f(t.color.r), f(t.color.g), f(t.color.b), f(t.color.α));
	glDrawArrays(GL_TRIANGLES, 0, 3)
end
Base.show(t::Triangle,io::IO) = println("Triangle at $(loc(q)).")
center(t::Triangle) = sum(vertices)/length(vertices)
shape!(t::Triangle,p1::Vec2d,p2::Vec2d,p3::Vec2d) = t.vertices .= [p1,p2,p3]

mutable struct Quadrangle <: Graphical
    vertices::Vector{Vec2d}
	color::Color
end
Quadrangle(p1::Vec2d,p2::Vec2d,p3::Vec2d,p4::Vec2d,c::Color) = Quadrangle([p1,p2,p3,p4],c)
Quadrangle(p::Vec2d,v1::Vec2d,v2::Vec2d,c) = Quadrangle(p,p+v1,p+v1+v2,p+v2,c)
function Square(p::Vec2d,side,c)
	p1 = p-0.5*side*VEC_EX-0.5*side*VEC_EY
	p2 = p+0.5*side*VEC_EX-0.5*side*VEC_EY
	p3 = p+0.5*side*VEC_EX+0.5*side*VEC_EY
	p4 = p-0.5*side*VEC_EX+0.5*side*VEC_EY
	Quadrangle(p1,p2,p3,p4,c)
end
function draw(q::Quadrangle)
	glBindVertexArray(quadrangle_vao)
	glBindBuffer(GL_ARRAY_BUFFER, quadrangle_vbo)
	p1,p2,p3,p4 = q.vertices
	data = [p1.x,p1.y,Float32(0),
			p2.x,p2.y,Float32(0),
			p3.x,p3.y,Float32(0),
			p4.x,p4.y,Float32(0)]
	glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STREAM_DRAW) #copy to the GPU
	glUseProgram(prog.triangle) #Reuses the triangle program.
	glUniform4f(prog.triangle_colorLoc, f(q.color.r), f(q.color.g), f(q.color.b), f(q.color.α))
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4)
end
Base.show(q::Quadrangle,io::IO) = println("Quadrangle at $(loc(q)).")
center(q::Quadrangle) = crosspoint(vertices...)
shape!(q::Quadrangle,p1::Vec2d,p2::Vec2d,p3::Vec2d,p4::Vec2d) = q.vertices .= [p1,p2,p3,p4]
shape!(q::Quadrangle,p::Vec2d,v1::Vec2d,v2::Vec2d) = shape!(q,p,p+v1,p+v1+v2,p+v2)

mutable struct Ellipse <: Graphical
    vertices::Vector{Vec2d} #Contain [centre, axis1, axis2]
	color::Color
end
Ellipse(p::Vec2d,a1::Vec2d,a2::Vec2d,c::Color) = Ellipse([p,a1,a2],c)
Circle(p::Vec2d,r::Real,c) = Ellipse(p,r*VEC_EX,r*VEC_EY,c)
function draw(g::Ellipse)
	glBindVertexArray(ellipse_vao)
	glBindBuffer(GL_ARRAY_BUFFER, ellipse_vbo)
	p,a1,a2 = g.vertices
	p1 = p-a1-a2
	p2 = p+a1-a2
	p3 = p+a1+a2
	p4 = p-a1+a2
	data = [p1.x,p1.y,0f0, 1f0,-1f0,
			p2.x,p2.y,0f0, 1f0,1f0,
			p3.x,p3.y,0f0, -1f0,1f0,
			p4.x,p4.y,0f0, -1f0,-1f0]
	glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STREAM_DRAW) #copy to the GPU
	glUseProgram(prog.ellipse) #Reuses the triangle program.
	glUniform4f(prog.ellipse_colorLoc, f(g.color.r), f(g.color.g), f(g.color.b), f(g.color.α))
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4)
end
Base.show(g::Ellipse,io::IO) = println("Quadrangle at $(loc(q)).")
center(g::Ellipse) = vertices[1]
position!(g::Ellipse,p::Vec2d) = g.vertices[1] = p
shape!(g::Ellipse,p::Vec2d,a1::Vec2d,a2::Vec2d) = g.vertices = [p,a1,a2]
shape!(g::Ellipse,p::Vec2d,r::Real) = q.vertices = shape!(g,p,p+r*VEC_EX,p+r*VEC_EY)
shape!(g::Ellipse,r::Real) = q.vertices = shape!(g,vertices[1],r)


#==
The vertices are in all cases mapped to uv coordinates as shown below.
By default, the vertices are set such that screen space (x,y) corresponds to (u,v) in the natural way:
vertices	-> (u,v)  		(x,y) (default)
vertices[1] -> (.5,.5)  	( 0, 0)	This vertex is the center
vertices[2] -> (0,0)  		(-1,-1)	bottom left
vertices[3] -> (0,1)  		(-1, 1)	bottom right
vertices[4] -> (1,0)  		( 1,-1)	top left
vertices[5] -> (1,1)  		( 1, 1)	top right

To get a standard loaded from disk image in the upright position:
vertices	-> (u,v)  		(x,y) (for upright image)
vertices[1] -> (.5,.5)  	( 0, 0)	This vertex is the center
vertices[2] -> (0,0)  		(-1, 1)	top left
vertices[3] -> (0,1)  		( 1, 1)	top right
vertices[4] -> (1,0)  		(-1,-1)	bottom left
vertices[5] -> (1,1)  		( 1,-1)	bottom right

The default layout is summarized in the diagram below:
(x,y) location					  (u,v)
	4   5   		->   (1,0)               (1,1)
	  1     		->            (.5,.5)
	2   3   		->   (0,0)               (0,1)

The center is saved instead of recalculated.
The vertices can of course change, but their binding to the uv coordinates is constant.
==#
mutable struct Sprite <: Graphical
	texture::UInt32 #Location of the texture on the GPU
	width::UInt32
	height::UInt32
	isrgba::Bool
	vertices::Vector{Vec2d}
	color::Color
end
function Sprite(p1::Vec2d,p2::Vec2d,p3::Vec2d,p4::Vec2d,tex::Array{UInt8,3},c::Color=COLOR_WHITE)
	width, height = size(tex)[2:3]
	vertices = [crosspoint(p1,p2,p3,p4),p1,p2,p3,p4]
	size(tex)[1]!=3 && size(tex)[1]!=4 && (@error("texture format not supported"); return nothing)
	isrgba = size(tex)[1]==4

	#Store and configure texture on the GPU
	textureP = UInt32[0]
	glGenTextures(1, textureP)
	glBindTexture(GL_TEXTURE_2D, textureP[1])
	if isrgba #rgb
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, tex)
	else #rgba
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, tex)
	end
	glGenerateMipmap(GL_TEXTURE_2D)
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST) #GL_LINEAR
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
	#glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
	#glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER)
	#glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, [0f0, 0f0, 0f0, 0f0])

	Sprite(textureP[1],width,height,isrgba,vertices,c)
end
# const default_vertices = [Vec2d(-1.0,1.0), Vec2d(1.0,1.0), Vec2d(-1.0,-1.0), Vec2d(1.0,-1.0)]
const default_vertices = [Vec2d(-1.0,-1.0), Vec2d(-1.0,1.0), Vec2d(1.0,-1.0), Vec2d(1.0,1.0)]
Sprite(tex::Array{UInt8,3},c::Color=COLOR_WHITE) = Sprite(default_vertices..., tex,c)

# Construct Sprite with existing texture pointer
function Sprite(p1::Vec2d,p2::Vec2d,p3::Vec2d,p4::Vec2d,textureP::Integer,c::Color=COLOR_WHITE)
	# width and height of existing texture can be found as follows:
	glBindTexture(GL_TEXTURE_2D, textureP)
	w = UInt[0]; h = UInt[0]; αsize = UInt[0]; 
	miplevel = 0
	glGetTexLevelParameteriv(GL_TEXTURE_2D, miplevel, GL_TEXTURE_WIDTH, w);
	glGetTexLevelParameteriv(GL_TEXTURE_2D, miplevel, GL_TEXTURE_HEIGHT, h);
	glGetTexLevelParameteriv(GL_TEXTURE_2D, miplevel, GL_TEXTURE_ALPHA_SIZE, αsize);
	width = w[1]; height = h[1]; isrgba = αsize[1] > 0

	vertices = [crosspoint(p1,p2,p3,p4),p1,p2,p3,p4]
	Sprite(textureP,width,height,isrgba,vertices,c)
end
Sprite(textureP::Integer,c::Color=COLOR_WHITE) = Sprite(default_vertices..., textureP,c)

# Construct Sprite with existing Shaders.Texture object 
Sprite(tex::Shaders.Texture,c::Color=COLOR_WHITE) = Sprite(default_vertices..., tex.pointer,c)

# Calculates the center of mass of the given 4 vertices
# (previously calculated the intersection between p1--p3 and p2--p4)
function crosspoint(p1::Vec2d,p3::Vec2d,p2::Vec2d,p4::Vec2d)
	# A = [p2.y-p1.y	p1.x-p2.x;
	# 	 p4.y-p3.y	p3.x-p4.x]
	# b = [p2.y*p1.x-p2.x*p1.y, p4.y*p3.x-p4.x*p3.y]
	# p = A\b
	# Vec2d(p...)
	(p1+p2+p3+p4)/4
end
Sprite(p::Vec2d,v1::Vec2d,v2::Vec2d,tex,c=COLOR_WHITE) = Sprite(p,p+v1,p+v1+v2,p+v2,tex,c)
Sprite(p::Vec2d,tex,c=COLOR_WHITE) = Sprite(p,VEC_EX,VEC_EY,tex,c)
Sprite(tex,c=COLOR_WHITE) = Sprite(VEC_ORIGIN,tex,c)
free(s::Sprite) = glDeleteTextures(1,[s.texture])
loc(s::Sprite) = s.vertices[2]
center(s::Sprite) = s.vertices[1]
shape!(s::Sprite,p1::Vec2d,p2::Vec2d,p3::Vec2d,p4::Vec2d) = s.vertices .= [crosspoint(p1,p2,p3,p4),p1,p2,p3,p4]
shape!(s::Sprite,p::Vec2d,v1::Vec2d,v2::Vec2d) = shape!(s,p,p+v1,p+v1+v2,p+v2)
function draw(s::Sprite)
	glBindVertexArray(sprite_vao)
	glBindBuffer(GL_ARRAY_BUFFER, sprite_vbo)
	c,p1,p2,p3,p4 = s.vertices
	# data = [c.x,c.y,0f0,0.5f0,0.5f0,
	# 		p1.x,p1.y,0f0, 1f0,0f0,
	# 		p2.x,p2.y,0f0, 1f0,1f0,
	# 		p3.x,p3.y,0f0, 0f0,1f0,
	# 		p4.x,p4.y,0f0, 0f0,0f0,
	# 		p1.x,p1.y,0f0, 1f0,0f0]
	data = [c.x,c.y,0f0,0.5f0,0.5f0,
			p1.x,p1.y,0f0, 0f0,0f0,
			p2.x,p2.y,0f0, 0f0,1f0,
			p4.x,p4.y,0f0, 1f0,1f0,
			p3.x,p3.y,0f0, 1f0,0f0,
			p1.x,p1.y,0f0, 0f0,0f0]
	glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW) #copy to the GPU
	glUseProgram(prog.sprite)
	glUniform4f(prog.sprite_colorLoc, f(s.color.r), f(s.color.g), f(s.color.b), f(s.color.α))
	#gpu_upload(camera)
	glActiveTexture(GL_TEXTURE0)
	glBindTexture(GL_TEXTURE_2D, s.texture)
	glUniform1i(prog.sprite_textureLoc, 0) #NOTE: This 0 corresponds to the GL_TEXTURE0 that is active.
	glDrawArrays(GL_TRIANGLE_FAN, 0, 6)
end
Base.show(s::Sprite,io::IO) = println("Sprite with texture stored on GPU at $(s.texture)")

end
