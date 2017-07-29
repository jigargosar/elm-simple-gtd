module Model.GroupDocStore exposing (..)

import Context
import Document
import GroupDoc
import List.Extra as List
import Maybe.Extra as Maybe
import Project
import Store
import Types.GroupDoc exposing (..)
import X.Record exposing (Field, fieldLens)


contextStore =
    X.Record.fieldLens .contextStore (\s b -> { b | contextStore = s })


projectStore =
    X.Record.fieldLens .projectStore (\s b -> { b | projectStore = s })


filterContexts pred model =
    Store.filterDocs pred model.contextStore
        |> List.append (Context.filterNull pred)
        |> Context.sort


filterProjects pred model =
    Store.filterDocs pred model.projectStore
        |> List.append (Project.filterNull pred)
        |> Project.sort


findProjectById id =
    .projectStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> [ Project.null ] |> List.find (Document.hasId id))


findProjectByIdIn =
    flip findProjectById


findContextById id =
    .contextStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> [ Context.null ] |> List.find (Document.hasId id))


findContextByIdIn =
    flip findContextById


findGroupDocById groupDocId =
    let
        ( getStore, id, null ) =
            case groupDocId of
                ContextGroupDocId id ->
                    ( .contextStore, id, Context.null )

                ProjectGroupDocId id ->
                    ( .projectStore, id, Project.null )
    in
    getStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> [ null ] |> List.find (Document.hasId id))


getActiveProjects =
    filterProjects GroupDoc.isActive


getActiveContexts =
    filterContexts GroupDoc.isActive


storeFieldFromGDType :
    GroupDocType
    ->
        Field GroupDocStore
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
