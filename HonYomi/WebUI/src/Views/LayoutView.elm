module LayoutView exposing (..)

import FontAwesome.Web as Icon
import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick, onInput)
import Messages exposing (..)
import Models exposing (..)


getPageName : Page -> String
getPageName page =
    case page of
        LoginPage _ ->
            "Login"

        LibraryPage _ ->
            "Library"

        ConfigPage _ ->
            "Config"


applyLayout : Model -> Html Msg -> Html Msg
applyLayout model html =
    let
        pagename =
            getPageName <| getPage model
    in
    case model of
        Unauthorized _ ->
            html

        Authorized _ _ ->
            layoutView pagename html


getRoutes : List ( Html Msg, Msg )
getRoutes =
    [ ( Icon.home, Route RouteToLibrary ), ( text "Config", Route RouteToConfig ) ]


routesSpan : Html Msg
routesSpan =
    let
        mapRoute : ( Html Msg, Msg ) -> Html Msg
        mapRoute ( display, msg ) =
            a [ class "route", onClick msg ] [ display ]
    in
    span [ id "routes" ] (List.map mapRoute getRoutes)


pageHeader : Html Msg
pageHeader =
    div [ class "page-header" ]
        [ div [ class "nav-routes" ] [ routesSpan ]
        ]


bodyLayout : String -> Html Msg -> Html Msg
bodyLayout pagename html =
    div [ class "page-body" ]
        [ div [ class "page-info" ] [ h2 [ class "hidden" ] [ text pagename ] ]
        , div [ class "main-content" ] [ html ]
        ]


layoutView : String -> Html Msg -> Html Msg
layoutView pagename html =
    div [ class "page-wrapper" ]
        [ pageHeader
        , bodyLayout pagename html
        ]
