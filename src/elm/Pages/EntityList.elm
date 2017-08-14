module Pages.EntityList
    exposing
        ( Model
        , Msg(..)
        , createEntityTree
        , getEntityListItemDomIdFromEntityId
        , getMaybeLastKnownFocusedEntityId
        , getPath
        , getTitleColourTuple
        , initialValue
        , maybeInitFromPath
        , update
        )

import Data.EntityListCursor as Cursor
import Data.EntityListFilter as Filter exposing (Filter)
import Data.EntityTree as Tree
import Data.TodoDoc exposing (TodoStore)
import Entity exposing (..)
import GroupDoc exposing (ContextStore, ProjectStore)
import Pages.EntityList.TreeBuilder as TreeBuilder
import Ports
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (..)
import XUpdate as U


type alias ModelRecord =
    { path : List String
    , filter : Filter.Filter
    , cursor : Cursor.Model
    }


type Model
    = Model ModelRecord


unwrap (Model a) =
    a


getPath =
    unwrap >> .path


getFilter =
    unwrap >> .filter


toModelLens lens =
    let
        modelRecordL : FieldLens ModelRecord Model
        modelRecordL =
            fieldLens (\(Model b) -> b) (\s _ -> Model s)
    in
    composeLens lens modelRecordL


cursorL =
    fieldLens (\b -> b.cursor) (\s b -> { b | cursor = s })
        |> toModelLens


getCursor =
    get cursorL


constructor : Filter.Path -> Filter -> Cursor.Model -> Model
constructor path filter cursor =
    ModelRecord path filter cursor
        |> Model


initialValue : ( Model, Cmd msg )
initialValue =
    let
        ( filter, path ) =
            Filter.initialFilterPathTuple

        cursor =
            Cursor.initialValue filter
    in
    ( constructor path filter cursor, focusEntityListCmd )


maybeInitFromPath : List String -> Maybe Model -> Maybe ( Model, Cmd msg )
maybeInitFromPath path maybePreviousModel =
    let
        initFromFilter filter =
            let
                model =
                    maybePreviousModel ?= (initialValue |> Tuple.first)
            in
            ( constructor path filter (getCursor model), focusEntityListCmd )
    in
    Filter.maybeFromPath path
        ?|> initFromFilter


getFilterViewModel =
    getFilter >> Filter.toViewModel


getTitleColourTuple =
    getFilterViewModel >> apply2 ( .displayName, .headerColor )


getTitle =
    getFilterViewModel >> .displayName


getMaybeLastKnownFocusedEntityId : Model -> Maybe EntityId
getMaybeLastKnownFocusedEntityId =
    get cursorL >> .maybeCursorEntityId


getEntityListItemDomIdFromEntityId entityId =
    case entityId of
        ContextEntityId docId ->
            "entity-list-context-id-" ++ docId

        ProjectEntityId docId ->
            "entity-list-project-id-" ++ docId

        TodoEntityId docId ->
            "entity-list-todo-id-" ++ docId


type Msg
    = OnMoveFocusBy Int
    | OnSetCursorEntityId EntityId
    | OnFocusListCursorAfterChangesReceivedFromPouchDBMsg
    | OnGoToEntityId EntityId
    | OnFocusEntityList


type alias HasStores x =
    { x
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
    }


update :
    { a | navigateToPathMsg : Filter.Path -> msg }
    -> HasStores x
    -> Msg
    -> Model
    -> U.Return Model Msg msg
update config appModel msg model =
    let
        defRet : ( Model, List (Cmd Msg), List msg )
        defRet =
            U.pure model

        updateDefRet msg =
            update config appModel msg model
    in
    case msg of
        OnSetCursorEntityId entityId ->
            -- note: this is automatically called by focusIn event of list item.
            let
                entityIdList =
                    createEntityIdList model appModel

                cursor =
                    Cursor.create entityIdList
                        (Just entityId)
                        (getFilter model)
            in
            defRet
                |> U.map (set cursorL cursor)

        OnFocusEntityList ->
            defRet |> U.addCmd focusEntityListCmd

        OnMoveFocusBy offset ->
            Cursor.findEntityIdByOffsetIndex offset (getCursor model)
                ?|> (\entityId ->
                        updateDefRet (OnSetCursorEntityId entityId)
                            |> U.addCmd (focusEntityIdCmd entityId)
                    )
                ?= defRet

        OnFocusListCursorAfterChangesReceivedFromPouchDBMsg ->
            computeNewMaybeCursorEntityId appModel model
                ?|> (\entityId ->
                        updateDefRet (OnSetCursorEntityId entityId)
                            |> U.addCmd (focusEntityIdCmd entityId)
                    )
                ?= defRet

        OnGoToEntityId entityId ->
            let
                filter =
                    --config.navigateToPath
                    case entityId of
                        ProjectEntityId docId ->
                            Filter.projectFilter docId

                        ContextEntityId docId ->
                            Filter.contextFilter docId

                        TodoEntityId docId ->
                            Filter.groupByActiveContextsFilter

                path =
                    Filter.toPath filter
            in
            defRet
                |> U.addCmd (focusEntityIdCmd entityId)
                |> U.addMsg (config.navigateToPathMsg path)


focusEntityIdCmd entityId =
    Ports.focusSelector ("#" ++ getEntityListItemDomIdFromEntityId entityId)


focusEntityListCmd =
    Ports.focusSelector ".focusable-list-item[tabindex=0]"


createEntityTree model appModel =
    TreeBuilder.createEntityTree_ (getFilter model) (getTitle model) appModel


createEntityIdList model appModel =
    createEntityTree model appModel |> Tree.toEntityIdList


computeNewMaybeCursorEntityId appModel model =
    let
        newEntityIdList =
            createEntityIdList model appModel

        newFilter =
            getFilter model
    in
    getCursor model
        |> Cursor.computeNewEntityIdAtCursor newFilter newEntityIdList
