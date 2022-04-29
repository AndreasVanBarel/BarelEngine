module Empires

export ZoneSection, WorldSection, Empire

using Worlds
using Populations

mutable struct ZoneSection
    zone::Zone
    pct::Float32
    population::Population
    buildings::Vector{Building}
end

mutable struct WorldSection
    zoneSections::Vector{ZoneSection}
end

struct Empire
    name::String
    shortname::String
    worldSections::Vector{WorldSection}
end
Empire(name::String) = Empire(name,name,WorldSection[])
Empire(name::String,shortname::String) = Empire(name,shortname,WorldSection[])

end
