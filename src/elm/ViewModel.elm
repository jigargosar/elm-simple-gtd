module ViewModel exposing (..)

import AppColors
import AppDrawer.GroupViewModel exposing (DocumentWithNameViewModel)
import Color
import Entity.Types exposing (..)
import GroupDoc.ViewModel exposing (GroupDocViewModel)
import List.Extra as List
import Material
import Maybe.Extra as Maybe
import Page exposing (Page(CustomSyncSettingsPage, EntityListPage))
import Pages.EntityList exposing (..)
import Todo.ItemView exposing (TodoViewModel)
import Todo.ViewModel
import Types.AppModel exposing (..)
import Types.GroupDoc exposing (..)
import Types.Todo exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type alias Model msg =
    { contexts : AppDrawer.GroupViewModel.ViewModel msg
    , projects : AppDrawer.GroupViewModel.ViewModel msg
    , viewName : String
    , header : { backgroundColor : Color.Color }
    , mdl : Material.Model
    , createProjectGroupVM : (EntityId -> Int) -> List TodoDoc -> ProjectDoc -> GroupDocViewModel msg
    , createContextGroupVM : (EntityId -> Int) -> List TodoDoc -> ContextDoc -> GroupDocViewModel msg
    , createTodoViewModel : AppModel -> Bool -> TodoDoc -> TodoViewModel msg
    }



--create : AppModel -> Model


create config model =
    let
        contextsVM =
            AppDrawer.GroupViewModel.contexts config model

        projectsVM =
            AppDrawer.GroupViewModel.projects config model

        page =
            model.page

        ( viewName, headerBackgroundColor ) =
            getViewInfo page projectsVM contextsVM model

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
    , createProjectGroupVM = GroupDoc.ViewModel.createProjectGroupVM config
    , createContextGroupVM = GroupDoc.ViewModel.createContextGroupVM config
    , createTodoViewModel = Todo.ViewModel.createTodoViewModel config
    }


getViewInfo page projectsVM contextsVM model =
    let
        entityById id =
            List.find (.id >> equals id)

        appHeaderInfoById id vm =
            entityById id vm.entityList
                |> Maybe.orElseLazy (\_ -> entityById id vm.archivedEntityList)
                |> Maybe.orElseLazy (\_ -> entityById id vm.nullVMAsList)
                >>? .appHeader
                >>?= { name = "o_O", backgroundColor = sgtdBlue }
                >> (\{ name, backgroundColor } -> ( name, backgroundColor ))
    in
    case page of
        EntityListPage page ->
            case page of
                ContextsView ->
                    ( contextsVM.title, contextsVM.icon.color )

                ContextView id ->
                    appHeaderInfoById id contextsVM

                ProjectsView ->
                    ( projectsVM.title, projectsVM.icon.color )

                ProjectView id ->
                    appHeaderInfoById id projectsVM

                BinView ->
                    ( "Bin", sgtdBlue )

                DoneView ->
                    ( "Done", sgtdBlue )

                RecentView ->
                    ( "Recent", sgtdBlue )

        CustomSyncSettingsPage ->
            ( "Custom Sync", sgtdBlue )


sgtdBlue =
    AppColors.sgtdBlue
