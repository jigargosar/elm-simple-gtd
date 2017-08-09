module Models.GroupDocStore exposing (..)

import Document
import GroupDoc exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Set
import Store
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (..)


contextStore =
    fieldLens .contextStore (\s b -> { b | contextStore = s })


projectStore =
    fieldLens .projectStore (\s b -> { b | projectStore = s })


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


getActiveProjects =
    filterProjects GroupDoc.isActive


getActiveProjectIdSet appModel =
    getActiveProjects appModel
        .|> Document.getId
        |> Set.fromList


getActiveContexts =
    filterContexts GroupDoc.isActive


getActiveDocs gdType =
    case gdType of
        ProjectGroupDocType ->
            getActiveProjects

        ContextGroupDocType ->
            getActiveContexts


storeFieldFromGDType :
    GroupDocType
    ->
        FieldLens GroupDocStore
            { model
                | projectStore : GroupDocStore
                , contextStore : GroupDocStore
            }
storeFieldFromGDType gdType =
    case gdType of
        ProjectGroupDocType ->
            fieldLens .projectStore (\s b -> { b | projectStore = s })

        ContextGroupDocType ->
            fieldLens .contextStore (\s b -> { b | contextStore = s })
