module ViewModel exposing (..)

import Document
import Entity
import OldGroupEntity.ViewModel exposing (DocumentWithNameViewModel)
import Html exposing (Attribute)
import Model exposing (Msg)
import Todo
import Todo.View
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model exposing (EntityFocus, ViewType(..))
import View.Shared exposing (SharedViewModel)


type alias Model =
    { contexts : OldGroupEntity.ViewModel.ViewModel
    , projects : OldGroupEntity.ViewModel.ViewModel
    , viewName : String
    , mainViewType : ViewType
    , header : { backgroundColor : String }
    , shared : SharedViewModel
    , createTodoViewModel : Attribute Msg -> Todo.Model -> Todo.View.TodoViewModel
    }


create : Model.Model -> Model
create model =
    let
        contextsVM =
            OldGroupEntity.ViewModel.contexts model

        projectsVM =
            OldGroupEntity.ViewModel.projects model

        mainViewType =
            model.mainViewType

        ( viewName, headerBackgroundColor ) =
            getViewInfo mainViewType projectsVM contextsVM

        sharedViewModel =
            View.Shared.createSharedViewModel model
    in
        { contexts = contextsVM
        , projects = projectsVM
        , viewName = viewName
        , mainViewType = mainViewType
        , header = { backgroundColor = headerBackgroundColor }
        , shared = sharedViewModel
        , createTodoViewModel = (Todo.View.createTodoViewModel sharedViewModel)
        }


getViewInfo mainViewType projectsVM contextsVM =
    let
        entityById id =
            List.find (.id >> equals id)

        appHeaderInfoById id =
            entityById id
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
                        contextsVM.entityList |> appHeaderInfoById id

                    Entity.ProjectsView ->
                        ( projectsVM.title, projectsVM.icon.color )

                    Entity.ProjectView id ->
                        projectsVM.entityList |> appHeaderInfoById id

            BinView ->
                ( "Bin", sgtdBlue )

            DoneView ->
                ( "Done", sgtdBlue )

            SyncView ->
                ( "Custom Sync", sgtdBlue )


sgtdBlue =
    --paper-blue-a200
    "rgb(68, 138, 255)"
