module IndexTypes exposing (Model, Msg(..), Resource(..))

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Http
import Model exposing (Language, LanguageId, LanguageMetaKind)
import Url exposing (Url)


type Resource
    = Home
    | Language LanguageId
    | NewLanguageForm
    | EditLanguageForm LanguageId
    | NotFound


type alias Model =
    { resource : Resource
    , key : Key
    , communicating : Bool
    , communicationError : Maybe Http.Error
    , languages : Maybe (Result Http.Error (List Language))
    , language : Maybe (Result Http.Error Language)
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