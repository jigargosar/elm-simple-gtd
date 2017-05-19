module ViewModel exposing (..)

import Document
import Entity.ViewModel exposing (EntityViewModel)
import Html exposing (Attribute)
import Msg exposing (Msg)
import Todo
import Todo.View
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model exposing (GroupByViewType(..), EntityFocus, MainViewType(..))
import View.Shared exposing (SharedViewModel)


type EntityView
    = EntityView EntityViewModel
    | TodoView Todo.Model


getIdOfEntityView entityView =
    case entityView of
        TodoView todo ->
            Document.getId todo

        EntityView vm ->
            vm.id


type alias Model =
    { contexts : Entity.ViewModel.ViewModel
    , projects : Entity.ViewModel.ViewModel
    , viewName : String
    , mainViewType : MainViewType
    , header : { backgroundColor : String }
    , shared : SharedViewModel
    , createTodoViewModel : Attribute Msg -> Todo.Model -> Todo.View.TodoViewModel
    , focusedEntityInfo : EntityFocus
    }


create : Model.Model -> Model
create model =
    let
        contextsVM =
            Entity.ViewModel.contexts model

        projectsVM =
            Entity.ViewModel.projects model

        mainViewType =
            model.mainViewType

        ( viewName, headerBackgroundColor ) =
            getViewInfo mainViewType projectsVM contextsVM

        sharedViewModel =
            View.Shared.createSharedViewModel model
    in
        Model
            contextsVM
            projectsVM
            viewName
            mainViewType
            { backgroundColor = headerBackgroundColor }
            sharedViewModel
            (Todo.View.createTodoViewModel sharedViewModel)
            model.focusedEntityInfo


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
                    ContextsView ->
                        ( contextsVM.title, contextsVM.icon.color )

                    ContextView id ->
                        contextsVM.entityList |> appHeaderInfoById id

                    ProjectsView ->
                        ( projectsVM.title, projectsVM.icon.color )

                    ProjectView id ->
                        projectsVM.entityList |> appHeaderInfoById id

            BinView ->
                ( "Bin", sgtdBlue )

            DoneView ->
                ( "Done", sgtdBlue )

            SyncView ->
                ( "Sync", sgtdBlue )


sgtdBlue =
    --paper-blue-a200
    "rgb(68, 138, 255)"
