# Barel Engine
Tools for interfacing with compute shaders for GPU computations. 
Low level, relying solely on OpenGL (not OpenCL). This has the advantage that results are rendered in real time in a window without needing to pass through the CPU again.
Originally ideated as a (toy) 2d gaming engine, since this did not exist in Julia at the time.

## Features

- Full screen or windowed
- Mouse and keyboard input handlers
- Vsync
- IO of textures
- Primitives for transfering textures and other variables between the CPU and GPU
- support for basic 'game loop'

## Installation

This is installed using the standard tools of the [package manager](https://julialang.github.io/Pkg.jl/v1/getting-started/):

```julia
pkg> add https://github.com/AndreasVanBarel/BarelEngine.git
```
You get the `pkg>` prompt by hitting `]` as the first character of the line.

## Executing a particle simulation

First run `init.jl`, then `Programs/particles.jl`.
The following controls are available:
- `p` - start or pauze the simulation
- `ESC` - exit the application
- `f` - toggle full screen
- `LMB` - pan by dragging using the left mouse button
- `,` - zoom out (`<` key on qwerty)
- `.` - zoom in (`>` key on qwerty)
- `r` - resets view

The result, after pressing `p` to start, could look as follows:
<p align="center">
  <img src="https://github.com/AndreasVanBarel/BarelEngine/blob/master/particles.png" width="500" title="Particle simulation example">
</p>

## Example 
In the following example we draw a texture on the screen, the four corners of which are adorned by small green circles. These green circles can be clicked and dragged to deform or move the texture around. 
The example can also be found in `Examples\example2.jl`.

```julia
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
free.([sprite,bg])
destroyWindow()
```
