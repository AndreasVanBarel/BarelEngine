#version 450 core

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
layout (rgba32f, binding = 0) uniform readonly image2D in_tex; //must be the same format as in the host program
layout (binding = 1) uniform writeonly image2D out_tex; //must be the same format as in the host program

layout (location = 2) uniform float mu; //diffusion coefficient, set to 0.0 for no diffusion
layout (location = 3) uniform float lambda; //decay coefficient, set to 0.0 for no decay
layout (location = 4) uniform float dt; //time spent
// NOTE: dt*mu should be between 0 and 1/5

const ivec2 tile_size = ivec2(4,4); // Local tile size (without halo)

void main() {
    float decay = exp(-lambda*dt);
    float diff = min(dt*mu, 0.2);

    ivec2 globalID = ivec2(gl_GlobalInvocationID.xy); // Global thread ID (pixel to work on)
    ivec2 localID = ivec2(gl_LocalInvocationID.xy);   // Local thread ID
    ivec2 groupID = ivec2(gl_WorkGroupID.xy);         // Work group ID

    // Memory for tile with halo
    vec4 tile[tile_size.x + 2][tile_size.y + 2];

    // == Tile fetching ==
    ivec2 tileOrigin = globalID * tile_size - ivec2(1, 1); // global origin of the current workgroup
    for (int x = 0; x < tile_size.x + 2; x++) {    
        for (int y = 0; y < tile_size.y + 2; y++) {
            ivec2 fetchCoord = tileOrigin + ivec2(x, y);
            fetchCoord = clamp(fetchCoord, ivec2(0, 0), imageSize(in_tex) - ivec2(1, 1)); // Clamp to image boundaries
            tile[x][y] = imageLoad(in_tex, fetchCoord); // Fetch texel and store it in shared memory
            // note that out of bounds imageLoad returns 0
        }
    }

    // == Tile processing == 
    for (int x = 1; x < tile_size.x + 1; x++) {    
        for (int y = 1; y < tile_size.y + 1; y++) {
            ivec2 coord = tileOrigin + ivec2(x, y);
            coord = clamp(coord, ivec2(0, 0), imageSize(in_tex) - ivec2(1, 1)); // Clamp to image boundaries

            // == Getting current (central) texel and neighbors ==
            vec4 in_vals = tile[x][y]; // current value in the cell
            vec3 central = in_vals.rgb;
            vec3 left = tile[x-1][y].rgb;
            vec3 right = tile[x+1][y].rgb;
            vec3 up = tile[x][y+1].rgb;
            vec3 down = tile[x][y-1].rgb;

            // == Diffusion ==
            vec3 sum = left+right+up+down;
            vec3 res = decay * ((1-4*diff)*central + diff*sum);

            // == Write the result to the output texture ==
            imageStore(out_tex, coord, vec4(res,in_vals.a));
        }
    }

    // // == Getting current (central) texel and neighbors ==
    // // Compute the coordinates in shared memory for this thread
    // ivec2 sharedCoord = localID + ivec2(1, 1);

    // // Fetch neighbors
    // vec4 in_vals = tile[sharedCoord.x][sharedCoord.y]; // current value in the cell
    // vec3 central = in_vals.rgb;
    // vec3 left = tile[sharedCoord.x-1][sharedCoord.y].rgb;
    // vec3 right = tile[sharedCoord.x+1][sharedCoord.y].rgb;
    // vec3 up = tile[sharedCoord.x][sharedCoord.y+1].rgb;
    // vec3 down = tile[sharedCoord.x][sharedCoord.y-1].rgb;

    // // vec4 in_vals = imageLoad(in_tex, globalID);
    // // vec3 central = in_vals.rgb; // current value in the cell
    // // vec3 left = imageLoad(in_tex, globalID + ivec2(-1,0)).rgb;
    // // vec3 right = imageLoad(in_tex, globalID + ivec2(1,0)).rgb;
    // // vec3 up = imageLoad(in_tex, globalID + ivec2(0,1)).rgb;
    // // vec3 down = imageLoad(in_tex, globalID + ivec2(0,-1)).rgb;
    // // // note that out of bounds imageLoad returns 0

    // // == Diffusion ==
    // vec3 sum = left+right+up+down;
    // vec3 res = decay * ((1-4*diff)*central + diff*sum);

    // // == Write the result to the output texture ==
    // imageStore(out_tex, globalID, vec4(res,in_vals.a));
}