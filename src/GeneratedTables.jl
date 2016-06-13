module GeneratedTables

using GeneratedTypes

export Cell, Column, Row, Table
export name

include("cell.jl")
include("column.jl")
include("row.jl")
include("table.jl")

end # module
