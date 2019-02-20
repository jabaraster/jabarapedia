module Index exposing (Model, Msg(..), Resource(..), init, links, main, onUrlChange, onUrlRequest, parseUrl, subscriptions, update, view)

import Api
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key, pushUrl)
import List exposing (map)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as JD
import Model exposing (Language, LanguageId)
import Url exposing (Url)
import Url.Builder as UB
import Url.Parser as UP exposing (..)



-- MAIN


main : Platform.Program JD.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        }



-- ON_URL_REQUEST


onUrlRequest : UrlRequest -> Msg
onUrlRequest urlRequest =
    LinkClicked urlRequest



-- ON_URL_CHANGE


onUrlChange : Url -> Msg
onUrlChange url =
    UrlChange url



-- MODEL


type alias Model =
    { resource : Resource
    , key : Key
    , languages : List Language
    , language : Maybe Language
    }

type Resource
    = Home
    | LanguageIndex
    | Language LanguageId
    | NotFound


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    case parseUrl url of
        NotFound ->
            ( { resource = NotFound, key = key, languages = [], language = Nothing }, Browser.Navigation.load "/" )

        Home ->
            ( { resource = Home, key = key, languages = [], language = Nothing }, Cmd.none )

        LanguageIndex ->
            ( { resource = LanguageIndex, key = key, languages = [], language = Nothing }, Api.getLanguages IndexLoaded )

        Language languageId ->
            ( { resource = parseUrl url, key = key, languages = [], language = Nothing }, Api.getLanguage languageId LanguageLoaded )



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
            ( { model | resource = parseUrl url }, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( { model | resource = parseUrl url }, pushUrl model.key <| Url.toString url )

                Browser.External href ->
                    ( model, Browser.Navigation.load href )

        IndexLoaded res ->
            case res of
                Ok languages ->
                    ( { model | languages = languages }, Cmd.none )

                Err err ->
                    ( model, Cmd.none )

        LanguageLoaded res ->
            case res of
                Ok language ->
                    ( { model | language = Just language }, Cmd.none )

                Err err ->
                    ( model, Cmd.none )


parseUrl : Url -> Resource
parseUrl url =
    Maybe.withDefault NotFound <|
        UP.parse
            (UP.oneOf
                [ UP.map Home <| UP.top
                , UP.map LanguageIndex <| UP.s "language"
                , UP.map Language (UP.s "language" </> UP.string)
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
            { title = "NOT FOUND"
            , body =
                [ h1 [] [ text "Hello, Jabarapedia!" ]
                , links
                ]
            }

        Home ->
            { title = "Home"
            , body =
                [ h1 [] [ text "Hello, Jabarapedia!" ]
                , links
                ]
            }

        LanguageIndex ->
            { title = "LanguageIndex"
            , body =
                [ h1 [] [ text "Hello, Jabarapedia!" ]
                , ol [] <| List.map (\lang -> 
                      li [] [a [ href <| "/language/" ++ lang.path ] [ text lang.name ] ]
                   ) model.languages
                ]
            }

        Language name ->
            { title = "Detail of " ++ name
            , body =
                [ h1 [] [ text "Hello, Jabarapedia!" ]
                , h2 [] [ text <| "Detail of " ++ name ]
                , links
                ]
            }


links : Html msg
links =
    ul []
        [ li [] [ a [ href "/language/" ] [ text "/language/" ] ]
        , li [] [ a [ href "/language/haskell" ] [ text "/language/haskell" ] ]
        ]
