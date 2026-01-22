import Foundation
import AppKit

struct MusicInfo: Codable {
    let bundleIdentifier: String?
    let playing: Bool?
    let title: String?
    let artist: String?
    let album: String?
    let duration: Double?
    let elapsedTime: Double?
    let artworkData: String?
    let artworkMimeType: String?

    enum CodingKeys: String, CodingKey {
        case bundleIdentifier, playing, title, artist, album, duration, elapsedTime, artworkData, artworkMimeType
    }
}

struct StreamResponse: Codable {
    let type: String
    let payload: MusicInfo?
}