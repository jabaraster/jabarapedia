module Util exposing (errorText, isError, isJust, isNothing, isOk )

import Http


errorText : Http.Error -> String
errorText err =
    case err of
        Http.BadUrl url ->
            "Fail -> Bad URL ->" ++ url

        Http.Timeout ->
            "Fail -> Timeout."

        Http.NetworkError ->
            "Fail -> Network error."

        Http.BadStatus s ->
            "Fail -> Bad status -> " ++ String.fromInt s

        Http.BadBody b ->
            "Fail -> BadBody -> " ++ b


isJust : Maybe a -> Bool
isJust m =
    case m of
        Nothing ->
            False

        Just _ ->
            True


isNothing : Maybe a -> Bool
isNothing =
    not << isJust


isOk : Result e a -> Bool
isOk r =
    case r of
        Ok _ ->
            True

        Err _ ->
            False


isError : Result e a -> Bool
isError =
    not << isOk