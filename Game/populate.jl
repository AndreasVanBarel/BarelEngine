using Worlds
using Empires
using Units

# Physical worlds
sun = World("Sun", 696_342km, 1.9884e30, [], 24.47days)
sun.zones = [
    Zone("Surface",6.09e18,Climate(5772,0),Worlds.plasma)
    Zone("Corona",6.09e18,Climate(1e6,0),Worlds.plasma)
]

earth = World("Earth", 6371km, 5.97237e24, [], 0.99726968days, sun, 149_598_023km, 365.256363004days)
earth.zones = [
    Zone("Atmosphere",510_072_000km²,Climate(13.8C,50),Worlds.gas)
    Zone("Ocean",361_132_000km²,Climate(17C,100),Worlds.liquid)
    Zone("Tropical",31e6km²,Climate(26C,100),Worlds.soil)
    Zone("Arid",21_940_000km²,Climate(27C,0),Worlds.sand) # or Dry (desertlike)
    Zone("Temperate",21e6km²,Climate(11C,50),Worlds.soil)
    Zone("Cold",35e6km²,Climate(1C,25),Worlds.soil) # or Continental
    Zone("Polar",27e6km²,Climate(-20C,0),Worlds.ice)
    Zone("Mountains",13e6km²,Climate(5C,25),Worlds.rock) # including Highlands etc
]

# Politics
empire_NE = Empire("Neutral", "Neutral")
empire_EU = Empire("European Union", "EU")
empire_US = Empire("United States of America", "USA")
#empire_CN = Empire("China", "China")
#empire_RU = Empire("Russian Federation", "Russia")
#empire_AF = Empire("African Federation", "FA")

EUws = WorldSection([ZoneSection()])
push!(empire_EU.world)
