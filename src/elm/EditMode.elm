module EditMode exposing (..)

import Context
import Project
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias EditTodoModel =
    { todoId : Todo.Id
    , todo_ : Todo.Model
    , todoText : Todo.Text
    , projectName : Project.Name
    , contextName : Context.Name
    }


type alias NewTodoModel =
    Todo.Text


type EditMode
    = NewTodo NewTodoModel
    | EditTodo EditTodoModel
    | None
    | SwitchView
    | SwitchToGroupedView


none =
    None


createNewTodoModel =
    NewTodo


createEditTodoModel todo projectName contextName =
    { todoId = Todo.getId todo
    , todo_ = todo
    , todoText = Todo.getText todo
    , projectName = projectName
    , contextName = contextName
    }
        |> EditTodo


updateEditTodoText text editTodoModel =
    (EditTodo ({ editTodoModel | todoText = text }))


getMaybeEditTodoModel model =
    case model of
        EditTodo model ->
            Just model

        _ ->
            Nothing


getNewTodoModel model =
    case model of
        NewTodo model ->
            Just model

        _ ->
            Nothing


updateEditTodoProjectName projectName editTodoModel =
    (EditTodo ({ editTodoModel | projectName = projectName }))


updateEditTodoContextName contextName editTodoModel =
    (EditTodo ({ editTodoModel | contextName = contextName }))
