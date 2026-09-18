pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

Variants {
    model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).background.enabled)

    StyledWindow {
        id: win

        required property ShellScreen modelData

        screen: modelData
        name: "background"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: contentItem.Config.background.wallpaperEnabled ? WlrLayer.Background : WlrLayer.Bottom
        color: contentItem.Config.background.wallpaperEnabled ? "black" : "transparent"
        surfaceFormat.opaque: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        ShellState.ComponentRef {
            screen: win.screen
            slot: "background"
            component: win
        }

        Item {
            id: behindClock

            anchors.fill: parent

            Loader {
                id: wallpaper

                asynchronous: true

                anchors.fill: parent
                active: Config.background.wallpaperEnabled

                sourceComponent: Wallpaper {}
            }

            // RicistRice: awww draws the wallpaper for us, so the launcher's
            // preview needs a layer of its own (see WallpaperPreview.qml).
            // With the shell drawing it, the Wallpaper above previews by
            // itself — Wallpapers.current is the previewed path meanwhile.
            // RicistRice: awww can't play video, so a video wallpaper is
            // played here over awww's still of it. Only loaded while the
            // wallpaper actually is one — no MediaPlayer exists otherwise.
            // Declared before the preview below so the preview paints over it:
            // browsing away from a playing video has to cover it, not sit
            // under it. It follows actualCurrent, not current, for the same
            // reason — the video carries on playing behind a preview and is
            // still there when the preview is cancelled.
            // Loaded by file name rather than as a `sourceComponent:
            // VideoWallpaper {}`: naming the type resolves it when this file
            // compiles, even with active false, so a missing QtMultimedia
            // (qml6-module-qtmultimedia, see packages.txt) took the whole
            // config down with it — a black desktop and no shell at all.
            // Loading it by source keeps that failure inside this Loader.
            Loader {
                id: video

                asynchronous: true

                anchors.fill: parent
                active: !Config.background.wallpaperEnabled && Wallpapers.isVideo(Wallpapers.actualCurrent)
                source: "VideoWallpaper.qml"

                // Can't be set in a binding above, since the component isn't
                // named here; a video wallpaper replacing another one changes
                // the path while this stays loaded
                Binding {
                    target: video.item
                    property: "path"
                    value: Wallpapers.actualCurrent
                    when: video.status === Loader.Ready
                }
            }

            Loader {
                asynchronous: true

                anchors.fill: parent
                active: !Config.background.wallpaperEnabled

                sourceComponent: WallpaperPreview {}
            }

            Visualiser {
                anchors.fill: parent
                screen: win.modelData
                wallpaper: wallpaper
            }
        }

        Loader {
            id: clockLoader

            asynchronous: true
            active: Config.background.desktopClock.enabled

            anchors.margins: Tokens.padding.extraLargeIncreased
            anchors.leftMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)

            state: Config.background.desktopClock.position
            states: [
                State {
                    name: "top-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "top-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "top-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "middle-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "middle-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "middle-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "bottom-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "bottom-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "bottom-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                    }
                }
            ]

            transitions: Transition {
                AnchorAnim {}
            }

            sourceComponent: DesktopClock {
                wallpaper: behindClock
                absX: clockLoader.x
                absY: clockLoader.y
            }
        }
    }
}
