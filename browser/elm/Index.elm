module Index exposing (Model, Msg(..), Resource(..), init, main, parseUrl, subscriptions, update, view)

import Api
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode
import List exposing (map)
import Model exposing (Language, LanguageId)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing (..)
import View
import Util



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



-- ROUTING


type Resource
    = Home
    | Language LanguageId
    | NewLanguageForm
    | NotFound


parseUrl : Url -> Resource
parseUrl url =
    Maybe.withDefault NotFound <|
        Url.Parser.parse
            (Url.Parser.oneOf
                [ Url.Parser.map Home <| Url.Parser.top
                , Url.Parser.map NewLanguageForm (Url.Parser.s "form" </> Url.Parser.s "language" </> Url.Parser.s "new")
                , Url.Parser.map Language (Url.Parser.s "language" </> Url.Parser.string)
                ]
            )
            url


pushUrl : Key -> Url -> Cmd msg
pushUrl key url =
    Browser.Navigation.pushUrl key <| Url.toString url



-- MODEL


type alias Model =
    { resource : Resource
    , key : Key
    , languages : Maybe (Result Http.Error (List Language))
    , language : Maybe (Result Http.Error Language)

    , editLanguage : Language
    }


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
        , editLanguage = 
          { name = ""
          , path = ""
          , impression = ""
          , meta =
            { lightWeight = False
            , staticTyping = True
            , functional = Just True
            , objectOriented = Just False
            }
          }
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

                NewLanguageForm ->
                    ( newModel, Api.getLanguages IndexLoaded )

                Language path ->
                    ( { newModel | language = Nothing }, Cmd.batch [ Api.getLanguages IndexLoaded, Api.getLanguage path LanguageLoaded ] )
    in
    if urlPush then
        ( m, Cmd.batch [ pushUrl model.key url, cmd ] )

    else
        ( m, cmd )



-- UPDATE


type Msg
    = UrlChange Url
    | LinkClicked UrlRequest
    | IndexLoaded (Result Http.Error (List Language))
    | LanguageLoaded (Result Http.Error Language)
    | LanguageNameChange String
    | LanguagePathChange String
    | LanguageImpressionChange String
    | SaveLanguage


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


        LanguageNameChange s ->
            let lang = model.editLanguage
            in  ( { model | editLanguage = { lang | name = s } }, Cmd.none )
        LanguagePathChange s ->
            let lang = model.editLanguage
            in  ( { model | editLanguage = { lang | path = s } }, Cmd.none )
        LanguageImpressionChange s ->
            let lang = model.editLanguage
            in  ( { model | editLanguage = { lang | impression = s } }, Cmd.none )
        SaveLanguage ->
            ( Debug.log "on save!!" model, Cmd.none )

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
                , inner = [ p [] [ text "Jabarapediaはプログラミングが大好きな私 じゃばら が、プログラミング言語について語るサイトです." ] ]
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
        NewLanguageForm ->
            viewCore
                { title = "New language"
                , model = model
                , inner = [
                    h1 [] [ text "New language" ]
                    , Html.form [ class "jabarapedia-form"] [
                        h3 [] [ text "Basic information" ]
                      , input [ type_ "text", placeholder "Language name"
                              , value model.editLanguage.name
                              , onInput LanguageNameChange
                              ] []
                      , input [ type_ "text", placeholder "id"
                              , value model.editLanguage.path
                              , onInput LanguagePathChange
                              ] []

                      , h3 [] [ text "Meta" ]
                      , metaCheck "Light weight" (Just model.editLanguage.meta.lightWeight)
                      , metaCheck "Static typing" (Just model.editLanguage.meta.staticTyping)
                      , metaCheck "Functional" model.editLanguage.meta.functional
                      , metaCheck "Object oriented" model.editLanguage.meta.objectOriented

                      , h3 [] [ text "Impression" ]
                      , textarea [ placeholder "Impression by Markdown."
                                 , value model.editLanguage.impression
                                 , onInput LanguageImpressionChange
                                 ] []
                      , hr [] []
                      , button [ onClick SaveLanguage, type_ "button", class "primary" ] [ text "Save" ]
                    ]
                ]
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
        h1 [] [ text "Index" ]
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
        ]


viewError : Http.Error -> List (Html msg)
viewError err =
    [ h3 [] [ text "Oops... error occurred..." ]
    , p [] [ text <| Util.errorText err ]
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
    [ h1 [] [ text lang.name, button [] [ View.fas "edit" ] ]
    , h2 [] [ text "Meta" ]
    , div []
        [ metaCheck "Light weight" (Just lang.meta.lightWeight)
        , metaCheck "Static typing" (Just lang.meta.staticTyping)
        , metaCheck "Functional" lang.meta.functional
        , metaCheck "Object oriented" lang.meta.objectOriented
        ]
    , h2 [] [ text "Impression" ]
    , p [] [ text lang.impression ]
    ]


metaCheck : String -> Maybe Bool -> Html msg
metaCheck label b =
    let
        ( bs, fas ) =
            case b of
                Nothing ->
                    ( "nothing", "question-circle" )

                Just True ->
                    ( "true", "check-circle" )

                Just False ->
                    ( "false", "times-circle" )
    in
    span [ class "meta-check" ] [ View.fas_ bs fas, span [] [ text label ] ]


languageLink : Language -> Html msg
languageLink lang =
    a [ href <| "/language/" ++ lang.path ] [ text lang.name ]


list : Html msg -> Html msg
list inner =
    li [] [ inner ]