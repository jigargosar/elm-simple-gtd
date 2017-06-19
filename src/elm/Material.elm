module Material exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)


--smallIcon name =
--    i [ class "material-icons small" ] [ text name ]


icon name =
    i [ class "default-color material-icons" ] [ text name ]


iconA name attr =
    div attr [ i [ class "material-icons" ] [ text name ] ]


iconButton name attributes =
    div attributes
        [ a [ class "btn-flat btn-floating" ]
            [ i [ class "default-color material-icons" ] [ text name ] ]
        ]


smallIconButton name attributes =
    div attributes
        [ a [ class "btn-flat btn-floating x24 " ]
            [ i [ class "default-color material-icons" ] [ text name ] ]
        ]


divider =
    div [ class "divider" ] []
