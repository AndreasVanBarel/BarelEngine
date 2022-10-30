#version 430 core

layout (local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
layout (binding = 1) uniform writeonly image2D out_tex; //must be the same format as in the host program

layout (std430, binding = 2) buffer ParticlesBuffer
{
    vec4 particles[];
};

layout (std430, binding = 5) buffer ParticleColors
{
    uint colors[];
};

// layout (location = 3) uniform int width;
// layout (location = 4) uniform int height;

vec4 get_color(uint i) {
    uint c = colors[i];
    uint r = (c >> 0) & 0xff;
    uint g = (c >> 8) & 0xff;
    uint b = (c >> 16) & 0xff;
    uint a = (c >> 24) & 0xff;
    return vec4(r,g,b,a)/255;
}

void main() {
    uint index = gl_GlobalInvocationID.x; //particle to work on

    vec4 p = particles[index];
    vec4 color = get_color(index);

    float posx = p.x;
    float posy = p.y;
    float velx = p.z;
    float vely = p.w;

    int nx = int(posx);
    int ny = int(posy);

    imageStore(out_tex, ivec2(nx,ny), color);
}