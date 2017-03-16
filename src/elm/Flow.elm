module Flow exposing (..)

import List.Extra
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type Node
    = Branch String Node Node
    | Leaf String


isActionable =
    Branch "Is it Actionable ?"
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


onYes : Tracker -> Maybe Tracker
onYes ( node, parentNodes ) =
    case node of
        Branch q y n ->
            Just ( y, node :: parentNodes )

        Leaf q ->
            Nothing


onNo : Tracker -> Maybe Tracker
onNo ( node, parentNodes ) =
    case node of
        Branch q y n ->
            Just ( n, node :: parentNodes )

        Leaf q ->
            Nothing


onBack ( _, parentNodes ) =
    List.Extra.uncons parentNodes


test : Maybe Tracker
test =
    rootTracker
        |> tapLog "start"
        |> onNo
        ?|> tapLog "no"
        ?+> onYes
        ?|> tapLog "yes"
        ?+> onNo
        ?|> tapLog "no"


tapLog str val =
    let
        _ =
            val |> (Tuple.first >> Debug.log str)
    in
        val
