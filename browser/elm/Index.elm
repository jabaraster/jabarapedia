module Index exposing (Model(..), Msg(..), init, main, onUrlChange, onUrlRequest, subscriptions, update, view)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Html exposing (..)
import Url exposing (Url)
import Url.Parser as UP
import Json.Decode as JD


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
    case urlRequest of
        Browser.Internal url ->
            case UP.parse up url of
                Nothing -> ToNotFound



-- ON_URL_CHANGE


onUrlChange : Url -> Msg
onUrlChange url =
    case UP.parse up url of
        Nothing -> ToNotFound
        Just _  -> ToHome

up : UP.Parser 
up = UP.s "home"


-- MODEL


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init _ _ _ =
    ( Home, Cmd.none )


type Model
    = NotFound
    | Home



-- UPDATE


type Msg
    = ToNotFound
    | ToHome


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToNotFound ->
            ( NotFound, Cmd.none )
        Home ->
            ( Home, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    case model of
        NotFound ->
            { title = "NOT FOUND"
            , body = [ h1 [] [ text "NOT FOUND" ] ]
            }
        Home ->
            { title = "Welcome Jabarapedia"
            , body = [ h1 [] [ text "Hello, Jabarapedia!" ] ]
            }
