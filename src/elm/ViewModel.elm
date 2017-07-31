module ViewModel exposing (..)

import AppColors
import AppDrawer.GroupViewModel exposing (DocumentWithNameViewModel)
import GroupDoc.ViewModel exposing (GroupDocViewModel)
import List.Extra as List
import Maybe.Extra as Maybe
import Page exposing (..)
import Pages.EntityList exposing (..)
import Todo.ViewModel
import X.Function exposing (..)
import X.Function.Infix exposing (..)


--type alias Model msg =
--    { contexts : AppDrawer.GroupViewModel.ViewModel msg
--    , projects : AppDrawer.GroupViewModel.ViewModel msg
--    , viewName : String
--    , header : { backgroundColor : Color.Color }
--    , mdl : Material.Model
--    , createProjectGroupVM : (EntityId -> Int) -> List TodoDoc -> ProjectDoc -> GroupDocViewModel msg
--    , createContextGroupVM : (EntityId -> Int) -> List TodoDoc -> ContextDoc -> GroupDocViewModel msg
--    , createTodoViewModel : AppModel -> Bool -> TodoDoc -> TodoViewModel msg
--    }
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

        CustomSyncSettingsPage title ->
            ( title, sgtdBlue )


sgtdBlue =
    AppColors.sgtdBlue
