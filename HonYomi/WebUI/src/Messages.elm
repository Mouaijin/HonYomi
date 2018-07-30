{- Msg types for entire site -}


module Messages exposing (..)

import Models
import ServerBook as Book
import ServerConfig exposing (ServerConfig)
import ServerFile exposing (..)


type AuthMsg
    = SetUsernameField String
    | SetPasswordField String
    | LoginRequest
    | LoginSuccess Models.Token
    | LoginFailure String


type PlaybackMsg
    = ReserveTrackRequest ServerFile
    | ReserveTrackSuccess ( ServerFile, FileReservation )
    | ReserveTrackError String



--todo: figure out how the loading process will work, and how to wire up ports to do so


type LibraryMsg
    = BooksRequest
    | BooksSuccess Book.Library
    | BooksError String


type ConfigMsg
    = ConfigGetRequest
    | ConfigPostRequest
    | ConfigSuccess ServerConfig
    | ConfigError String
    | SetWatchForChanges Bool
    | SetScanInterval Int
    | SetServerPort Int
    | AddDir
    | RemoveDir Int
    | ModifyDir Int String


type RouteMsg
    = RouteToLibrary
    | RouteToConfig


type Msg
    = NoOp
    | TriggerRefresh
    | Refresh Models.Token
    | Auth AuthMsg
    | Library LibraryMsg
    | Config ConfigMsg
    | Playback PlaybackMsg
    | Route RouteMsg
