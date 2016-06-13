@Generated immutable Cell{Name, T}
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

@inline name{Name}(::Cell{Name}) = Name
@inline name{Name, T}(::Type{Cell{Name,T}}) = Name
@inline name{C <: Cell}(::Type{C}) = name(super(C))
@inline Base.eltype{Name, T}(::Cell{Name,T}) = T
@inline Base.eltype{Name, T}(::Type{Cell{Name,T}}) = T
@inline Base.eltype{C <: Cell}(::Type{C}) = eltype(super(C))
