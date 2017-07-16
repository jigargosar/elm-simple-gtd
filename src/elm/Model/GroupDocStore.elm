module Model.GroupDocStore exposing (..)

import Context
import Document
import Document.Types exposing (DocId)
import GroupDoc
import Project
import Store
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types exposing (AppModel)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record


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


findProjectById : DocId -> AppModel -> Maybe Project.Model
findProjectById id =
    .projectStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> ([ Project.null ] |> List.find (Document.hasId id)))


findProjectByIdIn =
    flip findProjectById


findContextById : DocId -> AppModel -> Maybe Context.Model
findContextById id =
    .contextStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> ([ Context.null ] |> List.find (Document.hasId id)))


findContextByIdIn =
    flip findContextById


getActiveProjects =
    filterProjects GroupDoc.isActive


getActiveContexts =
    filterContexts GroupDoc.isActive
