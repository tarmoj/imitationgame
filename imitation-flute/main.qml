import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.2
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtWebSockets 1.0
import QtSensors 5.0
import "js-functions.js" as JS

ApplicationWindow {
    title: qsTr("Flute-instrument")
    width: 660
    height: 480
    visible: true

    TiltSensor { //TODO: add a checkbox : use tilt sensor for pan and vibrato -  checked
        id:tilt
        active: tiltCheckBox.checked//true

        onReadingChanged: { // TODO: sea ainult siis kui muutus on teatud määrast suurem
            if (tiltCheckBox.checked) {
                var convert2pan =  reading.xRotation+50
                convert2pan = Math.max(panSlider.minimumValue ,Math.min(convert2pan,panSlider.maximumValue )) // limit to 0..100
                if (Math.abs(convert2pan-panSlider.value) > 5 ) {
                    panSlider.value = convert2pan
                    //temporary -  use it for volume, too:
                    volumeSlider.value = convert2pan
                }

                var convert2vibrato = Math.abs(reading.yRotation*2)
                convert2vibrato = Math.max(vibratoSlider.minimumValue ,Math.min(convert2vibrato,vibratoSlider.maximumValue )) // limit to 0..100
                if (Math.abs(convert2vibrato-vibratoSlider.value) > 10 )
                    vibratoSlider.value = convert2vibrato

            }
        }

    }

    function setNote(x) {
        x = (x<=1) ? 1 : x ; // to avoid getting index 12 //(x>=controllerRect.width-1) ? controllerRect.width-1 : x;
        var noteStep = controllerArea.width/JS.notes;
        var noteHere = Math.floor((controllerArea.width - x) / noteStep);
        if (JS.note != noteHere) { // check if note has changed
            JS.note = noteHere;
            //            if (socket.status == WebSocket.Open)
            //                socket.sendTextMessage(JS.NEWSTEP.toString()+","+JS.note.toString()); // to be convertet in server
            console.log("New note:",JS.note);
            csound.setChannel("step", JS.note)
            //csound.compileOrc(" gkValue init " + JS.note/11.0)
            airColumnRect.width = (controllerArea.x -  airColumnRect.x) + (JS.notes - JS.note)*noteStep; // start the air rect from embouchure, controller starts from the keys
            noteLabel.text = qsTr("Note: ")+JS.note.toString();


        }


    }

    function setNoise(y) {
        var noiseStep = controllerRect.height/JS.noiseLevels;
        var noiseHere = Math.floor((controllerRect.height - y )/ noiseStep);
        if (JS.noiseLevel != noiseHere) { // check if note has changed
            JS.noiseLevel = noiseHere;
            //            if (socket.status == WebSocket.Open)
            //                socket.sendTextMessage(JS.NEWNOISE.toString()+","+JS.noiseLevel.toString()+","+JS.noiseLevels.toString()); // to be convertet in server
            console.log("New noiseLevel:",JS.noiseLevel );
            csound.setChannel("noise", JS.noiseLevel/10)
            noiseLabel.text = qsTr("Noise level: ")+JS.noiseLevel.toString();
        }


    }

    WebSocket {
        id: socket
        url: "ws://192.168.1.130:11011/ws"
        onTextMessageReceived: {
            console.log("Received message: ",message);
            if (message.split(" ")[0]==="i2") {
                console.log("i2 message", message)
                csound.csEvent(message)
            }

            if (message.split(" ")[0]==="paused") {
                coverRect.visible = true
            }

            if (message.split(" ")[0]==="continue") {
                coverRect.visible = false
            }

        }
        onStatusChanged: if (socket.status == WebSocket.Error) {
                             console.log("Error: " + socket.errorString)
                             socket.active = false;
                             connectButton.text = "Connect"
                         } else if (socket.status == WebSocket.Connecting) {
                             connectButton.text = "Connecting"
                         } else if (socket.status == WebSocket.Open) {
                             console.log("Socket open")
                             connectButton.text = "Connected"
                         } else if (socket.status == WebSocket.Closed) {
                             console.log("Socket closed")
                             socket.active = false;
                             connectButton.text = "Connect"
                         }
        active: false
    }

    Component.onCompleted: {
        socket.active = true;
    }



    MessageDialog { // TODO: for info etc
        id: messageDialog
        title: qsTr("instructions  - imitation flute")
        text: qsTr("Touch the flute on its keys to play a note. \n"+
                   "Lower keys (longer aircolumn) play lower notes.\n"+
                   "\nIf you move finger or mouse up in the dark control area, the sound will get more noisy.\n"+
                   "You can control volume and vibrato intensity with tilting the device.\nVolume (x-axis): tilt the left or right side of the phone up or down\nVibrato (y axis): turn the screen from horizontal position to up or down\n" +
                   "You can swich out the sensor control (uncheck \'Use tilting\') and move thse sliders by hand\n\nThe app sends signal about your actions to server that plays the sounds for you. The app does not make any sound itself.\n"+
                   "If \'Connect\' button is grayed out, you are connected and ready to go.")
        onAccepted: {
            visible = false
        }
    }

    Rectangle {
        id: mainRect
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0;
                color: "#cdf505";
            }

            GradientStop {
                position: 0.3;
                color: "#21221e";
            }

            GradientStop {
                position: 0.7;
                color: "#21221e";
            }
            GradientStop {
                position: 1;
                color: "#cdf505";
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
                width: mainRect.width/2 // was 200
                text: "ws://192.168.1.130:11011/ws"
            }

            Button {
                id: connectButton
                enabled: !(socket.status==WebSocket.Open)
                text: qsTr("Connect")
                onClicked: {
                    if (!socket.active) {
                        socket.url = serverAddress.text
                        console.log("Connecting to ",socket.url)
                        socket.active = true;
                    }
                }
            }


        }

        Button {
            id: helButton
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.bottom: row1.bottom
            text: qsTr("Help");
            onClicked: messageDialog.visible = true
        }

        Row {
            id: sliderRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: controllerRect.top
            anchors.bottomMargin: 10
            spacing: 8

            CheckBox {
                id: tiltCheckBox
                style: CheckBoxStyle {label: Text {color:"#cdf505";
                        text: qsTr("Use tilting") } }
                checked: true

            }

            Label {
                text: qsTr("Volume: ")
                color: "#cdf505"
            }


            Slider {
                id: volumeSlider
                width: mainRect.width/5 // 150
                maximumValue: 100
                stepSize: 1
                value: 50

                onValueChanged: {
                    csound.setChannel("volume", value/100.0)
                }

            }

            Label {
                text: qsTr("Pan (Left<->Right): ")
                color: "#cdf505"
                visible: false
            }


            Slider {
                visible: false
                id: panSlider
                width: mainRect.width/5 // 150
                maximumValue: 100
                stepSize: 1
                value: 50
                property int pan: -1

                onValueChanged: {
                    var currentPan = Math.floor(value/10); // to send values only if change is big enough
                    if (currentPan != pan) {
                        pan = currentPan;
                        console.log("New pan: ", pan);
                        /*                        var sendString = JS.NEWPAN.toString() + "," + pan.toString()
                        console.log(sendString);
                        if (socket.status == WebSocket.Open)
                            socket.sendTextMessage(sendString); // to be convertet in server*/

                    }

                }


            }

            Label {
                text: qsTr("Vibrato: ")
                color: "#cdf505"

            }

            Slider {
                id: vibratoSlider
                width: panSlider.width//150
                maximumValue: 100
                stepSize: 1
                value: 0
                property int vibrato: -1

                onValueChanged: {
                    var currentV = Math.floor(value/10); // to send values only if change is big enough
                    if (currentV != vibrato) {
                        vibrato = currentV;
                        console.log("New vibrato: ", vibrato);

                        csound.setChannel("vibrato", vibrato/10)
                        //                        var sendString = JS.NEWVIBRATO.toString() + "," + vibrato.toString()
                        //console.log(sendString);
                        //                        if (socket.status == WebSocket.Open)
                        //                            socket.sendTextMessage(sendString); // to be convertet in server
                    }

                }


            }

        }



        Item {
            id: controllerRect

            width: parent.width*0.9
            height: width/5

            //color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                //fillMode: Image.PreserveAspectFit
                id: fluteImage
                anchors.bottom: parent.bottom
                width: parent.width
                height: width/15
                source: "flute.png"
                z:3

            }

            Rectangle {
                id:airColumnRect
                //color: "darkred"
                opacity: 1.2-(height/parent.height)
                gradient: Gradient {
                    GradientStop {
                        position: 0.00;
                        color: "#f5e8e8";
                    }
                    GradientStop {
                        position: 0.57;
                        color: "#f76666";
                    }
                    GradientStop {
                        position: 1.00;
                        color: "#ad0707";
                    }
                }
                visible: false

                x: parent.width*0.14 // begin from the headjoint opening
                anchors.bottom: parent.bottom
                height: parent.height/3 ; // TODO: sõltuv puudutuskohast
                width: JS.noteStep
                z: 2

                Behavior on width {
                    NumberAnimation { duration: 20 }
                }

                Behavior on height {
                    NumberAnimation { duration: 20 }
                }

            }


            MouseArea {
                id: controllerArea
                width: parent.width*0.6
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height
                //anchors.fill: parent

                //                Rectangle {anchors.fill:parent; color:"blue"; z:1} // test, to make it visible

                onPressed: {
                    setNote(mouseX);
                    setNoise(mouseY);
                    //                    if (socket.status == WebSocket.Open)
                    //                        socket.sendTextMessage(JS.NOTEON.toString());
                    airColumnRect.visible = true;
                    csound.csEvent("i 1  0 -1");
                }
                onReleased: {
                    //udpSender.sendNumbersInString(JS.NOTEOFF.toString());
                    //                    if (socket.status == WebSocket.Open)
                    //                        socket.sendTextMessage(JS.NOTEOFF.toString());
                    airColumnRect.visible = false;
                    csound.csEvent("i -1  0 0");
                    JS.note = -1; JS.noiseLevel = -1;
                }
                onMouseXChanged: if (containsPress) {
                                     setNote(mouseX)

                                 }

                onMouseYChanged: if (containsPress) {
                                     setNoise(mouseY);
                                     //console.log("Y:",mouseY)
                                     airColumnRect.height = Math.max( (this.height - mouseY), fluteImage.height+5) // does not work...
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


            //        Label {
            //            id: tiltLabel
            //            text: qsTr("tilt x: " + Math.floor(tilt.reading.xRotation) + "y: " + Math.floor(tilt.reading.yRotation))
            //        }


        }

        Rectangle {
            id: coverRect
            visible: false
            color: "#80808080"
            anchors.centerIn: parent
            width: 0.95*parent.width
            height: 0.95*parent.height

            Label {
                id: infoMessageLabel
                color: "#ffffff"
                opacity: 1
                anchors.centerIn: parent
                text: "Input disabled. Please wait"
            }

            MouseArea {anchors.fill:parent} // block click to anything that us under
        }


    }
}








