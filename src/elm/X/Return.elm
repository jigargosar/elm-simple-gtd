module X.Return exposing (..)

import Return exposing (Return, ReturnF)
import Task
import Time exposing (Time)
import Toolkit.Operators exposing (..)
import X.Debug
import X.Function as F exposing (..)
import X.Function.Infix exposing (..)


withMaybe :
    (a -> Maybe x)
    -> (x -> ReturnF msg a)
    -> ReturnF msg a
withMaybe f1 f2 =
    Return.andThen
        (\m ->
            f1 m ?|> f2 ?= identity |> F.apply (Return.singleton m)
        )


returnWithNow : (Time -> msg) -> ReturnF msg model
returnWithNow toMsg =
    Return.command (Task.perform toMsg Time.now)


returnWith :
    (a -> x)
    -> (x -> Return msg a -> Return msg b)
    -> Return msg a
    -> Return msg b
returnWith f1 f2 =
    Return.andThen
        (\m ->
            (f2 (f1 m)) (Return.singleton m)
        )


mapModelWith f1 f2 =
    Return.map
        (\m ->
            (f2 (f1 m)) m
        )


maybeMapModelWith f1 f2 =
    Return.map <|
        \m ->
            f2 (f1 m) m ?= m


mapModelWithMaybeF mf1 f2 =
    Return.map <|
        \m ->
            mf1 m ?|> f2 # m ?= m


andThenApplyWith f1 f2 =
    Return.andThen
        (\m ->
            (f2 (f1 m)) m
        )


andThenApplyWithMaybe f1 f2 =
    Return.andThen
        (\m ->
            f1 m ?|> f2 ?= m
        )


maybeEffect f =
    Return.effect_ (\m -> f m ?= Cmd.none)


apply =
    flip Return.andThen


andThenMaybe f =
    Return.andThen
        (\m ->
            f m ?= Return.singleton m
        )


mapTapLog =
    X.Debug.tapLog >>> Return.map
