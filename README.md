# GeneratedTables

This is an experimental package to prototype data tables using Generated types. The idea
is that a `Table` would be parameterized by it's column names as `Symbol`s.
We can then access the columns with a standard field reference, like:
```julia
table = Table{(:FirstName, :LastName, :DOB)}(fnames, lnames, dobs)
table.FirstName[3] # == fnames[3]
```

The *GeneratedTypes.jl* package is used to make possible the definition of
custom fields.

This solves the overly verbose syntax issues associated with *TypedTables.jl*
and simultaneously the speed issues of *DataFrames.jl* (that is, when using a
naive, row-by-row approach).
