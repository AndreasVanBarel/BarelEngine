using Engine

# t = Triangle(Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.0,0.5), COLOR_WHITE, 1.0)
# t2 = Triangle(Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.0,0.5), COLOR_WHITE, 1.0)

destroyWindow()
createWindow()
vsync(true)
wireframe(false)
tex = load_texture("resources/tree_icon.png")
tex2 = load_texture("resources/dragon.png")
sprite = Sprite(Vec2d(-0.4,-0.4), Vec2d(0.4,-0.4), Vec2d(0.4,0.4), Vec2d(-0.4,0.4), tex2, COLOR_WHITE, 255)
#sprite = Sprite(VEC_ORIGIN,tex)
bgtex = load_texture("resources/background.jpg")
bg = Sprite(Vec2d(-1.0,-1.0), Vec2d(1.0,-1.0), Vec2d(1.0,1.0), Vec2d(-1.0,1.0), bgtex)
squares = [Square(rand(Vec2d),0.03,rand(Color),25) for i = 1:0]
function onUpdate(t_elapsed)
    clear(COLOR_WHITE)
    draw(bg)
    draw(sprite)
    #quadrangle = Quadrangle(Vec2d(-0.5,0.5), Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.5,0.5), COLOR_RED)
    color = Color(0.5*(cos(t_elapsed)+1),0.5*(cos(t_elapsed+2π/3)+1),0.5*(cos(t_elapsed+4π/3)+1))
    triangle = Triangle(Vec2d(0.0,0.0), Vec2d(0.8*cos(t_elapsed),0.8*sin(t_elapsed)), Vec2d(0.8*cos(t_elapsed+1.0),0.8*sin(t_elapsed+1.0)), color, 63)
    #drawfree(quadrangle)
    drawfree(triangle)
    if mouse(0).pressed && mouse(0).mods < 255
        println(mouse(0))
        push!(squares, Square(mouse(),0.03,COLOR_GREEN))
    end
    draw.(squares)
    drawfree(Square(mouse(),0.03,COLOR_RED))
    draw(Circle(VEC_ORIGIN,0.2,COLOR_CYAN,127))
end
loop(onUpdate)
free(sprite)
free(bg)
free.(squares)
destroyWindow()
