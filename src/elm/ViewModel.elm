module ViewModel exposing (..)

import AppColors
import Color
import AppDrawer.GroupViewModel exposing (DocumentWithNameViewModel)
import Entity.Types
import Material
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Types exposing (AppModel)
import Types.ViewType exposing (ViewType(EntityListView, SyncView))


type alias Model =
    { contexts : AppDrawer.GroupViewModel.ViewModel
    , projects : AppDrawer.GroupViewModel.ViewModel
    , viewName : String
    , header : { backgroundColor : Color.Color }
    , mdl : Material.Model
    }


create : AppModel -> Model
create model =
    let
        contextsVM =
            AppDrawer.GroupViewModel.contexts model

        projectsVM =
            AppDrawer.GroupViewModel.projects model

        viewType =
            model.viewType

        ( viewName, headerBackgroundColor ) =
            getViewInfo viewType projectsVM contextsVM model

        editMode =
            model.editMode

        now =
            model.now
    in
        { contexts = contextsVM
        , projects = projectsVM
        , viewName = viewName
        , header = { backgroundColor = headerBackgroundColor }
        , mdl = model.mdl
        }


getViewInfo viewType projectsVM contextsVM model =
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
        case viewType of
            EntityListView viewType ->
                case viewType of
                    Entity.Types.ContextsView ->
                        ( contextsVM.title, contextsVM.icon.color )

                    Entity.Types.ContextView id ->
                        appHeaderInfoById id contextsVM

                    Entity.Types.ProjectsView ->
                        ( projectsVM.title, projectsVM.icon.color )

                    Entity.Types.ProjectView id ->
                        appHeaderInfoById id projectsVM

                    Entity.Types.BinView ->
                        ( "Bin", sgtdBlue )

                    Entity.Types.DoneView ->
                        ( "Done", sgtdBlue )

                    Entity.Types.RecentView ->
                        ( "Recent", sgtdBlue )

            SyncView ->
                ( "Custom Sync", sgtdBlue )


sgtdBlue =
    AppColors.sgtdBlue
