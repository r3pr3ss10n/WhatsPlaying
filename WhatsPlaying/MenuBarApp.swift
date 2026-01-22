import SwiftUI
import AppKit

class MenuBarApp: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var process: Process?
    private var outputHandle: FileHandle?
    private var errorHandle: FileHandle?
    private var bufferChunks: [String] = []
    private var showAlbum = false
    private var showArtwork = false
    private var currentMusicInfo: MusicInfo?
    private var artworkCache: [String: NSImage] = [:]
    private let decoder = JSONDecoder()
    private let bufferLimit = 5_000_000

    override init() {
        super.init()
        setupMenuBar()
        startStreaming()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "Loading..."
            button.action = #selector(showMenu)
            button.target = self
        }
    }

    private func startStreaming() {
        guard let scriptPath = Bundle.main.path(forResource: "mediaremote-adapter", ofType: "pl") else {
            statusItem?.button?.title = "Error: Script not found"
            return
        }

        guard let frameworkPath = Bundle.main.privateFrameworksPath?.appending("/MediaRemoteAdapter.framework"),
              FileManager.default.fileExists(atPath: frameworkPath) else {
            statusItem?.button?.title = "Error: Framework missing"
            return
        }

        cleanupProcess()

        process = Process()
        process?.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process?.arguments = [
            scriptPath,
            frameworkPath,
            "stream",
            "--no-diff"
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process?.standardOutput = outputPipe
        process?.standardError = errorPipe

        outputHandle = outputPipe.fileHandleForReading
        errorHandle = errorPipe.fileHandleForReading

        errorHandle?.readabilityHandler = { _ in }

        outputHandle?.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }

            let data = handle.availableData
            guard !data.isEmpty else { return }

            guard let chunk = String(data: data, encoding: .utf8) else { return }

            self.bufferChunks.append(chunk)
            let buffer = self.bufferChunks.joined()

            if buffer.count > self.bufferLimit {
                self.bufferChunks.removeAll()
                print("Warning: Buffer exceeded limit, clearing")
                return
            }

            let parts = buffer.components(separatedBy: "}\n")

            if let lastPart = parts.last {
                self.bufferChunks = [lastPart]
            }

            let completeParts = parts.dropLast()
            for part in completeParts {
                let jsonLine = part + "}"
                let trimmed = jsonLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && trimmed.hasPrefix("{") {
                    self.parseAndHandleOutput(trimmed)
                }
            }
        }

        do {
            try process?.run()
        } catch {
            statusItem?.button?.title = "Error: Failed to start"
            print("Failed to start process: \(error)")
        }
    }

    private func cleanupProcess() {
        outputHandle?.readabilityHandler = nil
        errorHandle?.readabilityHandler = nil
        process?.terminate()
        process?.waitUntilExit()
        outputHandle = nil
        errorHandle = nil
        process = nil
    }

    private func parseAndHandleOutput(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }

        do {
            let response = try decoder.decode(StreamResponse.self, from: data)

            guard let payload = response.payload else { return }
            guard payload.playing == true else { return }
            guard let title = payload.title, !title.isEmpty else { return }

            DispatchQueue.main.async { [weak self] in
                self?.updateDisplay(with: payload)
            }
        } catch {
            print("JSON parse error: \(error)")
        }
    }

    private func updateDisplay(with info: MusicInfo) {
        currentMusicInfo = info

        guard let button = statusItem?.button else { return }

        let artist = info.artist ?? "Unknown Artist"
        let title = info.title ?? "Unknown Title"
        var text = artist

        if showAlbum, let album = info.album, !album.isEmpty {
            text += " — \(album)"
        }

        text += " — \(title)"

        if showArtwork, let artworkData = info.artworkData, !artworkData.isEmpty {
            if let cached = artworkCache[artworkData] {
                button.image = cached
                button.title = "  " + text
                return
            }

            if let image = decodeArtwork(artworkData) {
                let resizedImage = resizeImage(image, targetSize: NSSize(width: 16, height: 16))
                artworkCache[artworkData] = resizedImage
                button.image = resizedImage
                button.title = "  " + text
                return
            }
        }

        button.image = nil
        button.title = text
    }

    private func decodeArtwork(_ base64String: String) -> NSImage? {
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        return NSImage(data: data)
    }

    private func resizeImage(_ image: NSImage, targetSize: NSSize) -> NSImage {
        let newSize = NSSize(width: targetSize.width, height: targetSize.height)
        let newImage = NSImage(size: newSize)

        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()

        return newImage
    }

    @objc private func showMenu() {
        let menu = NSMenu()

        let showArtworkItem = NSMenuItem(title: "Show Artwork", action: #selector(toggleShowArtwork), keyEquivalent: "")
        showArtworkItem.target = self
        showArtworkItem.state = showArtwork ? .on : .off
        menu.addItem(showArtworkItem)

        let showAlbumItem = NSMenuItem(title: "Show Album", action: #selector(toggleShowAlbum), keyEquivalent: "")
        showAlbumItem.target = self
        showAlbumItem.state = showAlbum ? .on : .off
        menu.addItem(showAlbumItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func quit() {
        cleanupProcess()
        NSApplication.shared.terminate(nil)
    }

    @objc private func toggleShowAlbum() {
        showAlbum.toggle()
        if let info = currentMusicInfo {
            updateDisplay(with: info)
        }
    }

    @objc private func toggleShowArtwork() {
        showArtwork.toggle()
        if let info = currentMusicInfo {
            updateDisplay(with: info)
        }
    }
}
