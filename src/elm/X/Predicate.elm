module X.Predicate exposing (..)

import Toolkit.Helpers exposing (..)







type alias Predicate a =
    a -> Bool


all : List (Predicate a) -> Predicate a
all list =
    applyList list >> List.all identity


any : List (Predicate a) -> Predicate a
any list =
    applyList list >> List.any identity


always =
    (\_ -> True)
