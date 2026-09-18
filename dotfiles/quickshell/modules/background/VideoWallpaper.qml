pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import qs.components
import qs.services

// RicistRice: awww draws images and GIFs but can't play video, so a video
// wallpaper is played here instead, on the shell's background window — which
// sits on the Bottom layer, one above awww's Background layer.
//
// awww still holds the video's own extracted frame underneath (still_of in
// theme.sh), and that is what does the work a second video player does in
// caelestia-aw, which this is adapted from. It renders every wallpaper itself,
// so it has nothing behind the video and needs two MediaPlayers, loading the
// next video in the hidden one and only swapping once it reports LoadedMedia,
// purely to avoid a black frame. Here the frame underneath is already the
// right one for the incoming video, so one player is enough: while it loads,
// and whenever playback is paused, awww's still shows through.
Item {
    id: root

    // Not `required`: Background.qml loads this by source rather than by type
    // (see the comment there), and a Loader can't fill in a required property
    property string path

    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState

    // Paths come from FileSystemModel unencoded, and a wallpaper named with a
    // space or a "#" would otherwise cut the URL short. Encoding per segment
    // keeps the separators as separators.
    function fileUrl(p: string): string {
        return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : "";
    }

    function apply(): void {
        if (WallpaperPauser.paused)
            player.pause();
        else
            player.play();
    }

    // Fade in over awww's still rather than cutting to it: the still is taken
    // from 30% into the video, so it isn't the frame playback starts on
    opacity: playing ? 1 : 0

    Behavior on opacity {
        Anim {
            type: Anim.SlowEffects
        }
    }

    VideoOutput {
        id: output

        anchors.fill: parent
        // Same framing as a wallpaper image (CachingImage's PreserveAspectCrop)
        fillMode: VideoOutput.PreserveAspectCrop
    }

    MediaPlayer {
        id: player

        videoOutput: output
        audioOutput: null // a wallpaper with sound would be a surprise
        loops: MediaPlayer.Infinite
        source: root.fileUrl(root.path)

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia)
                root.apply();
            else if (mediaStatus === MediaPlayer.InvalidMedia)
                console.warn("VideoWallpaper: cannot play", root.path, "-", errorString);
        }

        onErrorOccurred: (error, errorString) => {
            if (error !== MediaPlayer.NoError)
                console.warn("VideoWallpaper:", root.path, "-", errorString);
        }
    }

    Connections {
        target: WallpaperPauser

        function onPausedChanged(): void {
            root.apply();
        }
    }
}
