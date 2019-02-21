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
import View 



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

        ( m, cmd ) =
            case res of
                NotFound ->
                    ( newModel, Cmd.none )

                Home ->
                    ( newModel, Api.getLanguages IndexLoaded )

                Language path ->
                    ( { newModel | language = Nothing }, Cmd.batch [ Api.getLanguages IndexLoaded, Api.getLanguage path LanguageLoaded ] )
    in
    if urlPush then
        ( m, Cmd.batch [ pushUrl model.key url, cmd ] )

    else
        ( m, cmd )


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
            viewCore
                { title = "not found"
                , model = model
                , inner = [ span [] [ text "Sorry, request page not found." ] ]
                }

        Home ->
            viewCore
                { title = "Home"
                , model = model
                , inner = [ p [] [ text "Jabarapediaはプログラミングが大好きな私 じゃばら が、使ったことのあるプログラミング言語について語るサイトです." ] ]
                }

        Language path ->
            case model.language of
                Nothing ->
                    viewCore
                        { title = "Detail of " ++ path
                        , model = model
                        , inner = [ p [] [ text "now loading..." ] ]
                        }

                Just (Ok lang) ->
                    viewCore
                        { title = "Detail of " ++ lang.name
                        , model = model
                        , inner = viewLanguageDetail lang
                        }

                Just (Err err) ->
                    viewCore
                        { title = "Detail of " ++ path
                        , model = model
                        , inner = viewError err
                        }


type alias ViewParam msg =
    { title : String
    , model : Model
    , inner : List (Html msg)
    }


viewCore : ViewParam msg -> Document msg
viewCore param =
    { title = param.title ++ " | Jabarapedia"
    , body =
        [ hd
        , index param.model.languages
        , mainContent param.inner
        ]
    }


index : Maybe (Result Http.Error (List Language)) -> Html msg
index m =
    nav [ class "index" ] <|
        h1 [] [ text "Language Index" ]
            :: (case m of
                    Nothing ->
                        [ text "now loading..." ]

                    Just (Ok languages) ->
                        viewLanguageIndex languages

                    Just (Err err) ->
                        viewError err
               )


mainContent : List (Html msg) -> Html msg
mainContent =
    section [ class "main-content" ]


hd : Html msg
hd =
    header []
        [ a [ href "/" ] [ img [ src "/img/logo.jpg", class "logo" ] [] ]
        , span [] [ text "Jabarapedia" ]
        , button [] [ View.fas "edit" ]
        ]


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
    [ ul [] <| List.map (list << languageLink) languages ]


viewLanguageDetail : Language -> List (Html msg)
viewLanguageDetail lang =
    [ h1 [] [ text lang.name ]
    , h2 [] [ text "Impression" ]
    , p [] [ text lang.impression ]
    ]


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
