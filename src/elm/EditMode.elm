module EditMode exposing (..)

import Context
import Document
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
    , todoText : Todo.Text
    , projectName : Project.Name
    , contextName : Context.Name
    }


type alias EditContextModel =
    { id : Document.Id
    , name : Context.Name
    }


type alias EditProjectModel =
    { id : Document.Id
    , name : Project.Name
    }


type alias NewTodoModel =
    Todo.Text


type EditMode
    = NewTodo NewTodoModel
    | EditTodo EditTodoModel
    | EditContext EditContextModel
    | EditProject EditProjectModel
    | None
    | SwitchView
    | SwitchToGroupedView


none =
    None


createNewTodoModel =
    NewTodo


createEditTodoMode : Todo.Model -> Project.Name -> Context.Name -> EditMode
createEditTodoMode todo projectName contextName =
    { todoId = Document.getId todo
    , todoText = Todo.getText todo
    , projectName = projectName
    , contextName = contextName
    }
        |> EditTodo


editContextMode model =
    EditContext { id = Document.getId model, name = Context.getName model }


editContextSetName name ecm =
    EditContext { ecm | name = name }


editProjectMode model =
    EditProject { id = Document.getId model, name = Project.getName model }


editProjectSetName name epm =
    EditProject { epm | name = name }


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
