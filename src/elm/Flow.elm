module Flow exposing (..)

import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type Node
    = Branch String Node Node
    | Leaf String


isActionable =
    Branch "isActionable"
        (Leaf "Can be done under 2 mins?")
        (Branch "Is it worth keeping?"
            (Branch "Could Require Action Later ?"
                (Leaf "Move to SomDay/Maybe List?")
                (Leaf "Move to Reference?")
            )
            (Leaf "Trash it ?")
        )


type alias Tracker =
    ( Node, List Node )


tracker node =
    ( node, [] )


rootTracker =
    tracker isActionable


getQuestion ( node, _ ) =
    case node of
        Branch q _ _ ->
            q

        Leaf q ->
            q


onYes ( node, parentNodes ) =
    case node of
        Branch q y n ->
            Just ( y, node :: parentNodes )

        Leaf q ->
            Nothing
