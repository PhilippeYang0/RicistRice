-- Everything tweakable in one place: apps, look, and keybinds. Adapted from
-- caelestia's variables.lua; the modules in hyprland/ read these.
local scheme = require("utils.colours")

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    -- Apps (caelestia defaults foot/codium/thunar/pwvucontrol aren't installed here)
    terminal                   = "alacritty",
    browser                    = "firefox",
    editor                     = "mousepad",
    fileExplorer               = "nemo",
    audioSettings              = "pavucontrol",

    -- Keyboard. Hyprland has been running "us" (its default); Cinnamon uses "fr".
    -- Workspace binds use keycodes, so they work with either layout.
    kbLayout                   = "us",

    -- Touchpad
    touchpadDisableTyping      = true,
    touchpadScrollFactor       = 0.3,
    gestureFingers             = 3,
    workspaceSwipeFingers      = 4,
    gestureFingersMore         = 4,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 8,
    blurPasses                 = 2,
    blurXray                   = false,

    -- Shadow
    shadowEnabled              = true,
    shadowRange                = 15,
    shadowRenderPower          = 4,
    shadowColour               = "rgba(" .. scheme.inversePrimary .. "10)",

    -- Gaps
    workspaceGaps              = 20,
    windowGapsIn               = 5,
    windowGapsOut              = 10,
    singleWindowGapsOut        = 20,

    -- Window styling
    windowOpacity              = 0.95,
    windowRounding             = 15,
    windowBorderSize           = 1,
    activeWindowBorderColour   = "rgba(" .. scheme.primary .. "e6)",
    inactiveWindowBorderColour = "rgba(" .. scheme.onSurfaceVariant .. "11)",

    -- Misc
    volumeStep                 = 10,
    volumeMax                  = 100,
    cursorTheme                = "Yaru", -- same cursor Cinnamon uses
    cursorSize                 = 24,
    sleepGestureCmd            = "systemctl suspend", -- caelestia's suspend-then-hibernate needs hibernation set up

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Modifier only, the actual binds will be mod + 0-9. These should be strings and not arrays.
    -- RicistRice: swapped vs caelestia, which had move-window on SUPER + ALT and
    -- workspace groups on CTRL + SUPER. Now CTRL always means "bring the window
    -- with you" and ALT always means "workspace group", so the four read as a grid.
    kbGoToWs                   = "SUPER",
    kbMoveWinToWs              = "CTRL + SUPER",
    kbGoToWsGroup              = "SUPER + ALT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",

    -- All the following binds can be either an array of binds to bind multiple keys, or a single string.

    -- Workspaces
    kbMoveWinToWsSpecial       = { "SUPER + ALT + S", "CTRL + SUPER + SHIFT + Up" },
    kbMoveWinFromWsSpecial     = "CTRL + SUPER + SHIFT + Down",
    kbMoveWinToWsNext          = { "SUPER + ALT + mouse_down", "SUPER + ALT + Page_Down", "CTRL + SUPER + SHIFT + Right" },
    kbMoveWinToWsPrev          = { "SUPER + ALT + mouse_up", "SUPER + ALT + Page_Up", "CTRL + SUPER + SHIFT + Left" },
    -- RicistRice: CTRL + SUPER + Left/Right dropped from these two, they now
    -- move the whole workspace between monitors (kbMoveWsToMon* below).
    kbNextWs                   = { "SUPER + mouse_down", "SUPER + Page_Down" },
    kbPrevWs                   = { "SUPER + mouse_up", "SUPER + Page_Up" },
    -- RicistRice: send the current workspace to the monitor on that side
    kbMoveWsToMonLeft          = "CTRL + SUPER + Left",
    kbMoveWsToMonRight         = "CTRL + SUPER + Right",
    kbNextWsGroup              = "CTRL + SUPER + mouse_down",
    kbPrevWsGroup              = "CTRL + SUPER + mouse_up",

    -- Window Group
    kbWindowCycleNext          = "ALT + TAB",
    kbWindowCyclePrev          = "SHIFT + ALT + TAB",
    kbWindowGroupCycleNext     = "CTRL + ALT + TAB",
    kbWindowGroupCyclePrev     = "CTRL + SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + U",
    kbToggleGroup              = "SUPER + Comma",
    kbGroupLockActive          = "SUPER + SHIFT + Comma",

    -- Window Actions
    kbWindowDecreaseWidth      = { "SUPER + Minus", "SUPER + ALT + Left" },
    kbWindowIncreaseWidth      = { "SUPER + Equal", "SUPER + ALT + Right" },
    kbWindowDecreaseHeight     = { "SUPER + SHIFT + Minus", "SUPER + ALT + Up" },
    kbWindowIncreaseHeight     = { "SUPER + SHIFT + Equal", "SUPER + ALT + Down" },

    kbMoveWindow               = "SUPER + Z",
    kbResizeWindow             = "SUPER + X",
    kbCenterWindow             = "CTRL + SUPER + Backslash",
    kbNormalizeWindow          = "CTRL + SUPER + ALT + Backslash",
    kbWindowPip                = "SUPER + ALT + Backslash",
    kbPinWindow                = "SUPER + P",
    kbWindowFullscreen         = "SUPER + F",
    kbWindowBorderedFullscreen = "SUPER + ALT + F",
    kbToggleWindowFloating     = "SUPER + ALT + Space",
    kbCloseWindow              = "SUPER + Q",

    -- Special workspaces toggles
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + M",
    kbCommunicationWs          = "SUPER + D",
    -- (caelestia's Super+R todo workspace dropped: it launches todoist)

    -- Apps (Super+Return kept from the old hyprland.conf)
    kbTerminal                 = { "SUPER + T", "SUPER + Return" },
    kbBrowser                  = "SUPER + W",
    kbEditor                   = "SUPER + C",
    kbFileExplorer             = "SUPER + E",
    kbAudioSettings            = "CTRL + ALT + V",

    -- Utilities
    kbScreenshot               = "Print",
    kbScreenshotFreeze         = "SUPER + SHIFT + S",
    kbScreenshotRegion         = "SUPER + SHIFT + ALT + S",
    -- (caelestia's Ctrl+Alt+R screen recording binds dropped: they need the caelestia CLI)
    kbColorPicker              = "SUPER + SHIFT + C",

    -- Media
    kbMediaToggle              = "CTRL + SUPER + Space",
    kbMediaNext                = "CTRL + SUPER + Equal",
    kbMediaPrev                = "CTRL + SUPER + Minus",
    kbMediaStop                = "CTRL + SUPER + Backspace",
    kbVolumeMute               = "SUPER + SHIFT + M",

    -- Misc
    kbLauncher                 = "SUPER + SUPER_L",
    kbSession                  = "CTRL + ALT + Delete",
    kbShowSidebar              = "SUPER + N",
    kbClearNotifs              = "CTRL + ALT + C",
    kbShowPanels               = "SUPER + K",
    kbLock                     = "SUPER + L",
    kbRestoreLock              = "SUPER + ALT + L",
    kbSleep                    = "SUPER + SHIFT + L",
    -- Log out without the shell's session menu (Ctrl+Alt+Delete), in case the
    -- shell isn't running. Replaces the old Super+M, which caelestia uses for music.
    kbExit                     = "SUPER + SHIFT + E",

    -- Clipboard history via rofi (caelestia's picker and emoji picker need its CLI)
    kbClipboard                = "SUPER + V",
    kbClipboardDel             = "SUPER + ALT + V",
}
