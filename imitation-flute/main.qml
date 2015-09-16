import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import "js-functions.js" as JS

ApplicationWindow {
    title: qsTr("Hello World")
    width: 640
    height: 480
    visible: true

    function setNote(x) {
        x = (x>=controllerRect.width-1) ? controllerRect.width-1 : x;
        var noteStep = controllerRect.width/JS.notes;
        var noteHere = Math.floor(x / noteStep);
        if (JS.note != noteHere) { // check if note has changed
            JS.note = noteHere;
            udpSender.sendNumbersInString(JS.NEWSTEP.toString()+","+JS.note.toString());
            console.log("New note:",JS.note);
            airColumnRect.width = (JS.note+1)*noteStep;
            infoLabel.text = qsTr("Note: ")+JS.note.toString();

        }


    }

    function setNoise(y) {
        var noiseStep = controllerRect.height/JS.noiseLevels;
        var noiseHere = Math.floor((controllerRect.height - y )/ noiseStep);
        if (JS.noiseLevel != noiseHere) { // check if note has changed
            JS.noiseLevel = noiseHere;
            udpSender.sendNumbersInString(JS.NEWNOISE.toString()+","+JS.noiseLevel.toString()+","+JS.noiseLevels.toString()); // send maxSteps as 3rd parameter
            console.log("New noiseLevel:",JS.noiseLevel );
        }


}

    menuBar: MenuBar {
        Menu {
            title: qsTr("&File")
            MenuItem {
                text: qsTr("&Open")
                onTriggered: messageDialog.show(qsTr("Open action triggered"));
            }
            MenuItem {
                text: qsTr("E&xit")
                onTriggered: Qt.quit();
            }
        }
    }

    Rectangle {
        id: mainRect
        color: "#67e964"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.fill: parent




//        Button {
//            id: button1
//            x: -283
//            width: 126
//            height: 39
//            text: qsTr("Note ON")
//            anchors.top: parent.top
//            anchors.topMargin: 10
//            anchors.horizontalCenter: parent.horizontalCenter
//            onPressedChanged: {
//                var messageString;
//                if (button1.pressed) {
//                    var note = Math.floor(Math.random()*8);
//                    var noise = Math.floor(Math.random()*10);
//                    var noiseString = "101,"+noise.toString()+",10"; // last parameter NoiseSteps
//                    var noteString = "100," + note.toString();
//                    console.log(note, noise, noteString,noiseString);
//                    udpSender.sendNumbersInString(noiseString);
//                    udpSender.sendNumbersInString(noteString);
//                    messageString = "11";
//                } else {
//                    messageString = "10";
//                }
//                udpSender.sendNumbersInString(messageString);
//            }
//        }

        Rectangle {
            id: controllerRect

            width: parent.width*0.8
            height: 100

            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                id:airColumnRect
                color: "darkred"
                visible: false
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                height: parent.height/3 ; // TODO: sõltuv puudutuskohast
                width: JS.noteStep

            }

            MouseArea {
                id: controllerArea
                anchors.fill: parent

                onPressed: {
                    setNote(mouseX);
                    setNoise(mouseY);
                    udpSender.sendNumbersInString(JS.NOTEON.toString());
                    airColumnRect.visible = true;
                }
                onReleased: {
                    udpSender.sendNumbersInString(JS.NOTEOFF.toString());
                    airColumnRect.visible = false;
                    JS.note = -1; JS.noiseLevel = -1;
                }
                onMouseXChanged: if (containsPress) {
                                     setNote(mouseX)

                }

                onMouseYChanged: if (containsPress)
                                     setNoise(mouseY)




            }




        }
        Label {
            id: infoLabel
            x: 303
            text: qsTr("note: 0")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
        }
    }
}








