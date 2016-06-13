@Generated immutable Cell{Name, T}
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
