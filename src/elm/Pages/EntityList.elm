module Pages.EntityList exposing (..)

import Data.EntityListCursor as Cursor
import Data.EntityListFilter as Filter exposing (Filter(..), FilterViewModel, FlatFilterType(..), GroupByType(..), Path)
import Data.EntityTree as Tree exposing (GroupDocEntityNode(..), Tree)
import Entity exposing (..)
import Pages.EntityList.Tree
import Ports
import Toolkit.Operators exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type alias ModelRecord =
    { path : List String
    , filter : Filter
    , cursor : Cursor.Model
    }


type Model
    = Model ModelRecord


constructor : Path -> Filter -> Cursor.Model -> Model
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
        (Model model) =
            maybePreviousModel ?= initialValue
    in
    Filter.getMaybeFilterFromPath path
        ?|> (\filter ->
                constructor path
                    filter
                    model.cursor
            )


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
    get cursorFL >> .maybeCursorEntityId


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
                    createEntityIdList appModel pageModel

                cursor =
                    Cursor.create entityIdList
                        (Just entityId)
                        (getFilter pageModel)
            in
            set cursorFL cursor pageModel |> pure

        MoveFocusBy offset ->
            let
                cursor =
                    get cursorFL pageModel
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


overModel fn (Model model) =
    fn model


overModelF fn (Model model) =
    fn model |> Model


cursorFL =
    fieldLens (overModel .cursor) (\s b -> overModelF (\b -> { b | cursor = s }) b)


entityListCursorEntityIdListFL =
    let
        entityIdListFL =
            fieldLens .entityIdList (\s b -> { b | entityIdList = s })
    in
    composeInnerOuterFieldLens entityIdListFL cursorFL


createEntityTree pageModel appModel =
    Pages.EntityList.Tree.createEntityTree_ (getFilter pageModel) (getTitle pageModel) appModel


createEntityIdList appModel pageModel =
    createEntityTree pageModel appModel
        |> Tree.flatten
        .|> Entity.toEntityId


computeMaybeNewEntityIdAtCursor appModel pageModel =
    let
        newEntityIdList =
            createEntityIdList appModel pageModel

        newFilter =
            getFilter pageModel
    in
    get cursorFL pageModel
        |> Cursor.computeNewEntityIdAtCursor newFilter newEntityIdList
