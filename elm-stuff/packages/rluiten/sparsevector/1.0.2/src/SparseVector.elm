module SparseVector exposing
    ( SparseVector
    , empty
    , isEmpty
    , insert
    , insertList
    , magnitude
    , dot
    , cosineSimilarity
    )

{-| SparseVector is an n-dimension sparse vector.

Very simple implementation with just the functions I needed at the time for Lunrelm.

Model stored in Dict with index as key.

Dimension of vector is not held, so there is no way to check that dot or
cosineSimilarity are both using the same dimension vector.

@docs SparseVector
@docs empty
@docs isEmpty
@docs insert
@docs insertList

@docs magnitude
@docs dot
@docs cosineSimilarity

Copyright (c) 2016 Robin Luiten

-}

import Dict exposing (Dict)
import Set


{-| SparseVector type alias -}
type alias SparseVector = Dict Int Float


{-| Empty SparseVector -}
empty : SparseVector
empty = Dict.empty


{-| Return true if vector is empty -}
isEmpty : SparseVector -> Bool
isEmpty svector =
    Dict.isEmpty svector


{-| Insert value in vector.
-}
insert : Int -> Float -> SparseVector -> SparseVector
insert index value svector =
    Dict.insert index value svector


{-| Insert list of values in vector.
-}
insertList : List (Int, Float) -> SparseVector -> SparseVector
insertList values svector =
    List.foldr
      (\(index, value) svec -> insert index value svec)
      svector
      values


{-| Calculates magnitude of vector.

Sqrt of Sum of Squares of each dimension value.
-}
magnitude : SparseVector -> Float
magnitude svector =
    sqrt (List.sum (List.map (\x -> x * x) (Dict.values svector)))


{-| Calculates the dot product between vectors.
-}
dot : SparseVector ->  SparseVector -> Float
dot vec1 vec2 =
    let
      common =
        Set.intersect
          (Set.fromList (Dict.keys vec1))
          (Set.fromList (Dict.keys vec2))
      d1 = Dict.filter (\k v -> Set.member k common) vec1
      d2 = Dict.filter (\k v -> Set.member k common) vec2
    in
      List.sum
        <| List.map2 (\v1 v2 -> v1 * v2) (Dict.values d1) (Dict.values d2)


{-| Calculates the cosine similarity between vectors.
-}
cosineSimilarity : SparseVector ->  SparseVector -> Float
cosineSimilarity vec1 vec2 =
    (dot vec1 vec2) / ((magnitude vec1) * (magnitude vec2))
