# WhatsPlaying

A simple macOS menu bar app that displays the currently playing song in the menu bar.

![WhatsPlaying Screenshot](https://img1.pixhost.to/images/7386/624748132_tg_image_2401340531.png)

## Why?

After an update to the 15.4 version of macOS [NowPlayingMenuBar](https://github.com/TrevorBurnham/NowPlayingMenuBar) stopped working. It used MediaRemote framework directly, but Apple broke the APIs in macOS 15.4.

Every alternative to this app works only with Spotify or Apple music, i use neither. 

## How it works now?

This app now uses [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) - a library that provides stable access to MediaRemote on macOS 15.4+:

1. Uses Perl system binary which has entitlements to access MediaRemote
2. Runs `mediaremote-adapter.pl` script with bundled `MediaRemoteAdapter.framework`
3. Streams now playing information in real-time via JSON
4. Updates menu bar instantly when track changes

## Compatibility

- **macOS 15.4+**: Works using mediaremote-adapter
- **All music players**: Works with any app that uses MediaRemote (Apple Music, Spotify, TIDAL, Chrome, etc.)