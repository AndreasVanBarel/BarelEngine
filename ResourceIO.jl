module ResourceIO

export load_texture,r,g,b,α

using FileIO
import ColorTypes

function load_texture(path)
    texdata = load(path)
    width,height = size(texdata)
    # check for the alpha channel
    if eltype(texdata)<:ColorTypes.RGB
        rgb = Array{UInt8,3}(undef,3,width,height)
        for w = 1:width, h = 1:height
            rgb[1,w,h] = texdata[w,h].r.i
            rgb[2,w,h] = texdata[w,h].g.i
            rgb[3,w,h] = texdata[w,h].b.i
        end
        return rgb
    elseif eltype(texdata)<:ColorTypes.RGBA
        rgba = Array{UInt8,3}(undef,4,width,height)
        for w = 1:width, h = 1:height
            rgba[1,w,h] = texdata[w,h].r.i
            rgba[2,w,h] = texdata[w,h].g.i
            rgba[3,w,h] = texdata[w,h].b.i
            rgba[4,w,h] = texdata[w,h].alpha.i
        end
        return rgba
    else
        @error("Color type of this image is not supported.")
        return nothing
    end
end
r(tex::Array{UInt8,3}) = view(tex,1,:,:)
g(tex::Array{UInt8,3}) = view(tex,2,:,:)
b(tex::Array{UInt8,3}) = view(tex,3,:,:)
α(tex::Array{UInt8,3}) = view(tex,4,:,:)
r(tex::Array{UInt8,3},w,h) = view(tex,1,w,h)
g(tex::Array{UInt8,3},w,h) = view(tex,2,w,h)
b(tex::Array{UInt8,3},w,h) = view(tex,3,w,h)
α(tex::Array{UInt8,3},w,h) = view(tex,4,w,h)

end
