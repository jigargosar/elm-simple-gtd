module ViewModel exposing (..)

import Entity.ViewModel
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model.Types exposing (MainViewType(..))


type alias Model =
    { contexts : Entity.ViewModel.Model
    , projects : Entity.ViewModel.Model
    }


contextsVM m =
    Entity.ViewModel.contexts m


projectsVM m =
    Entity.ViewModel.projects m


create model =
    Model (contextsVM model) (projectsVM model)


getViewName mainViewType projectsVM contextsVM =
    let
        contextNameById id =
            contextsVM.entityList |> List.find (.id >> equals id) >>? .name >>? (++) "@" >>?= ""

        projectNameById id =
            projectsVM.entityList |> List.find (.id >> equals id) >>? .name >>? (++) "#" >>?= ""
    in
        case mainViewType of
            GroupByContextView ->
                contextsVM.title

            ContextView id ->
                contextNameById id

            GroupByProjectView ->
                projectsVM.title

            ProjectView id ->
                projectNameById id

            BinView ->
                "Bin"

            DoneView ->
                "Done"

            SyncView ->
                "Sync"
