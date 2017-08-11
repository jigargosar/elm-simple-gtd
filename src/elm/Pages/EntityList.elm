module Pages.EntityList exposing (..)

import Data.EntityListCursor as Cursor
import Data.EntityListFilter as Filter exposing (Filter)
import Data.EntityTree as Tree
import Entity exposing (..)
import Pages.EntityList.TreeBuilder as TreeBuilder
import Ports
import Toolkit.Operators exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type alias ModelRecord =
    { path : List String
    , filter : Filter.Filter
    , cursor : Cursor.Model
    }


type Model
    = Model ModelRecord


constructor : Filter.Path -> Filter -> Cursor.Model -> Model
constructor path filter cursor =
    ModelRecord path filter cursor
        |> Model


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
    Filter.getMaybeFilterFromPath path
        ?|> initFromFilter


getPath (Model pageModel) =
    pageModel.path


getFilterViewModel (Model pageModel) =
    Filter.getFilterViewModel pageModel.filter


getTitleColourTuple =
    getFilterViewModel >> (\filterModel -> ( filterModel.displayName, filterModel.headerColor ))


getTitle =
    getFilterViewModel >> .displayName


getFilter (Model pageModel) =
    pageModel.filter


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


update config appModel msg pageModel =
    let
        noop =
            pure pageModel

        dispatchMsg msg =
            update config appModel msg pageModel

        dispatchMaybeMsg msg =
            msg ?|> dispatchMsg ?= noop
    in
    case msg of
        SetCursorEntityId entityId ->
            -- note: this is automatically called by focusIn event of list item.
            let
                entityIdList =
                    createEntityIdList pageModel appModel

                cursor =
                    Cursor.create entityIdList
                        (Just entityId)
                        (getFilter pageModel)
            in
            set cursorL cursor pageModel |> pure

        MoveFocusBy offset ->
            let
                cursor =
                    get cursorL pageModel
            in
            Cursor.findEntityIdByOffsetIndex offset cursor
                ?|> SetCursorEntityId
                |> dispatchMaybeMsg

        RecomputeEntityListCursorAfterChangesReceivedFromPouchDBMsg ->
            computeMaybeNewEntityIdAtCursor appModel pageModel
                ?|> (\entityId ->
                        ( pageModel
                        , Ports.focusSelector ("#" ++ getEntityListDomIdFromEntityId entityId)
                        )
                    )
                ?= noop

        GoToEntityId entityId ->
            let
                _ =
                    --config.navigateToPath
                    1
            in
            noop


toRecord (Model a) =
    a


map fn (Model a) =
    fn a |> Model


cursorL =
    fieldLens (toRecord >> .cursor) (\s -> map (\b -> { b | cursor = s }))


createEntityTree pageModel appModel =
    TreeBuilder.createEntityTree_ (getFilter pageModel) (getTitle pageModel) appModel


createEntityIdList pageModel appModel =
    createEntityTree pageModel appModel |> Tree.toEntityIdList


computeMaybeNewEntityIdAtCursor appModel pageModel =
    let
        newEntityIdList =
            createEntityIdList pageModel appModel

        newFilter =
            getFilter pageModel
    in
    get cursorL pageModel
        |> Cursor.computeNewEntityIdAtCursor newFilter newEntityIdList
