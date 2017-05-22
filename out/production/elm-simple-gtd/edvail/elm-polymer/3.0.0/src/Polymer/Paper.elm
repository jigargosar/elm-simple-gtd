module Polymer.Paper
    exposing
        ( badge
        , behaviors
        , button
        , card
        , checkbox
        , dialog
        , dialogBehavior
        , dialogScrollable
        , drawerPanel
        , dropdownMenu
        , fab
        , headerPanel
        , iconButton
        , input
        , item
        , iconItem
        , itemBody
        , listbox
        , material
        , menu
        , menuButton
        , progress
        , radioButton
        , radioGroup
        , ripple
        , scrollHeaderPanel
        , slider
        , spinner
        , styles
        , tabs
        , tab
        , toast
        , toggleButton
        , toolbar
        , tooltip
        )

{-|
#Material design status message for elements
@docs badge
#Common behaviors across the paper elements
@docs behaviors
#Material design button
@docs button
#Material design piece of paper with unique related data
@docs card
#A material design checkbox
@docs checkbox
#A Material Design dialog
@docs dialog
#Implements a behavior used for material design dialogs
@docs dialogBehavior
#A scrollable area used inside the material design dialog
@docs dialogScrollable
#A responsive drawer panel
@docs drawerPanel
#An element that works similarly to a native browser select
@docs dropdownMenu
#A material design floating action button
@docs fab
#A header and content wrapper for layout with headers
@docs headerPanel
#A material design icon button
@docs iconButton
#Material design text fields
@docs input
#A material-design styled list item
@docs item, iconItem, itemBody
#Implements an accessible material design listbox
@docs listbox
#A material design container that looks like a lifted sheet of paper
@docs material
#Implements an accessible material design menu
@docs menu
#A material design element that composes a trigger and a dropdown menu
@docs menuButton
#A material design progress bar
@docs progress
#A material design radio button
@docs radioButton
#A group of material design radio buttons
@docs radioGroup
#Adds a material design ripple to any container
@docs ripple
#A header bar with scrolling behavior
@docs scrollHeaderPanel
#A material design-style slider
@docs slider
#A material design spinner
@docs spinner
#Common (global) styles for Material Design elements.
@docs styles
#Material design tabs
@docs tabs, tab
#A material design notification toast
@docs toast
#A material design toggle button control
@docs toggleButton
#A material design toolbar that is easily customizable
@docs toolbar
#Material design tooltip popup for content
@docs tooltip
-}

import Html exposing (Attribute, Html, node)


paper : String -> List (Attribute msg) -> List (Html msg) -> Html msg
paper name =
    "paper-" ++ name |> node


{-| -}
badge : List (Attribute msg) -> List (Html msg) -> Html msg
badge =
    paper "badge"


{-| -}
behaviors : List (Attribute msg) -> List (Html msg) -> Html msg
behaviors =
    paper "behaviors"


{-| -}
button : List (Attribute msg) -> List (Html msg) -> Html msg
button =
    paper "button"


{-| -}
card : List (Attribute msg) -> List (Html msg) -> Html msg
card =
    paper "card"


{-| -}
checkbox : List (Attribute msg) -> List (Html msg) -> Html msg
checkbox =
    paper "checkbox"


{-| -}
dialog : List (Attribute msg) -> List (Html msg) -> Html msg
dialog =
    paper "dialog"


{-| -}
dialogBehavior : List (Attribute msg) -> List (Html msg) -> Html msg
dialogBehavior =
    paper "dialog-behavior"


{-| -}
dialogScrollable : List (Attribute msg) -> List (Html msg) -> Html msg
dialogScrollable =
    paper "dialog-scrollable"


{-| -}
drawerPanel : List (Attribute msg) -> List (Html msg) -> Html msg
drawerPanel =
    paper "drawer-panel"


{-| -}
dropdownMenu : List (Attribute msg) -> List (Html msg) -> Html msg
dropdownMenu =
    paper "dropdown-menu"


{-| -}
fab : List (Attribute msg) -> List (Html msg) -> Html msg
fab =
    paper "fab"


{-| -}
headerPanel : List (Attribute msg) -> List (Html msg) -> Html msg
headerPanel =
    paper "header-panel"


{-| -}
iconButton : List (Attribute msg) -> List (Html msg) -> Html msg
iconButton =
    paper "icon-button"


{-| -}
input : List (Attribute msg) -> List (Html msg) -> Html msg
input =
    paper "input"


{-| Material design: Lists

`item` is an interactive list item. By default, it is a horizontal flexbox.
-}
item : List (Attribute msg) -> List (Html msg) -> Html msg
item =
    paper "item"


{-| `iconItem` is a convenience element to make an item with icon. It is an interactive list item with a fixed-width icon area, according to Material Design. This is useful if the icons are of varying widths, but you want the item bodies to line up. Use this like a <paper-item>. The child node with the attribute `itemIcon` is placed in the icon area.
-}
iconItem : List (Attribute msg) -> List (Html msg) -> Html msg
iconItem =
    paper "icon-item"


{-| Use `itemBody` in a `item` or `iconItem` to make two- or three- line items. It is a flex item that is a vertical flexbox.
-}
itemBody : List (Attribute msg) -> List (Html msg) -> Html msg
itemBody =
    paper "item-body"


{-| -}
listbox : List (Attribute msg) -> List (Html msg) -> Html msg
listbox =
    paper "listbox"


{-| -}
material : List (Attribute msg) -> List (Html msg) -> Html msg
material =
    paper "material"


{-| -}
menu : List (Attribute msg) -> List (Html msg) -> Html msg
menu =
    paper "menu"


{-| -}
menuButton : List (Attribute msg) -> List (Html msg) -> Html msg
menuButton =
    paper "menu-button"


{-| -}
progress : List (Attribute msg) -> List (Html msg) -> Html msg
progress =
    paper "progress"


{-| -}
radioButton : List (Attribute msg) -> List (Html msg) -> Html msg
radioButton =
    paper "radio-button"


{-| -}
radioGroup : List (Attribute msg) -> List (Html msg) -> Html msg
radioGroup =
    paper "radio-group"


{-| -}
ripple : List (Attribute msg) -> List (Html msg) -> Html msg
ripple =
    paper "ripple"


{-| -}
scrollHeaderPanel : List (Attribute msg) -> List (Html msg) -> Html msg
scrollHeaderPanel =
    paper "scroll-header-panel"


{-| -}
slider : List (Attribute msg) -> List (Html msg) -> Html msg
slider =
    paper "slider"


{-| -}
spinner : List (Attribute msg) -> List (Html msg) -> Html msg
spinner =
    paper "spinner"


{-| -}
styles : List (Attribute msg) -> List (Html msg) -> Html msg
styles =
    paper "styles"


{-| Material design: Tabs

`tabs` makes it easy to explore and switch between different views or functional aspects of an app, or to browse categorized data sets.

Use selected property to get or set the selected tab.
-}
tabs : List (Attribute msg) -> List (Html msg) -> Html msg
tabs =
    paper "tabs"


{-| `tab` is styled to look like a tab. It should be used in conjunction with `tabs`.
-}
tab : List (Attribute msg) -> List (Html msg) -> Html msg
tab =
    paper "tab"


{-| -}
toast : List (Attribute msg) -> List (Html msg) -> Html msg
toast =
    paper "toast"


{-| -}
toggleButton : List (Attribute msg) -> List (Html msg) -> Html msg
toggleButton =
    paper "toggle-button"


{-| -}
toolbar : List (Attribute msg) -> List (Html msg) -> Html msg
toolbar =
    paper "toolbar"


{-| -}
tooltip : List (Attribute msg) -> List (Html msg) -> Html msg
tooltip =
    paper "tooltip"
