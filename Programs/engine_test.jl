using Engine

# t = Triangle(Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.0,0.5), COLOR_WHITE, 1.0)
# t2 = Triangle(Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.0,0.5), COLOR_WHITE, 1.0)

destroyWindow()
createWindow()
vsync(true)
wireframe(false)
tex_dragon = load_texture("resources/dragon2.png")
points = [Vec2d(-0.4,0.4), Vec2d(0.4,0.4), Vec2d(-0.4,-0.4), Vec2d(0.4,-0.4)]
sprite = Sprite(points..., tex_dragon)
circles = Circle.(points,0.02,[COLOR_GREEN])
bgtex = load_texture("resources/background2.jpg")
bg = Sprite(Vec2d(-1.0,1.0), Vec2d(1.0,1.0), Vec2d(-1.0,-1.0), Vec2d(1.0,-1.0), bgtex)
selected = 1
#translate!(camera,Vec2d(0.2,0.4))
#scale!(camera,0.5)
function onUpdate(t_elapsed)
    global selected
    clear(COLOR_WHITE)
    draw(bg)
    if mouse(0).pressed && mouse(0).mods < 128 #first click, update the selected
        for i in eachindex(circles)
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
end
loop(onUpdate)
free.([sprite,bg])
destroyWindow()
