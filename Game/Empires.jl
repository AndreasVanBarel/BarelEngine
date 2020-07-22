module Empires

export ZoneSection, WorldSection, Empire

using Worlds

mutable struct ZoneSection
    zone::Zone
    pct::Float32
end

mutable struct WorldSection
    zoneSections::Vector{ZoneSection}
end

mutable struct Empire
    name::String
    shortname::String
    worldSections::Vector{WorldSection}
end
Empire(name::String) = Empire(name,name,WorldSection[])
Empire(name::String,shortname::String) = Empire(name,shortname,WorldSection[])

end
