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


branchNode =
    Branch


actionNode =
    Action


confirmActionNode =
    ConfirmAction


createTracker node =
    ( node, [] )


getQuestion ( node, _ ) =
    case node of
        Branch q _ _ ->
            q

        Action q ->
            q

        ConfirmAction q a ->
            q


onYes : Tracker -> Maybe Tracker
onYes ( node, parentNodes ) =
    case node of
        Branch q y n ->
            Just ( y, node :: parentNodes )

        Action q ->
            Nothing

        ConfirmAction q a ->
            Just ( a, node :: parentNodes )


onNo : Tracker -> Maybe Tracker
onNo ( node, parentNodes ) =
    case node of
        Branch q y n ->
            Just ( n, node :: parentNodes )

        Action q ->
            Nothing

        ConfirmAction q a ->
            onBack ( node, parentNodes )


onBack ( _, parentNodes ) =
    List.uncons parentNodes
