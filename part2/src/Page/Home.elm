module Page.Home exposing (view)

import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id, placeholder)


view tags =
    div [ class "home-page" ]
        [ viewBanner
        , div [ class "container page" ]
            [ div [ class "row" ]
                [ div [ class "col-md-9" ] [ viewFeed ]
                , div [ class "col-md-3" ]
                    [ div [ class "sidebar" ]
                        [ p [] [ text "Popular Tags" ]

                        -- TODO instead of passing [] to viewTags, pass the actual tags
                        , viewTags tags
                        ]
                    ]
                ]
            ]
        ]


viewTags tags =
    let
        renderedTags =
            -- TODO use `List.map` and `viewTag` to render the tags
            List.map viewTag [ "hi", "hi2", "hi3" ]
    in
    div [ class "tag-list" ] renderedTags


viewTag tagName =
    {- TODO render something like this:

       <button class="tag-pill tag-default">tag name goes here</button>
    -}
    button [ class "tag-pill tag-default" ] [ text tagName ]


viewBanner =
    div [ class "banner" ]
        [ div [ class "container" ]
            [ h1 [ class "logo-font" ] [ text "conduit" ]
            , p [] [ text "A place to share your knowledge." ]
            ]
        ]


viewFeed =
    div [ class "feed-toggle" ] [ text "(We’ll display some articles here later.)" ]
