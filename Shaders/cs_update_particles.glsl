#version 430 core

layout (local_size_x = 128, local_size_y = 1, local_size_z = 1) in;
layout (rgba32f, binding = 0) uniform image2D world; //must be the same format as in the host program
// the above should probably become a sampler (since the texture should be sampled at non-integer values)

layout (std430, binding = 2) buffer ParticlesBuffer
{
    vec4 particles[];
};

layout (location = 3) uniform int width;
layout (location = 4) uniform int height;
layout (location = 5) uniform float dt;

// gets image pixel position from position in [0.0,1.0]x[0.0,1.0]
ivec2 get_impos(vec2 pos) {
    int imx = int(pos.x * width);
    int imy = int(pos.y * height);
    return ivec2(imx,imy);
}

// deposits pheromones of color pheromone_color in the world image at pixel impos 
void deposit(ivec2 impos, vec3 pheromone_color) {
    vec3 values = imageLoad(world, impos).xyz;
    imageStore(world, impos, vec4(min(values+pheromone_color, vec3(1.0,1.0,1.0)), 1.0));
}

float get_angle(vec2 v) {
    return v.x == 0.0 ? 0.0 : atan(v.y, v.x); 
}

vec2 get_vec(float angle) {
    return vec2(cos(angle), sin(angle));
}

// Assumptions: dt < 1, dt*vel < 1 componentwise.
void main() {
    uint index = gl_GlobalInvocationID.x; //particle to work on

    vec4 p = particles[index];
    vec2 pos = p.xy;
    vec2 vel = p.zw;

    // Update particle position
    vec2 pos_new = pos + dt*vel;
    vec2 vel_new = vel;

    if (pos_new.x < 0.0 ) {
        pos_new.x = -pos_new.x;
        vel_new.x = -vel_new.x;
    } else if (pos_new.x > 1.0) {
        pos_new.x = 2.0-pos_new.x;
        vel_new.x = -vel_new.x;
    }
    if (pos_new.y < 0.0) {
        pos_new.y = -pos_new.y;
        vel_new.y = -vel_new.y;
    } else if (pos_new.y > 1.0) {
        pos_new.y = 2.0-pos_new.y;
        vel_new.y = -vel_new.y;
    }

    ivec2 impos = get_impos(pos_new);

    // deposit pheromones
    vec3 pheromone_color = vec3(0.01,0.0,0.0);
    deposit(impos, pheromone_color);

    // sense the world and update orientation (i.e., velocity)
    float pixel_size = 1.0/width;
    float pi = 3.1415926535897932384;
    float sensor_length = pixel_size * 15; // 3 is the length in pixels
    float sensor_angle = pi/8;
    float rot_speed = pi; // radians per second

    float angle = get_angle(vel_new);

    vec2 leftpos = pos_new + get_vec(angle+sensor_angle)*sensor_length;
    vec2 forwardpos = pos_new + get_vec(angle)*sensor_length;
    vec2 rightpos = pos_new + get_vec(angle-sensor_angle)*sensor_length;

    float leftval = imageLoad(world, get_impos(leftpos)).r; // left sensor value
    float forwardval = imageLoad(world, get_impos(forwardpos)).r; // forward sensor value
    float rightval = imageLoad(world, get_impos(rightpos)).r; // right sensor value

    float new_angle;
    if (forwardval > leftval && forwardval > rightval) {
        new_angle = angle;
    } else {
        if (leftval > rightval) {
            new_angle = angle + rot_speed * dt;
        } else {
            new_angle = angle - rot_speed * dt;
        }
    }

    vel_new = length(vel_new) * get_vec(new_angle); 

    // write updated particle position and velocity
    particles[index] = vec4(pos_new, vel_new);
}
