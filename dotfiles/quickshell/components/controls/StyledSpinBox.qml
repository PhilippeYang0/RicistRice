import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

// RicistRice: caelestia builds this on DoubleSpinBox, which only exists from
// Qt 6.11 (Arch). Ubuntu 26.04 has Qt 6.10, where the shell refused to load
// ("DoubleSpinBox is not a type"). This is the same control on the integer
// SpinBox: it counts in units of 1/valueScale (0.5 is stored as 5 when
// valueScale is 10), so decimal steps still work. Set the real* properties
// instead of from/to/stepSize/value, and read currentValue.
SpinBox {
    id: root

    property real realFrom: 0
    property real realTo: 99
    property real realStepSize: 1
    property real realValue: 0
    readonly property int decimals: realStepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(realStepSize))) : 0
    readonly property int valueScale: Math.pow(10, decimals)
    readonly property real currentValue: value / valueScale

    property int repeatRate: 400
    property int repeatDecay: 50
    property int cLayer: 1

    function increase(): void {
        value = Math.min(to, value + stepSize);
        valueModified();
    }

    function decrease(): void {
        value = Math.max(from, value - stepSize);
        valueModified();
    }

    from: Math.round(realFrom * valueScale)
    to: Math.round(realTo * valueScale)
    stepSize: Math.max(1, Math.round(realStepSize * valueScale))
    value: Math.round(realValue * valueScale)

    textFromValue: (v, locale) => Number(v / valueScale).toLocaleString(locale, "f", decimals)
    valueFromText: (text, locale) => Math.round(Number.fromLocaleString(locale, text) * valueScale)
    validator: DoubleValidator {
        bottom: root.realFrom
        top: root.realTo
        decimals: root.decimals
        notation: DoubleValidator.StandardNotation
        locale: root.locale.name
    }

    editable: true
    spacing: Tokens.spacing.small

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(up.indicator.implicitHeight, down.indicator.implicitHeight, contentItem.implicitHeight) + topPadding + bottomPadding

    leftPadding: up.indicator.implicitWidth + Tokens.spacing.extraSmall / 2
    rightPadding: down.indicator.implicitWidth + Tokens.spacing.extraSmall / 2

    contentItem: TextFieldBase {
        text: root.textFromValue(root.value, root.locale)

        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly

        leftPadding: Tokens.padding.medium
        rightPadding: Tokens.padding.medium

        implicitWidth: 65
        horizontalAlignment: TextField.AlignHCenter

        background: StyledRect {
            radius: Tokens.rounding.extraSmall
            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
        }
    }

    down.indicator: IconButton {
        id: downButton

        topRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
        bottomRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

        icon: "remove"
        disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
        color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
        type: IconButton.Text
        padding: Tokens.padding.extraSmall
        isRound: true
        label.anchors.horizontalCenterOffset: pressed ? 0 : 2
        disabled: !enabled

        Behavior on topRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on label.anchors.horizontalCenterOffset {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    up.indicator: IconButton {
        id: upButton

        anchors.right: parent.right

        topLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
        bottomLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

        icon: "add"
        disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
        color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
        type: IconButton.Text
        padding: Tokens.padding.extraSmall
        isRound: true
        label.anchors.horizontalCenterOffset: pressed ? 0 : -2
        disabled: !enabled

        Behavior on topLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on label.anchors.horizontalCenterOffset {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Timer {
        id: timer

        running: upButton.pressed || downButton.pressed
        onRunningChanged: {
            if (!running)
                interval = root.repeatRate;
        }

        interval: root.repeatRate
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (upButton.pressed)
                root.increase();
            else if (downButton.pressed)
                root.decrease();
            if (interval > root.repeatDecay)
                interval -= root.repeatDecay;
        }
    }
}
