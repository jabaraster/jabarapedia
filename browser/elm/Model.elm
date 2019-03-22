module Model exposing (..)

import Json.Decode as JD


type alias LanguageId
    = String


type alias LanguageMeta =
    { lightWeight : Bool
    , staticTyping : Bool
    , functional: Bool
    , objectOriented: Bool
    }


type alias Language =
    { name : String
    , path : LanguageId
    , impression : String
    , meta : LanguageMeta
    }

emptyLanguage : Language
emptyLanguage =
    { name = ""
    , path = ""
    , impression = ""
    , meta =
      { lightWeight = False
      , staticTyping = True
      , functional = True
      , objectOriented = False
      }
    }

languageMetaDecoder : JD.Decoder LanguageMeta
languageMetaDecoder =
    JD.map4 LanguageMeta
        (JD.field "lightWeight" JD.bool)
        (JD.field "staticTyping" JD.bool)
        (JD.field "functional" JD.bool)
        (JD.field "objectOriented" JD.bool)


languageDecoder : JD.Decoder Language
languageDecoder =
    JD.map4 Language
        (JD.field "name" JD.string)
        (JD.field "path" JD.string)
        (JD.maybe (JD.field "impression" JD.string) |> JD.andThen (\m ->
              case m of
                Nothing -> JD.succeed ""
                Just s  -> JD.succeed s
              ))
        (JD.field "meta" languageMetaDecoder)
