module GLPrograms

export generatePrograms
using ModernGL

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
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, infoLog_length)
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

void main()
{
	FragColor = vec4(1.0f, 0.5f, 0.2f, 0.5f);
}\0
""";

function generatePrograms()
	## Triangle
	# Vertex Shader
	triangle_vs = glCreateShader(GL_VERTEX_SHADER) #UInt32
	glShaderSource(triangle_vs, 1, [triangle_vs_src], [length(triangle_vs_src)])
	glCompileShader(triangle_vs)
	checkCompilation(triangle_vs)

	# Fragment Shader
	triangle_fs = glCreateShader(GL_FRAGMENT_SHADER) #UInt32
	glShaderSource(triangle_fs, 1, [triangle_fs_src], [length(triangle_fs_src)])
	glCompileShader(triangle_fs)
	checkCompilation(triangle_fs)

	# Program
	triangle_prog = glCreateProgram(); #UInt32
	glAttachShader(triangle_prog, triangle_vs)
	glAttachShader(triangle_prog, triangle_fs)
	glLinkProgram(triangle_prog)
	checkLinking(triangle_prog)

	return triangle_prog
end

end
