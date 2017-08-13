module Update.Keyboard exposing (..)

import Data.TodoDoc exposing (..)
import Document exposing (DocId)
import Entity exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode)
import GroupDoc exposing (..)
import Json.Encode as E
import Keyboard
import Keyboard.Extra as KX exposing (Key(..))
import Models.GroupDocStore exposing (contextStore, projectStore)
import Models.Selection
import Models.TodoDocStore as TodoDocStore
import Ports
import Return
import Set exposing (Set)
import Store
import X.Function.Infix exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type Msg
    = OnGlobalKeyUp Int
    | OnGlobalKeyDown Int


subscriptions =
    Sub.batch
        [ Keyboard.ups OnGlobalKeyUp
        , Keyboard.downs OnGlobalKeyDown
        ]


type alias SubModel =
    ()


type alias SubModelF =
    SubModel -> SubModel


type alias SubReturn msg =
    Return.Return msg SubModel


type alias SubReturnF msg =
    SubReturn msg -> SubReturn msg


type alias Config msg a =
    { a
        | onStartAddingTodoToInbox : msg
        , onStartAddingTodoWithFocusInEntityAsReference : msg
        , revertExclusiveModeMsg : msg
        , focusNextEntityMsgNew : msg
        , focusPrevEntityMsgNew : msg
        , clearSelectionMsg : msg
    }


update : Config msg a -> { b | editMode : ExclusiveMode } -> Msg -> List msg
update config appModel msg =
    case msg of
        OnGlobalKeyUp keyCode ->
            onGlobalKeyUp config appModel.editMode keyCode

        OnGlobalKeyDown keyCode ->
            onGlobalKeyDown config appModel.editMode keyCode


onGlobalKeyDown config xMode keyCode =
    let
        key =
            KX.fromCode keyCode

        onEditModeNone =
            case key of
                ArrowUp ->
                    [ config.focusPrevEntityMsgNew ]

                ArrowDown ->
                    [ config.focusNextEntityMsgNew ]

                _ ->
                    []
    in
    case xMode of
        ExclusiveMode.Types.XMNone ->
            onEditModeNone

        _ ->
            []


onGlobalKeyUp config exMode keyCode =
    let
        key =
            KX.fromCode keyCode

        clear =
            [ config.clearSelectionMsg
            , config.revertExclusiveModeMsg
            ]

        onEditModeNone =
            case key of
                Escape ->
                    clear

                CharX ->
                    clear

                CharQ ->
                    [ config.onStartAddingTodoWithFocusInEntityAsReference ]

                CharI ->
                    [ config.onStartAddingTodoToInbox ]

                _ ->
                    []
    in
    case ( key, exMode ) of
        ( _, ExclusiveMode.Types.XMNone ) ->
            onEditModeNone

        ( Escape, _ ) ->
            [ config.revertExclusiveModeMsg ]

        _ ->
            []
