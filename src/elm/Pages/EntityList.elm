module Pages.EntityList exposing (..)

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
import X.Return exposing (..)


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


constructor : Filter.Path -> Filter -> Cursor.Model -> Model
constructor path filter cursor =
    ModelRecord path filter cursor
        |> Model


initialValue : Model
initialValue =
    let
        ( filter, path ) =
            Filter.initialFilterPathTuple

        cursor =
            Cursor.initialValue filter
    in
    constructor path filter cursor


maybeInitFromPath : List String -> Maybe Model -> Maybe Model
maybeInitFromPath path maybePreviousModel =
    let
        initFromFilter filter =
            let
                model =
                    maybePreviousModel ?= initialValue
            in
            constructor path filter (get cursorL model)
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


getEntityListDomIdFromEntityId entityId =
    case entityId of
        ContextEntityId docId ->
            "entity-list-context-id-" ++ docId

        ProjectEntityId docId ->
            "entity-list-project-id-" ++ docId

        TodoEntityId docId ->
            "entity-list-todo-id-" ++ docId


type Msg
    = MoveFocusBy Int
    | SetCursorEntityId EntityId
    | RecomputeEntityListCursorAfterChangesReceivedFromPouchDBMsg
    | GoToEntityId EntityId


type alias HasStores x =
    { x
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
    }


update :
    { a | navigateToPathMsg : Filter.Path -> Cmd msg }
    -> HasStores x
    -> Msg
    -> Model
    -> ( Model, Cmd msg )
update config appModel msg model =
    let
        noop =
            pure model
    in
    case msg of
        SetCursorEntityId entityId ->
            -- note: this is automatically called by focusIn event of list item.
            onSetCursorEntityId entityId appModel model

        MoveFocusBy offset ->
            let
                cursor =
                    get cursorL model
            in
            Cursor.findEntityIdByOffsetIndex offset cursor
                ?|> (\entityId -> onSetCursorEntityId entityId appModel model)
                ?= noop

        RecomputeEntityListCursorAfterChangesReceivedFromPouchDBMsg ->
            computeMaybeNewEntityIdAtCursor appModel model
                ?|> (\entityId ->
                        ( model
                        , focusEntityIdCmd entityId
                        )
                    )
                ?= noop

        GoToEntityId entityId ->
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
            model ! [ config.navigateToPathMsg path, focusEntityIdCmd entityId ]


onSetCursorEntityId entityId appModel model =
    let
        entityIdList =
            createEntityIdList model appModel

        cursor =
            Cursor.create entityIdList
                (Just entityId)
                (getFilter model)
    in
    set cursorL cursor model |> pure


focusEntityIdCmd entityId =
    Ports.focusSelector ("#" ++ getEntityListDomIdFromEntityId entityId)


createEntityTree model appModel =
    TreeBuilder.createEntityTree_ (getFilter model) (getTitle model) appModel


createEntityIdList model appModel =
    createEntityTree model appModel |> Tree.toEntityIdList


computeMaybeNewEntityIdAtCursor appModel model =
    let
        newEntityIdList =
            createEntityIdList model appModel

        newFilter =
            getFilter model
    in
    get cursorL model
        |> Cursor.computeNewEntityIdAtCursor newFilter newEntityIdList
