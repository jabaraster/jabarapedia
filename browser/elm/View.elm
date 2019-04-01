module View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (map, range)


span_ : String -> String -> Html msg
span_ cls txt =
    span [ class cls ] [ text txt ]


span__ : String -> Html msg
span__ txt =
    span [] [ text txt ]


hr_ : Html msg
hr_ =
    hr [] []


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg ] []


type alias Prefix =
    String


type alias TrueClass =
    String


type alias FalseClass =
    String


conditionClass : Bool -> Prefix -> TrueClass -> FalseClass -> Attribute msg
conditionClass cond pre t f =
    class <|
        if cond then
            pre ++ " " ++ t

        else
            pre ++ " " ++ f


conditionClass_ : Bool -> TrueClass -> FalseClass -> Attribute msg
conditionClass_ cond t f =
    class <|
        if cond then
            t

        else
            f


toggleArrow : Bool -> Html msg
toggleArrow open =
    span
        [ class <|
            "toggle-arrow"
                ++ (if open then
                        " toggle-open"

                    else
                        " toggle-close"
                   )
        ]
        [ text "▶︎" ]


type alias Min =
    Int


type alias Max =
    Int


type alias NewValue =
    Int


fas : String -> Html msg
fas iconName =
    i [ class <| "fas fa-" ++ iconName ] []


fas_ : String -> String -> Html msg
fas_ clsName iconName =
    i [ class <| clsName ++ " fas fa-" ++ iconName ] []


stars : Min -> Max -> Int -> (NewValue -> msg) -> Html msg
stars min max cur handler =
    div [ class "stars" ] <|
        map
            (\idx ->
                let
                    h =
                        handler idx
                in
                i
                    [ class <|
                        "fas fa-star "
                            ++ (if idx <= cur then
                                    "star-on"

                                else
                                    "star-off"
                               )
                    , onClick h
                    ]
                    []
            )
        <|
            range min max
