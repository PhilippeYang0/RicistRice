pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.services

// RicistRice: decides when a video wallpaper should stop playing, adapted from
// caelestia-aw's service of the same name. Decoding video costs GPU and
// battery all the time, but the wallpaper is only worth decoding when some of
// it is actually on screen — so playback stops when windows cover it, and on
// battery.
//
// The thresholds below are plain constants rather than shell.json settings:
// the config keys live in caelestia's C++ plugin, which we build from a pinned
// upstream commit (scripts/build-shell.sh), so adding one would mean carrying
// a patch to it. Edit them here instead.
Singleton {
    id: root

    // Pause on battery. Only ever true on a laptop; a desktop has no battery
    // for UPower to report, so this costs nothing there.
    readonly property bool pauseOnBattery: true
    // Pause when windows cover the wallpaper
    readonly property bool pauseWhenCovered: true
    // A single window taking this much of the monitor counts as covering it
    readonly property real coverage: 0.7
    // ...and this many windows on the workspace do too, however big they are:
    // tiled side by side they leave nothing but gaps showing
    readonly property int coveringWindows: 2

    property bool paused: false
    // What paused it, for working out why the wallpaper stopped
    property string reason: "nothing"

    function recalculate(): void {
        if (pauseOnBattery && UPower.onBattery && UPower.displayDevice.isLaptopBattery) {
            paused = true;
            reason = "on battery";
            return;
        }

        if (pauseWhenCovered) {
            const monitor = Hypr.focusedMonitor;
            const ws = monitor?.activeWorkspace ?? Hypr.focusedWorkspace;
            const windows = ws?.toplevels.values ?? [];

            if (windows.length >= coveringWindows) {
                paused = true;
                reason = `${windows.length} windows on the workspace`;
                return;
            }

            const screen = monitor ? Quickshell.screens.find(s => s.name === monitor.name) : null;
            const area = screen ? screen.width * screen.height : 0;
            if (area > 0) {
                for (const w of windows) {
                    const size = w.lastIpcObject?.size;
                    if (size?.length >= 2 && size[0] * size[1] >= area * coverage) {
                        paused = true;
                        reason = `${w.lastIpcObject?.title ?? "a window"} covers the wallpaper`;
                        return;
                    }
                }
            }
        }

        paused = false;
        reason = "nothing";
    }

    Connections {
        // The raw Hyprland singleton, not qs.services' Hypr wrapper: Hypr
        // re-emits only the events it cares about, and these aren't among them
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            // Anything that can change which windows are on the focused
            // workspace, or how big they are
            if (event.name.startsWith("workspace") || event.name.startsWith("activewindow") || ["openwindow", "closewindow", "movewindow", "moveworkspace", "fullscreen", "changefloatingmode", "focusedmon", "resizeactivewindow"].includes(event.name))
                recalcTimer.restart();
        }
    }

    Connections {
        target: UPower

        function onOnBatteryChanged(): void {
            recalcTimer.restart();
        }
    }

    // Hyprland reports a window before it has been given its final size, and a
    // burst of events arrives for one action; settle before measuring
    Timer {
        id: recalcTimer

        interval: 100
        onTriggered: root.recalculate()
    }

    // Hyprland's state arrives asynchronously, so the first reading can be of
    // an empty workspace list. Re-check for a few seconds after startup.
    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true

        property int attempts: 0

        onTriggered: {
            root.recalculate();
            if (++attempts >= 5)
                running = false;
        }
    }
}
