module Model.GroupDocStore exposing (..)

import Context
import Document
import GroupDoc
import GroupDoc.Types exposing (GroupDocStore, GroupDocType(ContextGroupDocType, ProjectGroupDocType))
import List.Extra as List
import Maybe.Extra as Maybe
import Project
import Store
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



--findProjectById : DocId -> AppModel -> Maybe Project.Model


findProjectById id =
    .projectStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> [ Project.null ] |> List.find (Document.hasId id))


findProjectByIdIn =
    flip findProjectById



--findContextById : DocId -> AppModel -> Maybe Context.Model


findContextById id =
    .contextStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> [ Context.null ] |> List.find (Document.hasId id))


findContextByIdIn =
    flip findContextById


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
