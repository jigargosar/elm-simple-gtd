module ProjectStore.Internal exposing (..)

import Maybe.Extra
import PouchDB
import Project exposing (EncodedProject, Project, ProjectName)
import ProjectStore.Types exposing (..)
import String.Extra
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Random.Pcg as Random exposing (Seed)
import List.Extra as List
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Ext.Random as Random
import Time exposing (Time)


decodeList : List EncodedProject -> List Project
decodeList =
    List.map (D.decodeValue Project.decoder)
        >> List.filterMap
            (\result ->
                case result of
                    Ok project ->
                        Just project

                    Err x ->
                        let
                            _ =
                                Debug.log "Error while decoding Project" x
                        in
                            Nothing
            )


generator : List EncodedProject -> Random.Generator ProjectStore
generator =
    PouchDB.generator "project-db" Project.encode Project.decoder


findByName projectName =
    PouchDB.findBy (Project.nameEquals (String.trim projectName))


addNewIfDoesNotExist projectName now m =
    if (String.Extra.isBlank projectName) then
        m
    else
        findByName projectName m
            |> Maybe.Extra.unpack (\_ -> PouchDB.insert (Project.init projectName now) m) (\_ -> m)
