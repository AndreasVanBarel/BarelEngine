# Draws some things on the screen and allows one to draw small rectangles by clicking the mouse.
using Engine

destroyWindow()
createWindow()
vsync(true)
wireframe(false)
tex_dragon = load_texture("resources/dragon.png")
points = [Vec2d(-0.4,0.4), Vec2d(0.4,0.4), Vec2d(-0.4,-0.4), Vec2d(0.4,-0.4)]
sprite = Sprite(points..., tex_dragon)
#sprite = Sprite(VEC_ORIGIN,tex)
bgtex = load_texture("resources/background.jpg")
bg = Sprite(Vec2d(-1.0,1.0), Vec2d(1.0,1.0), Vec2d(-1.0,-1.0), Vec2d(1.0,-1.0), bgtex)
# squares = [Square(rand(Vec2d),0.03,rand(Color)) for i = 1:10]
squares = []
function onUpdate(t_elapsed)
    global selected
    clear(COLOR_WHITE)
    draw(bg)
    draw(sprite)
    #quadrangle = Quadrangle(Vec2d(-0.5,0.5), Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.5,0.5), COLOR_RED)
    color = Color(0.5*(cos(t_elapsed)+1),0.5*(cos(t_elapsed+2π/3)+1),0.5*(cos(t_elapsed+4π/3)+1),0.25)
    triangle = Triangle(Vec2d(0.0,0.0), Vec2d(0.8*cos(t_elapsed ),0.8*sin(t_elapsed)), Vec2d(0.8*cos(t_elapsed+1.0),0.8*sin(t_elapsed+1.0)), color)
    #drawfree(quadrangle)
    drawfree(triangle)
    if mouse(0).pressed && mouse(0).mods < 255
        println(mouse(0))
        push!(squares, Square(mouse(),0.03,COLOR_GREEN))
    end
    draw.(squares)
    drawfree(Square(mouse(),0.03,COLOR_RED))
end
loop(onUpdate)
free.([sprite,bg])
destroyWindow()
