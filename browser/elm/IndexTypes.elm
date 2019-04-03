module IndexTypes exposing (Model, Msg(..), Page(..))

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Http
import Model exposing (Language, LanguageId, LanguageMetaKind, RemoteResource)
import Url exposing (Url)


type Page
    = HomePage
    | LanguagePage LanguageId
    | NewLanguagePage
    | EditLanguagePage LanguageId
    | NotFoundPage


type alias Model =
    { page : Page
    , key : Key
    , communicating : Bool
    , communicationError : Maybe Http.Error
    , languages : RemoteResource (List Language)
    , language : RemoteResource Language
    , editLanguage : Maybe Language
    }


type Msg
    = None
    | UrlChange Url
    | LinkClicked UrlRequest
    | IndexLoaded (Result Http.Error (List Language))
    | LanguageLoaded (Result Http.Error Language)
    | LanguageLoadedForEdit (Result Http.Error Language)
    | GoLanguageEditor
    | LanguageNameChange String
    | LanguagePathChange String
    | LanguageImpressionChange String
    | LanguageMetaChange LanguageMetaKind
    | CreateLanguage
    | UpdateLanguage
    | SuccessSaveLanguage (Result Http.Error ())
