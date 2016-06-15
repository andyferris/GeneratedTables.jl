module GeneratedTables

using GeneratedTypes

import Base: getindex, unsafe_getindex, setindex!, unsafe_setindex!

export Cell, Column, Row, Table
export name, eltypes

include("cell.jl")
include("column.jl")
include("row.jl")
include("table.jl")
include("extra_constructors.jl")
include("show.jl")

end # module
