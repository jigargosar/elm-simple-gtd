module ReminderOverlay exposing (..)

import Document
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type Model
    = None
    | Initial Todo.Id Todo.Text


type Action
    = Snooze
    | Dismiss
    | Done


init todo =
    Initial (Document.getId todo) (Todo.getText todo)


shouldBeVisible model =
    case model of
        None ->
            False

        _ ->
            True


getMaybeTodoId model =
    case model of
        Initial id _ ->
            Just id

        _ ->
            Nothing


none =
    None
