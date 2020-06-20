module GLPrograms

export generatePrograms
using ModernGL

struct Programs
	triangle::UInt32
	triangle_colorLoc::Int32
	ellipse::UInt32
	ellipse_colorLoc::Int32
	sprite::UInt32
	sprite_colorLoc::Int32
	sprite_textureLoc::Int32
end

# Compilation and linking of shaders
function checkCompilation(shader::UInt32)
	success = Int32[-1]
	glGetShaderiv(shader, GL_COMPILE_STATUS, success)
	if success[1]!=1
		infoLog_length = Int32[0]
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, infoLog_length)
		infoLog = Vector{UInt8}(undef,infoLog_length[1]+1) #+1 might be necessary to store the C string terminator
	    glGetShaderInfoLog(shader, infoLog_length[1], infoLog_length, infoLog)
		s_infoLog = String(infoLog[1:infoLog_length[1]])
	    println("ERROR::SHADER::COMPILATION_FAILED\n"*s_infoLog)
	end
	return success[1]
end

function checkLinking(program::UInt32)
	success = Int32[-1]
	glGetProgramiv(program, GL_LINK_STATUS, success)
	if success[1]!=1
		infoLog_length = Int32[0]
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, infoLog_length)
		infoLog = Vector{UInt8}(undef,infoLog_length[1]+1) #+1 might be necessary to store the C string terminator
		glGetProgramInfoLog(program, infoLog_length[1], infoLog_length, infoLog)
		s_infoLog = String(infoLog[1:infoLog_length[1]])
		println("ERROR::PROGRAM::LINKING_FAILED\n"*s_infoLog)
	end
	return success[1]
end

# Vertex Shader for Triangle
triangle_vs_src = """
#version 330 core
layout (location = 0) in vec3 aPos;
void main()
{
	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0f);
}\0
""";

# Fragment Shader for Triangle
triangle_fs_src = """
#version 330 core
out vec4 FragColor;
uniform vec4 color;
void main()
{
	FragColor = color;
}\0
""";

# Vertex Shader for Ellipse
ellipse_vs_src = """
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 auv;
out vec2 uv;
void main()
{
	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0f);
	uv = auv;
}\0
""";

# Fragment Shader for Ellipse
ellipse_fs_src = """
#version 330 core
in vec2 uv;
out vec4 FragColor;
uniform vec4 color;
void main()
{
	float Rsq = 1.0;
    float dist = dot(uv,uv);
    if (dist > Rsq) {
        discard;
    }
	FragColor = color;
}\0
""";

# Vertex Shader for Sprite
sprite_vs_src = """
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 auv;
out vec2 uv;
void main()
{
	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0f);
	uv = auv;
}\0
""";

# Fragment Shader for Sprite
sprite_fs_src = """
#version 330 core
in vec2 uv;
out vec4 FragColor;
uniform vec4 color;
uniform sampler2D tex;
void main()
{
	FragColor = texture(tex, uv)*color;
}\0
""";

#FragColor = texture(tex, uv)*color;
#FragColor = vec4(uv,1.0f,1.0f);

function createVertexShader(src::String)
	shader = glCreateShader(GL_VERTEX_SHADER) #UInt32
	glShaderSource(shader, 1, [src], [length(src)])
	glCompileShader(shader)
	checkCompilation(shader)
	return shader
end
function createFragmentShader(src::String)
	shader = glCreateShader(GL_FRAGMENT_SHADER) #UInt32
	glShaderSource(shader, 1, [src], [length(src)])
	glCompileShader(shader)
	checkCompilation(shader)
	return shader
end
function createProg(vs_src::String, fs_src::String)
	vs = createVertexShader(vs_src) # vertex shader
	fs = createFragmentShader(fs_src) # fragment shader
	prog = glCreateProgram() #UInt32
	glAttachShader(prog, vs)
	glAttachShader(prog, fs)
	glLinkProgram(prog)
	checkLinking(prog)
	return prog
end
function generatePrograms()
	triangle_prog = createProg(triangle_vs_src, triangle_fs_src)
	triangle_colorLoc = glGetUniformLocation(triangle_prog, "color")
	ellipse_prog = createProg(ellipse_vs_src, ellipse_fs_src)
	ellipse_colorLoc = glGetUniformLocation(ellipse_prog, "color")
	sprite_prog = createProg(sprite_vs_src, sprite_fs_src)
	sprite_colorLoc = glGetUniformLocation(sprite_prog, "color")
	sprite_texLoc = glGetUniformLocation(sprite_prog, "tex")
	Programs(triangle_prog, triangle_colorLoc,
			ellipse_prog, ellipse_colorLoc,
			sprite_prog, sprite_colorLoc, sprite_texLoc)
end

end
