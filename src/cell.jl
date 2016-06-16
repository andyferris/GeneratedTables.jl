@Generated 1 immutable Cell{Name, T}
    if !isa(Name, Symbol)
        str = "Cell parameter 1 (Name) is expected to be a symbol, got $Name"
        return :(error(str))
    end

    if !isa(T, DataType)
        str = "Cell parameter 2 (T) is expected to be a DataType, got $T"
        return :(error(str))
    end

    :(Name::T)
end

function Base.call{Name, T}(::Type{Cell{Name}}, data::T)
    Cell{Name,T}(data)
end

Base.call{Name, T, Tnew}(::Type{Cell{Name,Tnew}}, cell::Cell{Name,T})    = Cell{Name,Tnew}(convert(Tnew, cell.(1)))
Base.convert{Name, Name_new, T, T_new}(::Type{Cell{Name_new,T_new}}, cell::Cell{Name,T}) = Cell{Name_new,T_new}(convert(T_new, cell.(1)))


@inline colname{Name}(::Cell{Name}) = Name
@inline colname{Name, T}(::Type{Cell{Name,T}}) = Name
@inline colname{C <: Cell}(::Type{C}) = colname(super(C))
@inline Base.eltype{Name, T}(::Cell{Name,T}) = T
@inline Base.eltype{Name, T}(::Type{Cell{Name,T}}) = T
@inline Base.eltype{C <: Cell}(::Type{C}) = eltype(super(C))

@inline nrow(::Cell) = 1
@inline ncol(::Cell) = 1

Base.start(cell::Cell) = false
Base.next(cell::Cell, state) = (cell.(1), true)
Base.done(cell::Cell, state) = state
Base.endof(cell::Cell) = 1
Base.length(cell::Cell) = 1

@inline getindex(c::Cell) = c.(1)
@inline getindex(c::Cell, i) = i == 1 ? c.(1) : error("Cannot index Cell at $i")

# copy
Base.copy{Name}(cell::Cell{Name}) = Cell{Name}(copy(cell.(1)))
