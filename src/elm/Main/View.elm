module Main.View exposing (appView)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation, onEnter)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Flow
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import Todo as Todo exposing (EditMode(..))
import TodoStore.View
import Flow.Model as Flow exposing (Node)
import InBasketFlow
import InBasketFlow.View


todoListViewConfig =
    { onAddTodoClicked = OnAddTodoClicked
    , onDeleteTodoClicked = OnDeleteTodoClicked
    , onEditTodoClicked = OnEditTodoClicked
    , onEditTodoTextChanged = OnEditTodoTextChanged
    , onEditTodoBlur = OnEditTodoBlur
    , onEditTodoEnterPressed = OnEditTodoEnterPressed
    , onNewTodoTextChanged = OnNewTodoTextChanged
    , onNewTodoBlur = OnNewTodoBlur
    , onNewTodoEnterPressed = OnNewTodoEnterPressed
    }



{-
   <app-header reveals>
       <app-toolbar>
         <paper-icon-button icon="menu" onclick="drawer.toggle()"></paper-icon-button>
         <div main-title>My app</div>
         <paper-icon-button icon="delete"></paper-icon-button>
         <paper-icon-button icon="search"></paper-icon-button>
         <paper-icon-button icon="close"></paper-icon-button>
         <paper-progress value="10" indeterminate bottom-item></paper-progress>
       </app-toolbar>
     </app-header>
-}


appView m =
    div []
        [ headerView m
        , div [ id "center-view" ] [ centerView m ]
        ]


headerView m =
    node "app-header"
        [ attribute "reveals" "true"
        , attribute "fixed" "true"
        , attribute "condenses" "true"
        , attribute "effects" "waterfall"
        ]
        [ node "app-toolbar"
            []
            [ node "paper-icon-button" [ attribute "icon" "favorite" ] []
            , node "paper-button"
                [ attribute "raised" "true"
                , onClick OnShowTodoList
                ]
                [ text "Show List" ]
            , node "paper-button"
                [ attribute "raised" "true"
                , onClick OnProcessInBasket
                ]
                [ text "Process Stuff" ]
            , addTodoView (getEditMode m) todoListViewConfig
            ]
        ]



--headerView m =
--    node "app-header"
--        [ attribute "reveals" "true"
--          --        , attribute "fixed" "true"
--        ]
--        [ node "app-toolbar"
--            []
--            [ div [ attribute "main-title" "true" ] [ text "main title" ]
--            ]
--        ]


addTodoView editMode viewConfig =
    case editMode of
        EditNewTodoMode text ->
            addNewTodoView viewConfig text

        _ ->
            addTodoButton viewConfig


addNewTodoView viewConfig text =
    node "paper-input"
        [ onInput viewConfig.onNewTodoTextChanged
        , value text
        , onBlur viewConfig.onNewTodoBlur
        , autofocus True
        , onEnter viewConfig.onNewTodoEnterPressed
        ]
        []


addTodoButton viewConfig =
    node "paper-button"
        [ attribute "raised" "true"
        , onClick viewConfig.onAddTodoClicked
        ]
        [ text "Add" ]


centerView m =
    case getViewState m of
        TodoListViewState ->
            todoListView m

        InBasketFlowViewState maybeTodo inBasketFlowModel ->
            InBasketFlow.View.view maybeTodo inBasketFlowModel


todoListView m =
    div []
        [ TodoStore.View.allTodosView todoListViewConfig (getEditMode m) (getTodoCollection m)
        ]
