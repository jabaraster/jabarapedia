module Api exposing (..)

import Http
import Model exposing (LanguageId, Language)
import Json.Decode as JD

getLanguages : (Result Http.Error (List Language) -> msg) -> Cmd msg
getLanguages operation =
  Http.riskyRequest
    { url = "https://api.jabarapedia.jabara.info/language/index"
    , method = "GET"
    , body = Http.emptyBody
    , headers = []
    , timeout = Nothing
    , tracker = Nothing
    , expect = Http.expectJson operation <| JD.list Model.languageDecoder
    }

getLanguage : LanguageId -> (Result Http.Error Language -> msg) -> Cmd msg
getLanguage languageId operation =
  Http.riskyRequest
    { url = "https://api.jabarapedia.jabara.info/language/" ++ languageId
    , method = "GET"
    , body = Http.emptyBody
    , headers = []
    , timeout = Nothing
    , tracker = Nothing
    , expect = Http.expectJson operation <| Model.languageDecoder
    }

createLanguage : Language -> (Result Http.Error () -> msg) -> Cmd msg
createLanguage lang operation =
  Http.riskyRequest
    { url = "https://api.jabarapedia.jabara.info/language/index"
    , method = "POST"
    , body = Http.jsonBody <| Model.languageEncoder lang
    , headers = []
    , timeout = Nothing
    , tracker = Nothing
    , expect = Http.expectWhatever operation
    }

updateLanguage : Language -> (Result Http.Error () -> msg) -> Cmd msg
updateLanguage lang operation =
  Http.riskyRequest
    { url = "https://api.jabarapedia.jabara.info/language/" ++ lang.path
    , method = "PUT"
    , body = Http.jsonBody <| Model.languageEncoder lang
    , headers = []
    , timeout = Nothing
    , tracker = Nothing
    , expect = Http.expectWhatever operation
    }