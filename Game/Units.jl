module Units

export km, ly
export km²
export years, days, hrs, mins
export C

import Base.*

# in meters
const km = 1000
const ly = 9460730472580800

# in square meters
const km² = 1e6

# in seconds
const years = 31_557_600
const days = 86400
const hrs = 3600
const mins = 60

# in Kelvin
struct Celsius end
const C = Celsius()
*(x,C::Celsius) = x+273.15

end
