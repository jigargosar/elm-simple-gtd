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
    , mainViewType : MainViewType
    }


create model =
    let
        contextsVM =
            Entity.ViewModel.contexts model

        projectsVM =
            Entity.ViewModel.projects model

        mainViewType =
            model.mainViewType

        ( viewName, _ ) =
            getViewInfo mainViewType projectsVM contextsVM
    in
        Model contextsVM projectsVM viewName mainViewType


getViewInfo mainViewType projectsVM contextsVM =
    let
        contextNameById id =
            contextsVM.entityList |> maybeNameById id >>? (++) "@" >>?= ""

        entityById id =
            List.find (.id >> equals id)

        maybeNameById id =
            entityById id >>? .name

        projectNameById id =
            projectsVM.entityList |> maybeNameById id >>? (++) "#" >>?= ""
    in
        case mainViewType of
            GroupByContextView ->
                ( contextsVM.title, contextsVM.icon.color )

            ContextView id ->
                ( contextNameById id, "" )

            GroupByProjectView ->
                ( projectsVM.title, "" )

            ProjectView id ->
                ( projectNameById id, "" )

            BinView ->
                ( "Bin", "" )

            DoneView ->
                ( "Done", "" )

            SyncView ->
                ( "Sync", "" )
