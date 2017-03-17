module InBasketFlow.Model exposing (..)

import List.Extra as List
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type Node msg
    = Branch String (Node msg) (Node msg)
    | Action String msg
    | ConfirmAction String (Node msg)


type InBasketFlowActionType
    = Yes
    | No
    | Back


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
                Yes ->
                    onYes

                No ->
                    onNo

                Back ->
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


getTrackerNode : Tracker msg -> Node msg
getTrackerNode =
    Tuple.first


getCurrentNode : Model msg -> Node msg
getCurrentNode =
    getTracker >> getTrackerNode


getQuestion model =
    case getCurrentNode model of
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
