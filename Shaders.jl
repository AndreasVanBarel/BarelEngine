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
export Texture, free, bind, bind_texture_unit, bind_image_unit, shape, size, allocate
export TextureType
export get_julia_type, get_nb_values
export TYPE_R32F, TYPE_RG32F, TYPE_RGB32F, TYPE_RGBA32F
export TYPE_R8, TYPE_RG8, TYPE_RGB8, TYPE_RGBA8

export gen_buffer_pointer 
export Buffer, bind_buffer_unit

export set, get, get!

import Base: bind, size, ndims, get

## General
const null = Ptr{Nothing}() # Note: same as C_NULL

function debug(s)
    err = glGetError()
    println("s with errors: $err")
    err == 0 || @error("GL Error code $err")
end

# Should remove this; errors should probably be checked somewhere centrally. (?)
function check_errors()
    err = glGetError()
    err == 0 || @error("GL Error code $err")
end

## Compiling and linking shaders
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

# filepath containing code, returning pointer to GPU code. 
function compile_file(filepath::String)
    shader_code = open(filepath) do io read(io, String) end
    return compile(shader_code)
end
compile(shader_code::String) = createComputeProg(shader_code)

## Execution
function execute(prog, workgroups_x::Integer, workgroups_y::Integer, workgroups_z::Integer)
    glUseProgram(prog)
    glDispatchCompute(workgroups_x, workgroups_y, workgroups_z) # Dispatch (i.e., execute)
end

## Utility functions for quickly setting integer and float uniforms
function set(prog::UInt32, identifier::String, values...)
    loc = glGetUniformLocation(prog, identifier)
    (loc == -1) && @warn("identifier not found in shader (loc=$loc)")
    glUseProgram(prog)
    set(loc, values...)
end 
set(loc::Integer, value::Float32) = glUniform1f(loc,value)
set(loc::Integer, v1::Float32, v2::Float32) = glUniform2f(loc,v1,v2)
set(loc::Integer, v1::Float32, v2::Float32, v3::Float32) = glUniform3f(loc,v1,v2,v3)
set(loc::Integer, v1::Float32, v2::Float32, v3::Float32, v4::Float32) = glUniform4f(loc,v1,v2,v3,v4)
set(loc::Integer, value::Float64) = glUniform1d(loc,value)
set(loc::Integer, v1::Float64, v2::Float64) = glUniform2d(loc,v1,v2)
set(loc::Integer, v1::Float64, v2::Float64, v3::Float64) = glUniform3d(loc,v1,v2,v3)
set(loc::Integer, v1::Float64, v2::Float64, v3::Float64, v4::Float64) = glUniform4d(loc,v1,v2,v3,v4)
set(loc::Integer, value::Int32) = glUniform1i(loc,value)
set(loc::Integer, v1::Int32, v2::Int32) = glUniform2i(loc,v1,v2)
set(loc::Integer, v1::Int32, v2::Int32, v3::Int32) = glUniform3i(loc,v1,v2,v3)
set(loc::Integer, v1::Int32, v2::Int32, v3::Int32, v4::Int32) = glUniform4i(loc,v1,v2,v3,v4)

## GPU Data

## Textures 

# !Texture will not be bound to anything (not to GL_TEXTURE_2D or any other)
function gen_texture_pointer()::UInt32
    texturePP = UInt32[0] # texturePP[1] will contain pointer to texture memory
    glGenTextures(1, texturePP) # sets texturePP[1] (generates 1 of the previously unused texture names; gets deallocated with glDeleteTextures)
    textureP = texturePP[1]
    return textureP
end

struct TextureType
    internal_format::UInt32 # Format of each pixel on the GPU
    format::UInt32 # Number of components per pixel
    type::UInt32 # Format of each component on the CPU side
end
const TYPE_R32F = TextureType(GL_R32F, GL_RED, GL_FLOAT)
const TYPE_RG32F = TextureType(GL_RG32F, GL_RG, GL_FLOAT)
const TYPE_RGB32F = TextureType(GL_RGB32F, GL_RGB, GL_FLOAT)
const TYPE_RGBA32F = TextureType(GL_RGBA32F, GL_RGBA, GL_FLOAT)
const TYPE_R8 = TextureType(GL_R8, GL_RED, GL_UNSIGNED_BYTE)
const TYPE_RG8 = TextureType(GL_RG8, GL_RG, GL_UNSIGNED_BYTE)
const TYPE_RGB8 = TextureType(GL_RGB8, GL_RGB, GL_UNSIGNED_BYTE) # !Must do bind_image_unit(_, _, GL_RGBA8) since GL_RGB8 not defined, see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBindImageTexture.xhtml
const TYPE_RGBA8 = TextureType(GL_RGBA8, GL_RGBA, GL_UNSIGNED_BYTE)

function GL_TEXTURE(D::UInt8)::UInt32
    D==1 && return GL_TEXTURE_1D
    D==2 && return GL_TEXTURE_2D
    D==3 && return GL_Texture_3D
    @error("Texture dimension not supported")
    return UInt32(0)
end
function get_julia_type(t::TextureType)
    t.type == GL_FLOAT && return Float32
    t.type == GL_UNSIGNED_BYTE && return UInt8
    return Nothing
end
function get_nb_values(t::TextureType)
    t.format == GL_RED && return 1
    t.format == GL_RG && return 2
    t.format == GL_RGB && return 3
    t.format == GL_RGBA && return 4
    return 1
end

struct Texture 
    pointer::UInt32 # GPU pointer to this texture
    type::TextureType 
    D::UInt8 # either 1d, 2d or 3d
end
function Texture(type::TextureType,D)
    tex = Texture(gen_texture_pointer(),type,UInt8(D))

    # Setting some default values
    bind(tex)
    glTexParameteri(GL_TEXTURE(tex.D), GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE(tex.D), GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE(tex.D), GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE(tex.D), GL_TEXTURE_MIN_FILTER, GL_NEAREST)

    return tex
end
free(tex::Texture) = glDeleteTextures(1,[tex.pointer]) # Deallocates and frees on the GPU

# Binds currently active texture unit's GL_TEXTURE_X to tex, where X depends on tex's properties.
bind(tex::Texture) = glBindTexture(GL_TEXTURE(tex.D), tex.pointer) 

# Sets currently active texture unit 
bind_texture_unit(tex_unit::Integer) = glActiveTexture(GL_TEXTURE0 + tex_unit) 

# Binds a texture to a texture unit (and sets currently active texture)
function bind_texture_unit(tex_unit::Integer, tex::Texture) 
    bind_texture_unit(tex_unit)
    glBindTexture(GL_TEXTURE(tex.D), tex.pointer)
end

# Binds a texture to an image unit
#   First variable is image unit index, This corresponds to the "binding=<image_unit>" part in the shader
#   Last variable gives format to present to the shader, which could be different from internal image format.
function bind_image_unit(image_unit::Integer, tex::Texture, shader_format=tex.type.internal_format; access=GL_READ_WRITE)
    glBindImageTexture(image_unit, tex.pointer, 0, GL_FALSE, 0, access, shader_format) # "bind a level of a texture to an image unit"
end

# returns all of the applicable (width,height,depth) 
function shape(tex::Texture)
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
function size(tex::Texture)
    get_nb_values(tex.type) == 1 && return shape(tex)
    return (get_nb_values(tex.type), shape(tex)...) 
end
size(tex::Texture,i::Integer) = size(tex)[i]
ndims(tex::Texture) = get_nb_values(tex.type) == 1 ? Int(tex.D) : Int(tex.D + 1)

# Allocates memory for the texture accomodating the given shape
function allocate(tex::Texture, shape...) 
    tex.D == length(shape) || @error("Tried to init $(tex.D)D texture with $(length(size))D shape")
    bind(tex)
    tex.D==1 && glTexImage1D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, shape..., 0, tex.type.format, tex.type.type, null) 
    tex.D==2 && glTexImage2D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, shape..., 0, tex.type.format, tex.type.type, null) 
    tex.D==3 && glTexImage3D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, shape..., 0, tex.type.format, tex.type.type, null) 
    return 
end

# Sets values in given Texture tex
function set(tex::Texture, values::Array) #values is essentially a pointer to a Float32 array
    get_julia_type(tex.type) == eltype(values) || @error("Tried to set $(get_julia_type(tex.type)) texture with $(eltype(values)) values")
    shape = size(values)[end-tex.D+1:end] #gets last tex.D entries in size(values)
    bind(tex)
    tex.D==1 && glTexImage1D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, shape..., 0, tex.type.format, tex.type.type, values)
    tex.D==2 && glTexImage2D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, shape..., 0, tex.type.format, tex.type.type, values)
    tex.D==3 && glTexImage3D(GL_TEXTURE(tex.D), 0, tex.type.internal_format, shape..., 0, tex.type.format, tex.type.type, values)
    check_errors()
    return
end

# Gets values in tex
function get(tex::Texture)
    data = Array{get_julia_type(tex.type),ndims(tex)}(undef, size(tex)...)
    get!(tex::Texture, data)
    return data
end

# Copies values in tex to a given data structure. The user must make sure the data structure is of the correct type and size.
function get!(tex::Texture, data)
    bind(tex)
    glGetTexImage(GL_TEXTURE(tex.D), 0, tex.type.format, tex.type.type, data) 
    return data
end

## Buffers 

# !Buffer will not be bound to anything (not to GL_SHADER_STORAGE_BUFFER or any other)
function gen_buffer_pointer()::UInt32
    bufferPP = UInt32[0] # bufferP[1] will contain pointer to buffer memory
    glGenBuffers(1, bufferPP) # sets bufferP[1] (generates 1 of the previously unused buffer names; gets deallocated with glDeleteBuffers)
    bufferP = bufferPP[1]
    return bufferP
end

struct Buffer 
    pointer::UInt32 # GPU pointer to this buffer
end

function Buffer()
    buf = Buffer(gen_buffer_pointer())
    return buf
end
free(buf::Buffer) = glDeleteBuffers(1,[buf.pointer]) # Deallocates and frees on the GPU

# Binds GL_SHADER_STORAGE_BUFFER to buf
bind(buf::Buffer) = glBindBuffer(GL_SHADER_STORAGE_BUFFER, buf.pointer) 
# unbind(::Buffer) = glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);

# Binds buffer to given binding point
function bind_buffer_unit(buf_unit::Integer, buf::Buffer)
    bind(buf)
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, buf_unit, buf.pointer) #glBindBufferRange 
end

# Allocates len bytes of memory for the buffer
function allocate(buf::Buffer, len::Integer) 
    bind(buf)
    glBufferData(GL_SHADER_STORAGE_BUFFER, len, 0, GL_DYNAMIC_DRAW)
    # unbind(buf)
    return
end

# Sets data in given Buffer buf
function set(buf::Buffer, data::Array) #values is essentially a pointer to a Float32 array
    bind(buf)
    glBufferData(GL_SHADER_STORAGE_BUFFER, length(data)*sizeof(eltype(data)), data, GL_DYNAMIC_DRAW)
    # unbind(buf)
    return
end

# returns the size of the buffer in bytes
function size(buf::Buffer)
    sizeP = UInt64[0]
    bind(buf)
    glGetBufferParameteri64v(GL_SHADER_STORAGE_BUFFER, GL_BUFFER_SIZE, sizeP)
    # unbind(buf)
    return sizeP[1]
end

# Gets data in buf cast to the given eltype (default is UInt8, i.e., byte by byte)
function get(eltype::Type, buf::Buffer)
    buf_size = size(buf)
    el_size = sizeof(eltype)
    data_size = ceil(Int, buf_size/el_size)
    data = Array{eltype}(undef, data_size)
    get!(buf::Buffer, data)
    return data
end
get(buf::Buffer) = get(UInt8, buf::Buffer)

# Copies data in buf to a given data structure. The user must make sure the data structure is of the correct type and size.
function get!(buf::Buffer, data)
    bind(buf)
    glGetBufferSubData(GL_SHADER_STORAGE_BUFFER, 0, size(buf), data)
    return data
end

end