module Model exposing (..)

import Json.Decode as JD
import Json.Encode as JE


type alias LanguageId =
    String


type alias LanguageMeta =
    { lightWeight : Bool
    , staticTyping : Bool
    , functional : Bool
    , objectOriented : Bool
    }


type LanguageMetaKind
    = LightWeight
    | StaticTyping
    | Functional
    | ObjectOriented


kinds : List LanguageMetaKind
kinds =
    [ LightWeight, StaticTyping, Functional, ObjectOriented ]


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

fieldName_lightWeight = "lightWeight"
fieldName_staticTyping = "staticTyping"
fieldName_functional = "functional"
fieldName_objectOriented = "objectOriented"
fieldName_name = "name"
fieldName_path = "path"
fieldName_impression = "impression"
fieldName_meta = "meta"


languageMetaDecoder : JD.Decoder LanguageMeta
languageMetaDecoder =
    JD.map4 LanguageMeta
        (JD.field fieldName_lightWeight    JD.bool)
        (JD.field fieldName_staticTyping   JD.bool)
        (JD.field fieldName_functional     JD.bool)
        (JD.field fieldName_objectOriented JD.bool)

languageMetaEncoder : LanguageMeta -> JE.Value
languageMetaEncoder meta =
    JE.object [
        ( fieldName_lightWeight   , JE.bool meta.lightWeight )
      , ( fieldName_staticTyping  , JE.bool meta.staticTyping )
      , ( fieldName_functional    , JE.bool meta.functional )
      , ( fieldName_objectOriented, JE.bool meta.objectOriented)
    ]

languageDecoder : JD.Decoder Language
languageDecoder =
    JD.map4 Language
        (JD.field fieldName_name JD.string)
        (JD.field fieldName_path JD.string)
        (JD.maybe (JD.field fieldName_impression JD.string)
            |> JD.andThen
                (\m ->
                    case m of
                        Nothing ->
                            JD.succeed ""

                        Just s ->
                            JD.succeed s
                )
        )
        (JD.field fieldName_meta languageMetaDecoder)

languageEncoder : Language -> JE.Value
languageEncoder lang =
    JE.object [
        ( fieldName_name      , JE.string lang.name )
      , ( fieldName_path      , JE.string lang.path )
      , ( fieldName_impression, JE.string lang.impression )
      , ( fieldName_meta      , languageMetaEncoder lang.meta )
    ]