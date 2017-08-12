module ExclusiveMode.Update exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(..))
import GroupDoc exposing (GroupDocForm)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.FormTypes exposing (TodoForm)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (set)
import XUpdate


type ExclusiveModeMsg
    = OnSetExclusiveMode ExclusiveMode
    | OnRevertExclusiveMode
    | OnSaveExclusiveModeForm


type alias Model =
    ExclusiveMode


type alias Config msg a =
    { a
        | saveTodoFormMsg : TodoForm -> msg
        , saveGroupDocFormMsg : GroupDocForm -> msg
    }


update :
    Config msg a
    -> ExclusiveModeMsg
    -> Model
    -> XUpdate.XReturn ExclusiveMode ExclusiveModeMsg msg
update config msg model =
    case msg of
        OnSetExclusiveMode newModel ->
            XUpdate.pure newModel

        OnRevertExclusiveMode ->
            update config (OnSetExclusiveMode XMNone) model

        OnSaveExclusiveModeForm ->
            let
                configMsgList =
                    case model of
                        XMGroupDocForm form ->
                            [ config.saveGroupDocFormMsg form ]

                        XMTodoForm form ->
                            [ config.saveTodoFormMsg form ]

                        _ ->
                            []
            in
            XUpdate.pure model
                |> XUpdate.addMsgList configMsgList
