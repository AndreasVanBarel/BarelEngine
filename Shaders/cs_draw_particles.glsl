#version 430 core

layout (local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
layout (binding = 1) uniform writeonly image2D out_tex; //must be the same format as in the host program

layout (std430, binding = 2) buffer ParticlesBuffer
{
    vec4 particles[];
};

layout (location = 3) uniform int width;
layout (location = 4) uniform int height;

void main() {
    vec4 color = vec4(1.0,1.0,1.0,1.0);

    uint index = gl_GlobalInvocationID.x; //particle to work on

    vec4 p = particles[index];
    float posx = p.x;
    float posy = p.y;
    float velx = p.z;
    float vely = p.w;

    int nx = int(posx * width);
    int ny = int(posy * height);

    imageStore(out_tex, ivec2(nx,ny), color);
}