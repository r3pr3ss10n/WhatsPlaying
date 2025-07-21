# WhatsPlaying

A simple macOS menu bar app that displays the currently playing song in the menu bar.

![WhatsPlaying Screenshot](https://img1.pixhost.to/images/7386/624748132_tg_image_2401340531.png)

## Why?

After an update to the 15.4 version of macOS [NowPlayingMenuBar](https://github.com/TrevorBurnham/NowPlayingMenuBar) stopped working. It used MediaRemote framework directly, but Apple broke the APIs in macOS 15.4.

Every alternative to this app works only with Spotify or Apple music, i use neither. 

## How it works now?

So instead of using MediaRemote directly, this app uses a workaround:

1. Runs JavaScript via `osascript`
2. JavaScript loads MediaRemote framework at runtime
3. Grabs the current song info from the system
4. Updates menu bar every 2 seconds