module Index exposing (Model, Msg(..), Resource(..), init, links, main, onUrlChange, onUrlRequest, parseUrl, subscriptions, update, view)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key, pushUrl)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as JD
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


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    Debug.log "init" ( { resource = parseUrl url, key = key }, Cmd.none )


type alias Model =
    { resource : Resource
    , key : Key
    }


type Resource
    = Home
    | LanguageIndex
    | Language String
    | NotFound



-- UPDATE


type Msg
    = UrlChange Url
    | LinkClicked UrlRequest


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange url ->
            Debug.log "UrlChange" ( { model | resource = parseUrl url }, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    Debug.log "LinkClicked[Internal]" ( { model | resource = parseUrl url }, pushUrl model.key <| Url.toString url )

                Browser.External href ->
                    Debug.log "LinkClicked[External]" ( model, Browser.Navigation.load href )


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
                , links
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
