module Main exposing (main)

import ConfigView exposing (configPageView)
import Html exposing (..)
import LayoutView exposing (..)
import LibraryView exposing (libraryPageView)
import LoginView exposing (loginPageView)
import Maybe exposing (withDefault)
import Messages exposing (..)
import Models exposing (..)
import Ports exposing (..)
import Requests exposing (authRequest, configGetRequest, configPostRequest, libraryRequest, mapAuthRequest, refreshRequest)
import Time


type alias Page =
    Int


init : ( Model, Cmd Msg )
init =
    ( initMainModel, Cmd.none )


replaceToken : Model -> Token -> Model
replaceToken model token =
    { model | token = token }


updateLoginPage : Model -> AuthMsg -> LoginModel -> ( Model, Cmd Msg )
updateLoginPage model authmsg lpage =
    case authmsg of
        SetUsernameField s ->
            let
                newPage =
                    { lpage | username = s }
            in
            ( { model | page = LoginPage newPage }, Cmd.none )

        Messages.SetPasswordField s ->
            let
                newPage =
                    { lpage | password = s }
            in
            ( { model | page = LoginPage newPage }, Cmd.none )

        Messages.LoginRequest ->
            let
                authResponse =
                    authRequest lpage
            in
            ( model, authResponse )

        Messages.LoginSuccess tok ->
            update (Library BooksRequest) { model | token = tok, page = LibraryPage initLibraryModel }

        Messages.LoginFailure _ ->
            ( model, Cmd.none )


updateLibraryPage : Model -> LibraryMsg -> LibraryModel -> ( Model, Cmd Msg )
updateLibraryPage model libmsg lpage =
    case libmsg of
        BooksRequest ->
            let
                booksResponse =
                    libraryRequest model.token
            in
            ( model, booksResponse )

        Messages.BooksSuccess bs ->
            let
                newPage =
                    { lpage | books = bs }
            in
            ( { model | page = LibraryPage newPage }, Cmd.none )

        BooksError _ ->
            ( model, Cmd.none )

        SetSelectedBook book ->
            ( { model | page = LibraryPage <| setSelectedBook lpage book }, Cmd.none )

        UnsetBook ->
            ( { model | page = LibraryPage <| unsetSelectedBook lpage }, Cmd.none )


updateConfigPage : Model -> ConfigMsg -> ConfigModel -> ( Model, Cmd Msg )
updateConfigPage model config cpage =
    case config of
        ConfigGetRequest ->
            ( model, configGetRequest <| model.token )

        ConfigPostRequest ->
            ( model, configPostRequest model.token cpage.config )

        ConfigSuccess conf ->
            let
                newPage =
                    ConfigPage { cpage | config = conf }
            in
            ( { model | page = newPage }, Cmd.none )

        ConfigError _ ->
            ( model, Cmd.none )

        SetWatchForChanges b ->
            let
                oldconf =
                    cpage.config

                conf =
                    { oldconf | watchForChanges = b }

                newPage =
                    ConfigPage { cpage | config = conf }
            in
            ( { model | page = newPage }, Cmd.none )

        SetScanInterval i ->
            let
                oldconf =
                    cpage.config

                conf =
                    { oldconf | scanInterval = i }

                newPage =
                    ConfigPage { cpage | config = conf }
            in
            ( { model | page = newPage }, Cmd.none )

        SetServerPort p ->
            let
                oldconf =
                    cpage.config

                conf =
                    { oldconf | serverPort = p }

                newPage =
                    ConfigPage { cpage | config = conf }
            in
            ( { model | page = newPage }, Cmd.none )

        AddDir ->
            let
                newPage =
                    addWatchDirectory cpage
            in
            ( { model | page = ConfigPage newPage }, Cmd.none )

        RemoveDir i ->
            let
                newPage =
                    removeWatchDirectory i cpage
            in
            ( { model | page = ConfigPage newPage }, Cmd.none )

        ModifyDir i s ->
            let
                newPage =
                    modifyWatchDirectory i s cpage
            in
            ( { model | page = ConfigPage newPage }, Cmd.none )


updatePlayback : Model -> PlaybackMsg -> ( Model, Cmd Msg )
updatePlayback model msg =
    let
        pmod =
            getPlayback model
    in
    case msg of
        SetTrack mfile ->
            case mfile of
                Just file ->
                    updatePlayback { model | playback = Just <| setPlayback file model.token pmod } ReloadTrack

                Nothing ->
                    ( model, Cmd.none )

        ReloadTrack ->
            ( model, loadAudioSource () )

        ProgressChanged progress ->
            let
                newPlayback =
                    Just <| { pmod | currentTime = progress }
            in
            ( { model | playback = newPlayback }, Cmd.none )

        DurationChanged dur ->
            let
                newPlayback =
                    Just <| { pmod | duration = dur }
            in
            ( { model | playback = newPlayback }, Cmd.none )

        Ended ->
            let
                newPlayback =
                    Just <| { pmod | ended = True }
            in
            ( { model | playback = newPlayback }, Cmd.none )

        Play ->
            ( model, playAudio () )

        Pause ->
            ( model, pauseAudio () )

        Played ->
            let
                newPlayback =
                    Just <| { pmod | isPlaying = True }
            in
            ( { model | playback = newPlayback }, Cmd.none )

        Paused ->
            let
                newPlayback =
                    Just <| { pmod | isPlaying = False }
            in
            ( { model | playback = newPlayback }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case ( message, model.page ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        ( TriggerRefresh, _ ) ->
            ( model, refreshRequest model.token )

        ( Refresh tok, _ ) ->
            ( replaceToken model tok, Cmd.none )

        ( Auth authmsg, LoginPage lpage ) ->
            updateLoginPage model authmsg lpage

        ( Auth authmsg, _ ) ->
            ( model, Cmd.none )

        ( Library libmsg, LibraryPage lpage ) ->
            updateLibraryPage model libmsg lpage

        ( Library libmsg, _ ) ->
            ( model, Cmd.none )

        ( Config config, ConfigPage cpage ) ->
            updateConfigPage model config cpage

        ( Config config, _ ) ->
            ( model, Cmd.none )

        ( Playback _, LoginPage _ ) ->
            ( model, Cmd.none )

        ( Playback pmsg, _ ) ->
            updatePlayback model pmsg

        ( Route route, _ ) ->
            case route of
                RouteToLibrary ->
                    update (Library BooksRequest) { model | page = LibraryPage initLibraryModel }

                RouteToConfig ->
                    update (Config ConfigGetRequest) { model | page = ConfigPage initConfigModel }


getPageView : Model -> Html Msg
getPageView model =
    case model.page of
        LoginPage pmod ->
            loginPageView pmod

        LibraryPage pmod ->
            libraryPageView pmod

        ConfigPage cmod ->
            configPageView cmod


view : Model -> Html Msg
view model =
    applyLayout model <| getPageView model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ audioProgress (Playback << ProgressChanged)
        , durationChange (Playback << DurationChanged)
        , onEnded (\_ -> Playback Ended)
        , onPlayed (\_ -> Playback Played)
        , onPaused (\_ -> Playback Paused)

        -- , Time.every Time.second <| \_ -> Playback UpdatePostion
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
