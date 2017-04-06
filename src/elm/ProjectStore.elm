module ProjectStore exposing (..)

import Dict
import Ext.Random as Random
import Maybe.Extra
import PouchDB
import Project exposing (EncodedProject, Project, ProjectName)
import ProjectStore.Types exposing (..)
import String.Extra
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import List.Extra as List
import Random.Pcg as Random
import Time exposing (Time)


getEncodedProjectNames =
    PouchDB.map (Project.getName >> E.string) >> E.list


getProjectIdToNameDict =
    PouchDB.map (apply2 ( Project.getId, Project.getName )) >> Dict.fromList


findNameById id =
    PouchDB.findById id >>? Project.getName


generator : List EncodedProject -> Random.Generator ProjectStore
generator =
    PouchDB.generator "project-db" Project.encode Project.decoder


findByName projectName =
    PouchDB.findBy (Project.nameEquals (String.trim projectName))


insertIfNotExistByName projectName now m =
    if (String.Extra.isBlank projectName) then
        m
    else
        findByName projectName m
            |> Maybe.Extra.unpack (\_ -> PouchDB.insert (Project.init projectName now) m) (\_ -> m)
