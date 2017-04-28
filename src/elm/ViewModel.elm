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
    , viewName : String
    }


create model =
    let
        contextsVM =
            Entity.ViewModel.contexts model

        projectsVM =
            Entity.ViewModel.projects model

        mainViewType =
            model.mainViewType

        viewName =
            getViewName mainViewType projectsVM contextsVM
    in
        Model contextsVM projectsVM viewName


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
