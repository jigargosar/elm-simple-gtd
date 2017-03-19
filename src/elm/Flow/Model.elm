module Flow.Model exposing (..)

import FunctionExtra exposing (..)
import List.Extra as List
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type Node msg
    = Branch String (Node msg) (Node msg)
    | Action String msg
    | ConfirmAction String (Node msg)


type FlowAction
    = YesAction
    | NoAction
    | BackAction


type alias Tracker msg =
    ( Node msg, List (Node msg) )


type alias Model msg =
    { tracker : Tracker msg }


init : Node msg -> Model msg
init rootNode =
    { tracker = createTracker rootNode }


update at model =
    model
        |> (case at of
                YesAction ->
                    onYes

                NoAction ->
                    onNo

                BackAction ->
                    onBack
           )
        >> Maybe.withDefault model


branchNode =
    Branch


actionNode =
    Action


confirmActionNode =
    ConfirmAction


createTracker node =
    ( node, [] )


getTracker : Model msg -> Tracker msg
getTracker =
    (.tracker)


trackerGetNode : Tracker msg -> Node msg
trackerGetNode =
    Tuple.first


trackerGetParents =
    Tuple.second


getTrackersCurrentNode : Model msg -> Node msg
getTrackersCurrentNode =
    getTracker >> trackerGetNode


trackerGetNextActions flowActionToMsg tracker =
    let
        backNA =
            if trackerIsRoot tracker then
                []
            else
                [ "Back" => flowActionToMsg BackAction ]

        yesAction =
            "Yes" => flowActionToMsg YesAction

        noAction =
            "No" => flowActionToMsg NoAction
    in
        case trackerGetNode tracker of
            Branch q y n ->
                [ yesAction, noAction ] ++ backNA

            Action q msg ->
                [ "Yes" => msg ] ++ backNA

            ConfirmAction q a ->
                [ yesAction ] ++ backNA


getNextActions flowActionToMsg =
    getTracker >> trackerGetNextActions flowActionToMsg


trackerIsRoot =
    trackerGetParents >> List.isEmpty


getQuestion model =
    case getTrackersCurrentNode model of
        Branch q _ _ ->
            q

        Action q _ ->
            q

        ConfirmAction q a ->
            q


setTracker tracker model =
    { model | tracker = tracker }


updateMaybeTracker fun model =
    fun model
        ?|> setTracker
        # model


onYes =
    updateMaybeTracker (getTracker >> trackerOnYes)


onNo =
    updateMaybeTracker (getTracker >> trackerOnNo)


onBack =
    updateMaybeTracker (getTracker >> trackerOnBack)


trackerOnYes : Tracker msg -> Maybe (Tracker msg)
trackerOnYes ( node, parentNodes ) =
    case node of
        Branch q y n ->
            Just ( y, node :: parentNodes )

        Action q _ ->
            Nothing

        ConfirmAction q a ->
            Just ( a, node :: parentNodes )


trackerOnNo : Tracker msg -> Maybe (Tracker msg)
trackerOnNo ( node, parentNodes ) =
    case node of
        Branch q y n ->
            Just ( n, node :: parentNodes )

        Action q _ ->
            Nothing

        ConfirmAction q a ->
            trackerOnBack ( node, parentNodes )


trackerOnBack : Tracker msg -> Maybe (Tracker msg)
trackerOnBack ( _, parentNodes ) =
    List.uncons parentNodes
