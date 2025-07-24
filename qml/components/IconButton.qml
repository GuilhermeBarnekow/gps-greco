// Copyright (C) 2024 Michael Torrie and the QtAgOpenGPS Dev Team
// SPDX-License-Identifier: GNU General Public License v3.0 or later
//
// Main button. Checked, or icon. Gradual shading-- not all one solid color
import QtQuick
import QtQuick.Controls.Fusion
// import QtQuick.Effects  // Not available in Qt 6.4.2 - commented out temporarily

import ".."
import "../components"

Button {
    implicitWidth: 70 * theme.scaleWidth
    implicitHeight: 70 * theme.scaleHeight
    property var heightMinusPadding: implicitHeight - topPadding
    id: icon_button
    text: ""
    hoverEnabled: true
    //checkable: true
    icon.source: ""
    icon.color: "transparent"
	property alias imageFillMode: content_image.fillMode

    property double iconHeightScaleText: 0.75
    property int border: 2

    property bool disabled: false

    //property color color1: "#ffffff"
    //property color color2: "#cccccc"
    //property color color3: "#888888"
    property color color1: "transparent"
    property color color2: color1
    property color color3: color1

    property color colorHover1: "#ffffff"
    property color colorHover2: "#ffffff"
    property color colorHover3: "#888888"

    property color colorChecked1: "#c8e8ff"
    property color colorChecked2: "#7cc8ff"
    property color colorChecked3: "#467191"


    //For compatibility with the old IconButton and friends
    property bool isChecked: icon_button.checked

    property string buttonText: text
    property bool noText: false  //if no text-for iconButtonColor

    onIsCheckedChanged: {
        checked = isChecked;
    }

    //This is specific to this base type... must be re-implemented in subtypes
    onCheckedChanged: {
        if (checked && useIconChecked) {
            content_image.source = iconChecked
            //console.warn("icon should be ", content_image.source)
        } else {
            content_image.source = icon.source
            //console.warn("icon should be ", content_image.source)
        }

    }

    property url iconChecked: icon.source
    property bool useIconChecked: false

    onIconCheckedChanged: {
        if (iconChecked != "") {
            useIconChecked = true
        } else {
            useIconChecked = false
        }
    }

    property int radius: 10
    onRadiusChanged: {
        icon_button_background.radius = radius
    }

    onWidthChanged: {
        //console.warn(text, "Width is now ", width)
    }

    onHeightChanged: {
        //console.warn(height)
    }
    contentItem: Rectangle {
        id: icon_button_content
        anchors.fill: backgroundItem
        visible: !disabled
        color: "transparent"

        Text {
            id: text1
            text: if(icon_button.noText)//this way I can reuse iconButton on iconbuttoncolor
                      ""
                  else
                      icon_button.text
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height*0.02
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
            font.pixelSize: parent.height * 0.15
            z: 1
            visible: icon_button ? true : false
            color: enabled ? "black" : "grey"
        }

        Image {
            id: content_image
            width: parent.width
            anchors.fill: parent
            anchors.topMargin: parent.height * 0.00
            anchors.bottomMargin: icon_button.text  ?
                                      heightMinusPadding - heightMinusPadding * icon_button.iconHeightScaleText + heightMinusPadding * 0.00
                                    : heightMinusPadding * 0.02
            anchors.leftMargin: parent.width * 0.00
            anchors.rightMargin: parent.width * 0.00
            fillMode: Image.PreserveAspectFit
            source: icon_button.icon.source
        }

        // MultiEffect temporarily disabled - not available in Qt 6.4.2
        Rectangle {
            id: disableFilter
            anchors.fill: content_image
            color: "gray"
            opacity: 0.5
            visible: ! icon_button.enabled
        }


    }

    background: Item{
        id: backgroundItem
        Rectangle{
            anchors.fill: parent
            color: "transparent"
            visible: disabled
            MouseArea{
                anchors.fill: parent
                onClicked: {}
            }
        }

        Rectangle {
            visible: !disabled
            anchors.fill: parent
            border.width: icon_button.border
            border.color: enabled ? "black" : "grey"
            //border.width: icon_button.border
            radius: 10
            id: icon_button_background
            gradient: Gradient {
                GradientStop {
                    id: gradientStop1
                    position: 0
                    color: icon_button.color1
                }

                GradientStop {
                    id: gradientStop2
                    position: 0.5
                    color: icon_button.color2
                }

                GradientStop {
                    id: gradientStop3
                    position: 1
                    color: icon_button.color3
                }
            }

            states: [
                State {
                    when: icon_button.down
                    name: "pressedUnchecked"
                    PropertyChanges {
                        target: gradientStop1
                        color: icon_button.color3
                    }
                    PropertyChanges {
                        target: gradientStop2
                        color: icon_button.color3
                    }
                    PropertyChanges {
                        target: gradientStop3
                        color: icon_button.color1
                    }
                    /* PropertyChanges {
                    target: icon_button_background
                    border.width: 5
                }*/
                    /*
                PropertyChanges {
                    target: content_image
                    source: icon_button.icon.source
                }
                */

                },
                State {
                    when: icon_button.down && icon_button.checked
                    name: "pressedChecked"
                    PropertyChanges {
                        target: gradientStop1
                        color: icon_button.color3
                    }
                    PropertyChanges {
                        target: gradientStop2
                        color: icon_button.color3
                    }
                    PropertyChanges {
                        target: gradientStop3
                        color: icon_button.color1
                    }
                    /*   PropertyChanges {
                    target: icon_button_background
                    border.width: 1
                }*/
                    PropertyChanges {
                        target: content_image
                        source: icon_button.icon.source
                    }
                },
                State {
                    when: ! icon_button.down && icon_button.checked
                    name: "checked"
                    PropertyChanges {
                        target: gradientStop1
                        color: icon_button.colorChecked1
                    }
                    PropertyChanges {
                        target: gradientStop2
                        color: icon_button.colorChecked2
                    }
                    PropertyChanges {
                        target: gradientStop3
                        color: icon_button.colorChecked3
                    }
                    /* PropertyChanges {
                    target: icon_button_background
                    border.width: 0
                }*/
                    /*
                PropertyChanges {
                    target: content_image
                    source: (icon_button.iconChecked ? icon_button.iconChecked : icon_button.icon.source)
                }
                */
                },
                State {
                    when: ! icon_button.down && ! icon_button.checked && ! icon_button.hovered
                    name: "up"
                    PropertyChanges {
                        target: gradientStop1
                        color: icon_button.color1
                    }
                    PropertyChanges {
                        target: gradientStop2
                        color: icon_button.color2
                    }
                    PropertyChanges {
                        target: gradientStop3
                        color: icon_button.color3
                    }
                    /*PropertyChanges {
                    target: icon_button_background
                    border.width: 0
                }*/
                    /*
                PropertyChanges {
                    target: content_image
                    source: icon_button.icon.source
                }
                */
                },
                State {
                    when: icon_button.hovered
                    name: "hovered"
                    /* PropertyChanges {
                    target: icon_button_background
                    border.width: 1
                }*/
                    PropertyChanges {
                        target: gradientStop1
                        color: icon_button.colorHover1
                    }
                    PropertyChanges {
                        target: gradientStop2
                        color: icon_button.colorHover2
                    }
                    PropertyChanges {
                        target: gradientStop3
                        color: icon_button.colorHover3
                    }
                    /*
                PropertyChanges {
                    target: content_image
                    source: icon_button.icon.source
                }
                */
                }
            ]

        }
    }
}
