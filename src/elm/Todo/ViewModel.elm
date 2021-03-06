module Todo.ViewModel exposing (createTodoViewModel)

import Data.TodoDoc
import Date
import Document
import EntityId
import GroupDoc
import Keyboard.Extra as Key
import Regex
import Set
import Store
import String.Extra
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Keyboard
import X.Time


getDisplayText todo =
    let
        tripleNewLineAndRestRegex =
            Regex.regex "\\n\\n\\n(.|\n)*"

        trimAndReplaceEmptyWithDefault =
            String.trim >> String.Extra.nonEmpty >>?= "< empty >"
    in
    Data.TodoDoc.getText todo
        |> trimAndReplaceEmptyWithDefault
        |> Regex.replace
            (Regex.AtMost 1)
            tripleNewLineAndRestRegex
            (\match -> "\n...")



--createTodoViewModel : AppModel -> Bool -> TodoDoc -> TodoViewModel AppMsg


createTodoViewModel config getEntityListItemDomIdFromEntityId appModel isFocusable todo =
    let
        tabindexAV =
            let
                tabindexValue =
                    if isFocusable then
                        0
                    else
                        -1
            in
            tabindexValue

        now =
            appModel.lastKnownCurrentTime

        todoId =
            Document.getId todo

        truncateName =
            String.Extra.ellipsis 15

        projectId =
            Data.TodoDoc.getProjectId todo

        projectDisplayName =
            projectId
                |> (Store.findById # appModel.projectStore >>? GroupDoc.getName)
                ?= ""
                |> truncateName
                |> String.append "#"

        contextId =
            Data.TodoDoc.getContextId todo

        contextDisplayName =
            contextId
                |> (Store.findById # appModel.contextStore >>? GroupDoc.getName)
                ?= "Inbox"
                |> String.append "@"
                |> truncateName

        entityId =
            EntityId.fromTodoDocId todoId

        reminder =
            createScheduleViewModel config now todo

        onKeyDownMsg ({ key } as ke) =
            if X.Keyboard.isNoSoftKeyDown ke then
                case key of
                    Key.Space ->
                        config.onToggleEntitySelection entityId

                    Key.CharE ->
                        startEditingMsg

                    Key.CharD ->
                        toggleDoneMsg

                    Key.Delete ->
                        toggleDeleteMsg

                    Key.CharP ->
                        config.onStartEditingTodoProject todo

                    Key.CharC ->
                        config.onStartEditingTodoContext todo

                    Key.CharR ->
                        reminder.startEditingMsg

                    _ ->
                        config.noop
            else
                config.noop

        startEditingMsg =
            --            if isFocusable then
            config.onStartEditingTodoText todo

        --            else
        --                config.noop
        toggleDeleteMsg =
            config.onToggleDeletedAndMaybeSelection todoId

        toggleDoneMsg =
            config.onToggleDoneAndMaybeSelection todoId
    in
    { key = todoId
    , domId = getEntityListItemDomIdFromEntityId entityId
    , isDone = Data.TodoDoc.isDone todo
    , isDeleted = Document.isDeleted todo
    , onKeyDownMsg = onKeyDownMsg
    , displayText = getDisplayText todo
    , projectDisplayName = projectDisplayName
    , contextDisplayName = contextDisplayName
    , showContextDropDownMsg = config.onStartEditingTodoContext todo
    , showProjectDropDownMsg = config.onStartEditingTodoProject todo
    , startEditingMsg = startEditingMsg
    , canBeFocused = isFocusable
    , toggleDoneMsg = toggleDoneMsg
    , reminder = reminder
    , onFocusIn = config.setFocusInEntityWithEntityId entityId
    , tabindexAV = tabindexAV
    , isSelected = appModel.selectedEntityIdSet |> Set.member todoId
    , mdl = appModel.mdl
    , onMdl = config.onMdl
    , noop = config.noop
    }



--createScheduleViewModel : Time -> TodoDoc -> ScheduleViewModel AppMsg


createScheduleViewModel config now todo =
    let
        overDueText =
            "Overdue"

        formatReminderTime time =
            let
                dueDate =
                    Date.fromTime time

                nowDate =
                    Date.fromTime now
            in
            if time < now then
                overDueText
            else
                X.Time.smartFormat now time

        displayText =
            Data.TodoDoc.getMaybeTime todo ?|> formatReminderTime ?= ""
    in
    { displayText = displayText
    , isOverDue = displayText == overDueText
    , startEditingMsg = config.onStartEditingReminder todo
    }
