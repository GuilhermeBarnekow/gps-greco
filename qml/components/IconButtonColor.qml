// Copyright (C) 2024 Michael Torrie and the QtAgOpenGPS Dev Team
// SPDX-License-Identifier: GNU General Public License v3.0 or later
//
// Like IconButton, Just solid colors, though
import QtQuick
import QtQuick.Controls.Fusion
// import QtQuick.Effects  // Not available in Qt 6.4.2 - commented out temporarily

IconButton {
    implicitWidth: 120 * theme.scaleWidth
    implicitHeight: 80 * theme.scaleHeight
    id: icon_button

    //property alias border: icon_button_background.border
    //property alias radius: icon_button_background.radius
    border: 2

    property color borderColorEnabled: "black"
    property color borderColorDisabled: "grey"

    color1: color //redneck code
    color2: color
    color3: color

    noText: true //no text at the bottom- all at the top

    colorChecked1: colorChecked
    colorChecked2: colorChecked
    colorChecked3: colorChecked
    property color color: aog.backgroundColor
    property color colorChecked: "#99ff99"
    property color colorHover: "white"
    onButtonTextChanged: text = buttonText

    topInset: if(text.length>0)
                  text1.height
              else
                  0
    topPadding: if(text.length>0)
                  text1.height
              else
                  0
    MouseArea{
		visible: text.length>0
        id: textLabel
        width: icon_button.width
        height: text1.height
        anchors.top: parent.top
        onClicked: console.log("")
        Text {
            id: text1
            text: icon_button.text
            anchors.top: parent.top
            anchors.left: parent.left
            font.bold: true
            font.pixelSize: 15
        }
    }
}
