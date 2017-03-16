module Flow exposing (..)

import List.Extra
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type Node
    = Branch String Node Node
    | Action String
    | ConfirmAction String Node


isActionable =
    Branch "Is it Actionable ?"
        (Branch "Can be done under 2 mins?"
            (ConfirmAction "Do it now?"
                (Action "Timer Started, Go Go Go !!!")
            )
            (Action "Involves Multiple Steps?")
        )
        (Branch "Is it worth keeping?"
            (Branch "Could Require Action Later ?"
                (Action "Move to SomDay/Maybe List?")
                (Action "Move to Reference?")
            )
            (Action "Trash it ?")
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
