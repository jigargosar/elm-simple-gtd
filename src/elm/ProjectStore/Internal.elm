module ProjectStore.Internal exposing (..)

import Project exposing (EncodedProject, Project, ProjectId, ProjectName)
import ProjectStore.Types exposing (..)
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


generate : Random.Generator Project -> ModelF
generate generator m =
    Random.step generator (getSeed m)
        |> Tuple.mapSecond (setSeed # m)
        |> apply2 ( Tuple.first, uncurry addToPendingPersistence )
        |> uncurry prepend


addToPendingPersistence : Project -> ProjectStore -> ProjectStore
addToPendingPersistence project =
    updateToPersistList (getToPersistList >> (::) (Project.getId project))


addFromTuple : ( Project, ProjectStore ) -> ( Project, ProjectStore )
addFromTuple =
    apply2 ( Tuple.first, uncurry prepend )


prepend project =
    updateList (getList >> (::) project)


map fn =
    getList >> List.map fn


findBy predicate =
    getList >> List.find predicate


findById id =
    findBy (Project.idEquals id)


decodeListOfEncodedProjects : List EncodedProject -> List Project
decodeListOfEncodedProjects =
    List.map (D.decodeValue Project.decoder)
        >> List.filterMap
            (\result ->
                case result of
                    Ok project ->
                        Just project

                    Err x ->
                        let
                            _ =
                                Debug.log "Error while decoding Project"
                        in
                            Nothing
            )


init list seed =
    ProjectStoreModel [] seed list |> ProjectStore


generator =
    decodeListOfEncodedProjects >> init >> Random.mapWithIndependentSeed


createAndAdd : ProjectName -> Time -> ModelF
createAndAdd projectName now =
    generate (Project.generator projectName now)



{--CODE_GEN_START--}


update f (ProjectStore model) =
    f model |> ProjectStore


get f (ProjectStore model) =
    f model


getSeed : Model -> Seed
getSeed =
    get (.seed)


setSeed : Seed -> ModelF
setSeed seed =
    update (\model -> { model | seed = seed })


updateSeed : (Model -> Seed) -> ModelF
updateSeed updater model =
    setSeed (updater model) model


getList : Model -> List Project
getList =
    get (.list)


setList : List Project -> ModelF
setList list =
    update (\model -> { model | list = list })


updateList : (Model -> List Project) -> ModelF
updateList updater model =
    setList (updater model) model


getToPersistList : Model -> List ProjectId
getToPersistList =
    get (.toPersistList)


setToPersistList : List ProjectId -> ModelF
setToPersistList toPersistList =
    update (\model -> { model | toPersistList = toPersistList })


updateToPersistList : (Model -> List ProjectId) -> ModelF
updateToPersistList updater model =
    setToPersistList (updater model) model
