module InBasketFlow.Model exposing (..)

import List.Extra as List
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type Node
    = Branch String Node Node
    | Action String
    | ConfirmAction String Node


type alias Tracker =
    ( Node, List Node )


type alias Model =
    { tracker : Tracker }


init : Node -> Model
init rootNode =
    { tracker = createTracker rootNode }


branchNode =
    Branch


actionNode =
    Action


confirmActionNode =
    ConfirmAction


createTracker node =
    ( node, [] )


getTracker : Model -> Tracker
getTracker =
    (.tracker)


getTrackerNode : Tracker -> Node
getTrackerNode =
    Tuple.first


getCurrentNode : Model -> Node
getCurrentNode =
    getTracker >> getTrackerNode


getQuestion model =
    case getCurrentNode model of
        Branch q _ _ ->
            q

        Action q ->
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


trackerOnYes : Tracker -> Maybe Tracker
trackerOnYes ( node, parentNodes ) =
    case node of
        Branch q y n ->
            Just ( y, node :: parentNodes )

        Action q ->
            Nothing

        ConfirmAction q a ->
            Just ( a, node :: parentNodes )


trackerOnNo : Tracker -> Maybe Tracker
trackerOnNo ( node, parentNodes ) =
    case node of
        Branch q y n ->
            Just ( n, node :: parentNodes )

        Action q ->
            Nothing

        ConfirmAction q a ->
            trackerOnBack ( node, parentNodes )


trackerOnBack : Tracker -> Maybe Tracker
trackerOnBack ( _, parentNodes ) =
    List.uncons parentNodes
