import GLFW
import ModernGL
GL = ModernGL

GLFW.Init() || @error("GLFW failed to initialize")

# Specify OpenGL version
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3);
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3);
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE);

# Create a window and its OpenGL context
width, height = 640,480
window = GLFW.CreateWindow(width, height, "Barel Engine")
if isnothing(window)
	@error("Window or context creation failed.")
	GL.glfwTerminate()
end
# Make the window's context current
GLFW.MakeContextCurrent(window)
GL.glViewport(0, 0, width, height);
GLFW.SwapInterval(0); #Activate V-sync

function error_callback(error, description::String)
	@error(description)
	return nothing
end
GLFW.SetErrorCallback(error_callback);

function key_callback(window::GLFW.Window, key::GLFW.Key, scancode::Int32, action::GLFW.Action, mods::Int32)
    if (key == GLFW.KEY_ESCAPE && action == GLFW.PRESS)
        GLFW.SetWindowShouldClose(window, true);
	end
end
GLFW.SetKeyCallback(window, key_callback);

function framebuffer_size_callback(window::GLFW.Window, width, height)
    GL.glViewport(0, 0, width, height);
	println("The window was resized to $width × $height")
	return nothing
end
GLFW.SetFramebufferSizeCallback(window, framebuffer_size_callback);

function clearColorBuffer(r::Float64, g::Float64, b::Float64, α::Float64=1.0)
	GL.glClearColor(r, g, b, α)
	GL.glClear(GL.GL_COLOR_BUFFER_BIT)
end
clearColorBuffer(r::Integer,g::Integer,b::Integer,α::Integer=255) = clearColorBuffer(r/255,g/255,b/255,α/255)
clearColorBuffer() = clearColorBuffer(0.0,0.0,0.0,1.0)

# Compilation and linking of shaders
function checkCompilation(shader::UInt32)
	success = Int32[-1];
	GL.glGetShaderiv(shader, GL.GL_COMPILE_STATUS, success);
	if success[1]!=1
		infoLog_length = Int32[0]
		GL.glGetShaderiv(shader, GL.GL_INFO_LOG_LENGTH, infoLog_length);
		infoLog = Vector{UInt8}(undef,infoLog_length[1]+1); #+1 might be necessary to store the C string terminator
	    GL.glGetShaderInfoLog(shader, infoLog_length[1], infoLog_length, infoLog);
		s_infoLog = String(infoLog[1:infoLog_length[1]])
	    println("ERROR::SHADER::COMPILATION_FAILED\n"*s_infoLog);
	end
	return success[1]
end

function checkLinking(program::UInt32)
	success = Int32[-1];
	GL.glGetProgramiv(program, GL.GL_LINK_STATUS, success);
	if success[1]!=1
		infoLog_length = Int32[0]
		GL.glGetShaderiv(shader, GL.GL_INFO_LOG_LENGTH, infoLog_length);
		infoLog = Vector{UInt8}(undef,infoLog_length[1]+1); #+1 might be necessary to store the C string terminator
		GL.glGetProgramInfoLog(program, infoLog_length[1], infoLog_length, infoLog);
		s_infoLog = String(infoLog[1:infoLog_length[1]])
		println("ERROR::PROGRAM::LINKING_FAILED\n"*s_infoLog);
	end
	return success[1]
end

vertexShaderSource = """
#version 330 core
layout (location = 0) in vec3 aPos;
void main()
{
	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0f);
}\0
""";
vertexShader = GL.glCreateShader(GL.GL_VERTEX_SHADER); #UInt32
GL.glShaderSource(vertexShader, 1, [vertexShaderSource], [length(vertexShaderSource)]);
GL.glCompileShader(vertexShader);
checkCompilation(vertexShader)

fragmentShaderSource = """
#version 330 core
out vec4 FragColor;

void main()
{
    FragColor = vec4(1.0f, 0.5f, 0.2f, 0.5f);
}\0
""";
fragmentShader = GL.glCreateShader(GL.GL_FRAGMENT_SHADER); #UInt32
GL.glShaderSource(fragmentShader, 1, [fragmentShaderSource], [length(fragmentShaderSource)]);
GL.glCompileShader(fragmentShader);
checkCompilation(fragmentShader)

# Creating the shader program
shaderProgram = GL.glCreateProgram(); #UInt32
GL.glAttachShader(shaderProgram, vertexShader);
GL.glAttachShader(shaderProgram, fragmentShader);
GL.glLinkProgram(shaderProgram);
checkLinking(shaderProgram)

# NOTE: This Program can be used through: GL.glUseProgram(shaderProgram);

# Setup for the drawing of a triangle
vertices = Float32[-0.5, -0.5, 0.0,
  			0.5, -0.5, 0.0,
  			0.0,  0.5, 0.0]

vao = UInt32[0] # Vertex Array Object
GL.glGenVertexArrays(1, vao)
GL.glBindVertexArray(vao[1])

vbo = UInt32[0] # Vertex Buffer Object
GL.glGenBuffers(1,vbo)
GL.glBindBuffer(GL.GL_ARRAY_BUFFER, vbo[1])
GL.glBufferData(GL.GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL.GL_STATIC_DRAW)

GL.glEnableVertexAttribArray(0)
GL.glVertexAttribPointer(0, 3, GL.GL_FLOAT, GL.GL_FALSE, 3*sizeof(Float32), Ptr{Nothing}(0))

function testDraw()
	GL.glBindVertexArray(vao[1])
	GL.glUseProgram(shaderProgram)
	GL.glDrawArrays(GL.GL_TRIANGLES, 0, 3)
	#GL.glBindVertexArray(0)
end

function drawTriangles(vertices)
	vao = UInt32[0] # Vertex Array Object
	GL.glGenVertexArrays(1, vao)
	GL.glBindVertexArray(vao[1])

	vbo = UInt32[0] # Vertex Buffer Object
	GL.glGenBuffers(1,vbo)
	GL.glBindBuffer(GL.GL_ARRAY_BUFFER, vbo[1])
	GL.glBufferData(GL.GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL.GL_STATIC_DRAW)

	GL.glEnableVertexAttribArray(0)
	GL.glVertexAttribPointer(0, 3, GL.GL_FLOAT, GL.GL_FALSE, 3*sizeof(Float32), Ptr{Nothing}(0))

	GL.glUseProgram(shaderProgram)
	GL.glDrawArrays(GL.GL_TRIANGLES, 0, Int(length(vertices)/3))
end

function genRandomTriangles(n::Int)
	# Generate the random triangles
#	vertices = Vector{Float32}(3*n, undef)
	r = 2*rand(Float32,9,n).-1 #values between -1 and 1
	r[4:6,:] = r[1:3,:]+0.1*r[4:6,:]
	r[7:9,:] = r[1:3,:]+0.1*r[7:9,:]
	vertices = reshape(r,9*n,1)
end


# GL.glGetError()
# clearColorBuffer(0.2,0.3,0.3,1.0)
# testDraw()
# GLFW.SwapBuffers(window)
# GLFW.PollEvents()

GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_LINE);

# Main render loop
t = time_ns()
# Loop until the user closes the window
while !GLFW.WindowShouldClose(window)
	# FPS calculation and show in window title
	global t
	fps = 1e9/(time_ns()-t)
	t = time_ns()
	s_fps = fps==Inf ? "Inf" : string(round(Int,fps))
	GLFW.SetWindowTitle(window, "Barel Engine at "*s_fps*" fps");

	# Render here
	clearColorBuffer(0.2,0.3,0.3,1.0)
	#testDraw()
	triangles = genRandomTriangles(1000)
	drawTriangles(triangles)

	# Swap front and back buffers
	GLFW.SwapBuffers(window)

	# Poll for and process events
	GLFW.PollEvents()
	err = GL.glGetError()
	err == 0 || @error("GL Error code $err")
end

# Finalize
GLFW.DestroyWindow(window)
GLFW.Terminate()
# return 0;

#### Experimental

# function drawTrianlge(vertices::Vector{Float64})
# 	vao = UInt32[0]; # Vertex Array Object
# 	GL.glGenVertexArrays(1, vao);
# 	GL.glBindVertexArray(vao[1]);
# 	vbo = UInt32[0]; # Vertex Buffer Object
# 	GL.glGenBuffers(1,vbo)
# 	GL.glBindBuffer(GL.GL_ARRAY_BUFFER, vbo[1])
# 	GL.glBufferData(GL.GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL.GL_STATIC_DRAW);
# end
#
# struct Vertex
# 	x::Float64
# 	y::Float64
# 	z::Float64
# end
# function drawTriangle(vertices::Vector{Vertex})
# 	v1 = vertices[1]
# 	v2 = vertices[2]
# 	v3 = vertices[3]
# 	drawTriangle([v1.x, v1.y, v1.z,
# 				   v2.x, v2.y, v2.z
# 				   v3.x, v3.y, v3.z])
# end
