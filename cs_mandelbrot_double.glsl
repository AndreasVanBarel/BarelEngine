#version 430 core

#extension GL_ARB_gpu_shader_fp64 : enable

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout (binding = 0) uniform writeonly image2D out_tex; //must be the same format as in the host program
uniform sampler1D colors; //color map
   
layout (location = 1) uniform dvec2 center;
layout (location = 2) uniform double scale;  
//center 0.0 and scale 1.0 give unit square

layout (location = 3) uniform int maxit;

layout (location = 4) uniform float p1;    
layout (location = 5) uniform float p2;    


void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);

    dvec2 npos; //normalized position between 0.0 and 1.0
    npos.x = double(pos.x)/(gl_NumWorkGroups.x * gl_WorkGroupSize.x);
    npos.y = double(pos.y)/(gl_NumWorkGroups.y * gl_WorkGroupSize.y);

    //normalized position between -1.0 and 1.0
    npos.x = (npos.x*2-1.0)*scale + center.x;
	npos.y = (npos.y*2-1.0)*scale + center.y;

    dvec2 c = npos;
    dvec2 z = c;

    int i;
    for(i=0; i<maxit; i++) {
        // z^2 + c
        double z_real = (z.x * z.x - z.y * z.y) + c.x;
        double z_imag = (z.y * z.x + z.x * z.y) + c.y;

        // z^3 + c
        // double z_real = (z.x*z.x*z.x - 3*z.x*z.y*z.y) + c.x;
        // double z_imag = (3*z.x*z.x*z.y - z.y*z.y*z.y) + c.y;

        if((z_real * z_real + z_imag * z_imag) > 4.0) break;
        z.x = z_real;
        z.y = z_imag;
    }

    // float result = (i == maxit ? 0.0 : float(i)) / (maxit-1); // color result between 0 and 1
    // vec4 value = vec4(result, result, result, 1.0);

    float result = float(i+1) / 25;
    result = mod(log(result), 1.0); //result between 0.0 and 1.0

    result = p1 + (p2-p1)*result;

    vec4 value = i == maxit ? vec4(0.0,0.0,0.0,1.0) : texture(colors, result);

    imageStore(out_tex, pos, value);
}