module Page.Article.Editor exposing (Model, Msg, initEdit, initNew, update, view)

import Data.Article as Article exposing (Article, Body)
import Data.Session exposing (Session)
import Data.User exposing (User)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, disabled, href, id, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Page.Errored exposing (PageLoadError, pageLoadError)
import Request.Article
import Route
import Task exposing (Task)
import Util exposing (pair, viewIf)
import Validate exposing (Validator, ifBlank, validate)
import Views.Form as Form
import Views.Page as Page


-- MODEL --


type alias Model =
    { errors : List Error
    , editingArticle : Maybe Article.Slug
    , title : String
    , body : String
    , description : String
    , tags : List String
    , isSaving : Bool
    }


initNew : Model
initNew =
    { errors = []
    , editingArticle = Nothing
    , title = ""
    , body = ""
    , description = ""
    , tags = []
    , isSaving = False
    }


initEdit : Session -> Article.Slug -> Task PageLoadError Model
initEdit session slug =
    let
        maybeAuthToken =
            session.user
                |> Maybe.map .token
    in
    Request.Article.get maybeAuthToken slug
        |> Http.toTask
        |> Task.mapError (\_ -> pageLoadError Page.Other "Article is currently unavailable.")
        |> Task.map
            (\article ->
                { errors = []
                , editingArticle = Just slug
                , title = article.title
                , body = Article.bodyToMarkdownString article.body
                , description = article.description
                , tags = article.tags
                , isSaving = False
                }
            )



-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "editor-page" ]
        [ div [ class "container page" ]
            [ div [ class "row" ]
                [ div [ class "col-md-10 offset-md-1 col-xs-12" ]
                    [ Form.viewErrors model.errors
                    , viewForm model
                    ]
                ]
            ]
        ]


viewForm : Model -> Html Msg
viewForm model =
    let
        isEditing =
            model.editingArticle /= Nothing

        saveButtonText =
            if isEditing then
                "Update Article"
            else
                "Publish Article"
    in
    Html.form [ onSubmit Save ]
        [ fieldset []
            [ Form.input
                {- TODO Sign up for an account (you can enter nonsense for all
                   the signup fields) and then click `New Post` in the header to
                   view the Article Editor.

                   When the user enters some input for Article Title,
                   we want to update the `title` field in the Model.

                   HINT: We'll need to add something to the definition of Msg to
                   do this. Look at how SetDescription is used in the next field!
                -}
                [ class "form-control-lg"
                , placeholder "Article Title"
                , onInput ArticleTitle
                , value model.title
                ]
                []
            , Form.input
                [ placeholder "What's this article about?"
                , onInput SetDescription
                , value model.description
                ]
                []
            , Form.textarea
                [ placeholder "Write your article (in markdown)"
                , attribute "rows" "8"
                , onInput SetBody
                , value model.body
                ]
                []
            , Form.input
                [ placeholder "Enter tags"
                , onInput SetTags
                , value (String.join " " model.tags)
                ]
                []
            , button [ class "btn btn-lg pull-xs-right btn-primary", disabled model.isSaving ]
                [ text saveButtonText ]
            ]
        ]



-- UPDATE --


type Msg
    = Save
    | ArticleTitle String
    | SetDescription String
    | SetBody String
    | SetTags String
    | CreateCompleted (Result Http.Error (Article Body))
    | EditCompleted (Result Http.Error (Article Body))


update : User -> Msg -> Model -> ( Model, Cmd Msg )
update user msg model =
    case msg of
        Save ->
            case validate modelValidator model of
                [] ->
                    case model.editingArticle of
                        Nothing ->
                            user.token
                                |> Request.Article.create model
                                |> Http.send CreateCompleted
                                |> pair { model | errors = [], isSaving = True }

                        Just slug ->
                            user.token
                                |> Request.Article.update slug model
                                |> Http.send EditCompleted
                                |> pair { model | errors = [], isSaving = True }

                errors ->
                    ( { model | errors = errors }, Cmd.none )

        ------------------------------------------------------------------------
        --                                                                    --
        --  TODO add something here that sets the title based on user input.  --
        --                                                                    --
        --  HINT: take a look at how SetDescription does something similar!   --
        --                                                                    --
        ------------------------------------------------------------------------
        ArticleTitle title ->
            ( { model | title = title }, Cmd.none )

        SetDescription description ->
            ( { model | description = description }, Cmd.none )

        SetBody body ->
            ( { model | body = body }, Cmd.none )

        SetTags tagsStr ->
            ( { model | tags = tagsFromString tagsStr }, Cmd.none )

        CreateCompleted (Ok article) ->
            Route.Article article.slug
                |> Route.modifyUrl
                |> pair model

        CreateCompleted (Err error) ->
            ( { model
                | errors = model.errors ++ [ ( Form, "Server error while attempting to publish article" ) ]
                , isSaving = False
              }
            , Cmd.none
            )

        EditCompleted (Ok article) ->
            Route.Article article.slug
                |> Route.modifyUrl
                |> pair model

        EditCompleted (Err error) ->
            ( { model
                | errors = model.errors ++ [ ( Form, "Server error while attempting to save article" ) ]
                , isSaving = False
              }
            , Cmd.none
            )



-- VALIDATION --


type Field
    = Form
    | Title
    | Body


type alias Error =
    ( Field, String )


modelValidator : Validator Error Model
modelValidator =
    Validate.all
        [ ifBlank .title ( Title, "title can't be blank." )
        , ifBlank .body ( Body, "body can't be blank." )
        ]



-- INTERNAL --


tagsFromString : String -> List String
tagsFromString str =
    str
        |> String.split " "
        |> List.map String.trim
        |> List.filter (not << String.isEmpty)


redirectToArticle : Article.Slug -> Cmd msg
redirectToArticle =
    Route.modifyUrl << Route.Article
