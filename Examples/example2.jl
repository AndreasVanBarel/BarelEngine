# Draws a dragon on the screen with 4 vertices that can be repositioned using the mouse.
# Run init.jl first
using Engine

destroyWindow() # in case one is still present; does nothing if no window is present
createWindow()
vsync(true)

tex_background = load_texture("resources/background.jpg")
background = Sprite(Vec2d(-1.0,1.0), Vec2d(1.0,1.0), Vec2d(-1.0,-1.0), Vec2d(1.0,-1.0), tex_background)

tex_dragon = load_texture("resources/dragon.png")
points = [Vec2d(-0.4,0.4), Vec2d(0.4,0.4), Vec2d(-0.4,-0.4), Vec2d(0.4,-0.4)]
sprite = Sprite(points..., tex_dragon)

radius = 0.02
circles = Circle.(points,radius,[COLOR_GREEN])


function move_vertex(i)
    i == 0 && return
    ps = sprite.vertices[2:5]
    ps[i] = mouse()
    shape!(sprite, ps...)
    position!(circles[i], mouse())
end

selected = 0
function onUpdate(t_elapsed)
    global selected
    clear(COLOR_WHITE)
    draw(background)
    if mouse(0).pressed && mouse(0).mods < 128 #first click, update the selected
        for i in eachindex(circles)
            if dist(mouse(),loc(circles[i])) < radius
                selected = i
                color!(circles[i], COLOR_RED)
                move_vertex(selected)
            end
        end
    elseif mouse(0).pressed && mouse(0).mods >= 128 #held pressed
        move_vertex(selected)
    else #mouse not pressed
        selected != 0 && color!(circles[selected], COLOR_GREEN)
        selected = 0
    end
    draw(sprite)
    draw.(circles)
end
loop(onUpdate)
free.([sprite,background])
destroyWindow()