-- grep -B 1 -A 22 "case " src/elm/**.elm  > case-expressions.elm

src/elm/CommonMsg.elm-update msg =
src/elm/CommonMsg.elm:    case msg of
src/elm/CommonMsg.elm-        NoOp ->
src/elm/CommonMsg.elm-            Cmd.none |> Return.command
src/elm/CommonMsg.elm-
src/elm/CommonMsg.elm-        Focus selector ->
src/elm/CommonMsg.elm-            selector |> DomPorts.focusSelector |> Return.command
src/elm/CommonMsg.elm-
src/elm/CommonMsg.elm-        LogString string ->
src/elm/CommonMsg.elm-            let
src/elm/CommonMsg.elm-                _ =
src/elm/CommonMsg.elm-                    X.Debug.log "CM:LogString" string
src/elm/CommonMsg.elm-            in
src/elm/CommonMsg.elm-            update NoOp
src/elm/CommonMsg.elm-
src/elm/CommonMsg.elm-
src/elm/CommonMsg.elm-type alias Helper msg =
src/elm/CommonMsg.elm-    { noOp : msg
src/elm/CommonMsg.elm-    , focus : DomSelector -> msg
src/elm/CommonMsg.elm-    , logString : String -> msg
src/elm/CommonMsg.elm-    }
src/elm/CommonMsg.elm-
src/elm/CommonMsg.elm-
src/elm/CommonMsg.elm-createHelper : (Msg -> msg) -> Helper msg
--
--
src/elm/Entity.elm-getEntityDocId entity =
src/elm/Entity.elm:    case entity of
src/elm/Entity.elm-        TodoEntity model ->
src/elm/Entity.elm-            getDocId model
src/elm/Entity.elm-
src/elm/Entity.elm-        GroupEntity group ->
--
src/elm/Entity.elm-        GroupEntity group ->
src/elm/Entity.elm:            case group of
src/elm/Entity.elm-                ProjectEntity model ->
src/elm/Entity.elm-                    getDocId model
src/elm/Entity.elm-
src/elm/Entity.elm-                ContextEntity model ->
src/elm/Entity.elm-                    getDocId model
src/elm/Entity.elm-
src/elm/Entity.elm-
src/elm/Entity.elm-toEntityId entity =
--
src/elm/Entity.elm-toEntityId entity =
src/elm/Entity.elm:    case entity of
src/elm/Entity.elm-        TodoEntity m ->
src/elm/Entity.elm-            TodoId (getDocId m)
src/elm/Entity.elm-
src/elm/Entity.elm-        GroupEntity ge ->
--
src/elm/Entity.elm-        GroupEntity ge ->
src/elm/Entity.elm:            case ge of
src/elm/Entity.elm-                ProjectEntity m ->
src/elm/Entity.elm-                    ProjectId (getDocId m)
src/elm/Entity.elm-
src/elm/Entity.elm-                ContextEntity m ->
src/elm/Entity.elm-                    ContextId (getDocId m)
src/elm/Entity.elm-
src/elm/Entity.elm-
src/elm/Entity.elm-equalById =
src/elm/Entity.elm-    tuple2 >>> mapAllT2 toEntityId >> equalsT2
src/elm/Entity.elm-
src/elm/Entity.elm-
src/elm/Entity.elm-hasEntityId entityId entity =
src/elm/Entity.elm-    toEntityId entity |> equals entityId
src/elm/Entity.elm-
src/elm/Entity.elm-
src/elm/Entity.elm-findEntityByOffsetIn offsetIndex entityList fromEntity =
src/elm/Entity.elm-    entityList
src/elm/Entity.elm-        |> List.findIndex (equalById fromEntity)
src/elm/Entity.elm-        ?= 0
src/elm/Entity.elm-        |> add offsetIndex
src/elm/Entity.elm-        |> List.clampIndexIn entityList
src/elm/Entity.elm-        |> List.atIndexIn entityList
--
--
src/elm/Entity/Tree.elm-flatten tree =
src/elm/Entity/Tree.elm:    case tree of
src/elm/Entity/Tree.elm-        ContextRoot node nodeList ->
src/elm/Entity/Tree.elm-            Entity.fromContext node.context
src/elm/Entity/Tree.elm-                :: flatten (ProjectForest nodeList)
src/elm/Entity/Tree.elm-
src/elm/Entity/Tree.elm-        ProjectRoot node nodeList ->
src/elm/Entity/Tree.elm-            Entity.fromProject node.project
src/elm/Entity/Tree.elm-                :: flatten (ContextForest nodeList)
src/elm/Entity/Tree.elm-
src/elm/Entity/Tree.elm-        ContextForest nodeList ->
src/elm/Entity/Tree.elm-            nodeList
src/elm/Entity/Tree.elm-                |> List.concatMap
src/elm/Entity/Tree.elm-                    (\node -> Entity.fromContext node.context :: (node.todoList .|> Entity.Types.TodoEntity))
src/elm/Entity/Tree.elm-
src/elm/Entity/Tree.elm-        ProjectForest groupList ->
src/elm/Entity/Tree.elm-            groupList
src/elm/Entity/Tree.elm-                |> List.concatMap
src/elm/Entity/Tree.elm-                    (\g ->
src/elm/Entity/Tree.elm-                        Entity.fromProject g.project
src/elm/Entity/Tree.elm-                            :: (g.todoList .|> Entity.Types.TodoEntity)
src/elm/Entity/Tree.elm-                    )
src/elm/Entity/Tree.elm-
src/elm/Entity/Tree.elm-        TodoForest title todoList ->
--
--
src/elm/Entity/Types.elm-getDocIdFromEntityId entityId =
src/elm/Entity/Types.elm:    case entityId of
src/elm/Entity/Types.elm-        ContextId id ->
src/elm/Entity/Types.elm-            id
src/elm/Entity/Types.elm-
src/elm/Entity/Types.elm-        ProjectId id ->
src/elm/Entity/Types.elm-            id
src/elm/Entity/Types.elm-
src/elm/Entity/Types.elm-        TodoId id ->
src/elm/Entity/Types.elm-            id
src/elm/Entity/Types.elm-
src/elm/Entity/Types.elm-
src/elm/Entity/Types.elm-createTodoEntityId =
src/elm/Entity/Types.elm-    TodoId
--
--
src/elm/Entity/View.elm-    in
src/elm/Entity/View.elm:    case grouping of
src/elm/Entity/View.elm-        Entity.Tree.ContextRoot contextGroup subGroupList ->
src/elm/Entity/View.elm-            let
src/elm/Entity/View.elm-                header =
src/elm/Entity/View.elm-                    createContextVM contextGroup |> groupHeaderView
src/elm/Entity/View.elm-            in
src/elm/Entity/View.elm-            header :: multiProjectView subGroupList
src/elm/Entity/View.elm-
src/elm/Entity/View.elm-        Entity.Tree.ProjectRoot projectGroup subGroupList ->
src/elm/Entity/View.elm-            let
src/elm/Entity/View.elm-                header =
src/elm/Entity/View.elm-                    createProjectVM projectGroup |> groupHeaderView
src/elm/Entity/View.elm-            in
src/elm/Entity/View.elm-            header :: multiContextView subGroupList
src/elm/Entity/View.elm-
src/elm/Entity/View.elm-        Entity.Tree.ContextForest groupList ->
src/elm/Entity/View.elm-            multiContextView groupList
src/elm/Entity/View.elm-
src/elm/Entity/View.elm-        Entity.Tree.ProjectForest groupList ->
src/elm/Entity/View.elm-            multiProjectView groupList
src/elm/Entity/View.elm-
src/elm/Entity/View.elm-        Entity.Tree.TodoForest title todoList ->
src/elm/Entity/View.elm-            todoListView todoList
--
--
src/elm/Firebase/Model.elm-getMaybeUserProfile user =
src/elm/Firebase/Model.elm:    case user of
src/elm/Firebase/Model.elm-        SignedOut ->
src/elm/Firebase/Model.elm-            Nothing
src/elm/Firebase/Model.elm-
src/elm/Firebase/Model.elm-        SignedIn userModel ->
src/elm/Firebase/Model.elm-            userModel.providerData |> List.head
src/elm/Firebase/Model.elm-
src/elm/Firebase/Model.elm-
src/elm/Firebase/Model.elm-getMaybeUserId user =
--
src/elm/Firebase/Model.elm-getMaybeUserId user =
src/elm/Firebase/Model.elm:    case user of
src/elm/Firebase/Model.elm-        SignedOut ->
src/elm/Firebase/Model.elm-            Nothing
src/elm/Firebase/Model.elm-
src/elm/Firebase/Model.elm-        SignedIn userModel ->
src/elm/Firebase/Model.elm-            userModel.id |> Just
--
--
src/elm/Firebase/SignIn.elm-stringToMaybeState string =
src/elm/Firebase/SignIn.elm:    case string of
src/elm/Firebase/SignIn.elm-        "SkipSignIn" ->
src/elm/Firebase/SignIn.elm-            Just SkipSignIn
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-        "TriedSignOut" ->
src/elm/Firebase/SignIn.elm-            Just TriedSignOut
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-        "SignInSuccess" ->
src/elm/Firebase/SignIn.elm-            Just SignInSuccess
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-        "FirstVisitNotSignedIn" ->
src/elm/Firebase/SignIn.elm-            Just FirstVisitNotSignedIn
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-        _ ->
src/elm/Firebase/SignIn.elm-            Nothing
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-stateDecoder : Decoder State
src/elm/Firebase/SignIn.elm-stateDecoder =
src/elm/Firebase/SignIn.elm-    D.string
src/elm/Firebase/SignIn.elm-        |> D.andThen
src/elm/Firebase/SignIn.elm-            (\string ->
src/elm/Firebase/SignIn.elm-                string |> stringToMaybeState ?|> D.succeed ?= D.fail ("Unknown State: " ++ string)
--
--
src/elm/Firebase/SignIn.elm-shouldSkipSignIn model =
src/elm/Firebase/SignIn.elm:    case model.state of
src/elm/Firebase/SignIn.elm-        SignInSuccess ->
src/elm/Firebase/SignIn.elm-            True
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-        SkipSignIn ->
src/elm/Firebase/SignIn.elm-            True
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-        _ ->
src/elm/Firebase/SignIn.elm-            False
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-setSkipSignIn =
src/elm/Firebase/SignIn.elm-    X.Record.set state SkipSignIn
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-setStateToTriedSignOut =
src/elm/Firebase/SignIn.elm-    X.Record.set state TriedSignOut
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-
src/elm/Firebase/SignIn.elm-setStateToSignInSuccess =
src/elm/Firebase/SignIn.elm-    X.Record.set state SignInSuccess
--
--
src/elm/GroupDoc.elm-        (\v1 v2 ->
src/elm/GroupDoc.elm:            case ( isNull v1, isNull v2 ) of
src/elm/GroupDoc.elm-                ( True, False ) ->
src/elm/GroupDoc.elm-                    LT
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-                ( False, True ) ->
src/elm/GroupDoc.elm-                    GT
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-                ( True, True ) ->
src/elm/GroupDoc.elm-                    EQ
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-                ( False, False ) ->
src/elm/GroupDoc.elm-                    compareNotNulls ( v1, v2 )
src/elm/GroupDoc.elm-        )
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-compareNotNulls tuple =
src/elm/GroupDoc.elm-    let
src/elm/GroupDoc.elm-        compareName =
src/elm/GroupDoc.elm-            Tuple2.mapBoth getName >> uncurry compare
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-        compareModifiedAt =
src/elm/GroupDoc.elm-            Tuple2.mapBoth (Document.getModifiedAt >> negate) >> uncurry compare
src/elm/GroupDoc.elm-    in
--
--
src/elm/GroupDoc.elm-        |> (\archivedTuple ->
src/elm/GroupDoc.elm:                case archivedTuple of
src/elm/GroupDoc.elm-                    ( True, False ) ->
src/elm/GroupDoc.elm-                        LT
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-                    ( False, True ) ->
src/elm/GroupDoc.elm-                        GT
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-                    ( True, True ) ->
src/elm/GroupDoc.elm-                        compareModifiedAt tuple
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-                    ( False, False ) ->
src/elm/GroupDoc.elm-                        compareName tuple
src/elm/GroupDoc.elm-           )
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-isActive =
src/elm/GroupDoc.elm-    X.Predicate.all [ Document.isNotDeleted, isNotArchived ]
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-archivedButNotDeletedPred =
src/elm/GroupDoc.elm-    X.Predicate.all [ Document.isNotDeleted, isArchived ]
src/elm/GroupDoc.elm-
src/elm/GroupDoc.elm-
--
--
src/elm/GroupDoc/FormView.elm-        ( entityId, nameLabel ) =
src/elm/GroupDoc/FormView.elm:            (case form.groupDocType of
src/elm/GroupDoc/FormView.elm-                ContextGroupDocType ->
src/elm/GroupDoc/FormView.elm-                    ( ContextId, "Context" )
src/elm/GroupDoc/FormView.elm-
src/elm/GroupDoc/FormView.elm-                ProjectGroupDocType ->
src/elm/GroupDoc/FormView.elm-                    ( ProjectId, "Project" )
src/elm/GroupDoc/FormView.elm-            )
src/elm/GroupDoc/FormView.elm-                |> Tuple2.mapEach (apply form.id) (String.append # " Name")
src/elm/GroupDoc/FormView.elm-
src/elm/GroupDoc/FormView.elm-        toMsg =
src/elm/GroupDoc/FormView.elm-            config.onEntityUpdateMsg entityId
src/elm/GroupDoc/FormView.elm-
src/elm/GroupDoc/FormView.elm-        fireNameChanged =
src/elm/GroupDoc/FormView.elm-            config.onGD_UpdateFormName form
src/elm/GroupDoc/FormView.elm-
src/elm/GroupDoc/FormView.elm-        fireSaveForm =
src/elm/GroupDoc/FormView.elm-            config.onSaveExclusiveModeForm
src/elm/GroupDoc/FormView.elm-
src/elm/GroupDoc/FormView.elm-        fireCancel =
src/elm/GroupDoc/FormView.elm-            config.revertExclusiveMode
src/elm/GroupDoc/FormView.elm-
src/elm/GroupDoc/FormView.elm-        fireToggleArchive =
src/elm/GroupDoc/FormView.elm-            config.onToggleGroupDocArchived form.groupDocId
--
--
src/elm/GroupDoc/FormView.elm-        defaultButtons =
src/elm/GroupDoc/FormView.elm:            case form.mode of
src/elm/GroupDoc/FormView.elm-                GDFM_Edit ->
src/elm/GroupDoc/FormView.elm-                    Mat.okCancelArchiveButtons config form.isArchived fireToggleArchive
src/elm/GroupDoc/FormView.elm-
src/elm/GroupDoc/FormView.elm-                GDFM_Add ->
src/elm/GroupDoc/FormView.elm-                    Mat.okCancelButtons config
src/elm/GroupDoc/FormView.elm-    in
src/elm/GroupDoc/FormView.elm-    div
src/elm/GroupDoc/FormView.elm-        [ class "overlay"
src/elm/GroupDoc/FormView.elm-        , onClickStopPropagation fireCancel
src/elm/GroupDoc/FormView.elm-        , onKeyDownStopPropagation (\_ -> config.noop)
src/elm/GroupDoc/FormView.elm-        ]
src/elm/GroupDoc/FormView.elm-        [ div [ class "modal fixed-center", onClickStopPropagation config.noop ]
src/elm/GroupDoc/FormView.elm-            [ div [ class "modal-content" ]
src/elm/GroupDoc/FormView.elm-                [ div
src/elm/GroupDoc/FormView.elm-                    [ class "input-field"
src/elm/GroupDoc/FormView.elm-                    , onKeyDownStopPropagation (\_ -> config.noop)
src/elm/GroupDoc/FormView.elm-                    , onClickStopPropagation config.noop
src/elm/GroupDoc/FormView.elm-                    ]
src/elm/GroupDoc/FormView.elm-                    [ input
src/elm/GroupDoc/FormView.elm-                        [ class "auto-focus"
src/elm/GroupDoc/FormView.elm-                        , autofocus True
src/elm/GroupDoc/FormView.elm-                        , defaultValue form.name
--
--
src/elm/GroupDoc/Types.elm-createGroupDocIdFromType gdType =
src/elm/GroupDoc/Types.elm:    case gdType of
src/elm/GroupDoc/Types.elm-        ContextGroupDocType ->
src/elm/GroupDoc/Types.elm-            ContextGroupDocId
src/elm/GroupDoc/Types.elm-
src/elm/GroupDoc/Types.elm-        ProjectGroupDocType ->
src/elm/GroupDoc/Types.elm-            ProjectGroupDocId
src/elm/GroupDoc/Types.elm-
src/elm/GroupDoc/Types.elm-
src/elm/GroupDoc/Types.elm-type GroupDocAction
src/elm/GroupDoc/Types.elm-    = GDA_StartAdding
src/elm/GroupDoc/Types.elm-
src/elm/GroupDoc/Types.elm-
src/elm/GroupDoc/Types.elm-type GroupDocIdAction
src/elm/GroupDoc/Types.elm-    = GDA_ToggleArchived
src/elm/GroupDoc/Types.elm-    | GDA_ToggleDeleted
src/elm/GroupDoc/Types.elm-    | GDA_UpdateFormName GroupDocForm GroupDocName
src/elm/GroupDoc/Types.elm-    | GDA_SaveForm GroupDocForm
src/elm/GroupDoc/Types.elm-
src/elm/GroupDoc/Types.elm-
src/elm/GroupDoc/Types.elm-type alias GroupDocForm =
src/elm/GroupDoc/Types.elm-    { id : DocId
src/elm/GroupDoc/Types.elm-    , groupDocType : GroupDocType
src/elm/GroupDoc/Types.elm-    , groupDocId : GroupDocId
--
--
src/elm/GroupDoc/ViewModel.elm-        onKeyDownMsg { key } =
src/elm/GroupDoc/ViewModel.elm:            case key of
src/elm/GroupDoc/ViewModel.elm-                Key.CharE ->
src/elm/GroupDoc/ViewModel.elm-                    startEditingMsg
src/elm/GroupDoc/ViewModel.elm-
src/elm/GroupDoc/ViewModel.elm-                Key.Delete ->
src/elm/GroupDoc/ViewModel.elm-                    toggleDeleteMsg
src/elm/GroupDoc/ViewModel.elm-
src/elm/GroupDoc/ViewModel.elm-                Key.CharG ->
src/elm/GroupDoc/ViewModel.elm-                    onEntityAction Entity.Types.EUA_OnGotoEntity
src/elm/GroupDoc/ViewModel.elm-
src/elm/GroupDoc/ViewModel.elm-                _ ->
src/elm/GroupDoc/ViewModel.elm-                    config.noop
src/elm/GroupDoc/ViewModel.elm-
src/elm/GroupDoc/ViewModel.elm-        archive =
src/elm/GroupDoc/ViewModel.elm-            let
src/elm/GroupDoc/ViewModel.elm-                isArchived =
src/elm/GroupDoc/ViewModel.elm-                    GroupDoc.isArchived groupDoc
src/elm/GroupDoc/ViewModel.elm-
src/elm/GroupDoc/ViewModel.elm-                iconName =
src/elm/GroupDoc/ViewModel.elm-                    if isArchived then
src/elm/GroupDoc/ViewModel.elm-                        "unarchive"
src/elm/GroupDoc/ViewModel.elm-                    else
src/elm/GroupDoc/ViewModel.elm-                        "archive"
--
--
src/elm/LaunchBar/Models.elm-getSearchItemName searchItem =
src/elm/LaunchBar/Models.elm:    case searchItem of
src/elm/LaunchBar/Models.elm-        SI_Project project ->
src/elm/LaunchBar/Models.elm-            Project.getName project
src/elm/LaunchBar/Models.elm-
src/elm/LaunchBar/Models.elm-        SI_Context context ->
src/elm/LaunchBar/Models.elm-            Context.getName context
src/elm/LaunchBar/Models.elm-
src/elm/LaunchBar/Models.elm-        SI_Projects ->
src/elm/LaunchBar/Models.elm-            "Projects"
src/elm/LaunchBar/Models.elm-
src/elm/LaunchBar/Models.elm-        SI_Contexts ->
src/elm/LaunchBar/Models.elm-            "Contexts"
--
--
src/elm/LaunchBar/View.elm-        keyHandler { key } =
src/elm/LaunchBar/View.elm:            case key of
src/elm/LaunchBar/View.elm-                Key.Enter ->
src/elm/LaunchBar/View.elm-                    matchingEntity |> OnLBEnter
src/elm/LaunchBar/View.elm-
src/elm/LaunchBar/View.elm-                _ ->
src/elm/LaunchBar/View.elm-                    NOOP
src/elm/LaunchBar/View.elm-    in
src/elm/LaunchBar/View.elm-    div
src/elm/LaunchBar/View.elm-        [ class "overlay"
src/elm/LaunchBar/View.elm-        , onKeyDownStopPropagation keyHandler
src/elm/LaunchBar/View.elm-        , onClickStopPropagation OnCancel
src/elm/LaunchBar/View.elm-        ]
src/elm/LaunchBar/View.elm-        [ div
src/elm/LaunchBar/View.elm-            [ id "launch-bar-container"
src/elm/LaunchBar/View.elm-            , class "layout horizontal"
src/elm/LaunchBar/View.elm-            , attribute "onclick"
src/elm/LaunchBar/View.elm-                "console.log('focusing');document.getElementById('hidden-input').focus(); event.stopPropagation(); event.preventDefault();"
src/elm/LaunchBar/View.elm-            , onInput (OnLBInputChanged model)
src/elm/LaunchBar/View.elm-            ]
src/elm/LaunchBar/View.elm-            [ div [ class "flex-auto ellipsis" ] [ text matchingEntityName ]
src/elm/LaunchBar/View.elm-            , div [ class "no-wrap input typing" ] [ text model.input ]
src/elm/LaunchBar/View.elm-            , input
src/elm/LaunchBar/View.elm-                [ id "hidden-input"
--
--
src/elm/Menu.elm-            in
src/elm/Menu.elm:            case key of
src/elm/Menu.elm-                Key.Enter ->
src/elm/Menu.elm-                    List.getAt focusedIndex items ?|> config.onSelect ?= config.noOp
src/elm/Menu.elm-
src/elm/Menu.elm-                Key.ArrowUp ->
src/elm/Menu.elm-                    onFocusIndexChangeByMsg -1
src/elm/Menu.elm-
src/elm/Menu.elm-                Key.ArrowDown ->
src/elm/Menu.elm-                    onFocusIndexChangeByMsg 1
src/elm/Menu.elm-
src/elm/Menu.elm-                _ ->
--
src/elm/Menu.elm-                _ ->
src/elm/Menu.elm:                    case keyString |> String.toList of
src/elm/Menu.elm-                        singleChar :: [] ->
src/elm/Menu.elm-                            onFocusItemStartingWithMsg singleChar
src/elm/Menu.elm-
src/elm/Menu.elm-                        _ ->
src/elm/Menu.elm-                            config.noOp
src/elm/Menu.elm-
src/elm/Menu.elm-        isFocusedAt =
src/elm/Menu.elm-            equals focusedIndex
src/elm/Menu.elm-
src/elm/Menu.elm-        onKeyDownAt index =
src/elm/Menu.elm-            if isFocusedAt index then
src/elm/Menu.elm-                onFocusedItemKeyDown
src/elm/Menu.elm-            else
src/elm/Menu.elm-                \_ -> config.noOp
src/elm/Menu.elm-    in
src/elm/Menu.elm-    { isFocusedAt = isFocusedAt
src/elm/Menu.elm-    , isSelectedAt = maybeSelectedIndex ?|> equals ?= (\_ -> False)
src/elm/Menu.elm-    , tabIndexValueAt = isFocusedAt >> boolToTabIndexValue
src/elm/Menu.elm-    , onKeyDownAt = onKeyDownAt
src/elm/Menu.elm-    , onSelect = config.onSelect
src/elm/Menu.elm-    , itemView = config.itemView
src/elm/Menu.elm-    , itemKey = config.itemKey
--
--
src/elm/Model.elm-        maybeForm =
src/elm/Model.elm:            case model.editMode of
src/elm/Model.elm-                XMCustomSync form ->
src/elm/Model.elm-                    Just form
src/elm/Model.elm-
src/elm/Model.elm-                _ ->
src/elm/Model.elm-                    Nothing
src/elm/Model.elm-    in
src/elm/Model.elm-    maybeForm ?= createRemoteSyncForm model
src/elm/Model.elm-
src/elm/Model.elm-
src/elm/Model.elm-
src/elm/Model.elm---createRemoteSyncForm : AppModel -> SyncForm
src/elm/Model.elm-
src/elm/Model.elm-
src/elm/Model.elm-createRemoteSyncForm model =
src/elm/Model.elm-    { uri = model.pouchDBRemoteSyncURI }
src/elm/Model.elm-
src/elm/Model.elm-
src/elm/Model.elm-
src/elm/Model.elm---getNow : AppModel -> Time
src/elm/Model.elm-
src/elm/Model.elm-
src/elm/Model.elm-getNow =
--
--
src/elm/Model/EntityList.elm-                focusNext oldIndex newIndex =
src/elm/Model/EntityList.elm:                    case compare oldIndex newIndex of
src/elm/Model/EntityList.elm-                        LT ->
src/elm/Model/EntityList.elm-                            setFocusInIndex oldIndex
src/elm/Model/EntityList.elm-
src/elm/Model/EntityList.elm-                        GT ->
src/elm/Model/EntityList.elm-                            setFocusInIndex (oldIndex + 1)
src/elm/Model/EntityList.elm-
src/elm/Model/EntityList.elm-                        EQ ->
src/elm/Model/EntityList.elm-                            identity
src/elm/Model/EntityList.elm-            in
src/elm/Model/EntityList.elm-            model
--
src/elm/Model/EntityList.elm-            model
src/elm/Model/EntityList.elm:                |> (case indexTuple of
src/elm/Model/EntityList.elm-                        -- note we want focus to remain on group entity, when edited, since its sort order may change. But if removed from view, we want to focus on next entity.
src/elm/Model/EntityList.elm-                        ( Just oldIndex, Just newIndex ) ->
src/elm/Model/EntityList.elm-                            if focusNextOnIndexChange then
src/elm/Model/EntityList.elm-                                focusNext oldIndex newIndex
src/elm/Model/EntityList.elm-                            else
src/elm/Model/EntityList.elm-                                identity
src/elm/Model/EntityList.elm-
src/elm/Model/EntityList.elm-                        ( Just oldIndex, Nothing ) ->
src/elm/Model/EntityList.elm-                            setFocusInIndex oldIndex
src/elm/Model/EntityList.elm-
src/elm/Model/EntityList.elm-                        _ ->
src/elm/Model/EntityList.elm-                            identity
src/elm/Model/EntityList.elm-                   )
src/elm/Model/EntityList.elm-
src/elm/Model/EntityList.elm-        getMaybeFocusInEntityIndex entityList model =
src/elm/Model/EntityList.elm-            entityList
src/elm/Model/EntityList.elm-                |> List.findIndex (Entity.equalById model.focusInEntity)
src/elm/Model/EntityList.elm-    in
src/elm/Model/EntityList.elm-    ( oldModel, newModel )
src/elm/Model/EntityList.elm-        |> Tuple2.mapBoth
src/elm/Model/EntityList.elm-            (createEntityListForCurrentView >> (getMaybeFocusInEntityIndex # oldModel))
src/elm/Model/EntityList.elm-        |> updateEntityListCursorFromEntityIndexTuple newModel
--
--
src/elm/Model/EntityTree.elm-    in
src/elm/Model/EntityTree.elm:    case viewType of
src/elm/Model/EntityTree.elm-        Entity.Types.ContextsView ->
src/elm/Model/EntityTree.elm-            getActiveContexts model
src/elm/Model/EntityTree.elm-                |> Entity.Tree.initContextForest
src/elm/Model/EntityTree.elm-                    getActiveTodoListForContextHelp
src/elm/Model/EntityTree.elm-
src/elm/Model/EntityTree.elm-        Entity.Types.ProjectsView ->
src/elm/Model/EntityTree.elm-            getActiveProjects model
src/elm/Model/EntityTree.elm-                |> Entity.Tree.initProjectForest
src/elm/Model/EntityTree.elm-                    getActiveTodoListForProjectHelp
src/elm/Model/EntityTree.elm-
src/elm/Model/EntityTree.elm-        Entity.Types.ContextView id ->
src/elm/Model/EntityTree.elm-            findContextById id model
src/elm/Model/EntityTree.elm-                ?= Context.null
src/elm/Model/EntityTree.elm-                |> Entity.Tree.initContextRoot
src/elm/Model/EntityTree.elm-                    getActiveTodoListForContextHelp
src/elm/Model/EntityTree.elm-                    findProjectByIdHelp
src/elm/Model/EntityTree.elm-
src/elm/Model/EntityTree.elm-        Entity.Types.ProjectView id ->
src/elm/Model/EntityTree.elm-            findProjectById id model
src/elm/Model/EntityTree.elm-                ?= Project.null
src/elm/Model/EntityTree.elm-                |> Entity.Tree.initProjectRoot
src/elm/Model/EntityTree.elm-                    getActiveTodoListForProjectHelp
--
--
src/elm/Model/GroupDocStore.elm-storeFieldFromGDType gdType =
src/elm/Model/GroupDocStore.elm:    case gdType of
src/elm/Model/GroupDocStore.elm-        ProjectGroupDocType ->
src/elm/Model/GroupDocStore.elm-            fieldLens .projectStore (\s b -> { b | projectStore = s })
src/elm/Model/GroupDocStore.elm-
src/elm/Model/GroupDocStore.elm-        ContextGroupDocType ->
src/elm/Model/GroupDocStore.elm-            fieldLens .contextStore (\s b -> { b | contextStore = s })
--
--
src/elm/Model/Stores.elm-findByEntityId entityId =
src/elm/Model/Stores.elm:    case entityId of
src/elm/Model/Stores.elm-        ContextId id ->
src/elm/Model/Stores.elm-            findContextById id >>? createContextEntity
src/elm/Model/Stores.elm-
src/elm/Model/Stores.elm-        ProjectId id ->
src/elm/Model/Stores.elm-            findProjectById id >>? createProjectEntity
src/elm/Model/Stores.elm-
src/elm/Model/Stores.elm-        TodoId id ->
src/elm/Model/Stores.elm-            findTodoById id >>? createTodoEntity
src/elm/Model/Stores.elm-
src/elm/Model/Stores.elm-
src/elm/Model/Stores.elm-setFocusInEntityWithEntityId entityId =
src/elm/Model/Stores.elm-    applyMaybeWith (findByEntityId entityId) Model.setFocusInEntity
--
--
src/elm/Model/ViewType.elm-maybeGetEntityListViewType model =
src/elm/Model/ViewType.elm:    case model.viewType of
src/elm/Model/ViewType.elm-        EntityListView viewType ->
src/elm/Model/ViewType.elm-            Just viewType
src/elm/Model/ViewType.elm-
src/elm/Model/ViewType.elm-        _ ->
src/elm/Model/ViewType.elm-            Nothing
src/elm/Model/ViewType.elm-
src/elm/Model/ViewType.elm-
src/elm/Model/ViewType.elm-getMainViewType =
src/elm/Model/ViewType.elm-    .viewType
src/elm/Model/ViewType.elm-
src/elm/Model/ViewType.elm-
src/elm/Model/ViewType.elm-defaultView =
src/elm/Model/ViewType.elm-    EntityListView ContextsView
--
--
src/elm/Routes.elm-getPathFromModel model =
src/elm/Routes.elm:    case Model.ViewType.getMainViewType model of
src/elm/Routes.elm-        EntityListView viewType ->
src/elm/Routes.elm-            getPathFromViewType viewType
src/elm/Routes.elm-
src/elm/Routes.elm-        SyncView ->
src/elm/Routes.elm-            [ "custom-sync" ]
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm---delta2hash : AppModel -> AppModel -> Maybe UrlChange
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm-delta2hash =
src/elm/Routes.elm-    delta2builder >>> Maybe.map RouteUrl.Builder.toHashChange
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm---builder2messages : Builder -> List AppMsg
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm-builder2messages config builder =
src/elm/Routes.elm-    routeUrlBuilderToMaybeListViewType builder
src/elm/Routes.elm-        |> Maybe.Extra.unpack
--
--
src/elm/Routes.elm-            (\_ ->
src/elm/Routes.elm:                case RouteUrl.Builder.path builder of
src/elm/Routes.elm-                    "custom-sync" :: [] ->
src/elm/Routes.elm-                        [ config.switchToView SyncView ]
src/elm/Routes.elm-
src/elm/Routes.elm-                    _ ->
src/elm/Routes.elm-                        -- If nothing provided for this part of the URL, return empty list
src/elm/Routes.elm-                        [ config.switchToView Model.ViewType.defaultView ]
src/elm/Routes.elm-            )
src/elm/Routes.elm-            (config.switchToEntityListView >> X.List.singleton)
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm---hash2messages : Location -> List AppMsg
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm-hash2messages config location =
src/elm/Routes.elm-    builder2messages config (RouteUrl.Builder.fromHash location.href)
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm-
src/elm/Routes.elm---routeUrlBuilderToMaybeListViewType : RouteUrl.Builder.Builder -> Maybe EntityListViewType
src/elm/Routes.elm-
src/elm/Routes.elm-
--
--
src/elm/Routes.elm-routeUrlBuilderToMaybeListViewType builder =
src/elm/Routes.elm:    case RouteUrl.Builder.path builder of
src/elm/Routes.elm-        "lists" :: "contexts" :: [] ->
src/elm/Routes.elm-            ContextsView |> Just
src/elm/Routes.elm-
src/elm/Routes.elm-        "lists" :: "projects" :: [] ->
src/elm/Routes.elm-            ProjectsView |> Just
src/elm/Routes.elm-
src/elm/Routes.elm-        "bin" :: [] ->
src/elm/Routes.elm-            BinView |> Just
src/elm/Routes.elm-
src/elm/Routes.elm-        "done" :: [] ->
src/elm/Routes.elm-            DoneView |> Just
src/elm/Routes.elm-
src/elm/Routes.elm-        "recent" :: [] ->
src/elm/Routes.elm-            RecentView |> Just
src/elm/Routes.elm-
src/elm/Routes.elm-        "Inbox" :: [] ->
src/elm/Routes.elm-            ContextView "" |> Just
src/elm/Routes.elm-
src/elm/Routes.elm-        "context" :: id :: [] ->
src/elm/Routes.elm-            ContextView id |> Just
src/elm/Routes.elm-
src/elm/Routes.elm-        "project" :: "NotAssigned" :: [] ->
--
--
src/elm/Routes.elm-getPathFromViewType viewType =
src/elm/Routes.elm:    case viewType of
src/elm/Routes.elm-        ContextsView ->
src/elm/Routes.elm-            [ "lists", "contexts" ]
src/elm/Routes.elm-
src/elm/Routes.elm-        ProjectsView ->
src/elm/Routes.elm-            [ "lists", "projects" ]
src/elm/Routes.elm-
src/elm/Routes.elm-        ProjectView id ->
src/elm/Routes.elm-            if String.isEmpty id then
src/elm/Routes.elm-                [ "project", "NotAssigned" ]
src/elm/Routes.elm-            else
src/elm/Routes.elm-                [ "project", id ]
src/elm/Routes.elm-
src/elm/Routes.elm-        ContextView id ->
src/elm/Routes.elm-            if String.isEmpty id then
src/elm/Routes.elm-                [ "Inbox" ]
src/elm/Routes.elm-            else
src/elm/Routes.elm-                [ "context", id ]
src/elm/Routes.elm-
src/elm/Routes.elm-        BinView ->
src/elm/Routes.elm-            [ "bin" ]
src/elm/Routes.elm-
src/elm/Routes.elm-        DoneView ->
--
--
src/elm/Store.elm-            (\result ->
src/elm/Store.elm:                case result of
src/elm/Store.elm-                    Ok project ->
src/elm/Store.elm-                        Just project
src/elm/Store.elm-
src/elm/Store.elm-                    Err x ->
src/elm/Store.elm-                        let
src/elm/Store.elm-                            _ =
src/elm/Store.elm-                                X.Debug.log "Error while decoding Project" x
src/elm/Store.elm-                        in
src/elm/Store.elm-                        Nothing
src/elm/Store.elm-            )
src/elm/Store.elm-
src/elm/Store.elm-
src/elm/Store.elm-type alias Store x =
src/elm/Store.elm-    Store.Types.Store x
src/elm/Store.elm-
src/elm/Store.elm-
src/elm/Store.elm-dict =
src/elm/Store.elm-    Record.fieldLens .dict (\s b -> { b | dict = s })
src/elm/Store.elm-
src/elm/Store.elm-
src/elm/Store.elm-type alias OtherFieldsEncoder x =
src/elm/Store.elm-    Document x -> List ( String, E.Value )
--
--
src/elm/Todo.elm-update action =
src/elm/Todo.elm:    case action of
src/elm/Todo.elm-        TA_SetText val ->
src/elm/Todo.elm-            set text val
src/elm/Todo.elm-
src/elm/Todo.elm-        TA_SetContextId val ->
src/elm/Todo.elm-            set contextId val
src/elm/Todo.elm-
src/elm/Todo.elm-        TA_SetProjectId val ->
src/elm/Todo.elm-            set projectId val
src/elm/Todo.elm-
src/elm/Todo.elm-        TA_SetSchedule val ->
src/elm/Todo.elm-            set schedule val
src/elm/Todo.elm-
src/elm/Todo.elm-        TA_CopyProjectAndContextId fromTodo ->
src/elm/Todo.elm-            update (TA_SetContextId fromTodo.contextId)
src/elm/Todo.elm-                >> update (TA_SetProjectId fromTodo.projectId)
src/elm/Todo.elm-
src/elm/Todo.elm-        TA_SetProject project ->
src/elm/Todo.elm-            Document.getId project |> set projectId
src/elm/Todo.elm-
src/elm/Todo.elm-        TA_SetContext context ->
src/elm/Todo.elm-            Document.getId context |> set contextId
src/elm/Todo.elm-
--
--
src/elm/Todo/Form.elm-updateTodoForm action =
src/elm/Todo/Form.elm:    case action of
src/elm/Todo/Form.elm-        SetTodoText value ->
src/elm/Todo/Form.elm-            set text value
src/elm/Todo/Form.elm-
src/elm/Todo/Form.elm-        SetTodoMenuState value ->
src/elm/Todo/Form.elm-            set menuState value
src/elm/Todo/Form.elm-
src/elm/Todo/Form.elm-        SetTodoReminderDate value ->
src/elm/Todo/Form.elm-            set date value
src/elm/Todo/Form.elm-                >> updateMaybeTime
src/elm/Todo/Form.elm-
src/elm/Todo/Form.elm-        SetTodoReminderTime value ->
src/elm/Todo/Form.elm-            set time value
src/elm/Todo/Form.elm-                >> updateMaybeTime
src/elm/Todo/Form.elm-
src/elm/Todo/Form.elm-
src/elm/Todo/Form.elm-updateMaybeTime : TodoForm -> TodoForm
src/elm/Todo/Form.elm-updateMaybeTime =
src/elm/Todo/Form.elm-    overM maybeComputedTime computeMaybeTime
src/elm/Todo/Form.elm-
src/elm/Todo/Form.elm-
src/elm/Todo/Form.elm-computeMaybeTime : TodoForm -> Maybe Time
src/elm/Todo/Form.elm-computeMaybeTime { date, time } =
--
--
src/elm/Todo/Notification/Model.elm-addSnoozeOffset time offset =
src/elm/Todo/Notification/Model.elm:    case offset of
src/elm/Todo/Notification/Model.elm-        SnoozeForMilli milli ->
src/elm/Todo/Notification/Model.elm-            time + milli
src/elm/Todo/Notification/Model.elm-
src/elm/Todo/Notification/Model.elm-        SnoozeTillTomorrow ->
src/elm/Todo/Notification/Model.elm-            Date.fromTime time |> Date.ceiling Date.Day |> Date.add Date.Hour 10 |> Date.toTime
src/elm/Todo/Notification/Model.elm-
src/elm/Todo/Notification/Model.elm-
src/elm/Todo/Notification/Model.elm-initialView : TodoDoc -> TodoReminderOverlayModel
src/elm/Todo/Notification/Model.elm-initialView =
src/elm/Todo/Notification/Model.elm-    createTodoDetails >> tuple2 InitialView >> Just
src/elm/Todo/Notification/Model.elm-
src/elm/Todo/Notification/Model.elm-
src/elm/Todo/Notification/Model.elm-createTodoDetails todo =
src/elm/Todo/Notification/Model.elm-    TodoDetails (Document.getId todo) (Todo.getText todo)
src/elm/Todo/Notification/Model.elm-
src/elm/Todo/Notification/Model.elm-
src/elm/Todo/Notification/Model.elm-none =
src/elm/Todo/Notification/Model.elm-    Nothing
src/elm/Todo/Notification/Model.elm-
src/elm/Todo/Notification/Model.elm-
src/elm/Todo/Notification/Model.elm-snoozeView : TodoDetails -> TodoReminderOverlayModel
src/elm/Todo/Notification/Model.elm-snoozeView =
--
--
src/elm/Todo/Notification/View.elm-    in
src/elm/Todo/Notification/View.elm:    case activeView of
src/elm/Todo/Notification/View.elm-        Todo.Notification.Types.InitialView ->
src/elm/Todo/Notification/View.elm-            let
src/elm/Todo/Notification/View.elm-                vm =
src/elm/Todo/Notification/View.elm-                    { onDismissClicked = config.onReminderOverlayAction Todo.Notification.Model.Dismiss
src/elm/Todo/Notification/View.elm-                    , onDoneClicked = config.onReminderOverlayAction Todo.Notification.Model.MarkDone
src/elm/Todo/Notification/View.elm-                    , onSnoozeClicked = config.onReminderOverlayAction Todo.Notification.Model.ShowSnoozeOptions
src/elm/Todo/Notification/View.elm-                    }
src/elm/Todo/Notification/View.elm-            in
src/elm/Todo/Notification/View.elm-            activeViewShell
src/elm/Todo/Notification/View.elm-                [ Mat.bigIconTextBtn "not_interested" "dismiss" vm.onDismissClicked
src/elm/Todo/Notification/View.elm-                , Mat.bigIconTextBtn "snooze" "snooze" vm.onSnoozeClicked
src/elm/Todo/Notification/View.elm-                , Mat.bigIconTextBtn "done" "done!" vm.onDoneClicked
src/elm/Todo/Notification/View.elm-                ]
src/elm/Todo/Notification/View.elm-
src/elm/Todo/Notification/View.elm-        Todo.Notification.Types.SnoozeView ->
src/elm/Todo/Notification/View.elm-            let
src/elm/Todo/Notification/View.elm-                msg =
src/elm/Todo/Notification/View.elm-                    Todo.Notification.Model.SnoozeTill >> config.onReminderOverlayAction
src/elm/Todo/Notification/View.elm-
src/elm/Todo/Notification/View.elm-                vm =
src/elm/Todo/Notification/View.elm-                    { snoozeFor15Min = msg (Todo.Notification.Model.SnoozeForMilli (Time.minute * 15))
src/elm/Todo/Notification/View.elm-                    , snoozeFor1Hour = msg (Todo.Notification.Model.SnoozeForMilli Time.hour)
--
--
src/elm/Todo/Schedule.elm-        fields =
src/elm/Todo/Schedule.elm:            case model of
src/elm/Todo/Schedule.elm-                NoReminder dueAt ->
src/elm/Todo/Schedule.elm-                    [ encodeDueAt dueAt ]
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-                WithReminder dueAt reminderAt ->
src/elm/Todo/Schedule.elm-                    [ encodeDueAt dueAt
src/elm/Todo/Schedule.elm-                    , "reminderAt" => E.float reminderAt
src/elm/Todo/Schedule.elm-                    ]
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-                Unscheduled ->
src/elm/Todo/Schedule.elm-                    []
src/elm/Todo/Schedule.elm-    in
src/elm/Todo/Schedule.elm-    E.object fields
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-decodeV2 : Decoder Model
src/elm/Todo/Schedule.elm-decodeV2 =
src/elm/Todo/Schedule.elm-    let
src/elm/Todo/Schedule.elm-        decodeWithDueAt dueAt =
src/elm/Todo/Schedule.elm-            D.oneOf
src/elm/Todo/Schedule.elm-                [ D.at [ "schedule", "reminderAt" ] D.float
src/elm/Todo/Schedule.elm-                    |> D.andThen
src/elm/Todo/Schedule.elm-                        (\reminderAt ->
--
--
src/elm/Todo/Schedule.elm-getMaybeDueAt model =
src/elm/Todo/Schedule.elm:    case model of
src/elm/Todo/Schedule.elm-        NoReminder dueAt ->
src/elm/Todo/Schedule.elm-            Just dueAt
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-        WithReminder dueAt _ ->
src/elm/Todo/Schedule.elm-            Just dueAt
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-        Unscheduled ->
src/elm/Todo/Schedule.elm-            Nothing
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-getMaybeReminderTime model =
--
src/elm/Todo/Schedule.elm-getMaybeReminderTime model =
src/elm/Todo/Schedule.elm:    case model of
src/elm/Todo/Schedule.elm-        NoReminder dueAt ->
src/elm/Todo/Schedule.elm-            Nothing
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-        WithReminder _ reminderTime ->
src/elm/Todo/Schedule.elm-            Just reminderTime
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-        Unscheduled ->
src/elm/Todo/Schedule.elm-            Nothing
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-fromMaybeTime maybeTime =
src/elm/Todo/Schedule.elm-    maybeTime
src/elm/Todo/Schedule.elm-        ?|> initWithReminder
src/elm/Todo/Schedule.elm-        ?= unscheduled
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-turnReminderOff model =
--
src/elm/Todo/Schedule.elm-turnReminderOff model =
src/elm/Todo/Schedule.elm:    case model of
src/elm/Todo/Schedule.elm-        WithReminder dueAt _ ->
src/elm/Todo/Schedule.elm-            NoReminder dueAt
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-        NoReminder dueAt ->
src/elm/Todo/Schedule.elm-            model
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-        Unscheduled ->
src/elm/Todo/Schedule.elm-            model
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-autoSnooze now =
src/elm/Todo/Schedule.elm-    snoozeTill (now + (Time.minute * 15))
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-snoozeTill snoozedTillTime model =
--
src/elm/Todo/Schedule.elm-snoozeTill snoozedTillTime model =
src/elm/Todo/Schedule.elm:    case model of
src/elm/Todo/Schedule.elm-        NoReminder dueAt ->
src/elm/Todo/Schedule.elm-            WithReminder dueAt snoozedTillTime
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-        WithReminder dueAt _ ->
src/elm/Todo/Schedule.elm-            WithReminder dueAt snoozedTillTime
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-        Unscheduled ->
src/elm/Todo/Schedule.elm-            model
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-
src/elm/Todo/Schedule.elm-hasReminderChanged old new =
src/elm/Todo/Schedule.elm-    getMaybeReminderTime old /= getMaybeReminderTime new
--
--
src/elm/Todo/TimeTracker.elm-toggleStartStop todoId now model =
src/elm/Todo/TimeTracker.elm:    case model of
src/elm/Todo/TimeTracker.elm-        Nothing ->
src/elm/Todo/TimeTracker.elm-            initRunning todoId now
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-        Just _ ->
src/elm/Todo/TimeTracker.elm-            none
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-alarmDelay =
src/elm/Todo/TimeTracker.elm-    10 * Time.minute
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-initRunning : DocId -> Time -> Model
src/elm/Todo/TimeTracker.elm-initRunning todoId now =
src/elm/Todo/TimeTracker.elm-    wrap
src/elm/Todo/TimeTracker.elm-        { todoId = todoId
src/elm/Todo/TimeTracker.elm-        , state = Running now
src/elm/Todo/TimeTracker.elm-        , nextAlarmAt = now + alarmDelay
src/elm/Todo/TimeTracker.elm-        }
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-switchOrStartRunning : DocId -> Time -> Model -> Model
src/elm/Todo/TimeTracker.elm-switchOrStartRunning todoId now =
--
--
src/elm/Todo/TimeTracker.elm-updateNextAlarmAt now model =
src/elm/Todo/TimeTracker.elm:    case model of
src/elm/Todo/TimeTracker.elm-        Nothing ->
src/elm/Todo/TimeTracker.elm-            ( Nothing, model )
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-        Just rec ->
src/elm/Todo/TimeTracker.elm-            (if now >= rec.nextAlarmAt then
src/elm/Todo/TimeTracker.elm-                let
src/elm/Todo/TimeTracker.elm-                    newRec =
src/elm/Todo/TimeTracker.elm-                        { rec | nextAlarmAt = now + alarmDelay }
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-                    info =
src/elm/Todo/TimeTracker.elm-                        { todoId = rec.todoId
src/elm/Todo/TimeTracker.elm-                        , elapsedTime = getElapsedTime now newRec
src/elm/Todo/TimeTracker.elm-                        }
src/elm/Todo/TimeTracker.elm-                in
src/elm/Todo/TimeTracker.elm-                ( Just info, newRec )
src/elm/Todo/TimeTracker.elm-             else
src/elm/Todo/TimeTracker.elm-                ( Nothing, rec )
src/elm/Todo/TimeTracker.elm-            )
src/elm/Todo/TimeTracker.elm-                |> Tuple.mapSecond wrap
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-getElapsedTime now rec =
--
--
src/elm/Todo/TimeTracker.elm-getElapsedTime now rec =
src/elm/Todo/TimeTracker.elm:    case rec.state of
src/elm/Todo/TimeTracker.elm-        Running startedAt ->
src/elm/Todo/TimeTracker.elm-            now - startedAt
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-
src/elm/Todo/TimeTracker.elm-isTrackingTodo todo =
src/elm/Todo/TimeTracker.elm-    Maybe.unwrap False (\rec -> Document.hasId rec.todoId todo)
--
--
src/elm/Todo/ViewModel.elm-            if X.Keyboard.isNoSoftKeyDown ke then
src/elm/Todo/ViewModel.elm:                case key of
src/elm/Todo/ViewModel.elm-                    Key.Space ->
src/elm/Todo/ViewModel.elm-                        config.onToggleEntitySelection entityId
src/elm/Todo/ViewModel.elm-
src/elm/Todo/ViewModel.elm-                    Key.CharE ->
src/elm/Todo/ViewModel.elm-                        startEditingMsg
src/elm/Todo/ViewModel.elm-
src/elm/Todo/ViewModel.elm-                    Key.CharD ->
src/elm/Todo/ViewModel.elm-                        toggleDoneMsg
src/elm/Todo/ViewModel.elm-
src/elm/Todo/ViewModel.elm-                    Key.Delete ->
src/elm/Todo/ViewModel.elm-                        toggleDeleteMsg
src/elm/Todo/ViewModel.elm-
src/elm/Todo/ViewModel.elm-                    Key.CharP ->
src/elm/Todo/ViewModel.elm-                        config.onStartEditingTodoProject todo
src/elm/Todo/ViewModel.elm-
src/elm/Todo/ViewModel.elm-                    Key.CharC ->
src/elm/Todo/ViewModel.elm-                        config.onStartEditingTodoContext todo
src/elm/Todo/ViewModel.elm-
src/elm/Todo/ViewModel.elm-                    Key.CharR ->
src/elm/Todo/ViewModel.elm-                        reminder.startEditingMsg
src/elm/Todo/ViewModel.elm-
src/elm/Todo/ViewModel.elm-                    Key.CharG ->
--
--
src/elm/Update.elm-update andThenUpdate msg =
src/elm/Update.elm:    case msg of
src/elm/Update.elm-        OnMdl msg_ ->
src/elm/Update.elm-            andThen (Material.update OnMdl msg_)
src/elm/Update.elm-
src/elm/Update.elm-        OnViewTypeMsg msg_ ->
src/elm/Update.elm-            let
src/elm/Update.elm-                config : Update.ViewType.Config AppMsg AppModel
src/elm/Update.elm-                config =
src/elm/Update.elm-                    { clearSelection = map Model.Selection.clearSelection }
src/elm/Update.elm-            in
src/elm/Update.elm-            Update.ViewType.update config msg_
src/elm/Update.elm-
src/elm/Update.elm-        OnPersistLocalPref ->
src/elm/Update.elm-            Return.effect_ (LocalPref.encodeLocalPref >> Ports.persistLocalPref)
src/elm/Update.elm-
src/elm/Update.elm-        OnCloseNotification tag ->
src/elm/Update.elm-            command (Notification.closeNotification tag)
src/elm/Update.elm-
src/elm/Update.elm-        OnCommonMsg msg_ ->
src/elm/Update.elm-            CommonMsg.update msg_
src/elm/Update.elm-
src/elm/Update.elm-        OnSubscriptionMsg msg_ ->
src/elm/Update.elm-            let
--
--
src/elm/Update/AppDrawer.elm-update msg =
src/elm/Update/AppDrawer.elm:    case msg of
src/elm/Update/AppDrawer.elm-        OnToggleContextsExpanded ->
src/elm/Update/AppDrawer.elm-            mapOver (toggleGroupListExpanded contexts)
src/elm/Update/AppDrawer.elm-
src/elm/Update/AppDrawer.elm-        OnToggleProjectsExpanded ->
src/elm/Update/AppDrawer.elm-            mapOver (toggleGroupListExpanded projects)
src/elm/Update/AppDrawer.elm-
src/elm/Update/AppDrawer.elm-        OnToggleArchivedContexts ->
src/elm/Update/AppDrawer.elm-            mapOver (toggleGroupArchivedListExpanded contexts)
src/elm/Update/AppDrawer.elm-
src/elm/Update/AppDrawer.elm-        OnToggleArchivedProjects ->
src/elm/Update/AppDrawer.elm-            mapOver (toggleGroupArchivedListExpanded projects)
src/elm/Update/AppDrawer.elm-
src/elm/Update/AppDrawer.elm-        OnToggleOverlay ->
src/elm/Update/AppDrawer.elm-            mapOver toggleOverlay
src/elm/Update/AppDrawer.elm-
src/elm/Update/AppDrawer.elm-        OnWindowResizeTurnOverlayOff ->
src/elm/Update/AppDrawer.elm-            mapOver (set isOverlayOpen False)
--
--
src/elm/Update/AppHeader.elm-update config msg =
src/elm/Update/AppHeader.elm:    case msg of
src/elm/Update/AppHeader.elm-        OnShowMainMenu ->
src/elm/Update/AppHeader.elm-            config.setXMode (XMMainMenu Menu.initState)
src/elm/Update/AppHeader.elm-                >> command positionMainMenuCmd
src/elm/Update/AppHeader.elm-
src/elm/Update/AppHeader.elm-        OnMainMenuStateChanged menuState ->
src/elm/Update/AppHeader.elm-            menuState
src/elm/Update/AppHeader.elm-                |> XMMainMenu
src/elm/Update/AppHeader.elm-                >> config.setXMode
src/elm/Update/AppHeader.elm-
src/elm/Update/AppHeader.elm-
src/elm/Update/AppHeader.elm-positionMainMenuCmd =
src/elm/Update/AppHeader.elm-    DomPorts.positionPopupMenu "#main-menu-button"
--
--
src/elm/Update/CustomSync.elm-update config msg =
src/elm/Update/CustomSync.elm:    case msg of
src/elm/Update/CustomSync.elm-        OnStartCustomSync form ->
src/elm/Update/CustomSync.elm-            config.saveXModeForm
src/elm/Update/CustomSync.elm-                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)
src/elm/Update/CustomSync.elm-
src/elm/Update/CustomSync.elm-        OnUpdateCustomSyncFormUri form uri ->
src/elm/Update/CustomSync.elm-            { form | uri = uri }
src/elm/Update/CustomSync.elm-                |> XMCustomSync
src/elm/Update/CustomSync.elm-                >> config.setXMode
--
--
src/elm/Update/Entity.elm-update config msg =
src/elm/Update/Entity.elm:    case msg of
src/elm/Update/Entity.elm-        EM_Update entityId action ->
src/elm/Update/Entity.elm-            onUpdate config entityId action
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        EM_EntityListKeyDown entityList { key } ->
--
src/elm/Update/Entity.elm-        EM_EntityListKeyDown entityList { key } ->
src/elm/Update/Entity.elm:            case key of
src/elm/Update/Entity.elm-                Key.ArrowUp ->
src/elm/Update/Entity.elm-                    map (moveFocusBy -1 entityList)
src/elm/Update/Entity.elm-                        >> config.setDomFocusToFocusInEntityCmd
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-                Key.ArrowDown ->
src/elm/Update/Entity.elm-                    map (moveFocusBy 1 entityList)
src/elm/Update/Entity.elm-                        >> config.setDomFocusToFocusInEntityCmd
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-                _ ->
src/elm/Update/Entity.elm-                    identity
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-moveFocusBy : Int -> List Entity -> SubModelF model
src/elm/Update/Entity.elm-moveFocusBy =
src/elm/Update/Entity.elm-    Entity.findEntityByOffsetIn >>> maybeOver Model.focusInEntity
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-onUpdate :
src/elm/Update/Entity.elm-    Config msg model
src/elm/Update/Entity.elm-    -> EntityId
src/elm/Update/Entity.elm-    -> Entity.Types.EntityUpdateAction
src/elm/Update/Entity.elm-    -> SubReturnF msg model
--
--
src/elm/Update/Entity.elm-onUpdate config entityId action =
src/elm/Update/Entity.elm:    case action of
src/elm/Update/Entity.elm-        EUA_StartEditing ->
src/elm/Update/Entity.elm-            startEditingEntity config entityId
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        EUA_OnFocusIn ->
src/elm/Update/Entity.elm-            map (Model.Stores.setFocusInEntityWithEntityId entityId)
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        EUA_ToggleSelection ->
src/elm/Update/Entity.elm-            map (toggleEntitySelection entityId)
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        EUA_OnGotoEntity ->
src/elm/Update/Entity.elm-            let
src/elm/Update/Entity.elm-                switchToEntityListViewFromEntity entityId model =
src/elm/Update/Entity.elm-                    let
src/elm/Update/Entity.elm-                        maybeEntityListViewType =
src/elm/Update/Entity.elm-                            Model.ViewType.maybeGetEntityListViewType model
src/elm/Update/Entity.elm-                    in
src/elm/Update/Entity.elm-                    entityId
src/elm/Update/Entity.elm-                        |> toViewType model maybeEntityListViewType
src/elm/Update/Entity.elm-                        |> config.switchToEntityListView
src/elm/Update/Entity.elm-            in
src/elm/Update/Entity.elm-            returnWith identity (switchToEntityListViewFromEntity entityId)
src/elm/Update/Entity.elm-
--
--
src/elm/Update/Entity.elm-startEditingEntity config entityId =
src/elm/Update/Entity.elm:    case entityId of
src/elm/Update/Entity.elm-        ContextId id ->
src/elm/Update/Entity.elm-            X.Return.returnWithMaybe1
src/elm/Update/Entity.elm-                (Model.GroupDocStore.findContextById id)
src/elm/Update/Entity.elm-                (createEditContextForm >> XMGroupDocForm >> config.onSetExclusiveMode)
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        ProjectId id ->
src/elm/Update/Entity.elm-            X.Return.returnWithMaybe1
src/elm/Update/Entity.elm-                (Model.GroupDocStore.findProjectById id)
src/elm/Update/Entity.elm-                (createEditProjectForm >> XMGroupDocForm >> config.onSetExclusiveMode)
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        TodoId id ->
src/elm/Update/Entity.elm-            X.Return.returnWithMaybe1 (Model.Todo.findTodoById id)
src/elm/Update/Entity.elm-                config.onStartEditingTodo
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-toViewType : SubModel model -> Maybe EntityListViewType -> EntityId -> EntityListViewType
src/elm/Update/Entity.elm-toViewType appModel maybeCurrentEntityListViewType entityId =
--
src/elm/Update/Entity.elm-toViewType appModel maybeCurrentEntityListViewType entityId =
src/elm/Update/Entity.elm:    case entityId of
src/elm/Update/Entity.elm-        ContextId id ->
src/elm/Update/Entity.elm-            ContextView id
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        ProjectId id ->
src/elm/Update/Entity.elm-            ProjectView id
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        TodoId id ->
src/elm/Update/Entity.elm-            let
src/elm/Update/Entity.elm-                getViewTypeForTodo todo =
src/elm/Update/Entity.elm-                    maybeCurrentEntityListViewType
src/elm/Update/Entity.elm-                        ?|> getTodoGotoGroupView todo
src/elm/Update/Entity.elm-                        ?= (Todo.getContextId todo |> ContextView)
src/elm/Update/Entity.elm-            in
src/elm/Update/Entity.elm-            Model.Todo.findTodoById id appModel
src/elm/Update/Entity.elm-                ?|> getViewTypeForTodo
src/elm/Update/Entity.elm-                |> Maybe.Extra.orElse maybeCurrentEntityListViewType
src/elm/Update/Entity.elm-                ?= ContextsView
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-getTodoGotoGroupView todo prevView =
src/elm/Update/Entity.elm-    let
src/elm/Update/Entity.elm-        contextView =
--
--
src/elm/Update/Entity.elm-    in
src/elm/Update/Entity.elm:    case prevView of
src/elm/Update/Entity.elm-        ProjectsView ->
src/elm/Update/Entity.elm-            contextView
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        ProjectView _ ->
src/elm/Update/Entity.elm-            contextView
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        ContextsView ->
src/elm/Update/Entity.elm-            projectView
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        ContextView _ ->
src/elm/Update/Entity.elm-            projectView
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        BinView ->
src/elm/Update/Entity.elm-            ContextsView
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        DoneView ->
src/elm/Update/Entity.elm-            ContextsView
src/elm/Update/Entity.elm-
src/elm/Update/Entity.elm-        RecentView ->
src/elm/Update/Entity.elm-            ContextsView
--
--
src/elm/Update/ExclusiveMode.elm-update config msg =
src/elm/Update/ExclusiveMode.elm:    case msg of
src/elm/Update/ExclusiveMode.elm-        OnSetExclusiveMode mode ->
src/elm/Update/ExclusiveMode.elm-            setExclusiveMode mode |> map
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-        OnSetExclusiveModeToNoneAndTryRevertingFocus ->
src/elm/Update/ExclusiveMode.elm-            map setExclusiveModeToNone
src/elm/Update/ExclusiveMode.elm-                >> config.focusEntityList
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-        OnSaveExclusiveModeForm ->
src/elm/Update/ExclusiveMode.elm-            onSaveExclusiveModeForm config
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-exclusiveMode =
src/elm/Update/ExclusiveMode.elm-    fieldLens .editMode (\s b -> { b | editMode = s })
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-onSaveExclusiveModeForm : Config msg model -> SubReturnF msg model
src/elm/Update/ExclusiveMode.elm-onSaveExclusiveModeForm config =
src/elm/Update/ExclusiveMode.elm-    returnWith .editMode (saveExclusiveModeForm config)
src/elm/Update/ExclusiveMode.elm-        >> update config OnSetExclusiveModeToNoneAndTryRevertingFocus
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-setExclusiveMode =
--
--
src/elm/Update/ExclusiveMode.elm-saveExclusiveModeForm config exMode =
src/elm/Update/ExclusiveMode.elm:    case exMode of
src/elm/Update/ExclusiveMode.elm-        XMGroupDocForm form ->
src/elm/Update/ExclusiveMode.elm-            config.saveGroupDocForm form
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-        XMTodoForm form ->
src/elm/Update/ExclusiveMode.elm-            config.saveTodoForm form
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-        XMCustomSync form ->
src/elm/Update/ExclusiveMode.elm-            (\model -> { model | pouchDBRemoteSyncURI = form.uri })
src/elm/Update/ExclusiveMode.elm-                |> map
src/elm/Update/ExclusiveMode.elm-
src/elm/Update/ExclusiveMode.elm-        _ ->
src/elm/Update/ExclusiveMode.elm-            identity
--
--
src/elm/Update/Firebase.elm-update config msg =
src/elm/Update/Firebase.elm:    case msg of
src/elm/Update/Firebase.elm-        OnFB_NOOP ->
src/elm/Update/Firebase.elm-            identity
src/elm/Update/Firebase.elm-
src/elm/Update/Firebase.elm-        OnFB_SwitchToNewUserSetupModeIfNeeded ->
src/elm/Update/Firebase.elm-            let
src/elm/Update/Firebase.elm-                onSwitchToNewUserSetupModeIfNeeded model =
src/elm/Update/Firebase.elm-                    if Firebase.SignIn.shouldSkipSignIn model.signInModel then
src/elm/Update/Firebase.elm-                        if Store.isEmpty model.todoStore then
src/elm/Update/Firebase.elm-                            config.onStartSetupAddTodo
src/elm/Update/Firebase.elm-                        else
src/elm/Update/Firebase.elm-                            config.revertExclusiveMode
src/elm/Update/Firebase.elm-                    else
src/elm/Update/Firebase.elm-                        config.onSetExclusiveMode XMSignInOverlay
src/elm/Update/Firebase.elm-            in
src/elm/Update/Firebase.elm-            returnWith identity onSwitchToNewUserSetupModeIfNeeded
src/elm/Update/Firebase.elm-
src/elm/Update/Firebase.elm-        OnFBSignIn ->
src/elm/Update/Firebase.elm-            command (signIn ())
src/elm/Update/Firebase.elm-
src/elm/Update/Firebase.elm-        OnFBSkipSignIn ->
src/elm/Update/Firebase.elm-            Return.map (overSignInModel Firebase.SignIn.setSkipSignIn)
src/elm/Update/Firebase.elm-                >> config.onSwitchToNewUserSetupModeIfNeeded
--
--
src/elm/Update/Firebase.elm-                    Return.singleton model
src/elm/Update/Firebase.elm:                        |> (case model.user of
src/elm/Update/Firebase.elm-                                SignedOut ->
src/elm/Update/Firebase.elm-                                    identity
src/elm/Update/Firebase.elm-
src/elm/Update/Firebase.elm-                                SignedIn user ->
src/elm/Update/Firebase.elm-                                    Return.map
src/elm/Update/Firebase.elm-                                        (overSignInModel Firebase.SignIn.setStateToSignInSuccess)
src/elm/Update/Firebase.elm-                                        >> config.onSwitchToNewUserSetupModeIfNeeded
src/elm/Update/Firebase.elm-                           )
src/elm/Update/Firebase.elm-                )
src/elm/Update/Firebase.elm-
src/elm/Update/Firebase.elm-        OnFBUserChanged encodedUser ->
src/elm/Update/Firebase.elm-            D.decodeValue Firebase.Model.userDecoder encodedUser
src/elm/Update/Firebase.elm-                |> Result.mapError (Debug.log "Error decoding User")
src/elm/Update/Firebase.elm-                !|> (\user ->
src/elm/Update/Firebase.elm-                        Return.map (setUser user)
src/elm/Update/Firebase.elm-                            >> update config OnFBAfterUserChanged
src/elm/Update/Firebase.elm-                            >> maybeEffect firebaseUpdateClientCmd
src/elm/Update/Firebase.elm-                            >> maybeEffect firebaseSetupOnDisconnectCmd
src/elm/Update/Firebase.elm-                            >> startSyncWithFirebase
src/elm/Update/Firebase.elm-                    )
src/elm/Update/Firebase.elm-                != identity
src/elm/Update/Firebase.elm-
--
--
src/elm/Update/GroupDoc.elm-update config msg =
src/elm/Update/GroupDoc.elm:    case msg of
src/elm/Update/GroupDoc.elm-        OnGroupDocAction gdType groupDocAction ->
--
src/elm/Update/GroupDoc.elm-        OnGroupDocAction gdType groupDocAction ->
src/elm/Update/GroupDoc.elm:            case groupDocAction of
src/elm/Update/GroupDoc.elm-                GDA_StartAdding ->
src/elm/Update/GroupDoc.elm-                    createAddGroupDocForm gdType
src/elm/Update/GroupDoc.elm-                        |> XMGroupDocForm
src/elm/Update/GroupDoc.elm-                        >> config.onSetExclusiveMode
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-        OnSaveGroupDocForm form ->
src/elm/Update/GroupDoc.elm-            onGroupDocIdAction config form.groupDocId (GDA_SaveForm form)
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-        OnGroupDocIdAction groupDocId groupDocIdAction ->
src/elm/Update/GroupDoc.elm-            onGroupDocIdAction config groupDocId groupDocIdAction
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-onGroupDocIdAction config groupDocId groupDocIdAction =
src/elm/Update/GroupDoc.elm-    let
src/elm/Update/GroupDoc.elm-        ( gdType, id ) =
--
src/elm/Update/GroupDoc.elm-        ( gdType, id ) =
src/elm/Update/GroupDoc.elm:            case groupDocId of
src/elm/Update/GroupDoc.elm-                ContextGroupDocId id ->
src/elm/Update/GroupDoc.elm-                    ( ContextGroupDocType, id )
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-                ProjectGroupDocId id ->
src/elm/Update/GroupDoc.elm-                    ( ProjectGroupDocType, id )
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-        updateGroupDocHelp updateFn =
src/elm/Update/GroupDoc.elm-            (updateAllGroupDocs gdType updateFn (Set.singleton id) |> andThen)
src/elm/Update/GroupDoc.elm-                >> config.revertExclusiveMode
src/elm/Update/GroupDoc.elm-    in
--
src/elm/Update/GroupDoc.elm-    in
src/elm/Update/GroupDoc.elm:    case groupDocIdAction of
src/elm/Update/GroupDoc.elm-        GDA_ToggleArchived ->
src/elm/Update/GroupDoc.elm-            updateGroupDocHelp GroupDoc.toggleArchived
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-        GDA_ToggleDeleted ->
src/elm/Update/GroupDoc.elm-            updateGroupDocHelp Document.toggleDeleted
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-        GDA_UpdateFormName form newName ->
src/elm/Update/GroupDoc.elm-            GroupDoc.Form.setName newName form
src/elm/Update/GroupDoc.elm-                |> XMGroupDocForm
src/elm/Update/GroupDoc.elm-                |> config.onSetExclusiveMode
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-        GDA_SaveForm form ->
--
src/elm/Update/GroupDoc.elm-        GDA_SaveForm form ->
src/elm/Update/GroupDoc.elm:            case form.mode of
src/elm/Update/GroupDoc.elm-                GDFM_Add ->
src/elm/Update/GroupDoc.elm-                    insertGroupDoc form.groupDocType form.name
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-                GDFM_Edit ->
src/elm/Update/GroupDoc.elm-                    updateGroupDocHelp (GroupDoc.setName form.name)
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-insertGroupDoc gdType name =
src/elm/Update/GroupDoc.elm-    let
src/elm/Update/GroupDoc.elm-        store =
src/elm/Update/GroupDoc.elm-            Model.GroupDocStore.storeFieldFromGDType gdType
src/elm/Update/GroupDoc.elm-    in
src/elm/Update/GroupDoc.elm-    andThen
src/elm/Update/GroupDoc.elm-        (\model ->
src/elm/Update/GroupDoc.elm-            overReturn store (Store.insertAndPersist (GroupDoc.init name model.now)) model
src/elm/Update/GroupDoc.elm-        )
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm---updateContext : DocId -> (GroupDoc -> GroupDoc) -> ModelReturnF
src/elm/Update/GroupDoc.elm-
src/elm/Update/GroupDoc.elm-
--
--
src/elm/Update/LaunchBar.elm-update config msg =
src/elm/Update/LaunchBar.elm:    case msg of
src/elm/Update/LaunchBar.elm-        NOOP ->
src/elm/Update/LaunchBar.elm-            identity
src/elm/Update/LaunchBar.elm-
src/elm/Update/LaunchBar.elm-        OnLBEnter entity ->
src/elm/Update/LaunchBar.elm-            let
src/elm/Update/LaunchBar.elm-                v =
--
src/elm/Update/LaunchBar.elm-                v =
src/elm/Update/LaunchBar.elm:                    case entity of
src/elm/Update/LaunchBar.elm-                        SI_Project project ->
src/elm/Update/LaunchBar.elm-                            project |> getDocId >> Entity.Types.ProjectView
src/elm/Update/LaunchBar.elm-
src/elm/Update/LaunchBar.elm-                        SI_Projects ->
src/elm/Update/LaunchBar.elm-                            Entity.Types.ProjectsView
src/elm/Update/LaunchBar.elm-
src/elm/Update/LaunchBar.elm-                        SI_Context context ->
src/elm/Update/LaunchBar.elm-                            context |> getDocId >> Entity.Types.ContextView
src/elm/Update/LaunchBar.elm-
src/elm/Update/LaunchBar.elm-                        SI_Contexts ->
src/elm/Update/LaunchBar.elm-                            Entity.Types.ContextsView
src/elm/Update/LaunchBar.elm-            in
src/elm/Update/LaunchBar.elm-            config.onComplete
src/elm/Update/LaunchBar.elm-                >> config.onSwitchView v
src/elm/Update/LaunchBar.elm-
src/elm/Update/LaunchBar.elm-        OnLBInputChanged form text ->
src/elm/Update/LaunchBar.elm-            returnWith identity
src/elm/Update/LaunchBar.elm-                (\model ->
src/elm/Update/LaunchBar.elm-                    XMLaunchBar (updateInput config text model form)
src/elm/Update/LaunchBar.elm-                        |> config.setXMode
src/elm/Update/LaunchBar.elm-                )
src/elm/Update/LaunchBar.elm-
--
--
src/elm/Update/Subscription.elm-update config msg =
src/elm/Update/Subscription.elm:    case msg of
src/elm/Update/Subscription.elm-        OnNowChanged now ->
src/elm/Update/Subscription.elm-            map (setNow now)
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-        OnGlobalKeyUp keyCode ->
src/elm/Update/Subscription.elm-            onGlobalKeyUp config (KX.fromCode keyCode)
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-        OnPouchDBChange dbName encodedDoc ->
src/elm/Update/Subscription.elm-            let
src/elm/Update/Subscription.elm-                afterEntityUpsertOnPouchDBChange ( entity, model ) =
src/elm/Update/Subscription.elm-                    map (\_ -> model)
--
src/elm/Update/Subscription.elm-                    map (\_ -> model)
src/elm/Update/Subscription.elm:                        >> (case entity of
src/elm/Update/Subscription.elm-                                TodoEntity todo ->
src/elm/Update/Subscription.elm-                                    config.afterTodoUpsert todo
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-                                _ ->
src/elm/Update/Subscription.elm-                                    config.noop
src/elm/Update/Subscription.elm-                           )
src/elm/Update/Subscription.elm-            in
src/elm/Update/Subscription.elm-            X.Return.returnWithMaybe2 identity
src/elm/Update/Subscription.elm-                (upsertEncodedDocOnPouchDBChange dbName encodedDoc >>? afterEntityUpsertOnPouchDBChange)
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-        OnFirebaseDatabaseChange dbName encodedDoc ->
src/elm/Update/Subscription.elm-            Return.effect_ (upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm---onGlobalKeyUp : Config msg model -> Key -> SubReturnF msg model
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-onGlobalKeyUp config key =
src/elm/Update/Subscription.elm-    returnWith .editMode
src/elm/Update/Subscription.elm-        (\editMode ->
--
src/elm/Update/Subscription.elm-        (\editMode ->
src/elm/Update/Subscription.elm:            case ( key, editMode ) of
src/elm/Update/Subscription.elm-                ( key, XMNone ) ->
src/elm/Update/Subscription.elm-                    let
src/elm/Update/Subscription.elm-                        clear =
src/elm/Update/Subscription.elm-                            map Model.Selection.clearSelection
src/elm/Update/Subscription.elm-                                >> config.revertExclusiveMode
src/elm/Update/Subscription.elm-                    in
--
src/elm/Update/Subscription.elm-                    in
src/elm/Update/Subscription.elm:                    case key of
src/elm/Update/Subscription.elm-                        KX.Escape ->
src/elm/Update/Subscription.elm-                            clear
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-                        KX.CharX ->
src/elm/Update/Subscription.elm-                            clear
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-                        KX.CharQ ->
src/elm/Update/Subscription.elm-                            config.onStartAddingTodoWithFocusInEntityAsReference
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-                        KX.CharI ->
src/elm/Update/Subscription.elm-                            config.onStartAddingTodoToInbox
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-                        KX.Slash ->
src/elm/Update/Subscription.elm-                            config.openLaunchBarMsg
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-                        _ ->
src/elm/Update/Subscription.elm-                            identity
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-                ( KX.Escape, _ ) ->
src/elm/Update/Subscription.elm-                    config.revertExclusiveMode
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-                _ ->
--
--
src/elm/Update/Subscription.elm-upsertEncodedDocOnPouchDBChange dbName encodedEntity =
src/elm/Update/Subscription.elm:    case dbName of
src/elm/Update/Subscription.elm-        "todo-db" ->
src/elm/Update/Subscription.elm-            maybeOverT2 todoStore (Store.upsertOnPouchDBChange encodedEntity)
src/elm/Update/Subscription.elm-                >>? Tuple.mapFirst createTodoEntity
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-        "project-db" ->
src/elm/Update/Subscription.elm-            maybeOverT2 projectStore (Store.upsertOnPouchDBChange encodedEntity)
src/elm/Update/Subscription.elm-                >>? Tuple.mapFirst createProjectEntity
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-        "context-db" ->
src/elm/Update/Subscription.elm-            maybeOverT2 contextStore (Store.upsertOnPouchDBChange encodedEntity)
src/elm/Update/Subscription.elm-                >>? Tuple.mapFirst createContextEntity
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-        _ ->
src/elm/Update/Subscription.elm-            \_ -> Nothing
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm---upsertEncodedDocOnFirebaseDatabaseChange : String -> E.Value -> SubModel model -> Cmd msg
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-upsertEncodedDocOnFirebaseDatabaseChange dbName encodedEntity =
--
src/elm/Update/Subscription.elm-upsertEncodedDocOnFirebaseDatabaseChange dbName encodedEntity =
src/elm/Update/Subscription.elm:    case dbName of
src/elm/Update/Subscription.elm-        "todo-db" ->
src/elm/Update/Subscription.elm-            .todoStore >> Store.upsertInPouchDbOnFirebaseChange encodedEntity
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-        "project-db" ->
src/elm/Update/Subscription.elm-            .projectStore >> Store.upsertInPouchDbOnFirebaseChange encodedEntity
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-        "context-db" ->
src/elm/Update/Subscription.elm-            .contextStore >> Store.upsertInPouchDbOnFirebaseChange encodedEntity
src/elm/Update/Subscription.elm-
src/elm/Update/Subscription.elm-        _ ->
src/elm/Update/Subscription.elm-            \_ -> Cmd.none
--
--
src/elm/Update/Todo.elm-update config now msg =
src/elm/Update/Todo.elm:    case msg of
src/elm/Update/Todo.elm-        ToggleRunning todoId ->
src/elm/Update/Todo.elm-            mapOver timeTracker (Tracker.toggleStartStop todoId now)
src/elm/Update/Todo.elm-
src/elm/Update/Todo.elm-        OnSwitchOrStartTrackingTodo todoId ->
src/elm/Update/Todo.elm-            mapOver timeTracker (Tracker.switchOrStartRunning todoId now)
src/elm/Update/Todo.elm-
src/elm/Update/Todo.elm-        OnStopRunningTodo ->
src/elm/Update/Todo.elm-            onStopRunningTodo
src/elm/Update/Todo.elm-
src/elm/Update/Todo.elm-        OnGotoRunningTodo ->
src/elm/Update/Todo.elm-            onGotoRunningTodo config
src/elm/Update/Todo.elm-
src/elm/Update/Todo.elm-        UpdateTimeTracker ->
src/elm/Update/Todo.elm-            updateTimeTracker now
src/elm/Update/Todo.elm-
src/elm/Update/Todo.elm-        AfterUpsert todo ->
src/elm/Update/Todo.elm-            onAfterUpsertTodo todo
src/elm/Update/Todo.elm-
src/elm/Update/Todo.elm-        OnReminderNotificationClicked notif ->
src/elm/Update/Todo.elm-            onReminderNotificationClicked notif
src/elm/Update/Todo.elm-
src/elm/Update/Todo.elm-        RunningNotificationResponse res ->
--
--
src/elm/Update/Todo/Internal.elm-onSaveTodoForm config form =
src/elm/Update/Todo/Internal.elm:    case form.mode of
src/elm/Update/Todo/Internal.elm-        TFM_Edit editMode ->
src/elm/Update/Todo/Internal.elm-            let
src/elm/Update/Todo/Internal.elm-                updateTodoHelp action =
src/elm/Update/Todo/Internal.elm-                    updateTodo action form.id
src/elm/Update/Todo/Internal.elm-                        |> andThen
src/elm/Update/Todo/Internal.elm-            in
--
src/elm/Update/Todo/Internal.elm-            in
src/elm/Update/Todo/Internal.elm:            case editMode of
src/elm/Update/Todo/Internal.elm-                ETFM_EditTodoText ->
src/elm/Update/Todo/Internal.elm-                    updateTodoHelp <| TA_SetText form.text
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                ETFM_EditTodoSchedule ->
src/elm/Update/Todo/Internal.elm-                    updateTodoHelp <| TA_SetScheduleFromMaybeTime form.maybeComputedTime
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                _ ->
src/elm/Update/Todo/Internal.elm-                    identity
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-        TFM_Add addMode ->
src/elm/Update/Todo/Internal.elm-            saveAddTodoForm config addMode form |> andThen
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-inboxEntity =
src/elm/Update/Todo/Internal.elm-    Entity.Types.createContextEntity Context.null
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm---insertTodo : (DeviceId -> DocId -> TodoDoc) -> AppModel -> ( TodoDoc, AppModel )
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-insertTodo constructWithId =
--
--
src/elm/Update/Todo/Internal.elm-                    referenceEntity =
src/elm/Update/Todo/Internal.elm:                        case addMode of
src/elm/Update/Todo/Internal.elm-                            ATFM_AddToInbox ->
src/elm/Update/Todo/Internal.elm-                                inboxEntity
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                            ATFM_SetupFirstTodo ->
src/elm/Update/Todo/Internal.elm-                                inboxEntity
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                            ATFM_AddWithFocusInEntityAsReference ->
src/elm/Update/Todo/Internal.elm-                                model.focusInEntity
src/elm/Update/Todo/Internal.elm-                in
src/elm/Update/Todo/Internal.elm-                updateTodo
--
src/elm/Update/Todo/Internal.elm-                updateTodo
src/elm/Update/Todo/Internal.elm:                    (case referenceEntity of
src/elm/Update/Todo/Internal.elm-                        TodoEntity fromTodo ->
src/elm/Update/Todo/Internal.elm-                            TA_CopyProjectAndContextId fromTodo
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                        GroupEntity (ContextEntity context) ->
src/elm/Update/Todo/Internal.elm-                            TA_SetContext context
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                        GroupEntity (ProjectEntity project) ->
src/elm/Update/Todo/Internal.elm-                            TA_SetProject project
src/elm/Update/Todo/Internal.elm-                    )
src/elm/Update/Todo/Internal.elm-                    todoId
src/elm/Update/Todo/Internal.elm-                    >> setFocusInEntityWithTodoId config todoId
src/elm/Update/Todo/Internal.elm-            )
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-mapOver =
src/elm/Update/Todo/Internal.elm-    Record.over >>> Return.map
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-mapSet =
src/elm/Update/Todo/Internal.elm-    Record.set >>> Return.map
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
--
--
src/elm/Update/Todo/Internal.elm-        >> command
src/elm/Update/Todo/Internal.elm:            (case editFormMode of
src/elm/Update/Todo/Internal.elm-                ETFM_EditTodoText ->
src/elm/Update/Todo/Internal.elm-                    Cmd.none
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                ETFM_EditTodoContext ->
src/elm/Update/Todo/Internal.elm-                    positionPopup "#edit-context-button-"
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                ETFM_EditTodoProject ->
src/elm/Update/Todo/Internal.elm-                    positionPopup "#edit-project-button-"
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                ETFM_EditTodoSchedule ->
src/elm/Update/Todo/Internal.elm-                    positionPopup "#edit-schedule-button-"
src/elm/Update/Todo/Internal.elm-            )
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-onStartAddingTodo config addFormMode =
src/elm/Update/Todo/Internal.elm-    let
src/elm/Update/Todo/Internal.elm-        createXMode model =
src/elm/Update/Todo/Internal.elm-            Todo.Form.createAddTodoForm addFormMode |> XMTodoForm
src/elm/Update/Todo/Internal.elm-    in
src/elm/Update/Todo/Internal.elm-    X.Return.returnWith createXMode config.setXMode
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
--
--
src/elm/Update/Todo/Internal.elm-    in
src/elm/Update/Todo/Internal.elm:    (case res.action of
src/elm/Update/Todo/Internal.elm-        "stop" ->
src/elm/Update/Todo/Internal.elm-            onStopRunningTodo
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-        "continue" ->
src/elm/Update/Todo/Internal.elm-            identity
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-        _ ->
src/elm/Update/Todo/Internal.elm-            onGotoRunningTodo config
src/elm/Update/Todo/Internal.elm-    )
src/elm/Update/Todo/Internal.elm-        >> config.closeNotification todoId
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-onReminderNotificationClicked notif =
src/elm/Update/Todo/Internal.elm-    let
src/elm/Update/Todo/Internal.elm-        { action, data } =
src/elm/Update/Todo/Internal.elm-            notif
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-        todoId =
src/elm/Update/Todo/Internal.elm-            data.id
src/elm/Update/Todo/Internal.elm-    in
src/elm/Update/Todo/Internal.elm-    if action == "mark-done" then
src/elm/Update/Todo/Internal.elm-        Return.andThen (updateTodo TA_MarkDone todoId)
--
--
src/elm/Update/Todo/Internal.elm-                    (\entity ->
src/elm/Update/Todo/Internal.elm:                        case entity of
src/elm/Update/Todo/Internal.elm-                            Entity.Types.TodoEntity doc ->
src/elm/Update/Todo/Internal.elm-                                Document.hasId todoId doc
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-                            _ ->
src/elm/Update/Todo/Internal.elm-                                False
src/elm/Update/Todo/Internal.elm-                    )
src/elm/Update/Todo/Internal.elm-    in
src/elm/Update/Todo/Internal.elm-    maybeTodoEntity
src/elm/Update/Todo/Internal.elm-        |> Maybe.unpack
src/elm/Update/Todo/Internal.elm-            (\_ ->
src/elm/Update/Todo/Internal.elm-                setFocusInEntityWithTodoId config todoId
src/elm/Update/Todo/Internal.elm-                    >> config.switchToContextsView
src/elm/Update/Todo/Internal.elm-            )
src/elm/Update/Todo/Internal.elm-            config.setFocusInEntity
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-setFocusInEntityWithTodoId config =
src/elm/Update/Todo/Internal.elm-    createTodoEntityId >> config.setFocusInEntityWithEntityId
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-positionMoreMenuCmd todoId =
src/elm/Update/Todo/Internal.elm-    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ todoId)
--
--
src/elm/Update/Todo/Internal.elm-    in
src/elm/Update/Todo/Internal.elm:    case action of
src/elm/Update/Todo/Internal.elm-        Todo.Notification.Model.Dismiss ->
src/elm/Update/Todo/Internal.elm-            andThen (updateTodo TA_TurnReminderOff todoId)
src/elm/Update/Todo/Internal.elm-                >> map removeReminderOverlay
src/elm/Update/Todo/Internal.elm-                >> Return.command (Notification.closeNotification todoId)
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-        Todo.Notification.Model.ShowSnoozeOptions ->
src/elm/Update/Todo/Internal.elm-            map (setReminderOverlayToSnoozeView todoDetails)
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-        Todo.Notification.Model.SnoozeTill snoozeOffset ->
src/elm/Update/Todo/Internal.elm-            Return.andThen (snoozeTodoWithOffset snoozeOffset todoId)
src/elm/Update/Todo/Internal.elm-                >> Return.command (Notification.closeNotification todoId)
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-        Todo.Notification.Model.Close ->
src/elm/Update/Todo/Internal.elm-            map removeReminderOverlay
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-        Todo.Notification.Model.MarkDone ->
src/elm/Update/Todo/Internal.elm-            andThen (updateTodo TA_MarkDone todoId)
src/elm/Update/Todo/Internal.elm-                >> map removeReminderOverlay
src/elm/Update/Todo/Internal.elm-                >> Return.command (Notification.closeNotification todoId)
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-
src/elm/Update/Todo/Internal.elm-snoozeTodoWithOffset snoozeOffset todoId model =
--
--
src/elm/Update/ViewType.elm-update config msg =
src/elm/Update/ViewType.elm:    case msg of
src/elm/Update/ViewType.elm-        SwitchView viewType ->
src/elm/Update/ViewType.elm-            map (switchToView viewType)
src/elm/Update/ViewType.elm-                >> config.clearSelection
src/elm/Update/ViewType.elm-
src/elm/Update/ViewType.elm-        SwitchToEntityListView listView ->
src/elm/Update/ViewType.elm-            listView |> EntityListView >> SwitchView >> update config
src/elm/Update/ViewType.elm-
src/elm/Update/ViewType.elm-        SwitchToContextsView ->
src/elm/Update/ViewType.elm-            ContextsView |> SwitchToEntityListView >> update config
src/elm/Update/ViewType.elm-
src/elm/Update/ViewType.elm-
src/elm/Update/ViewType.elm-switchToView viewType model =
src/elm/Update/ViewType.elm-    { model | viewType = viewType }
--
--
src/elm/View/Header.elm-menuIcon config m =
src/elm/View/Header.elm:    case Firebase.getMaybeUserProfile m of
src/elm/View/Header.elm-        Nothing ->
src/elm/View/Header.elm-            Mat.headerIconBtn config.onMdl
src/elm/View/Header.elm-                m.mdl
src/elm/View/Header.elm-                [ Mat.resourceId "account-menu-not-signed-in"
src/elm/View/Header.elm-                , Mat.tabIndex -1
src/elm/View/Header.elm-                ]
src/elm/View/Header.elm-                [ Mat.icon "account_circle" ]
src/elm/View/Header.elm-
src/elm/View/Header.elm-        Just { photoURL } ->
src/elm/View/Header.elm-            img
src/elm/View/Header.elm-                [ src photoURL
src/elm/View/Header.elm-                , class "account"
src/elm/View/Header.elm-                ]
src/elm/View/Header.elm-                []
--
--
src/elm/View/Layout.elm-            div [ id "main-view-container" ]
src/elm/View/Layout.elm:                [ case Model.ViewType.getMainViewType model of
src/elm/View/Layout.elm-                    EntityListView viewType ->
src/elm/View/Layout.elm-                        Entity.View.list config appVM viewType model
src/elm/View/Layout.elm-
src/elm/View/Layout.elm-                    SyncView ->
src/elm/View/Layout.elm-                        View.CustomSync.view config model
src/elm/View/Layout.elm-                ]
src/elm/View/Layout.elm-
src/elm/View/Layout.elm-        isOverlayOpen =
src/elm/View/Layout.elm-            AppDrawer.Model.getIsOverlayOpen model.appDrawerModel
src/elm/View/Layout.elm-
src/elm/View/Layout.elm-        onClickStopPropagationAV =
src/elm/View/Layout.elm-            X.Html.onClickStopPropagation config.noop
src/elm/View/Layout.elm-
src/elm/View/Layout.elm-        layoutMainContent =
src/elm/View/Layout.elm-            div [ id "layout-main-content" ] [ mainViewContainer ]
src/elm/View/Layout.elm-    in
src/elm/View/Layout.elm-    if isOverlayOpen then
src/elm/View/Layout.elm-        div
src/elm/View/Layout.elm-            [ id "app-layout"
src/elm/View/Layout.elm-            , classList [ ( "sidebar-overlay", isOverlayOpen ) ]
src/elm/View/Layout.elm-            ]
src/elm/View/Layout.elm-            [ div
--
--
src/elm/View/MainMenu.elm-itemView ( textV, itemType ) =
src/elm/View/MainMenu.elm:    case itemType of
src/elm/View/MainMenu.elm-        URLItem url ->
src/elm/View/MainMenu.elm-            a [ href url, target "_blank" ] [ text textV ]
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm-        MsgItem _ ->
src/elm/View/MainMenu.elm-            text textV
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm-onItemSelect config ( _, itemType ) =
--
src/elm/View/MainMenu.elm-onItemSelect config ( _, itemType ) =
src/elm/View/MainMenu.elm:    case itemType of
src/elm/View/MainMenu.elm-        URLItem url ->
src/elm/View/MainMenu.elm-            config.revertExclusiveMode
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm-        MsgItem msg ->
src/elm/View/MainMenu.elm-            msg
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm---getItems : AppModel -> List Item
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm-getItems config appModel =
src/elm/View/MainMenu.elm-    let
src/elm/View/MainMenu.elm-        maybeUserProfile =
src/elm/View/MainMenu.elm-            Firebase.getMaybeUserProfile appModel
src/elm/View/MainMenu.elm-
src/elm/View/MainMenu.elm-        signInMenuItem =
src/elm/View/MainMenu.elm-            maybeUserProfile
src/elm/View/MainMenu.elm-                ?|> (\_ -> ( "SignOut", config.onSignOut ))
src/elm/View/MainMenu.elm-                ?= ( "SignIn", config.onSignIn )
src/elm/View/MainMenu.elm-                |> Tuple2.mapSecond MsgItem
src/elm/View/MainMenu.elm-
--
--
src/elm/View/Overlays.elm-        editModeOverlayView =
src/elm/View/Overlays.elm:            case appModel.editMode of
src/elm/View/Overlays.elm-                XMLaunchBar launchBar ->
src/elm/View/Overlays.elm-                    LaunchBar.View.init launchBar
src/elm/View/Overlays.elm-                        |> Html.map config.onLaunchBarMsg
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                XMTodoForm form ->
--
src/elm/View/Overlays.elm-                XMTodoForm form ->
src/elm/View/Overlays.elm:                    case form.mode of
src/elm/View/Overlays.elm-                        TFM_Edit editMode ->
--
src/elm/View/Overlays.elm-                        TFM_Edit editMode ->
src/elm/View/Overlays.elm:                            case editMode of
src/elm/View/Overlays.elm-                                ETFM_EditTodoContext ->
src/elm/View/Overlays.elm-                                    Todo.GroupEditView.context config form appModel
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                                ETFM_EditTodoProject ->
src/elm/View/Overlays.elm-                                    Todo.GroupEditView.project config form appModel
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                                ETFM_EditTodoSchedule ->
src/elm/View/Overlays.elm-                                    Todo.View.editTodoSchedulePopupView config form
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                                ETFM_EditTodoText ->
src/elm/View/Overlays.elm-                                    Todo.View.editTodoTextView config form
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                        TFM_Add addMode ->
--
src/elm/View/Overlays.elm-                        TFM_Add addMode ->
src/elm/View/Overlays.elm:                            case addMode of
src/elm/View/Overlays.elm-                                ATFM_SetupFirstTodo ->
src/elm/View/Overlays.elm-                                    View.GetStarted.setup config form
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                                ATFM_AddWithFocusInEntityAsReference ->
src/elm/View/Overlays.elm-                                    Todo.View.new config form
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                                ATFM_AddToInbox ->
src/elm/View/Overlays.elm-                                    Todo.View.new config form
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                XMSignInOverlay ->
src/elm/View/Overlays.elm-                    View.GetStarted.signInOverlay
src/elm/View/Overlays.elm-                        |> Html.map config.onFirebaseMsg
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                XMGroupDocForm form ->
src/elm/View/Overlays.elm-                    GroupDoc.FormView.init config form
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                XMMainMenu menuState ->
src/elm/View/Overlays.elm-                    View.MainMenu.init config menuState appModel
src/elm/View/Overlays.elm-
src/elm/View/Overlays.elm-                _ ->
src/elm/View/Overlays.elm-                    def
src/elm/View/Overlays.elm-    in
--
--
src/elm/ViewModel.elm-    in
src/elm/ViewModel.elm:    case viewType of
src/elm/ViewModel.elm-        EntityListView viewType ->
--
src/elm/ViewModel.elm-        EntityListView viewType ->
src/elm/ViewModel.elm:            case viewType of
src/elm/ViewModel.elm-                Entity.Types.ContextsView ->
src/elm/ViewModel.elm-                    ( contextsVM.title, contextsVM.icon.color )
src/elm/ViewModel.elm-
src/elm/ViewModel.elm-                Entity.Types.ContextView id ->
src/elm/ViewModel.elm-                    appHeaderInfoById id contextsVM
src/elm/ViewModel.elm-
src/elm/ViewModel.elm-                Entity.Types.ProjectsView ->
src/elm/ViewModel.elm-                    ( projectsVM.title, projectsVM.icon.color )
src/elm/ViewModel.elm-
src/elm/ViewModel.elm-                Entity.Types.ProjectView id ->
src/elm/ViewModel.elm-                    appHeaderInfoById id projectsVM
src/elm/ViewModel.elm-
src/elm/ViewModel.elm-                Entity.Types.BinView ->
src/elm/ViewModel.elm-                    ( "Bin", sgtdBlue )
src/elm/ViewModel.elm-
src/elm/ViewModel.elm-                Entity.Types.DoneView ->
src/elm/ViewModel.elm-                    ( "Done", sgtdBlue )
src/elm/ViewModel.elm-
src/elm/ViewModel.elm-                Entity.Types.RecentView ->
src/elm/ViewModel.elm-                    ( "Recent", sgtdBlue )
src/elm/ViewModel.elm-
src/elm/ViewModel.elm-        SyncView ->
--
--
src/elm/X/Decode.elm-            (\value ->
src/elm/X/Decode.elm:                case decodeValue decoder value of
src/elm/X/Decode.elm-                    Ok decoded ->
src/elm/X/Decode.elm-                        succeed decoded
src/elm/X/Decode.elm-
src/elm/X/Decode.elm-                    Err err ->
src/elm/X/Decode.elm-                        fail <| X.Debug.log message <| err
src/elm/X/Decode.elm-            )
--
--
src/elm/X/List.elm-listLastIndex list =
src/elm/X/List.elm:    case list of
src/elm/X/List.elm-        [] ->
src/elm/X/List.elm-            0
src/elm/X/List.elm-
src/elm/X/List.elm-        _ ->
src/elm/X/List.elm-            List.length list - 1
src/elm/X/List.elm-
src/elm/X/List.elm-
src/elm/X/List.elm-clampIndex index =
src/elm/X/List.elm-    listLastIndex >> clamp 0 # index
src/elm/X/List.elm-
src/elm/X/List.elm-
src/elm/X/List.elm-clampIndexIn =
src/elm/X/List.elm-    flip clampIndex
src/elm/X/List.elm-
src/elm/X/List.elm-
src/elm/X/List.elm-atIndexIn =
src/elm/X/List.elm-    flip List.getAt
src/elm/X/List.elm-
src/elm/X/List.elm-
src/elm/X/List.elm-prependIn =
src/elm/X/List.elm-    flip (::)
src/elm/X/List.elm-
--
--
src/elm/X/List.elm-toMaybe list =
src/elm/X/List.elm:    case list of
src/elm/X/List.elm-        [] ->
src/elm/X/List.elm-            Nothing
src/elm/X/List.elm-
src/elm/X/List.elm-        _ ->
src/elm/X/List.elm-            Just list
src/elm/X/List.elm-
src/elm/X/List.elm-
src/elm/X/List.elm-singleton item =
src/elm/X/List.elm-    [ item ]
--
--
src/elm/X/Maybe.elm-toList maybe =
src/elm/X/Maybe.elm:    case maybe of
src/elm/X/Maybe.elm-        Just just ->
src/elm/X/Maybe.elm-            [ just ]
src/elm/X/Maybe.elm-
src/elm/X/Maybe.elm-        Nothing ->
src/elm/X/Maybe.elm-            []
