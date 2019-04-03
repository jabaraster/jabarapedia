module Index exposing (..)

import Api
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import IndexTypes exposing (Model, Msg(..), Resource(..))
import Json.Decode
import List exposing (map)
import Model exposing (Language, LanguageId, LanguageMetaKind(..))
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing (..)
import Util
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



-- ROUTING


parseUrl : Url -> Resource
parseUrl url =
    Maybe.withDefault NotFound <|
        Url.Parser.parse
            (Url.Parser.oneOf
                [ Url.Parser.map Home <| Url.Parser.top
                , Url.Parser.map NewLanguageForm (Url.Parser.s "form" </> Url.Parser.s "language" </> Url.Parser.s "new")
                , Url.Parser.map EditLanguageForm (Url.Parser.s "form" </> Url.Parser.s "language" </> Url.Parser.string)
                , Url.Parser.map IndexTypes.Language (Url.Parser.s "language" </> Url.Parser.string)
                ]
            )
            url


pushUrl : Key -> Url -> Cmd msg
pushUrl key url =
    Browser.Navigation.pushUrl key <| Url.toString url


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
                    ( { newModel | communicating = Util.isNothing <| Util.resultToMaybe model.languages }
                    , Cmd.batch <| loadLanguagesIfNothing model.languages
                    )

                IndexTypes.Language path ->
                    ( { newModel
                        | language = Nothing
                        , communicating = True
                      }
                    , Cmd.batch <| Api.getLanguage path LanguageLoaded ::
                                   loadLanguagesIfNothing model.languages
                    )

                NewLanguageForm ->
                    ( { newModel
                        | editLanguage = Just Model.emptyLanguage
                        , communicating = True
                      }
                    , Api.getLanguages IndexLoaded
                    )

                EditLanguageForm languageId ->
                    ( { newModel | communicating = True }
                    , Cmd.batch <| Api.getLanguage languageId LanguageLoadedForEdit ::
                                   loadLanguagesIfNothing model.languages
                    )
    in
    if urlPush then
        ( m, Cmd.batch [ pushUrl model.key url, cmd ] )

    else
        ( m, cmd )


loadLanguagesIfNothing : Maybe (Result Http.Error (List Language)) -> List (Cmd Msg)
loadLanguagesIfNothing m =
    Maybe.withDefault [Api.getLanguages IndexLoaded] <| Maybe.map (always []) <| Util.resultToMaybe m


-- INIT


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    route url
        { resource = Home
        , key = key
        , communicating = False
        , communicationError = Nothing
        , languages = Nothing
        , language = Nothing
        , editLanguage = Nothing
        }
        False



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        None ->
            ( model, Cmd.none )

        UrlChange url ->
            route url model False

        LinkClicked urlRequest ->
            case Debug.log "" urlRequest of
                Browser.Internal url ->
                    route url model True

                Browser.External href ->
                    ( model, Browser.Navigation.load href )

        IndexLoaded res ->
            ( { model
                | languages = Just res
                , communicating = False
              }
            , Cmd.none
            )

        LanguageLoaded res ->
            ( { model
                | language = Just res
                , communicating = False
              }
            , Cmd.none
            )

        LanguageLoadedForEdit (Ok lang) ->
            ( { model
                | editLanguage = Just lang
                , communicating = False
              }
            , Cmd.none
            )

        LanguageLoadedForEdit (Err err) ->
            ( { model
                | editLanguage = Nothing
                , communicating = False
                , communicationError = Just err
              }
            , Cmd.none
            )

        GoLanguageEditor ->
            ( { model
                | editLanguage =
                    Maybe.andThen
                        (\res ->
                            case res of
                                Ok lang ->
                                    Just lang

                                Err _ ->
                                    Nothing
                        )
                        model.language
              }
            , Cmd.none
            )

        LanguageNameChange s ->
            ( operateEditLanguageValue model (\l -> { l | name = s }), Cmd.none )

        LanguagePathChange s ->
            ( operateEditLanguageValue model (\l -> { l | path = s }), Cmd.none )

        LanguageImpressionChange s ->
            ( operateEditLanguageValue model (\l -> { l | impression = s }), Cmd.none )

        LanguageMetaChange kind ->
            ( switchEditLanguageMeta model kind, Cmd.none )

        CreateLanguage ->
            case model.editLanguage of
                Nothing ->
                    ( model, Cmd.none )

                Just lang ->
                    ( { model | communicating = True }, Api.createLanguage lang SuccessSaveLanguage )

        UpdateLanguage ->
            case model.editLanguage of
                Nothing ->
                    ( model, Cmd.none )

                Just lang ->
                    ( { model | communicating = True }, Api.updateLanguage lang SuccessSaveLanguage )

        SuccessSaveLanguage (Ok ()) ->
            let
                mUrl =
                    Maybe.map (\lang -> Url.Builder.relative [ "language", lang.path ] []) model.editLanguage
                        |> Maybe.andThen Url.fromString
            in
            case mUrl of
                Nothing ->
                    ( { model
                        | communicating = False
                        , communicationError = Nothing
                        , editLanguage = Nothing
                      }
                    , Cmd.none
                    )

                Just url ->
                    route url
                        { model
                            | communicating = False
                            , communicationError = Nothing
                            , editLanguage = Nothing
                        }
                        True

        SuccessSaveLanguage (Err err) ->
            ( { model
                | communicating = False
                , communicationError = Just err
              }
            , Cmd.none
            )


operateEditLanguageValue : Model -> (Language -> Language) -> Model
operateEditLanguageValue model operation =
    Maybe.withDefault model <| Maybe.map (\lang -> { model | editLanguage = Just <| operation lang }) model.editLanguage


switchEditLanguageMeta : Model -> LanguageMetaKind -> Model
switchEditLanguageMeta model kind =
    Maybe.map
        (\lang ->
            let
                meta =
                    lang.meta

                newMeta =
                    case kind of
                        LightWeight ->
                            { meta | lightWeight = not meta.lightWeight }

                        StaticTyping ->
                            { meta | staticTyping = not meta.staticTyping }

                        Functional ->
                            { meta | functional = not meta.functional }

                        ObjectOriented ->
                            { meta | objectOriented = not meta.objectOriented }
            in
            { model | editLanguage = Just { lang | meta = newMeta } }
        )
        model.editLanguage
        |> Maybe.withDefault model



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

        IndexTypes.Language path ->
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
            case model.editLanguage of
                Just l ->
                    languageForm model l

                Nothing ->
                    viewCore
                        { title = "Not Found"
                        , model = model
                        , inner = [ h3 [] [ text "Not Found." ] ]
                        }

        EditLanguageForm languageId ->
            case model.editLanguage of
                Just l ->
                    languageForm model l

                Nothing ->
                    viewCore
                        { title = "Not Found"
                        , model = model
                        , inner = [ h3 [] [ text "Not Found." ] ]
                        }


getFromEditLanguage : Model -> a -> (Language -> a) -> a
getFromEditLanguage model default operation =
    case model.editLanguage of
        Just lang ->
            operation lang

        Nothing ->
            default


type alias ViewParam msg =
    { title : String
    , model : Model
    , inner : List (Html msg)
    }


viewCore : ViewParam msg -> Document msg
viewCore { title, model, inner } =
    { title = title ++ " | Jabarapedia"
    , body =
        [ hd model
        , index model.languages
        , mainContent inner
        ]
    }


languageForm : Model -> Language -> Document Msg
languageForm model lang =
    viewCore
        { title = lang.name
        , model = model
        , inner =
            [ h1 [] [ text "Edit language" ]
            , Html.form [ class "jabarapedia-form" ]
                ([ h3 [] [ text "Basic information" ]
                 , label [] [ text "Language name" ]
                 , input
                    [ type_ "text"
                    , value lang.name
                    , onInput LanguageNameChange
                    ]
                    []
                 , label [] [ text "id (part of url)" ]
                 , input
                    [ type_ "text"
                    , value lang.path
                    , onInput LanguagePathChange
                    ]
                    []
                 , h3 [] [ text "Meta" ]
                 ]
                    ++ metaChecks (Just LanguageMetaChange) lang
                    ++ [ h3 [] [ text "Impression" ]
                       , textarea
                            [ placeholder "Impression by Markdown."
                            , value lang.impression
                            , onInput LanguageImpressionChange
                            ]
                            []
                       , View.hr_
                       , button [ onSaveClick model, type_ "button", class "primary" ] [ text "Save" ]
                       ]
                )
            ]
        }


onSaveClick : Model -> Attribute Msg
onSaveClick model =
    case model.resource of
        NewLanguageForm ->
            onClick CreateLanguage

        EditLanguageForm _ ->
            onClick UpdateLanguage

        _ ->
            onClick None


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


hd : Model -> Html msg
hd model =
    header []
        [ a [ href "/" ] [ img [ src "/img/logo.jpg", class "logo" ] [] ]
        , span [] [ text "Jabarapedia" ]
        , View.fas_
            (if model.communicating then
                "loading-icon loading"

             else
                "loading-icon hide"
            )
            "redo"
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


viewLanguageDetail : Language -> List (Html Msg)
viewLanguageDetail lang =
    [ h1 [] [ text lang.name, button [ onClick GoLanguageEditor ] [ View.fas "edit" ] ]
    , h2 [] [ text "Meta" ]
    , div [] <| metaChecks Nothing lang
    , h2 [] [ text "Impression" ]
    , p [] [ text lang.impression ]
    ]


metaChecks : Maybe (LanguageMetaKind -> msg) -> Language -> List (Html msg)
metaChecks mKindAction lang =
    List.map
        (\kind ->
            let
                ( label, value ) =
                    case kind of
                        LightWeight ->
                            ( "Light weight", lang.meta.lightWeight )

                        StaticTyping ->
                            ( "Static typing", lang.meta.staticTyping )

                        Functional ->
                            ( "Functional", lang.meta.functional )

                        ObjectOriented ->
                            ( "Object oriented", lang.meta.objectOriented )

                mAction =
                    Maybe.map (\kindAction -> kindAction kind) mKindAction
            in
            span
                (metaCheckClass mAction :: (Maybe.withDefault [] <| Maybe.map (\action -> [ onClick action ]) mAction))
                [ View.fas_
                    (if value then
                        "true"

                     else
                        "false"
                    )
                    (if value then
                        "check-circle"

                     else
                        "times-circle"
                    )
                , span [] [ text label ]
                ]
        )
        Model.kinds


metaCheckClass : Maybe msg -> Attribute msg
metaCheckClass action =
    classList [ ( "meta-check", True ), ( "clickable", Util.isJust action ) ]


languageLink : Language -> Html msg
languageLink lang =
    a [ href <| "/language/" ++ lang.path ] [ text lang.name ]


list : Html msg -> Html msg
list inner =
    li [] [ inner ]
