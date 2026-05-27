// lockscreen — SDDM greeter styled to match the hyprlock lock screen.
//
// Layout, top to bottom, centred on screen:
//   1. Date in Japanese  (month, day, weekday — e.g. 5月27日火曜日)
//   2. Large clock        (HH:MM)
//   3. Login card         (username + password, rounded corners + drop shadow)
//   4. Session selector + power buttons along the bottom.
//
// Colours are lifted from dotfiles/hypr/.config/hypr/hyprlock.conf so the two
// screens read as one design. SDDM 0.21 on Arch is a Qt6 build, so this uses
// QtQuick.Controls (Basic style) and Qt5Compat.GraphicalEffects for the shadow.

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#0c0e14"

    // ---- palette (from hyprlock.conf) ------------------------------------
    readonly property color cText:     "#e8eaf0"   // bright text / clock
    readonly property color cTextDim:  "#c8ccd4"   // date / secondary
    readonly property color cCard:     "#14161e"   // card / input inner
    readonly property color cOutline:  "#3d4a5c"   // input outline
    readonly property color cAccent:   "#8aa8c8"   // focus / check
    readonly property color cFail:     "#ea6962"   // failed login

    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property string jpFont:   "Noto Sans CJK JP"

    // ---- background image + darkening overlay ----------------------------
    Image {
        id: bg
        anchors.fill: parent
        source: config.background || "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: config.dimOpacity ? parseFloat(config.dimOpacity) : 0.45
    }

    // ---- live clock / date -----------------------------------------------
    function refreshClock() {
        var now = new Date()
        clock.text = Qt.formatTime(now, "HH:mm")
        // ja_JP gives "火曜日" for dddd; matches hyprlock's %-m月%-d日%A.
        dateLabel.text = now.toLocaleDateString(Qt.locale("ja_JP"), "M月d日dddd")
    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: refreshClock()
    }

    // ---- centre column ----------------------------------------------------
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Text {
            id: dateLabel
            Layout.alignment: Qt.AlignHCenter
            color: root.cTextDim
            font.family: root.jpFont
            font.pixelSize: 26
            renderType: Text.NativeRendering
        }

        Text {
            id: clock
            Layout.alignment: Qt.AlignHCenter
            color: root.cText
            font.family: root.monoFont
            font.pixelSize: 112
            font.weight: Font.Medium
            renderType: Text.NativeRendering
        }

        Item { Layout.preferredHeight: 36; width: 1 }   // gap before card

        // ---- login card ---------------------------------------------------
        Item {
            id: cardWrap
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: card.width
            implicitHeight: card.height

            // Drop shadow: DropShadow renders only the shadow, drawn behind the
            // still-interactive card, so the text fields keep receiving input.
            DropShadow {
                anchors.fill: card
                source: card
                horizontalOffset: 0
                verticalOffset: 10
                radius: 28
                samples: 33
                color: "#aa000000"
                z: -1
            }

            Rectangle {
                id: card
                width: 360
                height: cardCol.implicitHeight + 48
                radius: 18
                color: Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.82)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.06)

                ColumnLayout {
                    id: cardCol
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 14

                    // Username — prefilled with the last user; editable so this
                    // still works as a multi-user display manager, not just a
                    // single-seat lock screen.
                    TextField {
                        id: userField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        text: userModel.lastUser
                        color: root.cText
                        font.family: root.jpFont
                        font.pixelSize: 16
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 14
                        selectByMouse: true
                        placeholderText: "ユーザー名"
                        placeholderTextColor: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.4)
                        background: Rectangle {
                            radius: 10
                            color: Qt.rgba(0, 0, 0, 0.35)
                            border.width: userField.activeFocus ? 2 : 1
                            border.color: userField.activeFocus ? root.cAccent : root.cOutline
                        }
                        onAccepted: passwordField.forceActiveFocus()
                    }

                    // Password — the prominent field, like hyprlock's input.
                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        echoMode: TextInput.Password
                        color: root.cText
                        font.family: root.jpFont
                        font.pixelSize: 16
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 14
                        focus: true
                        placeholderText: "パスワード..."
                        placeholderTextColor: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.4)
                        background: Rectangle {
                            radius: 10
                            color: Qt.rgba(0, 0, 0, 0.35)
                            border.width: passwordField.activeFocus ? 2 : 1
                            border.color: errorLabel.visible ? root.cFail
                                          : (passwordField.activeFocus ? root.cAccent : root.cOutline)
                        }
                        onAccepted: doLogin()
                        Component.onCompleted: forceActiveFocus()
                    }

                    Text {
                        id: errorLabel
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        color: root.cFail
                        font.family: root.jpFont
                        font.pixelSize: 13
                        visible: text.length > 0
                        text: ""
                    }
                }
            }
        }

        // Caps Lock warning — sits between the card and the power buttons, and
        // collapses to zero height when off so nothing shifts.
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            color: root.cFail
            font.family: root.jpFont
            font.pixelSize: 13
            visible: keyboard.capsLock
            text: "⇪ Caps Lock がオンです"
        }

        // ---- reboot + shutdown, centred directly under the login card ------
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 22
            spacing: 16

            // Reboot — Nerd Font glyph (JetBrainsMono NF); circular, dark, with
            // an accent-tinted hover. Always shown; dimmed + disabled if logind
            // says the action isn't permitted (also the case in --test-mode).
            ToolButton {
                id: rebootBtn
                text: ""            // nf-fa-refresh
                enabled: sddm.canReboot
                opacity: enabled ? 1.0 : 0.4
                ToolTip.visible: hovered
                ToolTip.text: "再起動"
                contentItem: Text {
                    text: rebootBtn.text; color: root.cTextDim
                    font.family: root.monoFont; font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 42; implicitHeight: 42; radius: 21
                    color: rebootBtn.hovered ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.22)
                                             : Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.75)
                    border.width: 1
                    border.color: rebootBtn.hovered ? root.cAccent : root.cOutline
                }
                onClicked: sddm.reboot()
            }

            // Shutdown — same treatment, red-tinted hover.
            ToolButton {
                id: powerBtn
                text: ""            // nf-fa-power_off
                enabled: sddm.canPowerOff
                opacity: enabled ? 1.0 : 0.4
                ToolTip.visible: hovered
                ToolTip.text: "電源を切る"
                contentItem: Text {
                    text: powerBtn.text; color: root.cTextDim
                    font.family: root.monoFont; font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 42; implicitHeight: 42; radius: 21
                    color: powerBtn.hovered ? Qt.rgba(root.cFail.r, root.cFail.g, root.cFail.b, 0.22)
                                            : Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.75)
                    border.width: 1
                    border.color: powerBtn.hovered ? root.cFail : root.cOutline
                }
                onClicked: sddm.powerOff()
            }
        }
    }

    // ---- bottom bar: session selector (bottom-right) ---------------------
    RowLayout {
        id: bottomBar
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12

        ComboBox {
            id: sessionBox
            model: sessionModel
            currentIndex: sessionModel.lastIndex
            textRole: "name"
            Layout.preferredWidth: 200
            font.family: root.jpFont
            font.pixelSize: 13
            // Minimal dark styling for the Basic Controls style.
            contentItem: Text {
                leftPadding: 10
                text: sessionBox.displayText
                color: root.cTextDim
                font: sessionBox.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle {
                radius: 8
                color: Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.75)
                border.width: 1
                border.color: root.cOutline
            }
        }
    }

    // ---- login plumbing ---------------------------------------------------
    function doLogin() {
        errorLabel.text = ""
        sddm.login(userField.text, passwordField.text, sessionBox.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorLabel.text = "認証失敗 ・ もう一度"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            errorLabel.text = ""
        }
    }
}
