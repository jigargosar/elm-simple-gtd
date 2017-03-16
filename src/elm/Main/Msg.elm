module Main.Msg exposing (..)

import Json.Decode
import Navigation exposing (Location)
import TodoCollection.Todo exposing (Todo, TodoId)


type ProcessingModel
    = NotProcessing
    | StartProcessing Todo
    | ProcessAsActionable Todo
    | ProcessAsNotActionable Todo



type Msg
    = LocationChanged Location
    | OnAddTodoClicked
    | OnDeleteTodoClicked TodoId
    | OnEditTodoClicked Todo
    | OnNewTodoTextChanged String
    | OnNewTodoBlur
    | OnNewTodoEnterPressed
    | OnEditTodoTextChanged String
    | OnEditTodoBlur
    | OnEditTodoEnterPressed
    | OnProcessButtonClicked
    | OnActionableYesClicked
    | OnActionableNoClicked
    | OnUpdateProcessingModel ProcessingModel
