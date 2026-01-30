import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#1e1e2e"

    // Background gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1e1e2e" }
            GradientStop { position: 1.0; color: "#2d2d44" }
        }
    }

    // Main content
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30

        // Welcome text
        Text {
            id: welcomeText
            text: "Welcome to Maxwell's System"
            color: "#cdd6f4"
            font.pixelSize: 32
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // Login form using SDDM components
        Rectangle {
            id: loginBox
            width: 400
            height: 300
            color: "#313244"
            radius: 10
            border.color: "#89b4fa"
            border.width: 2

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "Login"
                    color: "#cdd6f4"
                    font.pixelSize: 24
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // Username input
                TextField {
                    id: usernameField
                    placeholderText: "Username"
                    color: "#cdd6f4"
                    Layout.preferredWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                }

                // Password input
                TextField {
                    id: passwordField
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    color: "#cdd6f4"
                    Layout.preferredWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                }

                // Login button
                Button {
                    text: "Login"
                    color: "#1e1e2e"
                    Layout.preferredWidth: 100
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}











