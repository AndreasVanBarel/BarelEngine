module GLPrograms

export generatePrograms

using ModernGL
using Shaders

struct Programs
	triangle::UInt32
	triangle_colorLoc::Int32
	triangle_camLoc::Int32
	ellipse::UInt32
	ellipse_colorLoc::Int32
	ellipse_camLoc::Int32
	sprite::UInt32
	sprite_colorLoc::Int32
	sprite_textureLoc::Int32
	sprite_camLoc::Int32
end

# Vertex Shader for Triangle
triangle_vs_src = """
#version 330 core
layout (location = 0) in vec3 aPos;
uniform mat3 M_cam;
void main()
{
	vec3 p = M_cam*vec3(aPos.x, aPos.y, 1.0f);
	gl_Position = vec4(p.x, p.y, aPos.z, 1.0f);
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
uniform mat3 M_cam;
void main()
{
	vec3 p = M_cam*vec3(aPos.x, aPos.y, 1.0f);
	gl_Position = vec4(p.x, p.y, aPos.z, 1.0f);
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
uniform mat3 M_cam;
void main()
{
	vec3 p = M_cam*vec3(aPos.x, aPos.y, 1.0f);
	gl_Position = vec4(p.x, p.y, aPos.z, 1.0f);
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

function generatePrograms()
	triangle_prog = createProg(triangle_vs_src, triangle_fs_src)
	triangle_colorLoc = glGetUniformLocation(triangle_prog, "color")
	triangle_camLoc = glGetUniformLocation(triangle_prog, "M_cam")
	ellipse_prog = createProg(ellipse_vs_src, ellipse_fs_src)
	ellipse_colorLoc = glGetUniformLocation(ellipse_prog, "color")
	ellipse_camLoc = glGetUniformLocation(ellipse_prog, "M_cam")
	sprite_prog = createProg(sprite_vs_src, sprite_fs_src)
	sprite_colorLoc = glGetUniformLocation(sprite_prog, "color")
	sprite_texLoc = glGetUniformLocation(sprite_prog, "tex")
	sprite_camLoc = glGetUniformLocation(sprite_prog, "M_cam")
	Programs(triangle_prog, triangle_colorLoc, triangle_camLoc,
			ellipse_prog, ellipse_colorLoc, ellipse_camLoc,
			sprite_prog, sprite_colorLoc, sprite_texLoc, sprite_camLoc)
end

end
