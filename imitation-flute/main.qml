import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import Qt.WebSockets 1.0
import QtSensors 5.0
import "js-functions.js" as JS

ApplicationWindow {
    title: qsTr("Hello World")
    width: 640
    height: 480
    visible: true

    TiltSensor {
        id:tilt
        active:true

        onReadingChanged: { // TODO: sea ainult siis kui muutus on teatud määrast suurem
            panSlider.value = -reading.xRotation+50
            vibratoSlider.value = Math.abs(reading.yRotation*2)
        }
    }

    function setNote(x) {
        x = (x<=1) ? 1 : x ; // to avoid getting index 12 //(x>=controllerRect.width-1) ? controllerRect.width-1 : x;
        var noteStep = controllerRect.width/JS.notes;
        var noteHere = Math.floor((controllerRect.width - x) / noteStep);
        if (JS.note != noteHere) { // check if note has changed
            JS.note = noteHere;
            //udpSender.sendNumbersInString(JS.NEWSTEP.toString()+","+JS.note.toString());
            if (socket.status == WebSocket.Open)
                socket.sendTextMessage(JS.NEWSTEP.toString()+","+JS.note.toString()); // to be convertet in server
            console.log("New note:",JS.note);
            airColumnRect.width = (JS.notes - JS.note)*noteStep;
            noteLabel.text = qsTr("Note: ")+JS.note.toString();

        }


    }

    function setNoise(y) {
        var noiseStep = controllerRect.height/JS.noiseLevels;
        var noiseHere = Math.floor((controllerRect.height - y )/ noiseStep);
        if (JS.noiseLevel != noiseHere) { // check if note has changed
            JS.noiseLevel = noiseHere;
            //udpSender.sendNumbersInString(JS.NEWNOISE.toString()+","+JS.noiseLevel.toString()+","+JS.noiseLevels.toString()); // send maxSteps as 3rd parameter
            if (socket.status == WebSocket.Open)
                socket.sendTextMessage(JS.NEWNOISE.toString()+","+JS.noiseLevel.toString()+","+JS.noiseLevels.toString()); // to be convertet in server
            console.log("New noiseLevel:",JS.noiseLevel );
            noiseLabel.text = qsTr("Noise level: ")+JS.noiseLevel.toString();
        }


    }

    WebSocket {
        id: socket
        url: serverAddress.text //"ws://localhost:22022/ws"
        onTextMessageReceived: {
           console.log("Received message: ",message);
        }
        onStatusChanged: if (socket.status == WebSocket.Error) {
                             console.log("Error: " + socket.errorString)
                             socket.active = false;
                         } else if (socket.status == WebSocket.Open) {
                             console.log("Socket open")
                             //socket.sendTextMessage("Hello World")
                         } else if (socket.status == WebSocket.Closed) {
                             console.log("Socket closed")
                             socket.active = false;
                             //messageBox.text += "\nSocket closed"
                         }
        active: false
    }

    Component.onCompleted: {
        socket.active = true;
        console.log("TILT: ", tilt.outputRanges)
    }

    //Component.onCompleted: udpSender.setHostAddress("192.168.1.220")

    menuBar: MenuBar {
        Menu {
            title: qsTr("&Options")
            MenuItem {
                text: qsTr("&Host")
                onTriggered: messageDialog.show(qsTr("Open action triggered"));
            }
            MenuItem {
                text: qsTr("E&xit")
                onTriggered: Qt.quit();
            }
        }
    }

    MessageDialog { // TODO: for info etc
        id: messageDialog
    }

    Rectangle {
        id: mainRect
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#cdf505"
            }

            GradientStop {
                position: 1
                color: "#21221e"
            }
        }



        Row {
            x:5; y:5
            id: row1
            spacing: 5

            Label {
                text: qsTr("Server: ")
            }

            TextField {
                id: serverAddress
                width: 200
                text: "ws://192.168.1.220:22022/ws"
            }

            Button {
                id: connectButton
                enabled: !socket.active
                text: qsTr("Connect")
                onClicked: {
                    if (!socket.active)
                        socket.active = true;
                }
            }
        }

        Label {
            text: qsTr("Pan:")
            anchors.right: panSlider.left
            anchors.rightMargin: 10
            anchors.bottom: panSlider.bottom
        }

        Slider {
            id: panSlider
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: controllerRect.top
            anchors.bottomMargin: 10
            maximumValue: 100
            width: controllerRect.width/3
            stepSize: 1
            value: 50
            property int pan: -1

            onValueChanged: {
                var currentPan = Math.floor(value/10); // to send values only if change is big enough
                        if (currentPan != pan) {
                            pan = currentPan;
                            console.log("New pan: ", pan);
                            //doSendArray(new Int8Array([NEWPAN,pan]));
                            var sendString = JS.NEWPAN.toString() + "," + pan.toString()
                            console.log(sendString);
                            if (socket.status == WebSocket.Open)
                                socket.sendTextMessage(sendString); // to be convertet in server
                        }

            }


        }

        Slider {
            id: vibratoSlider
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: controllerRect.right
            anchors.leftMargin: 10
            orientation: Qt.Vertical
            height: controllerRect.height *1.2
            maximumValue: 100
            stepSize: 1
            value: 50
            property int vibrato: -1

            onValueChanged: {
                var currentV = Math.floor(value/10); // to send values only if change is big enough
                        if (currentV != vibrato) {
                            vibrato = currentV;
                            console.log("New vibrato: ", vibrato);
                            var sendString = JS.NEWVIBRATO.toString() + "," + vibrato.toString()
                            console.log(sendString);
                            if (socket.status == WebSocket.Open)
                                socket.sendTextMessage(sendString); // to be convertet in server
                        }

            }


        }

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
                gradient: Gradient {
                    GradientStop {
                        position: 0.00;
                        color: "#8b0000";
                    }
                    GradientStop {
                        position: 0.63;
                        color: "#eeb5b5";
                    }
                    GradientStop {
                        position: 1.00;
                        color: "#ffffff";
                    }
                }
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
                    //udpSender.sendNumbersInString(JS.NOTEON.toString());
                    if (socket.status == WebSocket.Open)
                        socket.sendTextMessage(JS.NOTEON.toString());
                    airColumnRect.visible = true;
                }
                onReleased: {
                    //udpSender.sendNumbersInString(JS.NOTEOFF.toString());
                    if (socket.status == WebSocket.Open)
                        socket.sendTextMessage(JS.NOTEOFF.toString());
                    airColumnRect.visible = false;
                    JS.note = -1; JS.noiseLevel = -1;
                }
                onMouseXChanged: if (containsPress) {
                                     setNote(mouseX)

                }

                onMouseYChanged: if (containsPress) {
                                     setNoise(mouseY);
                                     //console.log("Y:",mouseY)
                                     airColumnRect.height = (this.heigth/2 - mouseY) *2 // does not work...
                }




            }




        }


    Row {
        id:statusRow
        spacing: 5
        x: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5

        Label {
            id: noteLabel
            text: qsTr("note: 0")
        }

        Label {
            id: noiseLabel
            text: qsTr("noise: 0")
        }

        Label {
            id: tiltLabel
            text: qsTr("tilt x: " + Math.floor(tilt.reading.xRotation) + "y: " + Math.floor(tilt.reading.yRotation))
        }


    }


    }
}








