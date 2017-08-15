module Models.GroupDocStore exposing (..)

import Document exposing (DocId)
import GroupDoc exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Set exposing (Set)
import Store
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (..)


type alias HasGroupDocStores a =
    { a
        | projectStore : GroupDocStore
        , contextStore : GroupDocStore
    }


contextStore =
    fieldLens .contextStore (\s b -> { b | contextStore = s })


projectStore =
    fieldLens .projectStore (\s b -> { b | projectStore = s })


getStore gdType =
    case gdType of
        ContextGroupDocType ->
            .contextStore

        ProjectGroupDocType ->
            .projectStore


getNullDoc gdType =
    case gdType of
        ContextGroupDocType ->
            nullContext

        ProjectGroupDocType ->
            nullProject


filterNull gdType pred =
    [ getNullDoc gdType ] |> List.filter pred


filter : GroupDocType -> (GroupDoc -> Bool) -> HasGroupDocStores a -> List GroupDoc
filter gdType pred model =
    getStore gdType model
        |> Store.filterDocs pred
        |> GroupDoc.sort
        |> List.append (filterNull gdType pred)


filterContexts pred model =
    Store.filterDocs pred model.contextStore
        |> List.append (GroupDoc.filterNullContext pred)
        |> GroupDoc.sortContexts


filterProjects pred model =
    Store.filterDocs pred model.projectStore
        |> List.append (GroupDoc.filterNullProject pred)
        |> GroupDoc.sortProjects


findProjectById id =
    .projectStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> [ GroupDoc.nullProject ] |> List.find (Document.hasId id))


findProjectByIdIn =
    flip findProjectById


findContextById id =
    .contextStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> [ GroupDoc.nullContext ] |> List.find (Document.hasId id))


findContextByIdIn =
    flip findContextById


findByGroupDocId groupDocId =
    let
        ( getStore, id, null ) =
            case groupDocId of
                GroupDocId ContextGroupDocType id ->
                    ( .contextStore, id, GroupDoc.nullContext )

                GroupDocId ProjectGroupDocType id ->
                    ( .projectStore, id, GroupDoc.nullProject )
    in
    getStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> [ null ] |> List.find (Document.hasId id))


findByGroupDocIdOrNull groupDocId =
    findByGroupDocId groupDocId
        >>?= getNullFromGroupDocId groupDocId


getNullFromGroupDocId =
    getTypeFromGroupDocId >> getNullFromGroupDocType


getTypeFromGroupDocId groupDocId =
    case groupDocId of
        GroupDocId gdType _ ->
            gdType


getNullFromGroupDocType gdType =
    case gdType of
        ContextGroupDocType ->
            nullContext

        ProjectGroupDocType ->
            nullProject


getActiveDocs : GroupDocType -> HasGroupDocStores a -> List GroupDoc
getActiveDocs gdType =
    filter gdType GroupDoc.isActive


getActiveDocIdSet : GroupDocType -> HasGroupDocStores a -> Set DocId
getActiveDocIdSet =
    getActiveDocs
        >>> List.map Document.getId
        >> Set.fromList


getActiveProjects =
    filterProjects GroupDoc.isActive


getActiveContexts =
    filterContexts GroupDoc.isActive


storeFieldFromGDType :
    GroupDocType
    -> FieldLens GroupDocStore (HasGroupDocStores a)
storeFieldFromGDType gdType =
    case gdType of
        ProjectGroupDocType ->
            fieldLens .projectStore (\s b -> { b | projectStore = s })

        ContextGroupDocType ->
            fieldLens .contextStore (\s b -> { b | contextStore = s })
