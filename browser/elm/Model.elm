module Model exposing (Language, LanguageId, LanguageMeta, LanguageMetaKind(..), MetaAccessor, RemoteResource, emptyLanguage, fieldName_functional, fieldName_impression, fieldName_lightWeight, fieldName_meta, fieldName_name, fieldName_objectOriented, fieldName_path, fieldName_staticTyping, kinds, languageDecoder, languageEncoder, languageMetaDecoder, languageMetaEncoder, metaAccessor)

import Dict exposing (Dict)
import Http
import Json.Decode as JD
import Json.Encode as JE


type alias RemoteResource a =
    Maybe (Result Http.Error a)


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


type alias MetaAccessor =
    { label : String
    , getter : LanguageMeta -> Bool
    , setter : Bool -> LanguageMeta -> LanguageMeta
    }


kinds : List ( LanguageMetaKind, MetaAccessor )
kinds =
    [ ( LightWeight
      , { label = "Light Weight"
        , getter = .lightWeight
        , setter = \b meta -> { meta | lightWeight = b }
        }
      )
    , ( StaticTyping
      , { label = "Static Typing"
        , getter = .staticTyping
        , setter = \b meta -> { meta | staticTyping = b }
        }
      )
    , ( Functional
      , { label = "Functional"
        , getter = .functional
        , setter = \b meta -> { meta | functional = b }
        }
      )
    , ( ObjectOriented
      , { label = "Object Oriented"
        , getter = .objectOriented
        , setter = \b meta -> { meta | objectOriented = b }
        }
      )
    ]


emptyAccessor : MetaAccessor
emptyAccessor =
    { label = ""
    , getter = \_ -> True
    , setter = \_ meta -> meta
    }


metaAccessor : LanguageMetaKind -> MetaAccessor
metaAccessor kind =
    List.filter (\( k, _ ) -> k == kind) kinds
        |> List.head
        |> Maybe.map Tuple.second
        |> Maybe.withDefault emptyAccessor


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


fieldName_lightWeight =
    "lightWeight"


fieldName_staticTyping =
    "staticTyping"


fieldName_functional =
    "functional"


fieldName_objectOriented =
    "objectOriented"


fieldName_name =
    "name"


fieldName_path =
    "path"


fieldName_impression =
    "impression"


fieldName_meta =
    "meta"


languageMetaDecoder : JD.Decoder LanguageMeta
languageMetaDecoder =
    JD.map4 LanguageMeta
        (JD.field fieldName_lightWeight JD.bool)
        (JD.field fieldName_staticTyping JD.bool)
        (JD.field fieldName_functional JD.bool)
        (JD.field fieldName_objectOriented JD.bool)


languageMetaEncoder : LanguageMeta -> JE.Value
languageMetaEncoder meta =
    JE.object
        [ ( fieldName_lightWeight, JE.bool meta.lightWeight )
        , ( fieldName_staticTyping, JE.bool meta.staticTyping )
        , ( fieldName_functional, JE.bool meta.functional )
        , ( fieldName_objectOriented, JE.bool meta.objectOriented )
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
    JE.object
        [ ( fieldName_name, JE.string lang.name )
        , ( fieldName_path, JE.string lang.path )
        , ( fieldName_impression, JE.string lang.impression )
        , ( fieldName_meta, languageMetaEncoder lang.meta )
        ]
