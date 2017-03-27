module FunctionExtra exposing (..)



ifElse : (a -> Bool) -> (a -> b) -> (a -> b) -> a -> b
ifElse pred onTrue onFalse value =
    if pred value then
        onTrue value
    else
        onFalse value


whenBool bool =
    when (always bool)


when : (a -> Bool) -> (a -> a) -> a -> a
when pred onTrue value =
    ifElse pred onTrue (\_ -> value) value


unless : (a -> Bool) -> (a -> a) -> a -> a
unless pred =
    when (pred >> not)


reject pred =
    List.filter (pred >> not)


gt =
    (>)


lt =
    (<)


or =
    (||)


and =
    (&&)


equals =
    (==)


notEquals =
    (/=)


maybe2Tuple : (Maybe a, Maybe b) -> Maybe (a, b)
maybe2Tuple tuple =
  case tuple of
    (Just a, Just b) ->
      Just (a, b)

    _ ->
      Nothing


mapMaybe2Tuple fn = maybe2Tuple >> Maybe.map fn
