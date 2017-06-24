module CssBasics exposing
  ( Declaration, CssValue(..), UnitType(..), important, encodeCssValue
  , encodeDeclaration, toStyleAttribute
  )


{-|
## Some basic helpers for generating CSS style declarations

# CSS Representation
@docs Declaration, CssValue, UnitType, important

# Encoding CSS Values and Declarations
@docs encodeCssValue, encodeDeclaration

# Rendering to a Style Attribute
@docs toStyleAttribute

-}


import Html
import Html.Attributes as Attributes
import Color exposing (Color)


{-| A declaration is a key-value pair consisting of a style
[property](http://www.w3schools.com/cssref/default.asp)
name and the value assigned to that property. The property is given as a string
and the value is given as a `CssValue`.
-}
type alias Declaration =
  (String, CssValue)


{-| Represents the types of values that may be assigned to a style property.

__Examples:__

    ("text-align", Str "center")
      --> text-align:center;

    ("color", Col (Color.rgb 0 102 255))
      --> color:rgba(0,102,255,1);

    ("font-weight", Num 700)
      --> font-weight:700;

    ("font-size", Unit 2 Em)
      --> font-size:2em;

    ("font-family", FontStack ["Helvetica Neue", "Roboto", "sans-serif"])
      --> font-family:'Helvetica Neue',Roboto,sans-serif;

    ("margin", Sides [Unit 10 Px, Unit 20 Px])
      --> margin:10px 20px;

    ("border", Multiple " " [Unit 2 Px, Str "dashed", Str "green"])
      --> border:2px dashed green;

    ("padding", Important (Unit 0 NoUnit))
      --> padding:0!important;

    ("color", Undefined)
      --> color:inherit;

Note that `Undefined` is not a null value, but a default used for error
handling. When rendered to a string or attribute, a property with an `Undefined`
value will be assigned the value
[`inherit`](https://developer.mozilla.org/en-US/docs/Web/CSS/inherit).

-}
type CssValue
  = Str String
  | Col Color
  | Num Float
  | Integer Int
  | Unit Float UnitType
  | FontStack (List String)
  | Sides (List CssValue)
  | Multiple String (List CssValue)
  | Important CssValue
  | Undefined


{-| Represents an absolute or relative unit of length. A length of zero may be
represented as `Unit 0 NoUnit`, or simply as `Num 0`.
-}
type UnitType
  = Percent
  | Em
  | Ex
  | Ch
  | Rem
  | Px
  | Cm
  | Mm
  | In
  | Pt
  | Pc
  | Vh
  | Vw
  | Vmin
  | Vmax
  | NoUnit


{-| Add "!important" to a style declaration
-}
important : Declaration -> Declaration
important (property, value) =
  (property, Important value)


-- ENCODING CSS VALUES AND DECLARATIONS

{-| Convert a `CssValue` to a properly formatted string
-}
encodeCssValue : CssValue -> String
encodeCssValue value =
  let
    rgbToString rgb =
      [ "rgba("
      , rgb.red |> toString
      , ","
      , rgb.green |> toString
      , ","
      , rgb.blue |> toString
      , ","
      , rgb.alpha |> toString
      , ")"
      ]
        |> String.concat

    quoteMultiWord string =
      if (string |> String.words |> List.length) > 1 then
        "'" ++ string ++ "'"

      else
        string

    unitToString unit =
      case unit of
        Percent ->
          "%"

        NoUnit ->
          ""

        _ ->
          unit
            |> toString
            |> String.toLower

  in
    case value of
      Str string ->
        string

      Col color ->
        color
          |> Color.toRgb
          |> rgbToString

      Num number ->
        number
          |> toString

      Integer int ->
        int
          |> toString

      Unit number unit ->
        (number |> toString) ++ (unit |> unitToString)

      FontStack list ->
        list
          |> List.map quoteMultiWord
          |> String.join ","

      Sides list ->
        list
          |> List.map encodeCssValue
          |> String.join " "

      Multiple separator list ->
        list
          |> List.map encodeCssValue
          |> String.join separator

      Important value ->
        (value |> encodeCssValue) ++ "!important"

      Undefined ->
        "inherit"


{-| Convert a `Declaration` to a string of CSS code, formatted as
`"property:value;"`
-}
encodeDeclaration : Declaration -> String
encodeDeclaration (property, value) =
  [ property
  , ":"
  , (value |> encodeCssValue)
  , ";"
  ]
    |> String.concat


-- RENDERING TO A STYLE ATTRIBUTE

{-| Given a list of declarations, return a `style` attribute that may be
applied to an `Html` node
-}
toStyleAttribute : List Declaration -> Html.Attribute msg
toStyleAttribute declarationList =
  declarationList
    |> List.map (Tuple.mapSecond encodeCssValue)
    |> Attributes.style
