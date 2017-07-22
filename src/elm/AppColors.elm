module AppColors exposing (..)

import Color
import Color.Mixing


--import CssBasics
-- base colors


primaryColor =
    Color.rgb 68 138 255


sgtdBlue =
    Color.rgb 33 150 243



-- group colors


contextsColor =
    primaryColor


nullContextColor =
    sgtdBlue


defaultContextColor =
    mixDefaultGroupColor contextsColor


projectsColor =
    Color.rgb 124 77 255


nullProjectColor =
    Color.rgb 179 157 219


defaultProjectColor =
    mixDefaultGroupColor projectsColor


mixDefaultGroupColor =
    Color.Mixing.lighten 0.06


mixNullGroupColor =
    Color.Mixing.lighten 0.06



-- util
--encode =
--    CssBasics.Col >> CssBasics.encodeCssValue


encode =
    let
        _ =
            1
    in
    Color.toRgb
        >> (\{ red, green, blue, alpha } ->
                "rgba("
                    ++ toString red
                    ++ ","
                    ++ toString green
                    ++ ","
                    ++ toString blue
                    ++ ","
                    ++ toString alpha
                    ++ ")"
           )
