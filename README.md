# GeneratedTables

### About

This is an experimental package to prototype data tables using `@Generated`
types. Currently it only functions on Julia v0.4. If we can get generated types
to work in Julia v0.5, then I may port [TypedTables.jl](https://github.com/FugroRoames/TypedTables.jl)
over to this new formalism.

### Overview

The idea is that a `Table` contains the columns as its fields. We can
access the columns with a standard field reference, like:
```julia
using GeneratedTables
table = Table{(:FirstName, :LastName, :DOB)}(fnames, lnames, dobs)
table.FirstName[3] # == fnames[3]
```

The [GeneratedTypes.jl](https://github.com/andyferris/GeneratedTypes.jl) package
is used to make possible the definition of custom fields. The definition of a
`Table` is:

```julia
@Generated immutable Table{Names, Types <: Tuple}
    # Plus sanity checks:
    #     - Names is a tuple instance of unique Symbols,
    #     - Types is a Tuple-type containing the field types.

    exprs = [:( $(Names[i])::$(Types.parameters[i]) ) for i = 1:N]
    return Expr(:block, exprs...)
end
```

This solves the overly verbose syntax issues associated with *TypedTables.jl*
and simultaneously the speed issues of *DataFrames.jl* (that is, when using a
naive, row-by-row approach).

### Methods of construction

We can create a variety of table elements, including `Cell`, `Column`, `Row` and
`Table`. Upon construction, only the field name is necessary (the type is
inferred):
```julia
julia> using GeneratedTables

julia> cell = T.Cell{:a}(1)
Cell:
 ┌───┐
 │ a │
 ├───┤
 │ 1 │
 └───┘

 julia> fieldnames(cell)
 1-element Array{Symbol,1}:
  :a

 julia> cell.a
1
```

`Column`s are like `Cell`s in that they have only one field, but they expect a
container with `Vector`-like capabilities as input:
```julia
julia> col = Column{:a}([1, 2, 3])
3-row Column:
    ╒═══╕
Row │ a │
    ├───┤
  1 │ 1 │
  2 │ 2 │
  3 │ 3 │
    ╘═══╛

julia> col.a
3-element Array{Int64,1}:
 1
 2
 3

julia> col[2]
2
```
These containers support common operations like iteration, indexing, `push!`, etc.
We can use `vcat` to build `Column`s out of `Cell`s (or other `Column`s):
```julia
julia> vcat(cell, cell)
2-row Column:
    ╒═══╕
Row │ a │
    ├───┤
  1 │ 1 │
  2 │ 1 │
    ╘═══╛
```

`Row`s contain multiple fields, indicated by a tuple of symbols, like:
```julia
julia> vcat(cell,cell)
2-row Column:
    ╒═══╕
Row │ a │
    ├───┤
  1 │ 1 │
  2 │ 1 │
    ╘═══╛

julia> row = T.Row{(:a, :b, :c)}(1, 2.0, true)
3-element Row:
 ╓───┬────────┬───╖
 ║ a │ b      │ c ║
 ╟───┼────────┼───╢
 ║ 1 │ 2.0000 │ T ║
 ╙───┴────────┴───╜

julia> fieldnames(row)
3-element Array{Symbol,1}:
 :a
 :b
 :c

julia> row.b
2.0
```
The can also be constructed by a `hcat` of `Cell`s:
```julia
julia> hcat(Cell{:a}(1), Cell{:b}(2.0), Cell{:c}(true))
3-element Row:
 ╓───┬────────┬───╖
 ║ a │ b      │ c ║
 ╟───┼────────┼───╢
 ║ 1 │ 2.0000 │ T ║
 ╙───┴────────┴───╜
```

Finally, `Table`s are containers with multiple rows and columns. Their fields
can be whatever storage you prefer:
```julia
julia> t = Table{(:a,:b,:c)}([1,2,3], [2.0,4.0,6.0],[true,false,false])
3-row × 3-column Table:
    ╔═══╤════════╤═══╗
Row ║ a │ b      │ c ║
    ╟───┼────────┼───╢
  1 ║ 1 │ 2.0000 │ T ║
  2 ║ 2 │ 4.0000 │ F ║
  3 ║ 3 │ 6.0000 │ F ║
    ╚═══╧════════╧═══╝

julia> t.c
3-element Array{Bool,1}:
  true
 false
 false

julia> t[2]
3-element Row:
 ╓───┬────────┬───╖
 ║ a │ b      │ c ║
 ╟───┼────────┼───╢
 ║ 2 │ 4.0000 │ F ║
 ╙───┴────────┴───╜
 ```

 Semantically, they follow the convention that they are a storage vector of
 `Row`s (e.g. upon indexing or iteration), although in-memory they are stored
 as separate columns of data. (In the future, we may also introduce
 a `DenseTable` or similar which is *precisely* an in-memory `Vector{Row{...}}`).

### Future work

I'm still working hard on supporting common data table capabilities like selecting,
mutating, filtering, sorting, and joining. Many of these are already quasi-supported by
Julia's inbuilt functions (e.g. try `filter()` on a `Table` using a function
that maps `Row`s to `Bool`).

A "complete" solution would include a thought-out hashing and/or sorting scheme,
that may be leveraged by different types of join or for tables with one (or more)
keys made up of one (or more) rows.
