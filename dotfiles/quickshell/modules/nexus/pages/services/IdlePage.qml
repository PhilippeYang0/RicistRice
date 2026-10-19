import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.modules.nexus.common

// RicistRice: not in caelestia. Edits general.idle.* (acted on by modules/IdleMonitors.qml).
// general.idle.timeouts is one list of rules, so every change reads the list, patches
// one rule and writes the whole list back. Rules are matched by their idleAction, and
// any other rule in the list (e.g. a custom command) is left as it is.
PageBase {
    id: root

    // Used when a rule is missing from the list and gets switched on (timeout in seconds)
    readonly property var defaults: ({
            lock: {
                timeout: 180,
                idleAction: "lock"
            },
            screen: {
                timeout: 300,
                idleAction: "dpms off",
                returnAction: "dpms on"
            },
            suspend: {
                timeout: 600,
                idleAction: ["suspendThenHibernate"]
            }
        })

    function kindOf(rule: var): string {
        const action = rule.idleAction;
        if (action === "lock")
            return "lock";
        if (action === "dpms off")
            return "screen";
        if (Array.isArray(action) && action.length === 1 && /^(suspend|hibernate)/i.test(action[0]))
            return "suspend";
        return "";
    }

    function rule(kind: string): var {
        return GlobalConfig.general.idle.timeouts.find(r => kindOf(r) === kind);
    }

    function isOn(kind: string): bool {
        const r = rule(kind);
        return !!r && (r.enabled ?? true);
    }

    function minutes(kind: string): real {
        return (rule(kind)?.timeout ?? defaults[kind].timeout) / 60;
    }

    function setRule(kind: string, patch: var): void {
        // Copy first: the property hands out the live list, which is not safe to edit in place
        const list = JSON.parse(JSON.stringify(GlobalConfig.general.idle.timeouts));
        let i = list.findIndex(r => kindOf(r) === kind);
        if (i < 0)
            i = list.push(JSON.parse(JSON.stringify(defaults[kind]))) - 1;
        Object.assign(list[i], patch);
        GlobalConfig.general.idle.timeouts = list;
    }

    title: Tr.tr("Idle & power")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Idle actions
        SectionHeader {
            first: true
            text: Tr.tr("When the PC is idle")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Lock the screen")
            subtext: Tr.tr("Show the lock screen after a period without input")
            checked: root.isOn("lock")
            onToggled: root.setRule("lock", {
                enabled: checked
            })
        }

        StepperRow {
            label: Tr.tr("Lock after (minutes)")
            enabled: root.isOn("lock")
            opacity: enabled ? 1 : 0.5
            value: root.minutes("lock")
            from: 1
            to: 240
            stepSize: 1
            onMoved: v => root.setRule("lock", {
                    timeout: Math.round(v * 60)
                })
        }

        ToggleRow {
            text: Tr.tr("Turn the screen off")
            subtext: Tr.tr("Switch the display off, and back on at the next input")
            checked: root.isOn("screen")
            onToggled: root.setRule("screen", {
                enabled: checked
            })
        }

        StepperRow {
            label: Tr.tr("Screen off after (minutes)")
            enabled: root.isOn("screen")
            opacity: enabled ? 1 : 0.5
            value: root.minutes("screen")
            from: 1
            to: 240
            stepSize: 1
            onMoved: v => root.setRule("screen", {
                    timeout: Math.round(v * 60)
                })
        }

        ToggleRow {
            text: Tr.tr("Suspend")
            subtext: Tr.tr("Suspend the PC (it hibernates later if it stays asleep)")
            checked: root.isOn("suspend")
            onToggled: root.setRule("suspend", {
                enabled: checked
            })
        }

        StepperRow {
            last: true
            label: Tr.tr("Suspend after (minutes)")
            enabled: root.isOn("suspend")
            opacity: enabled ? 1 : 0.5
            value: root.minutes("suspend")
            from: 1
            to: 240
            stepSize: 1
            onMoved: v => root.setRule("suspend", {
                    timeout: Math.round(v * 60)
                })
        }

        // Exceptions
        SectionHeader {
            text: Tr.tr("Exceptions")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Not while media is playing")
            subtext: Tr.tr("Skip all idle actions while a player is playing")
            checked: GlobalConfig.general.idle.inhibitWhenAudio
            onToggled: GlobalConfig.general.idle.inhibitWhenAudio = checked
        }

        ToggleRow {
            text: Tr.tr("Not while plugged in")
            subtext: Tr.tr("Skip all idle actions while on mains power")
            checked: GlobalConfig.general.idle.inhibitWhenCharging
            onToggled: GlobalConfig.general.idle.inhibitWhenCharging = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Lock before suspending")
            subtext: Tr.tr("Also lock when the PC is suspended by hand")
            checked: GlobalConfig.general.idle.lockBeforeSleep
            onToggled: GlobalConfig.general.idle.lockBeforeSleep = checked
        }

        // Right now
        SectionHeader {
            text: Tr.tr("Right now")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.trCtx("Keep awake", "idle inhibitor")
            subtext: Tr.tr("Block every idle action until switched off, e.g. during a long download")
            checked: IdleInhibitor.enabled
            onToggled: IdleInhibitor.enabled = checked
        }
    }
}
