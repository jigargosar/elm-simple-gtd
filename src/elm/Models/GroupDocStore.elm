module Models.GroupDocStore exposing (..)

import Document
import GroupDoc exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Store
import X.Record exposing (FieldLens, fieldLens)


contextStore =
    X.Record.fieldLens .contextStore (\s b -> { b | contextStore = s })


projectStore =
    X.Record.fieldLens .projectStore (\s b -> { b | projectStore = s })


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
                ContextGroupDocId id ->
                    ( .contextStore, id, GroupDoc.nullContext )

                ProjectGroupDocId id ->
                    ( .projectStore, id, GroupDoc.nullProject )
    in
    getStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> [ null ] |> List.find (Document.hasId id))


getActiveProjects =
    filterProjects GroupDoc.isActive


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
