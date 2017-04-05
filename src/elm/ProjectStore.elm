module ProjectStore exposing (..)

import Dict
import Ext.Random as Random
import PouchDB
import Project exposing (EncodedProject, Project, ProjectName)
import ProjectStore.Types exposing (..)
import ProjectStore.Internal as Internal exposing (..)
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


generator =
    Internal.generator


getEncodedProjectNames =
    PouchDB.map (Project.getName >> E.string) >> E.list


getProjectIdToNameDict =
    PouchDB.map (apply2 ( Project.getId, Project.getName )) >> Dict.fromList


findNameById id =
    PouchDB.findById id >>? Project.getName


findByName =
    Internal.findByName


insertProjectIfNotExist =
    Internal.addNewIfDoesNotExist
