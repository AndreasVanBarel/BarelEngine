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

layout (location = 6) uniform float sensor_length;
layout (location = 7) uniform float sensor_angle; // radians
layout (location = 8) uniform float rot_speed; // radians per second

layout (location = 9) uniform float pheromone_strength;

// layout (location = 9) uniform vec3 pheromone_color;

// gets image pixel position from position in [0.0,1.0]x[0.0,1.0]
ivec2 get_impos(vec2 pos) {
    int imx = int(pos.x * width);
    int imy = int(pos.y * height);
    return ivec2(imx,imy);
}

// deposits pheromones of color pheromone_color in the world image at pixel impos 
void deposit(ivec2 impos, vec3 pheromone_color) {
    vec3 values = imageLoad(world, impos).xyz;
    imageStore(world, impos, vec4(min(values+pheromone_color*pheromone_strength, vec3(1.0,1.0,1.0)), 1.0));
}

float get_angle(vec2 v) {
    return v.x == 0.0 ? 0.0 : atan(v.y, v.x); 
}

vec2 get_vec(float angle) {
    return vec2(cos(angle), sin(angle));
}

float sense(vec2 pos, float angle) {
    vec2 sense_pos = pos + get_vec(angle)*sensor_length;
    float sense_val = imageLoad(world, get_impos(sense_pos)).r; 
    return sense_val;
    // float thresh = 0.01;
    // return sense_val > thresh ? sense_val : thresh; //return sensed value if over thresh
}

// Assumptions: dt < 1, dt*vel < 1 componentwise.
void main() {
    const float pi = 3.1415926535897932384;

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
    vec3 pheromone_color = vec3(1.0,0.0,0.0);
    float mask = 1.0;
    // mask = sin(pos_new.x*pi) * sin(pos_new.y*pi);
    // mask = pow(sin(pos_new.x*pi) * sin(pos_new.y*pi), 2);
    deposit(impos, mask*pheromone_color);

    // sense the world and update orientation (i.e., velocity)
    float angle = get_angle(vel_new);
    float leftval = sense(pos_new, angle+sensor_angle); // left sensor value
    float forwardval = sense(pos_new, angle); // forward sensor value
    float rightval = sense(pos_new, angle-sensor_angle); // right sensor value

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
