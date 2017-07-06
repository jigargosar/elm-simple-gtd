module ViewModel exposing (..)

import AppColors
import Color
import Context
import Dict exposing (Dict)
import Document exposing (Id)
import Entity
import AppDrawer.GroupViewModel exposing (DocumentWithNameViewModel)
import Material
import Model exposing (Msg)
import Project
import Set exposing (Set)
import Time exposing (Time)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model exposing (ViewType(..))


type alias Model =
    { contexts : AppDrawer.GroupViewModel.ViewModel
    , projects : AppDrawer.GroupViewModel.ViewModel
    , viewName : String
    , header : { backgroundColor : Color.Color }
    , mdl : Material.Model
    }


create : Model.Model -> Model
create model =
    let
        contextsVM =
            AppDrawer.GroupViewModel.contexts model

        projectsVM =
            AppDrawer.GroupViewModel.projects model

        mainViewType =
            model.mainViewType

        ( viewName, headerBackgroundColor ) =
            getViewInfo mainViewType projectsVM contextsVM model

        editMode =
            Model.getEditMode model

        now =
            Model.getNow model
    in
        { contexts = contextsVM
        , projects = projectsVM
        , viewName = viewName
        , header = { backgroundColor = headerBackgroundColor }
        , mdl = model.mdl
        }


getViewInfo mainViewType projectsVM contextsVM model =
    let
        entityById id =
            List.find (.id >> equals id)

        appHeaderInfoById id vm =
            entityById id vm.entityList
                |> Maybe.orElseLazy (\_ -> entityById id vm.archivedEntityList)
                |> Maybe.orElseLazy (\_ -> entityById id vm.nullVMAsList)
                >>? (.appHeader)
                >>?= { name = "o_O", backgroundColor = sgtdBlue }
                >> (\{ name, backgroundColor } -> ( name, backgroundColor ))
    in
        case mainViewType of
            EntityListView viewType ->
                case viewType of
                    Entity.ContextsView ->
                        ( contextsVM.title, contextsVM.icon.color )

                    Entity.ContextView id ->
                        appHeaderInfoById id contextsVM

                    Entity.ProjectsView ->
                        ( projectsVM.title, projectsVM.icon.color )

                    Entity.ProjectView id ->
                        appHeaderInfoById id projectsVM

                    Entity.BinView ->
                        ( "Bin", sgtdBlue )

                    Entity.DoneView ->
                        ( "Done", sgtdBlue )

                    Entity.RecentView ->
                        ( "Recent", sgtdBlue )

            SyncView ->
                ( "Custom Sync", sgtdBlue )


sgtdBlue =
    AppColors.sgtdBlue
