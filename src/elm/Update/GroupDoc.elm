module Update.GroupDoc exposing (..)

import Entity.Types exposing (Entity)
import GroupDoc
import GroupDoc.FormTypes exposing (GroupDocFormMode(..))
import GroupDoc.Types exposing (ContextStore, GroupDocType(..), ProjectStore)
import Msg.GroupDoc exposing (..)
import Return exposing (andThen)
import Stores
import Todo.Types exposing (TodoStore)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)
import ViewType exposing (ViewType)


type alias SubModel model =
    { model
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
        , now : Time
        , focusInEntity : Entity
        , mainViewType : ViewType
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model



--type alias Config msg model =
--    {}


update :
    {- Config msg model
       ->
    -}
    GroupDocMsg
    -> SubReturnF msg model
update msg =
    case msg of
        OnSaveGroupDocForm form ->
            -- todo: cleanup and move
            let
                update fn =
                    fn form.id (GroupDoc.setName form.name)
                        |> andThen
            in
                case form.groupDocType of
                    ContextGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                Stores.insertContext form.name

                            GDFM_Edit ->
                                update Stores.updateContext

                    ProjectGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                Stores.insertProject form.name

                            GDFM_Edit ->
                                update Stores.updateProject
