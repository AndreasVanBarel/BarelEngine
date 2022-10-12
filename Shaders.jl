# contains utilities for working with shaders in OpenGL
# - Compiling shaders
# - Setting variables in shaders
# - Allocating GPU memory and transfering data to and from the GPU 

module Shaders 

using ModernGL

export checkCompilation, checkLinking
export createVertexShader, createFragmentShader, createProg
export createComputeShader, createComputeProg, compile, compile_file
export execute

export gen_texture_pointer
export Texture, bind, shape, size, set_zeros
export TextureType
export get_julia_type, get_nb_values
export TYPE_R32F, TYPE_RG32F, TYPE_RGB32F, TYPE_RGBA32F

export set, get, get!

import Base: bind, size, ndims, get

##
const null = Ptr{Nothing}() # Note: same as C_NULL

function debug(s)
    err = glGetError()
    println("s with errors: $err")
    err == 0 || @error("GL Error code $err")
end

## Compilation and linking of shaders
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

## Vertex shaders and fragment shaders
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

## Compute Shaders 
function createComputeShader(src::String)
	shader = glCreateShader(GL_COMPUTE_SHADER) #UInt32
	glShaderSource(shader, 1, [src], [length(src)])
	glCompileShader(shader)
	checkCompilation(shader)
	return shader
end
function createComputeProg(cs_src::String)
	cs = createComputeShader(cs_src) # compute shader
	prog = glCreateProgram() #UInt32
	glAttachShader(prog, cs)
	glLinkProgram(prog)
	checkLinking(prog)
	return prog
end

## Compiling
# filepath containing code, returning pointer to GPU code. 
function compile_file(filepath::String)
    shader_code = open(filepath) do io read(io, String) end
    return compile(shader_code)
end
compile(shader_code::String) = createComputeProg(shader_code)

function execute(prog, workgroups_x::Integer, workgroups_y::Integer, workgroups_z::Integer)
    glUseProgram(prog)
    glDispatchCompute(workgroups_x, workgroups_y, workgroups_z) # Dispatch (i.e., execute)
end

## Utility functions for quickly setting integer and float uniforms
function set(prog::UInt32, identifier::String, values...)
    loc = glGetUniformLocation(prog, identifier)
    (loc == -1) && @warn("identifier not found in shader (loc=-1)")
    glUseProgram(prog)
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

## GPU Data

# !Texture is will not be bound to anything (not to GL_TEXTURE_2D or any other)
function gen_texture_pointer()::UInt32
    # Allocate texture name (textureP[1]) and bind it to GL_TEXTURE_2D
    texturePP = UInt32[0] # texturePP[1] will contain pointer to texture memory
    glGenTextures(1, texturePP) # sets texturePP[1] (generates 1 of the previously unused texture names; gets deallocated with glDeleteTextures)
    textureP = texturePP[1]
    return textureP
end

struct TextureType
    internal_format::UInt32
    format::UInt32
    type::UInt32
end
const TYPE_R32F = TextureType(GL_R32F, GL_RED, GL_FLOAT)
const TYPE_RG32F = TextureType(GL_RG32F, GL_RG, GL_FLOAT)
const TYPE_RGB32F = TextureType(GL_RGB32F, GL_RGB, GL_FLOAT)
const TYPE_RGBA32F = TextureType(GL_RGBA32F, GL_RGBA, GL_FLOAT)
function GL_TEXTURE(D::UInt8)::UInt32
    D==1 && return GL_TEXTURE_1D
    D==2 && return GL_TEXTURE_2D
    D==3 && return GL_Texture_3D
    @error("Texture dimension not supported")
    return UInt32(0)
end
function get_julia_type(t::TextureType)
    t.internal_format == GL_R32F && return Float32
    t.internal_format == GL_RG32F && return Float32
    t.internal_format == GL_RGB32F && return Float32
    t.internal_format == GL_RGBA32F && return Float32
    return Nothing
end
function get_nb_values(t::TextureType)::UInt8
    t.format == GL_RED && return 0x01
    t.format == GL_RG && return 0x02
    t.format == GL_RGB && return 0x03
    t.format == GL_RGBA && return 0x04
    return 0x01
end

struct Texture 
    pointer::UInt32 # GPU pointer to this texture
    type::TextureType 
    D::UInt8 # either 1d, 2d or 3d
end
function Texture(type::TextureType,D)
    tex = Texture(gen_texture_pointer(),type,UInt8(D))

    bind(tex)

    glTexParameteri(GL_TEXTURE(tex.D), GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE(tex.D), GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE(tex.D), GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE(tex.D), GL_TEXTURE_MIN_FILTER, GL_NEAREST)

    return tex
end
bind(tex::Texture) = glBindTexture(GL_TEXTURE(tex.D), tex.pointer)
# function bind(tex::Texture, tex_unit::Integer) 
#     glActiveTexture(GL_TEXTURE0 + tex_unit)
#     glBindTexture(GL_TEXTURE(tex.D), tex.pointer)
# end
# Binds texture to image unit
function bind(tex::Texture, im_unit::Integer) 
    glBindImageTexture(im_unit, tex.pointer, 0, GL_FALSE, 0, GL_READ_WRITE, tex.type.internal_format) # "bind a level of a texture to an image unit"
end
free(tex::Texture) = glDeleteTextures(1,tex.pointer)

# returns all of the applicable (width,height,depth) 
function shape(tex)
    miplevel = 0
    widthP = Int32[0]
    glGetTexLevelParameteriv(GL_TEXTURE(tex.D), miplevel, GL_TEXTURE_WIDTH, widthP);
    tex.D <= 1 && return (widthP[1],)
    heightP = Int32[0]
    glGetTexLevelParameteriv(GL_TEXTURE(tex.D), miplevel, GL_TEXTURE_HEIGHT, heightP);
    tex.D <= 2 && return (widthP[1], heightP[1])
    depthP = Int32[0]
    glGetTexLevelParameteriv(GL_TEXTURE(tex.D), miplevel, GL_TEXTURE_DEPTH, depthP);
    tex.D <= 2 && return (widthP[1], heightP[1], depthP[1])
end 
function size(tex)
    get_nb_values(tex.type) == 1 && return shape(tex)
    return (get_nb_values(tex.type), shape(tex)...) 
end
ndims(tex) = get_nb_values(tex.type) == 1 ? Int(tex.D) : Int(tex.D + 1)

# function set_zeros(tex::Texture, width::Integer)
#     glBindTexture(GL_TEXTURE(tex.D), tex.pointer) # GL_TEXTURE_1D is then an 'alias' for textureP
#     glTexImage2D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, width, 0, tex.type.format, tex.type.type, null) # fills the texture with null values
# end
# function set_zeros(tex::Texture, width::Integer, height::Integer)
#     glBindTexture(GL_TEXTURE(tex.D), tex.pointer) # GL_TEXTURE_2D is then an 'alias' for textureP
#     glTexImage2D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, width, height, 0, tex.type.format, tex.type.type, null) # fills the texture with null values
# end
# function set_zeros(tex::Texture, width::Integer, height::Integer, depth::Integer)
#     glBindTexture(GL_TEXTURE(tex.D), tex.pointer) # GL_TEXTURE_3D is then an 'alias' for textureP
#     glTexImage2D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, width, height, depth, 0, tex.type.format, tex.type.type, null) # fills the texture with null values
# end
function set_zeros(tex::Texture, shape...)
    tex.D == length(shape) || @error("Tried to set $(tex.D)D texture with $(length(size))D values")
    glBindTexture(GL_TEXTURE(tex.D), tex.pointer) # GL_TEXTURE_1D is then an 'alias' for textureP
    glTexImage2D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, shape..., 0, tex.type.format, tex.type.type, null) # fills the texture with null values
end


function bind_image_texture(tex::Texture, binding::Integer)
    glBindImageTexture(binding, tex.pointer, 0, GL_FALSE, 0, GL_READ_WRITE, tex.type.type) # "bind a level of a texture to an image unit"
    # First variable is binding index, 0 in this case. This corresponds to the "binding=0" part in the shader
end

# Sets values in given Texture tex
function set(tex::Texture, values::Array) #values is essentially a pointer to a Float32 array
    get_julia_type(tex.type) == eltype(values) || @error("Tried to set $(get_julia_type(tex.type)) texture with $(eltype(values)) values")
    shape = size(values)[end-tex.D+1:end] #gets last tex.D entries in size(values)
    bind(tex)
    glTexImage2D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, shape..., 0, tex.type.format, tex.type.type, values)
end

# Gets values to currently bound GL_TEXTURE_2D
function get(tex::Texture)
    data = Array{get_julia_type(tex.type),ndims(tex)}(undef, size(tex)...)
    get!(tex::Texture, data)
    return data
end

# Copies values currently bound to GL_TEXTURE_2D in a given data structure. The user must make sure the data structure is of the correct type and size.
function get!(tex::Texture, data)
    bind(tex)
    glGetTexImage(GL_TEXTURE(tex.D), 0, tex.type.format, tex.type.type, data) 
    return data
end

end