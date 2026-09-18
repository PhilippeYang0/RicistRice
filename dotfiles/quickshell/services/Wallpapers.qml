pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    // RicistRice: video wallpapers. These are the extensions theme.sh's
    // still_of treats as video (video_exts) and that random_wallpaper finds,
    // so the two must be changed together.
    readonly property list<string> validVideoExtensions: ["mp4", "webm", "mkv"]

    // Paths whose still theme.sh has handed over, path -> still path ("" when
    // it couldn't be extracted, so a broken video is only attempted once).
    // Replaced wholesale rather than edited, so bindings on it re-evaluate.
    property var stills: ({})
    // var, not list<string>: a value-type list hands JS a copy, so pushing to
    // it would quietly do nothing and every video would be asked for forever
    property var stillQueue: []
    // What getPreviewColoursProc is generating colours for, which lags
    // previewPath while the list is being scrolled (see preview())
    property string previewColoursPath

    function isVideo(path: string): bool {
        if (!path)
            return false;
        const ext = path.slice(path.lastIndexOf(".") + 1).toLowerCase();
        return validVideoExtensions.includes(ext);
    }

    // RicistRice: an image standing in for PATH — PATH itself when it is one,
    // and a frame extracted from the video when it isn't. Videos are drawn as
    // that still everywhere except the desktop itself, where VideoWallpaper
    // plays them: the launcher's list and preview would otherwise ask Qt to
    // load an mp4 as an image and get nothing.
    //
    // Extracting costs an ffmpeg run, so theme.sh caches it; it also owns
    // where the cache is, and is asked for the path rather than the shell
    // working it out, so there is one answer rather than two that must agree.
    // Returns "" until the answer arrives — callers show their placeholder
    // meanwhile and update when it does.
    function stillOf(path: string): string {
        if (!isVideo(path))
            return path;
        if (stills[path] !== undefined)
            return stills[path];
        requestStill(path);
        return "";
    }

    function requestStill(path: string): void {
        if (stills[path] !== undefined || stillQueue.includes(path))
            return;
        stillQueue.push(path);
        if (!stillProc.running)
            nextStill();
    }

    // One at a time: scrolling a folder of videos would otherwise start an
    // ffmpeg for every one of them at once
    function nextStill(): void {
        if (stillQueue.length === 0)
            return;
        stillProc.path = stillQueue[0];
        stillProc.running = true;
    }

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        Quickshell.execDetached([Paths.themeCmd, "wallpaper", "-r", ...smartArg]);
    }

    function setWallpaper(path: string): void {
        // RicistRice: if the colours being previewed are this wallpaper's,
        // keep them up until theme.sh's real ones land, so picking one doesn't
        // flash the old colours back in between. caelestia set this in the
        // launcher's search bar only, and only for its dynamic scheme; here
        // any theme's colours can follow the wallpaper (see preview()), and
        // clicking an item has to hold them too.
        previewColourLock = Colours.showPreview && path === previewPath;
        actualCurrent = path;
        Quickshell.execDetached([Paths.themeCmd, "wallpaper", "-f", path, ...smartArg]);
    }

    // The theme whose wallpaper folder PATH is in, or "" for one sitting
    // loose in the wallpaper folder. Mirrors theme_for_wallpaper in theme.sh,
    // except that it can't tell a folder that is a theme from one that isn't.
    function themeOf(path: string): string {
        if (!path.startsWith(`${Paths.wallsdir}/`))
            return "";
        const rel = path.slice(Paths.wallsdir.length + 1);
        const slash = rel.indexOf("/");
        return slash === -1 ? "" : rel.slice(0, slash);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        // RicistRice: caelestia only previews colours for its dynamic scheme,
        // since each of its other ones is a fixed palette. Ours also switches
        // theme when the wallpaper comes from another theme's folder
        // (adopt_theme_of in theme.sh), and theme.sh's `wallpaper -p` prints
        // the colours the pick would really give either way — so preview that
        // case too, and skip the work when neither applies. Skipping is only
        // right because dynamic is the one theme seeded from the wallpaper:
        // another theme taking "seed wallpaper" would want previewing within
        // its own folder too.
        const theme = themeOf(path);
        if (Colours.scheme === "dynamic" || (theme && theme !== Colours.scheme))
            previewColoursTimer.restart();
    }

    // A run costs around a second (matugen), and the launcher previews every
    // item the selection passes over, so wait for it to settle first
    function generatePreviewColours(): void {
        if (getPreviewColoursProc.running)
            return; // onExited picks up the latest path instead
        previewColoursPath = previewPath;
        getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        previewColoursTimer.stop();
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        // RicistRice: the lock is cleared by the new wallpaper reaching
        // path.txt below. Should theme.sh never get that far (it failed, or
        // the wallpaper picked was already the current one), let go anyway
        // rather than leave the preview colours up for good.
        if (previewColourLock)
            previewColourLockTimeout.restart();
        else if (pendingPreviewClear) {
            pendingPreviewClear = false;
            Colours.showPreview = false;
        }
    }

    Timer {
        id: previewColourLockTimeout

        interval: 5000
        onTriggered: root.previewColourLock = false
    }

    Timer {
        id: previewColoursTimer

        interval: 150
        onTriggered: root.generatePreviewColours()
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached([Paths.themeCmd, "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached([Paths.themeCmd, "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    Process {
        id: stillProc

        property string path

        command: [Paths.themeCmd, "thumb", path]
        stdout: StdioCollector {
            onStreamFinished: {
                const next = Object.assign({}, root.stills);
                next[stillProc.path] = text.trim();
                root.stills = next;
            }
        }
        onExited: {
            // Whether or not it worked — a video that can't be read is now
            // recorded as "" and won't be asked for again
            if (root.stills[stillProc.path] === undefined) {
                const next = Object.assign({}, root.stills);
                next[stillProc.path] = "";
                root.stills = next;
            }
            root.stillQueue = root.stillQueue.filter(p => p !== stillProc.path);
            root.nextStill();
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        // RicistRice: was FileSystemModel.Images, which also filters by
        // QImageReader.canRead() and so drops every video whatever the name
        // filters say. Files with an explicit list takes videos too; keep it
        // in step with theme.sh's random_wallpaper, which finds the same set.
        filter: FileSystemModel.Files
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp", "*.tif", "*.tiff", ...root.validVideoExtensions.map(e => `*.${e}`)]
    }

    Process {
        id: getPreviewColoursProc

        command: [Paths.themeCmd, "wallpaper", "-p", root.previewColoursPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                // RicistRice: the preview can end while this is still running,
                // and putting its colours up then would leave them up with
                // nothing left to clear them
                if (!root.showPreview)
                    return;
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
        onExited: {
            // The selection moved on while this was running
            if (root.showPreview && root.previewPath !== root.previewColoursPath)
                root.generatePreviewColours();
        }
    }
}
