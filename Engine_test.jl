using Engine

# t = Triangle(Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.0,0.5), COLOR_WHITE, 1.0)
# t2 = Triangle(Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.0,0.5), COLOR_WHITE, 1.0)

destroyWindow()
createWindow()
vsync(true)
wireframe(false)
<<<<<<< HEAD
tex_dragon = load_texture("resources/dragon.png")
points = [Vec2d(-0.4,-0.4), Vec2d(0.4,-0.4), Vec2d(0.4,0.4), Vec2d(-0.4,0.4)]
sprite = Sprite(points..., tex_dragon)
circles = Circle.(points,0.02,[COLOR_GREEN])
bgtex = load_texture("resources/background.jpg")
bg = Sprite(Vec2d(-1.0,-1.0), Vec2d(1.0,-1.0), Vec2d(1.0,1.0), Vec2d(-1.0,1.0), bgtex)
selected = 1
#translate!(camera,Vec2d(0.2,0.4))
#scale!(camera,0.5)
=======
#tex = load_texture("resources/tree_icon.png")
tex2 = load_texture("resources/dragon.png")
sprite = Sprite(Vec2d(-0.4,-0.4), Vec2d(0.4,-0.4), Vec2d(0.4,0.4), Vec2d(-0.4,0.4), tex2, COLOR_WHITE, 255)
#sprite = Sprite(VEC_ORIGIN,tex)
bgtex = load_texture("resources/background.jpg")
bg = Sprite(Vec2d(-1.0,-1.0), Vec2d(1.0,-1.0), Vec2d(1.0,1.0), Vec2d(-1.0,1.0), bgtex)
squares = [Square(rand(Vec2d),0.03,rand(Color)) for i = 1:10]
>>>>>>> master
function onUpdate(t_elapsed)
    global selected
    clear(COLOR_WHITE)
    draw(bg)
<<<<<<< HEAD
    if mouse(0).pressed && mouse(0).mods < 128 #first click, update the selected
        for i in 1:length(circles)
            if dist(mouse(),loc(circles[i])) < 0.02
                selected = i
                color!(circles[i], COLOR_RED)
                ps = sprite.vertices[2:5]
                ps[selected] = mouse()
                shape!(sprite, ps...)
                position!(circles[i], mouse())
            end
        end
    elseif mouse(0).pressed && mouse(0).mods >= 128 #still pressed
        if selected !=0
            ps = sprite.vertices[2:5]
            ps[selected] = mouse()
            shape!(sprite, ps...)
            position!(circles[selected], mouse())
        end
    else
        selected != 0 && color!(circles[selected], COLOR_GREEN)
        selected = 0
    end
    draw(sprite)
    draw.(circles)
=======
    draw(sprite)
    #quadrangle = Quadrangle(Vec2d(-0.5,0.5), Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.5,0.5), COLOR_RED)
    color = Color(0.5*(cos(t_elapsed)+1),0.5*(cos(t_elapsed+2π/3)+1),0.5*(cos(t_elapsed+4π/3)+1))
    triangle = Triangle(Vec2d(0.0,0.0), Vec2d(0.8*cos(t_elapsed ),0.8*sin(t_elapsed)), Vec2d(0.8*cos(t_elapsed+1.0),0.8*sin(t_elapsed+1.0)), color, 63)
    #drawfree(quadrangle)
    drawfree(triangle)
    if mouse(0).pressed && mouse(0).mods < 255
        println(mouse(0))
        push!(squares, Square(mouse(),0.03,COLOR_GREEN))
    end
    #draw.(squares)
    drawfree(Square(mouse(),0.03,COLOR_RED))
>>>>>>> master
end
loop(onUpdate)
free.([sprite,bg])
destroyWindow()
