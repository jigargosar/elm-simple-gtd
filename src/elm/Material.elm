module Material exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import X.Function.Infix exposing (..)
import X.Html exposing (onClickStopPropagation)


icon name =
    i [ class "default-color material-icons" ] [ text name ]


iconA name attr =
    div attr [ i [ class "material-icons" ] [ text name ] ]


iconButton name attributes =
    div attributes
        [ a [ class "btn-flat btn-floating", style [ "z-index" => "0" ] ]
            [ i [ class "default-color material-icons" ] [ text name ] ]
        ]


bigIconTextButton iconName textV clickHandler =
    div [ class "icon-text font-caption", onClickStopPropagation clickHandler ]
        [ a [ class "btn-flat btn-floating", style [ "z-index" => "0" ] ]
            [ i [ class "material-icons", style [ "font-size" => "6rem" ] ] [ text iconName ] ]
        , div [] [ text textV ]
        ]


smallIconButton name attributes =
    div attributes
        [ a [ class "btn-flat btn-floating x24", style [ "z-index" => "0" ] ]
            [ i [ class "default-color material-icons" ] [ text name ] ]
        ]


fab name attributes =
    div attributes
        [ a [ class "btn-floating" ]
            [ i [ class "material-icons", style [ "color" => "white" ] ] [ text name ] ]
        ]


divider =
    div [ class "divider" ] []
