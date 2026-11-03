//
//  NowPlaying.swift
//  HAL
//
//  Modèle pour la lecture en cours.
//

import Foundation

/// Ce que montre le lecteur d'Apple (Music)
public struct NowPlaying: Sendable {
    /// Le lecteur (Music) est lancé
    public var isPlayerRunning: Bool = false
    public var isPlaying: Bool = false
    public var track: String = ""
    public var artist: String = ""
    public var album: String = ""
    /// Année de l'album
    public var year: Int = 0
    /// Durée de la piste en secondes
    public var duration: Double = 0
    /// Pochette de la piste courante, données brutes (JPEG, PNG…)
    public var artworkData: Data?

    public init() {}

    public init(
        isPlayerRunning: Bool = false,
        isPlaying: Bool = false,
        track: String = "",
        artist: String = "",
        album: String = "",
        year: Int = 0,
        duration: Double = 0,
        artworkData: Data? = nil
    ) {
        self.isPlayerRunning = isPlayerRunning
        self.isPlaying = isPlaying
        self.track = track
        self.artist = artist
        self.album = album
        self.year = year
        self.duration = duration
        self.artworkData = artworkData
    }
}
