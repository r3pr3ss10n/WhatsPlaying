import SwiftUI
import AppKit
import OSAKit

class MenuBarApp: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var timer: Timer?

    override init() {
        super.init()
        setupMenuBar()
        startTimer()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "Loading..."
            button.action = #selector(showMenu)
            button.target = self
        }
    }

    private func startTimer() {
        fetchMusicInfo()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchMusicInfo()
        }
    }

    private func fetchMusicInfo() {
        let script = """
        function run() {
            try {
                const MediaRemote = $.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/MediaRemote.framework/');
                MediaRemote.load;

                const MRNowPlayingRequest = $.NSClassFromString('MRNowPlayingRequest');
                
                // idk if i should show appName
                // const appName = MRNowPlayingRequest.localNowPlayingPlayerPath.client.displayName;
                const infoDict = MRNowPlayingRequest.localNowPlayingItem.nowPlayingInfo;

                const title = infoDict.valueForKey('kMRMediaRemoteNowPlayingInfoTitle');
                const album = infoDict.valueForKey('kMRMediaRemoteNowPlayingInfoAlbum');
                const artist = infoDict.valueForKey('kMRMediaRemoteNowPlayingInfoArtist');

                const albumPart = album && album.js ? ` — ${album.js}` : '';

                return `${artist.js}${albumPart} — ${title.js}`;
            } catch (error) {
                return '';
            }
        }
        """

        executeJavaScript(script) { [weak self] result in
            DispatchQueue.main.async {
                self?.statusItem?.button?.title = "🎵 " + result
            }
        }
    }

    private func executeJavaScript(_ script: String, completion: @escaping (String) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-l", "JavaScript", "-e", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Error"
            completion(output)
        } catch {
            completion("Loading...")
        }
    }

    @objc private func showMenu() {
        let menu = NSMenu()

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func quit() {
        timer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}
