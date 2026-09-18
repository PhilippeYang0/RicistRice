pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

// RicistRice: caelestia draws the desktop wallpaper itself, so browsing
// wallpapers in the launcher previewed straight onto the desktop. Ours is
// drawn by awww (background.wallpaperEnabled is off in shell.json), so there
// was nothing for the preview to appear on. This lays the previewed wallpaper
// over awww's on the background window — which sits on the Bottom layer, one
// above awww's Background layer — and fades it away once the preview ends.
// awww itself is never touched, so cancelling a preview costs nothing: the
// overlay just fades out and the real wallpaper is there underneath, untouched.
//
// The image is caelestia's own Wallpaper component, pointed at the previewed
// path instead of the current one, so it crossfades between wallpapers the
// same way the real one would.
Item {
    id: root

    // A video is previewed as the still awww would put up for it, not played:
    // the launcher previews every item the selection passes over, and starting
    // a decoder for each would be far more than a preview is worth. "" until
    // theme.sh has extracted it, which keeps the preview down for that moment
    // rather than showing Wallpaper's "wallpaper missing?" card.
    readonly property string image: Wallpapers.stillOf(Wallpapers.previewPath)

    // Stays up for a moment after a preview that ended in the wallpaper
    // actually being picked: theme.sh has only just handed it to awww, and
    // fading out before awww has drawn it would flash the old wallpaper back.
    readonly property bool showing: (Wallpapers.showPreview || handover.running) && image !== ""

    Connections {
        target: Wallpapers

        function onShowPreviewChanged(): void {
            if (Wallpapers.showPreview)
                handover.stop();
            else if (Wallpapers.previewPath === Wallpapers.actualCurrent)
                handover.restart();
        }
    }

    Timer {
        id: handover

        // theme.sh runs awww first thing, so this only has to cover awww's own
        // transition; the fade out then hides any remainder
        interval: 1000
    }

    Loader {
        id: image

        anchors.fill: parent
        asynchronous: true

        opacity: root.showing ? 1 : 0
        active: opacity > 0 // dropped again between previews, it's a whole screen of pixels

        sourceComponent: Wallpaper {
            source: root.image
        }

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
