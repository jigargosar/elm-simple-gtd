module Update.Subscription exposing (..)

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


type SubscriptionMsg
    = OnGlobalKeyUp Int
    | OnGlobalKeyDown Int


subscriptions =
    Sub.batch
        [ Keyboard.ups OnGlobalKeyUp
        , Keyboard.downs OnGlobalKeyDown
        ]


type alias SubModel model =
    { model
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
        , selectedEntityIdSet : Set DocId
        , editMode : ExclusiveMode
    }


type alias SubModelF model =
    SubModel model -> SubModel model


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg a =
    { a
        | onStartAddingTodoToInbox : msg
        , onStartAddingTodoWithFocusInEntityAsReference : msg
        , revertExclusiveModeMsg : msg
        , focusNextEntityMsgNew : msg
        , focusPrevEntityMsgNew : msg
    }



--update : Config msg a -> SubscriptionMsg -> SubReturnF msg model


update config msg =
    case msg of
        OnGlobalKeyUp keyCode ->
            onGlobalKeyUp config keyCode

        OnGlobalKeyDown keyCode ->
            onGlobalKeyDown config keyCode


onGlobalKeyDown config keyCode =
    let
        key =
            KX.fromCode keyCode

        onEditModeNone =
            case key of
                ArrowUp ->
                    returnMsgAsCmd config.focusPrevEntityMsgNew

                ArrowDown ->
                    returnMsgAsCmd config.focusNextEntityMsgNew

                _ ->
                    identity
    in
    (\editMode ->
        case editMode of
            ExclusiveMode.Types.XMNone ->
                onEditModeNone

            _ ->
                identity
    )
        |> returnWith .editMode


onGlobalKeyUp config keyCode =
    let
        key =
            KX.fromCode keyCode

        clear =
            map Models.Selection.clearSelection
                >> returnMsgAsCmd config.revertExclusiveModeMsg

        onEditModeNone =
            case key of
                Escape ->
                    clear

                CharX ->
                    clear

                CharQ ->
                    returnMsgAsCmd
                        config.onStartAddingTodoWithFocusInEntityAsReference

                CharI ->
                    returnMsgAsCmd config.onStartAddingTodoToInbox

                _ ->
                    identity
    in
    (\exMode ->
        case ( key, exMode ) of
            ( _, ExclusiveMode.Types.XMNone ) ->
                onEditModeNone

            ( Escape, _ ) ->
                returnMsgAsCmd config.revertExclusiveModeMsg

            _ ->
                identity
    )
        |> returnWith .editMode
