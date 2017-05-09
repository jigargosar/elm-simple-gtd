module Model.Internal exposing (..)

import Context
import Document
import EditMode exposing (EditForm)
import Ext.Keyboard as Keyboard
import ListSelection
import Project
import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Types exposing (..)
import Time exposing (Time)
import Todo


getTodoStore : Model -> Todo.Store
getTodoStore =
    (.todoStore)


setTodoStore : Todo.Store -> ModelF
setTodoStore todoStore model =
    { model | todoStore = todoStore }


updateTodoStore : (Todo.Store -> Todo.Store) -> ModelF
updateTodoStore updater model =
    { model | todoStore = getTodoStore model |> updater }


getEditMode : Model -> EditForm
getEditMode =
    (.editMode)


setEditMode : EditForm -> ModelF
setEditMode editMode model =
    { model | editMode = editMode }


updateEditModeM : (Model -> EditForm) -> ModelF
updateEditModeM updater model =
    setEditMode (updater model) model


getProjectStore : Model -> Project.Store
getProjectStore =
    (.projectStore)


setProjectStore : Project.Store -> ModelF
setProjectStore projectStore model =
    { model | projectStore = projectStore }


updateProjectStoreM : (Model -> Project.Store) -> ModelF
updateProjectStoreM updater model =
    setProjectStore (updater model) model


getContextStore : Model -> Context.Store
getContextStore =
    (.contextStore)


setContextStore : Context.Store -> ModelF
setContextStore contextStore model =
    { model | contextStore = contextStore }


updateContextStoreM : (Model -> Context.Store) -> ModelF
updateContextStoreM updater model =
    setContextStore (updater model) model


getNow : Model -> Time
getNow =
    (.now)


setNow : Time -> ModelF
setNow now model =
    { model | now = now }


updateNowM : (Model -> Time) -> ModelF
updateNowM updater model =
    { model | now = updater model }


getListSelection : Model -> ListSelection.Model Document.Id
getListSelection =
    (.listSelection)


setListSelection : ListSelection.Model Document.Id -> ModelF
setListSelection listSelection model =
    { model | listSelection = listSelection }


updateListSelectionM : (Model -> ListSelection.Model Document.Id) -> ModelF
updateListSelectionM updater model =
    setListSelection (updater model) model


updateListSelection : (ListSelection.Model Document.Id -> ListSelection.Model Document.Id) -> ModelF
updateListSelection updater model =
    setListSelection (updater (getListSelection model)) model


getKeyboardState : Model -> Keyboard.State
getKeyboardState =
    (.keyboardState)


setKeyboardState : Keyboard.State -> ModelF
setKeyboardState keyboardState model =
    { model | keyboardState = keyboardState }


updateKeyboardStateM : (Model -> Keyboard.State) -> ModelF
updateKeyboardStateM updater model =
    setKeyboardState (updater model) model


updateKeyboardState : (Keyboard.State -> Keyboard.State) -> ModelF
updateKeyboardState updater model =
    setKeyboardState (updater (getKeyboardState model)) model
