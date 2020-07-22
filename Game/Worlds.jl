module Worlds

export World, Zone, Climate, Feature, Deposit, Life

@enum Resource hydrogen deuterium oxygen water iron silicon nitrogen
@enum Biome desert forest alpine arctic ocean atmosphere
@enum Terrain rock sand soil ice liquid gas plasma
@enum Habitat sea land air underground
@enum LifeType plant animal

abstract type World end
abstract type Feature end

mutable struct Life
    name::String
    habitats::Vector{Habitat}
    type::LifeType
    origin::World
end

mutable struct Deposit <: Feature
    resource::Resource
    size::Float32
end

struct Climate
    temperature::Float32
    humidity::Float32 #From 0 to 100
end

struct Zone
    name::String
    area::Float32
    climate::Climate
    terrain::Terrain
    lifeforms::Vector{Life}
    features_s::Vector{Feature}
    features_e::Vector{Feature}
    #features shared and exclusive.
end
Zone(name,area,climate,terrain) = Zone(name,area,climate,terrain,[],[],[])

mutable struct DefaultWorld <: World
    name::String
    radius::Float32 #m
    mass::Float32 #kg
    zones::Vector{Zone}
    dayperiod::Float32 #s
    parent::World
    orbitaldistance::Float32 #m
    orbitalperiod::Float32 #s #depends on the mass of the parent!
end
mutable struct NoWorld <: World end
const NO_WORLD = NoWorld()

DefaultWorld(name, radius, mass, zones, dayperiod) = DefaultWorld(name, radius, mass, zones, dayperiod, NO_WORLD, 0, 0)
World(args...) = DefaultWorld(args...)

end
