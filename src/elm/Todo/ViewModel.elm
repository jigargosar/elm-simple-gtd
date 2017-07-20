module Todo.ViewModel exposing (createTodoViewModel)

import Date
import Document.Types exposing (getDocId)
import Entity.Types
import EntityId
import GroupDoc
import Regex
import Set
import Store
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import String.Extra
import Todo
import X.Keyboard
import Keyboard.Extra as Key
import X.Time


getDisplayText todo =
    let
        tripleNewLineAndRestRegex =
            (Regex.regex "\\n\\n\\n(.|\n)*")

        trimAndReplaceEmptyWithDefault =
            String.trim >> String.Extra.nonEmpty >>?= "< empty >"
    in
        Todo.getText todo
            |> trimAndReplaceEmptyWithDefault
            |> Regex.replace
                (Regex.AtMost 1)
                tripleNewLineAndRestRegex
                (\match -> "\n...")



--createTodoViewModel : AppModel -> Bool -> TodoDoc -> TodoViewModel AppMsg


createTodoViewModel config appM isFocusable todo =
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
            appM.now

        todoId =
            getDocId todo

        truncateName =
            String.Extra.ellipsis 15

        projectId =
            Todo.getProjectId todo

        projectDisplayName =
            projectId
                |> (Store.findById # appM.projectStore >>? GroupDoc.getName)
                ?= ""
                |> truncateName
                |> String.append "#"

        contextId =
            Todo.getContextId todo

        contextDisplayName =
            contextId
                |> (Store.findById # appM.contextStore >>? GroupDoc.getName)
                ?= "Inbox"
                |> String.append "@"
                |> truncateName

        entityId =
            EntityId.fromTodoDocId todoId

        createEntityUpdateMsg =
            config.onEntityUpdateMsg (EntityId.fromTodoDocId todoId)

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

                    Key.CharG ->
                        createEntityUpdateMsg Entity.Types.EUA_OnGotoEntity

                    Key.CharS ->
                        config.onSwitchOrStartTrackingTodo todoId

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
        { isDone = Todo.isDone todo
        , key = todoId
        , isDeleted = Todo.getDeleted todo
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
        , onFocusIn = createEntityUpdateMsg Entity.Types.EUA_OnFocusIn
        , tabindexAV = tabindexAV
        , isSelected = appM.selectedEntityIdSet |> Set.member todoId
        , mdl = appM.mdl
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
            Todo.getMaybeTime todo ?|> formatReminderTime ?= ""
    in
        { displayText = displayText
        , isOverDue = displayText == overDueText
        , startEditingMsg = config.onStartEditingReminder todo
        }
