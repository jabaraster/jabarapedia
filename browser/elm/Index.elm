module Index exposing (Model, Msg(..), Resource(..), init, main, parseUrl, subscriptions, update, view)

import Api
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode
import List exposing (map)
import Model exposing (Language, LanguageId)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing (..)



-- MAIN


main : Platform.Program Json.Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChange
        }



-- MODEL


type alias Model =
    { resource : Resource
    , key : Key
    , languages : Maybe (Result Http.Error (List Language))
    , language : Maybe (Result Http.Error Language)
    }


type Resource
    = Home
    | LanguageIndex
    | Language LanguageId
    | NotFound


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        res =
            parseUrl url
    in
    route url
        { resource = Home
        , key = key
        , languages = Nothing
        , language = Nothing
        }
        False


route : Url -> Model -> Bool -> ( Model, Cmd Msg )
route url model urlPush =
    let
        res =
            parseUrl url

        newModel =
            { model | resource = res }
    in
    case res of
        NotFound ->
            ( newModel, Cmd.none )

        Home ->
            ( newModel, pushUrl model.key url )

        LanguageIndex ->
            if urlPush then
                ( newModel, Cmd.batch [ pushUrl model.key url, Api.getLanguages IndexLoaded ] )

            else
                ( newModel, Api.getLanguages IndexLoaded )

        Language path ->
            if urlPush then
                ( newModel, Cmd.batch [ pushUrl model.key url, Api.getLanguage path LanguageLoaded ] )

            else
                ( newModel, Api.getLanguage path LanguageLoaded )


pushUrl : Key -> Url -> Cmd msg
pushUrl key url =
    Browser.Navigation.pushUrl key <| Url.toString url



-- UPDATE


type Msg
    = UrlChange Url
    | LinkClicked UrlRequest
    | IndexLoaded (Result Http.Error (List Language))
    | LanguageLoaded (Result Http.Error Language)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange url ->
            route url model False

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    route url model True

                Browser.External href ->
                    ( model, Browser.Navigation.load href )

        IndexLoaded res ->
            ( { model | languages = Just res }, Cmd.none )

        LanguageLoaded res ->
            ( { model | language = Just res }, Cmd.none )


parseUrl : Url -> Resource
parseUrl url =
    Maybe.withDefault NotFound <|
        Url.Parser.parse
            (Url.Parser.oneOf
                [ Url.Parser.map Home <| Url.Parser.top
                , Url.Parser.map LanguageIndex <| Url.Parser.s "language"
                , Url.Parser.map Language (Url.Parser.s "language" </> Url.Parser.string)
                ]
            )
            url



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    case model.resource of
        NotFound ->
            { title = title "NOT FOUND"
            , body =
                [ h1 [] [ text "Sorry, request page is not found." ]
                ]
            }

        Home ->
            { title = title "Home"
            , body =
                [ h1 [] [ text "Jabarapedia, Home" ]
                , ul []
                    [ list <| a [ href "/language/" ] [ text "Language index" ]
                    ]
                ]
            }

        LanguageIndex ->
            case model.languages of
                Nothing ->
                    { title = title "Language index"
                    , body =
                        [ section []
                            [ h1 [] [ text "Language index" ]
                            , p [] [ text "now loading..." ]
                            ]
                        ]
                    }

                Just res ->
                    { title = title "Language index"
                    , body =
                        [ section [] <|
                            h1 [] [ text "Language index" ]
                                :: viewLanguageIndexRoute res
                        ]
                    }

        Language path ->
            case model.language of
                Nothing ->
                    { title = title <| "Detail of " ++ path
                    , body =
                        [ section []
                            [ h1 [] [ text <| "Detail of " ++ path ]
                            , p [] [ text "now loading..." ]
                            ]
                        ]
                    }

                Just res ->
                    case res of
                        Ok lang ->
                            { title = title <| "Detail of " ++ lang.name
                            , body =
                                [ section []
                                    [ h1 [] [ text <| "Detail of " ++ lang.name ]
                                    , viewLanguageDetail lang
                                    ]
                                ]
                            }

                        Err err ->
                            { title = title <| "Detail of " ++ path
                            , body =
                                [ section [] <|
                                    h1 [] [ text <| "Detail of " ++ path ]
                                        :: viewError err
                                ]
                            }


viewError : Http.Error -> List (Html msg)
viewError err =
    [ h3 [] [ text "Oops... error occurred..." ]
    , p [] [ text <| errorText err ]
    ]


viewLanguageIndexRoute : Result Http.Error (List Language) -> List (Html msg)
viewLanguageIndexRoute res =
    case res of
        Ok languages ->
            viewLanguageIndex languages

        Err err ->
            viewError err


viewLanguageIndex : List Language -> List (Html msg)
viewLanguageIndex languages =
    [ ol [] <| List.map (list << languageLink) languages ]


viewLanguageDetail : Language -> Html msg
viewLanguageDetail lang =
    section []
        [ h2 [] [ text "Impression" ]
        , p [] [ text lang.impression ]
        ]


title : String -> String
title t =
    t ++ " | Jabarapedia"


languageLink : Language -> Html msg
languageLink lang =
    a [ href <| "/language/" ++ lang.path ] [ text lang.name ]


list : Html msg -> Html msg
list inner =
    li [] [ inner ]



-- UTILITY


errorText : Http.Error -> String
errorText err =
    case err of
        Http.BadUrl url ->
            "Fail -> Bad URL ->" ++ url

        Http.Timeout ->
            "Fail -> Timeout."

        Http.NetworkError ->
            "Fail -> Network error."

        Http.BadStatus s ->
            "Fail -> Bad status -> " ++ String.fromInt s

        Http.BadBody b ->
            "Fail -> BadBody -> " ++ b
