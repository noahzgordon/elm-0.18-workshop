module Data.User exposing (User, Username, decoder, encode, usernameDecoder, usernameParser, usernameToHtml, usernameToString)

import Data.AuthToken as AuthToken exposing (AuthToken)
import Data.UserPhoto as UserPhoto exposing (UserPhoto)
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import UrlParser


type alias User =
    { email : String
    , token : AuthToken
    , username : Username
    , bio : Maybe String
    , image : UserPhoto
    }



-- SERIALIZATION --


decoder : Decoder User
decoder =
    decode User
        |> required "email" Decode.string
        |> required "token" AuthToken.decoder
        |> required "username" usernameDecoder
        |> required "bio" (Decode.nullable Decode.string)
        |> required "image" UserPhoto.decoder


encode : User -> Value
encode user =
    Encode.object
        [ ( "email", Encode.string user.email )
        , ( "token", AuthToken.encode user.token )
        , ( "username", encodeUsername user.username )
        , ( "bio", EncodeExtra.maybe Encode.string user.bio )
        , ( "image", UserPhoto.encode user.image )
        ]



-- IDENTIFIERS --


type alias Username =
    String


usernameToString : Username -> String
usernameToString username =
    username


usernameDecoder : Decoder Username
usernameDecoder =
    Decode.string


usernameParser : UrlParser.Parser (Username -> a) a
usernameParser =
    UrlParser.custom "USERNAME" Ok


encodeUsername : Username -> Value
encodeUsername username =
    Encode.string username


usernameToHtml : Username -> Html msg
usernameToHtml username =
    Html.text username
