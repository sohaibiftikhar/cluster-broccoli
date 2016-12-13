module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Set exposing (Set)
import Models.Resources.Template exposing (..)
import Models.Resources.Instance exposing (..)
import Models.Resources.Service exposing (..)
import Models.Resources.ServiceStatus exposing (..)
import Models.Resources.JobStatus exposing (..)
import Models.Resources.AboutInfo exposing (AboutInfo)
import Models.Resources.UserInfo exposing (UserInfo)
import Updates.UpdateAboutInfo exposing (updateAboutInfo)
import Updates.UpdateErrors exposing (updateErrors)
import Updates.UpdateLoginForm exposing (updateLoginForm)
import Updates.UpdateLoginStatus exposing (updateLoginStatus)
import Updates.UpdateBodyView exposing (updateBodyView)
import Updates.Messages exposing (UpdateAboutInfoMsg(..), UpdateLoginStatusMsg(..), UpdateErrorsMsg(..))
import Commands.FetchAbout
import Messages exposing (AnyMsg(..))
import Models.Ui.Notifications exposing (Errors)
import Models.Ui.LoginForm exposing (LoginForm, emptyLoginForm)
import Views.Header
import Views.Body
import Views.Notifications
import WebSocket
import Dict exposing (Dict)

-- TODO what type of submessages do I want to have?
-- - Messages changing resources
-- - Error messages
-- - Messages changing the view
-- so one message per entry in my model? that means that not every single thing should define its own Msg type otherwise it will get crazy

type alias Model =
  { aboutInfo : Maybe AboutInfo
  -- , templates : List Template
  , errors : Errors
  , loginForm : LoginForm
  , loggedIn : Maybe UserInfo
  , authEnabled : Maybe Bool
  , templates : List Template
  , expandedTemplates : Set TemplateId
  , instances : List Instance
  , services : Dict InstanceId (List Service)
  , jobStatuses : Dict InstanceId JobStatus
  -- , expandedNewInstanceForms : Set TemplateId
  }

template1 =
  Template
    "Apache Spark Standalone Cluster"
    "Apache Spark provides programmers with an application programming interface centered on a data structure called the resilient distributed dataset (RDD), a read-only multiset of data items distributed over a cluster of machines, that is maintained in a fault-tolerant way."
    "chj3kc67"
    [ "id"
    , "url"
    ]
    ( Dict.fromList
      [ ( "id", ParameterInfo "id" Nothing Nothing )
      , ( "url", ParameterInfo "url" (Just "http://localhost:8000") Nothing )
      ]
    )

template2 =
  Template
    "Apache Zeppelin"
    "A web-based notebook that enables interactive data analytics. You can make beautiful data-driven, interactive and collaborative documents with SQL, Python, Scala and more."
    "dsadjda4"
    [ "id"
    , "password"
    ]
    ( Dict.fromList
      [ ( "id", ParameterInfo "id" Nothing Nothing )
      , ( "password", ParameterInfo "password" Nothing (Just True) )
      ]
    )

initialModel : Model
initialModel =
  { aboutInfo = Nothing
  -- , templates = []
  , errors = []
  , loginForm = emptyLoginForm
  , loggedIn = Nothing
  , authEnabled = Nothing
  , expandedTemplates = Set.empty
  , templates =
    [ template1
    , template2
    ]
  , instances =
    [ Instance
        "dev-spark"
        template1
        ( Dict.fromList
          [ ("id", "dev-spark")
          , ("url", "http://localhost:9000")
          ]
        )
    , Instance
        "dev-zeppelin"
        template2
        ( Dict.fromList
          [ ("id", "dev-zeppelin")
          , ("password", "secret")
          ]
        )
    , Instance
        "frank-zeppelin"
        template2
        ( Dict.fromList
          [ ("id", "frank-zeppelin")
          , ("password", "secret2")
          ]
        )
    ]
  , services =
    ( Dict.fromList
      [ ( "dev-zeppelin"
        , [ Service "dev-zeppelin-ui" "http" "localhost" 9000 ServicePassing
          , Service "dev-zeppelin-spark-ui" "https" "localhost" 9001 ServiceFailing
          ]
        )
      , ( "frank-zeppelin"
        , [ Service "frank-zeppelin-ui" "http" "localhost" 9000 ServiceUnknown
          , Service "frank-zeppelin-spark-ui" "https" "localhost" 9001 ServiceUnknown
          ]
        )
      , ( "dev-spark"
        , [ Service "dev-spark-master" "http" "localhost" 9000 ServicePassing
          , Service "dev-spark-master-ui" "https" "localhost" 9001 ServicePassing
          , Service "dev-spark-worker" "https" "localhost" 9001 ServicePassing
          , Service "dev-spark-worker-ui" "https" "localhost" 9001 ServicePassing
          ]
        )
      ]
    )
  , jobStatuses =
    ( Dict.fromList
      [ ( "dev-zeppelin", JobRunning )
      , ( "frank-zeppelin", JobPending )
      , ( "dev-spark", JobStopped )
      ]
    )

  -- , expandedNewInstanceForms = Set.empty
  }

init : ( Model, Cmd AnyMsg )
init =
  ( initialModel
  , Cmd.batch
    [ Cmd.map UpdateAboutInfoMsg Commands.FetchAbout.fetchAbout
    -- , Cmd.map FetchTemplatesMsg Commands.FetchTemplates.fetchTemplates
    ]
  )

update : AnyMsg -> Model -> ( Model, Cmd AnyMsg )
update msg model =
  case msg of
    -- FetchTemplatesMsg subMsg ->
      -- let (newTemplates, cmd) =
      --   updateTemplates subMsg model.templates
      -- in
      --   ({ model | templates = newTemplates }
      --   , cmd
      --   )
    UpdateAboutInfoMsg subMsg ->
      let ((newAbout, newAuthEnabled), cmd) =
        updateAboutInfo subMsg model.aboutInfo
      in
        ( { model
          | aboutInfo = newAbout
          , authEnabled = newAuthEnabled
          }
        , cmd
        )
    UpdateLoginStatusMsg subMsg ->
      let (newLoginStatus, cmd) =
        updateLoginStatus subMsg model.loggedIn
      in
        ({ model | loggedIn = newLoginStatus }
        , cmd
        )
    UpdateErrorsMsg subMsg ->
      let (newErrors, cmd) =
        updateErrors subMsg model.errors
      in
        ({ model | errors = newErrors }
        , cmd
        )
    UpdateBodyViewMsg subMsg ->
      let (newExpandedTemplates, cmd) =
        updateBodyView subMsg model.expandedTemplates
      in
        ({ model | expandedTemplates = newExpandedTemplates }
        , cmd
        )
    UpdateLoginFormMsg subMsg ->
      let (newLoginForm, cmd) =
        updateLoginForm subMsg model.loginForm
      in
        ({ model | loginForm = newLoginForm }
        , cmd
        )
    NoOp -> (model, Cmd.none)

view : Model -> Html AnyMsg
view model =
  div
    []
    [ Views.Header.view model.aboutInfo model.loginForm model.loggedIn model.authEnabled
    , Views.Notifications.view model.errors
    , Html.map
        UpdateBodyViewMsg
        ( Views.Body.view
            model.templates
            model.expandedTemplates
            model.instances
            model.services
            model.jobStatuses
        )
    , text (toString model)
    ]

subscriptions : Model -> Sub AnyMsg
subscriptions model =
  Sub.map
    UpdateErrorsMsg
    -- TODO I need a module to handle the websocket string messages and parse them into JSON somehow
    -- TODO cut the websocket connection on logout
    ( WebSocket.listen "ws://localhost:9000/ws" AddError )

main =
  program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }
