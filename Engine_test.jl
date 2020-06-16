using Engine

createWindow()
t = Triangle(Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.0,0.5), COLOR_WHITE, 1.0)
t2 = Triangle(Vec2d(-0.5,-0.5), Vec2d(0.5,-0.5), Vec2d(0.0,0.5), COLOR_WHITE, 1.0)

function onUpdate(t_elapsed)
    clear()
    triangle = Triangle(Vec2d(0.0,0.0), Vec2d(0.8*cos(1e-9t_elapsed),0.8*sin(1e-9t_elapsed)), Vec2d(0.8*cos(1e-9t_elapsed+1.0),0.8*sin(1e-9t_elapsed+1.0)), COLOR_WHITE, 1.0)
    draw(triangle)
    Triangle!(triangle)
end

loop(onUpdate)
destroyWindow()
