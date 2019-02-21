module Model exposing (LanguageId, Language, LanguageMeta, languageDecoder, languageMetaDecoder)

import Json.Decode as JD


type alias LanguageId
    = String


type alias LanguageMeta =
    { lightWeight : Bool
    , staticTyping : Bool
    }


type alias Language =
    { name : String
    , path : LanguageId
    , impression : String
    , meta : LanguageMeta
    }


languageMetaDecoder : JD.Decoder LanguageMeta
languageMetaDecoder =
    JD.map2 LanguageMeta
        (JD.field "lightWeight" JD.bool)
        (JD.field "staticTyping" JD.bool)


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
