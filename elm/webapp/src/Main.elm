module Main exposing (..)

import Html exposing (Html, div, text, program)
import Messages exposing (Msg(..))
import Models exposing (Model, initialModel)
import Update exposing (update)
import View exposing (view)
import About.Commands exposing (fetch)

init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.map AboutMsg fetch )

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }