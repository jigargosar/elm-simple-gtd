module ColorMath exposing
  ( Rgba, Hsla, rgbaToColor, hslaToColor, hexToColor, colorToHex, colorToHex8
  , getRed, setRed, getGreen, setGreen, getBlue, setBlue, getHue, setHue
  , getSaturation, setSaturation, getLightness, setLightness, getAlpha, setAlpha
  , lighten, darken, saturate, desaturate, moreOpaque, moreTransparent
  , rotateHue, scaleToRed, scaleToAqua, colorTransform
  )

{-|

This package includes functions for
[getting and setting](#getting-and-setting-color-components)
individual rgba and hsla
color components, functions for
[relative color scaling](#relative-color-scaling)
by hue, saturation,
lightness, and alpha, and functions for converting among color
representations, including
[converting hexadecimal color codes](#converting-to-and-from-hex-codes)
to Elm `Color` values and vice versa.

# Getting and Setting Color Components

## RGB Components
@docs getRed, setRed, getGreen, setGreen, getBlue, setBlue

## HSL Components
@docs getHue, setHue, getSaturation, setSaturation, getLightness, setLightness

## Alpha
@docs getAlpha, setAlpha

# Relative Color Scaling

## Lightness
@docs lighten, darken

## Saturation
@docs saturate, desaturate

## Alpha
@docs moreOpaque, moreTransparent

## Hue
@docs rotateHue, scaleToRed, scaleToAqua

# Converting to and from Hex Codes
@docs hexToColor, colorToHex, colorToHex8

# Intermediate Color Representations
@docs Rgba, Hsla

### Converting back to `Color`
@docs rgbaToColor, hslaToColor

# Applying a color transform function to a [`CssValue`](http://package.elm-lang.org/packages/danielnarey/elm-css-basics/latest/CssBasics#CssValue)
@docs colorTransform
-}

import Toolkit.Operators exposing (..)
import Toolkit.Helpers as Helpers
import CssBasics exposing (CssValue(..))
import Color exposing (Color)
import Char
import Dict


-- INTERMEDIATE COLOR REPRESENTATIONS

{-| Represents the components of an RGBA color value. This is an alias for the
type returned when `Color.toRgb` is called.
-}
type alias Rgba =
  { red : Int
  , green : Int
  , blue : Int
  , alpha : Float
  }

{-| Represents the components of an HSLA color value. This is an alias for the
type returned when `Color.toHsl` is called.
-}
type alias Hsla =
  { hue : Float
  , saturation : Float
  , lightness : Float
  , alpha : Float
  }

-- CONVERTING BACK TO `Color`

{-| Converts RGBA components to a
[`Color`](http://package.elm-lang.org/packages/elm-lang/core/latest/Color#Color).
-}
rgbaToColor : Rgba -> Color
rgbaToColor rgba =
  ( rgba.red
    |> clamp 0 255
  , rgba.green
    |> clamp 0 255
  , rgba.blue
    |> clamp 0 255
  , rgba.alpha
    |> clamp 0 1
  )
    |> (Color.rgba |> Helpers.uncurry4)


{-| Converts HSLA components to a
[`Color`](http://package.elm-lang.org/packages/elm-lang/core/latest/Color#Color).
-}
hslaToColor : Hsla -> Color
hslaToColor hsla =
  ( hsla.hue
    |> checkForNaN
    |> clamp (degrees 0) (degrees 360)
  , hsla.saturation
    |> checkForNaN
    |> clamp 0 1
  , hsla.lightness
    |> clamp 0 1
  , hsla.alpha
    |> clamp 0 1
  )
    |> (Color.hsla |> Helpers.uncurry4)


-- CONVERTING HEXADECIMAL CODES TO `Color` VALUES

{-| Converts a string containing a 3-, 4-, 6-, or 8-digit hexadecimal color code
to a `Color`. Returns an error message if the string argument is not a valid
hexadecimal code. The hex code may be given with or without a leading "#".
-}
hexToColor : String -> Result String Color
hexToColor hexCode =
  let
    dropFirstChar charList =
      if charList ||> List.head == Just '#' then
        charList
          |> List.drop 1

      else
        charList

    checkDigits charList =
      case charList |> List.length of
        3 ->
          charList
           .|> (\c -> [c, c])
            |> List.concat
            |> List.map charToNum
            |> Helpers.resultList errorMsg
           !+> separateRgb
           !|> Helpers.map3Tuple hexToInt
           !|> (Color.rgb |> Helpers.uncurry3)

        4 ->
          charList
           .|> (\c -> [c, c])
            |> List.concat
            |> List.map charToNum
            |> Helpers.resultList errorMsg
            !+> separateRgba
            !|> Helpers.map4Tuple hexToInt
            !|> normalizeAlpha
            !|> (Color.rgba |> Helpers.uncurry4)

        6 ->
          charList
            |> List.map charToNum
            |> Helpers.resultList errorMsg
            !+> separateRgb
            !|> Helpers.map3Tuple hexToInt
            !|> (Color.rgb |> Helpers.uncurry3)

        8 ->
          charList
            |> List.map charToNum
            |> Helpers.resultList errorMsg
           !+> separateRgba
           !|> Helpers.map4Tuple hexToInt
           !|> normalizeAlpha
           !|> (Color.rgba |> Helpers.uncurry4)

        _ ->
          errorMsg
            |> Err

    charToNum char =
      if char |> Char.isDigit then
        char
          |> String.fromChar
          |> String.toInt

      else
        [ ('A', 10)
        , ('B', 11)
        , ('C', 12)
        , ('D', 13)
        , ('E', 14)
        , ('F', 15)
        ]
          |> Dict.fromList
          |> Dict.get char
          |> Result.fromMaybe errorMsg

    separateRgb numList =
      numList
        |> Helpers.apply3
          ( Helpers.take2Tuple
          , List.drop 2 >> Helpers.take2Tuple
          , List.drop 4 >> Helpers.take2Tuple
          )
        |> Helpers.maybe3Tuple
        |> Result.fromMaybe errorMsg

    separateRgba numList =
      numList
        |> Helpers.apply4
          ( Helpers.take2Tuple
          , List.drop 2 >> Helpers.take2Tuple
          , List.drop 4 >> Helpers.take2Tuple
          , List.drop 6 >> Helpers.take2Tuple
          )
        |> Helpers.maybe4Tuple
        |> Result.fromMaybe errorMsg

    hexToInt (firstDigit, secondDigit) =
      firstDigit
        |> (*) 16
        |> (+) secondDigit

    normalizeAlpha (r, g, b, a) =
      (r, g, b, toFloat a / 255)

    errorMsg =
      "Argument is not a valid hexadecimal color code"

  in
    hexCode
      |> String.toUpper
      |> String.toList
      |> dropFirstChar
      |> checkDigits


{-| Given a `Color`, returns the equivalent hexademimal color code as a
6-character string, with the alpha channel ignored.
-}
colorToHex : Color -> String
colorToHex color =
  color
    |> Helpers.applyList [getRed, getGreen, getBlue]
   .|> numToHex
    |> String.concat


{-| Given a `Color`, returns the equivalent hexademimal color code as an
8-character string, with the alpha channel represented by the last two
characters (note that 8-digit hex codes are not yet supported by all browsers).
-}
colorToHex8 : Color -> String
colorToHex8 color =
  let
    alphaToHex num =
      num * 255
        |> round
        |> numToHex

  in
    color
      |> colorToHex
      |> flip (++) (color |> getAlpha |> alphaToHex)


numToHex : Int -> String
numToHex num =
  let
    firstDigit num =
      base16Digits
        |> Dict.get (num // 16)
        ?= (num // 16 |> toString)

    secondDigit num =
      base16Digits
        |> Dict.get (rem num 16)
        ?= (rem num 16 |> toString)

    base16Digits =
      [ (10, "A")
      , (11, "B")
      , (12, "C")
      , (13, "D")
      , (14, "E")
      , (15, "F")
      ]
    |> Dict.fromList

  in
    (num |> firstDigit) ++ (num |> secondDigit)


-- GETTING AND SETTING COLOR COMPONENTS

-- RGB COMPONENTS

{-| Given a `Color`, returns the value of its red channel.
-}
getRed : Color -> Int
getRed color =
  color
    |> Color.toRgb
    |> .red


{-| Given an integer value from 0 to 255 and a `Color`, returns an
updated `Color` with the red channel set to the input value.
-}
setRed : Int -> Color -> Color
setRed value color =
  let
    updateRed r rgba =
      { rgba
      | red =
          r
      }

  in
    color
      |> Color.toRgb
      |> updateRed (value |> clamp 0 255)
      |> rgbaToColor


{-| Given a `Color`, returns the value of its green channel.
-}
getGreen : Color -> Int
getGreen color =
  color
    |> Color.toRgb
    |> .green


{-| Given an integer value from 0 to 255 and a `Color`, returns an
updated `Color` with the green channel set to the input value.
-}
setGreen : Int -> Color -> Color
setGreen value color =
  let
    updateGreen g rgba =
      { rgba
      | green =
          g
      }

  in
    color
      |> Color.toRgb
      |> updateGreen (value |> clamp 0 255)
      |> rgbaToColor


{-| Given a `Color`, returns the value of its blue channel.
-}
getBlue : Color -> Int
getBlue color =
  color
    |> Color.toRgb
    |> .blue


{-| Given an integer value from 0 to 255 and a `Color`, returns an
updated `Color` with the blue channel set to the input value.
-}
setBlue : Int -> Color -> Color
setBlue value color =
  let
    updateBlue b rgba =
      { rgba
      | blue =
          b
      }

  in
    color
      |> Color.toRgb
      |> updateBlue (value |> clamp 0 255)
      |> rgbaToColor


-- HSL COMPONENTS

{-| Given a `Color`, returns its hue as a decimal value between 0 and 360,
representing degrees on a color wheel. (Note that the standard Elm
representation of hue in the `Color` module is in radians rather than degrees.
Degrees are used in this package for compatibility with CSS and for the sake
of human readability.)
-}
getHue : Color -> Float
getHue color =
  color
    |> Color.toHsl
    |> .hue
    |> checkForNaN
    |> (*) (180/pi)


{-| Given a decimal value between 0 and 360 (representing degrees on a color
wheel) and a `Color`, returns an updated `Color` with the hue set to the input
value.
-}
setHue : Float -> Color -> Color
setHue value color =
  let
    updateHue h hsla =
      { hsla
      | hue =
          h
      }

  in
    color
      |> Color.toHsl
      |> updateHue (value |> clamp 0 360 |> degrees)
      |> hslaToColor




{-| Given a `Color`, returns its saturation as a decimal value between 0 and 1.
-}
getSaturation : Color -> Float
getSaturation color =
  color
    |> Color.toHsl
    |> .saturation
    |> checkForNaN


{-| Given a decimal value between 0 and 1 and a `Color`, returns an updated
`Color` with the saturation set to the input value.
-}
setSaturation : Float -> Color -> Color
setSaturation value color =
  let
    updateSaturation s hsla =
      { hsla
      | saturation =
          s
      }

  in
    color
      |> Color.toHsl
      |> updateSaturation (value |> clamp 0 1)
      |> hslaToColor


{-| Given a `Color`, returns its lightness as a decimal value between 0 and 1.
-}
getLightness : Color -> Float
getLightness color =
  color
    |> Color.toHsl
    |> .lightness


{-| Given a decimal value between 0 and 1 and a `Color`, returns an updated
`Color` with the lightness set to the input value.
-}
setLightness : Float -> Color -> Color
setLightness value color =
  let
    updateLightness l hsla =
      { hsla
      | lightness =
          l
      }

  in
    color
      |> Color.toHsl
      |> updateLightness (value |> clamp 0 1)
      |> hslaToColor


-- Alpha

{-| Given a `Color`, returns its alpha channel as a decimal value between 0 and
1.
-}
getAlpha : Color -> Float
getAlpha color =
  color
    |> Color.toRgb
    |> .alpha


{-| Given a decimal value between 0 and 1 and a `Color`, returns an updated
`Color` with the alpha channel set to the input value.
-}
setAlpha : Float -> Color -> Color
setAlpha value color =
  let
    updateAlpha a hsla =
      { hsla
      | alpha =
          a
      }

  in
    color
      |> Color.toHsl
      |> updateAlpha (value |> clamp 0 1)
      |> hslaToColor


-- RELATIVE COLOR SCALING

{-| Given a decimal value *x* between 0 and 1 and a `Color`, returns an updated
`Color` with the lightness *L* increased proportionally by the formula:

    L + ( x * (1 - L) )
-}
lighten : Float -> Color -> Color
lighten amount baseColor =
  let
    scaleFunction amount hsl =
      { hsl
      | lightness =
          (1 - hsl.lightness)
            |> (*) amount
            |> (+) hsl.lightness
      }

  in
    baseColor
      |> Color.toHsl
      |> scaleFunction (amount |> clamp 0 1)
      |> hslaToColor


{-| Given a decimal value *x* between 0 and 1 and a `Color`, returns an updated
`Color` with the lightness *L* decreased proportionally by the formula:

    L - (x * L)
-}
darken : Float -> Color -> Color
darken amount baseColor =
  let
    scaleFunction amount hsl =
      { hsl
      | lightness =
          hsl.lightness
            |> (*) amount
            |> (-) hsl.lightness
      }

  in
    baseColor
      |> Color.toHsl
      |> scaleFunction (amount |> clamp 0 1)
      |> hslaToColor


{-| Given a decimal value *x* between 0 and 1 and a `Color`, returns an updated
`Color` with the saturation *S* increased proportionally by the formula:

    S + ( x * (1 - S) )
-}
saturate : Float -> Color -> Color
saturate amount baseColor =
  let
    scaleFunction amount hsl =
      { hsl
      | saturation =
          (1 - hsl.saturation)
            |> (*) amount
            |> (+) hsl.saturation
      }

  in
    baseColor
      |> Color.toHsl
      |> scaleFunction (amount |> clamp 0 1)
      |> hslaToColor


{-| Given a decimal value *x* between 0 and 1 and a `Color`, returns an updated
`Color` with the saturation *S* decreased proportionally by the formula:

    S - (x * S)
-}
desaturate : Float -> Color -> Color
desaturate amount baseColor =
  let
    scaleFunction amount hsl =
      { hsl
      | saturation =
          hsl.saturation
            |> (*) amount
            |> (-) hsl.saturation
      }

  in
    baseColor
      |> Color.toHsl
      |> scaleFunction (amount |> clamp 0 1)
      |> hslaToColor


{-| Given a decimal value *x* between 0 and 1 and a `Color`, returns an updated
`Color` with the alpha *A* increased proportionally by the formula:

    A + ( x * (1 - A) )
-}
moreOpaque : Float -> Color -> Color
moreOpaque amount baseColor =
  let
    scaleFunction amount hsl =
      { hsl
      | alpha =
          (1 - hsl.alpha)
            |> (*) amount
            |> (+) hsl.alpha
      }

  in
    baseColor
      |> Color.toHsl
      |> scaleFunction (amount |> clamp 0 1)
      |> hslaToColor


{-| Given a decimal value *x* between 0 and 1 and a `Color`, returns an updated
`Color` with the alpha *A* decreased proportionally by the formula:

    A - (x * A)
-}
moreTransparent : Float -> Color -> Color
moreTransparent amount baseColor =
  let
    scaleFunction amount hsl =
      { hsl
      | alpha =
          hsl.alpha
            |> (*) amount
            |> (-) hsl.alpha
      }

  in
    baseColor
      |> Color.toHsl
      |> scaleFunction (amount |> clamp 0 1)
      |> hslaToColor


{-| Given a decimal value *x* between -1 and 1 and a `Color`, returns an updated
`Color` with the hue rotated by _(x * 360)_ degrees, as represented on a color
wheel.
-}
rotateHue : Float -> Color -> Color
rotateHue amount baseColor =
  let
    shiftHue amount hsl =
      { hsl
      | hue =
          if (hsl.hue + amount) < 0 then
            (hsl.hue + amount)
              |> (+) (degrees 360)

          else if (hsl.hue + amount) > degrees 360 then
            (hsl.hue + amount)
              |> flip (-) (degrees 360)

          else
            (hsl.hue + amount)
      }
  in
    baseColor
      |> Color.toHsl
      |> shiftHue (amount |> clamp -1 1 |> turns)
      |> hslaToColor


{-| Given a decimal value *x* between 0 and 1 and a `Color`, returns an updated
`Color` with the hue *H* scaled proportionally toward red by the formula:

    if H >= 180 then
      H + ( x * (360 - H) )
    else
      H - (x * H)
-}
scaleToRed : Float -> Color -> Color
scaleToRed amount baseColor =
  let
    scaleFunction amount hsl =
      { hsl
      | hue =
          if hsl.hue >= degrees 180 then
            (degrees 360 - hsl.hue)
              |> (*) amount
              |> (+) hsl.hue

          else
            hsl.hue
              |> (*) amount
              |> (-) hsl.hue
      }
  in
    baseColor
      |> Color.toHsl
      |> scaleFunction (amount |> clamp 0 1)
      |> hslaToColor


{-| Given a decimal value *x* between 0 and 1 and a `Color`, returns an updated
`Color` with the hue *H* scaled proportionally toward aqua by the formula:

    if H <= 180 then
      H + ( x * (180 - H) )
    else
      H - ( x * (H - 180) )
-}
scaleToAqua : Float -> Color -> Color
scaleToAqua amount baseColor =
  let
    scaleFunction amount hsl =
      { hsl
      | hue =
          if hsl.hue <= degrees 180 then
            (degrees 180 - hsl.hue)
              |> (*) amount
              |> (+) hsl.hue

          else
            (hsl.hue - degrees 180)
              |> (*) amount
              |> (-) hsl.hue
      }
  in
    baseColor
      |> Color.toHsl
      |> scaleFunction (amount |> clamp 0 1)
      |> hslaToColor


-- APPLYING A COLOR TRANSFORM TO A `CssValue`

{-| For use with the
[`CssBasics`](http://package.elm-lang.org/packages/danielnarey/elm-css-basics/latest/CssBasics)
package: Apply a color transform function to a `Col` value; returns an error
message if the `CssValue` is not of type `Col`.
-}
colorTransform : (Color -> Color) -> CssValue -> Result String CssValue
colorTransform transform value =
  case value of
    Col color ->
      color
        |> transform
        |> Col
        |> Ok

    _ ->
      "`CssValue` argument must be of type `Col`"
        |> Err


-- HELPER

checkForNaN : Float -> Float
checkForNaN value =
  if (value |> isNaN) then
    0
  else
    value
