import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.camera"

  property bool present: false
  property bool disabled: false
  property bool opened: false
  property bool inUse: false
  property var apps: []

  readonly property string appNames: apps.join(", ")

  visible: present
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function update(line) {
    try {
      var state = JSON.parse(line)
      present = state.present === true
      disabled = state.disabled === true
      opened = state.inUse === true
      apps = Array.isArray(state.apps) ? state.apps : []
    } catch (e) {}
  }

  // Browsers open every camera for a moment when a page lists devices.
  onOpenedChanged: {
    if (opened) {
      inUseTimer.restart()
    } else {
      inUseTimer.stop()
      inUse = false
    }
  }

  Timer {
    id: inUseTimer
    interval: 1000
    onTriggered: root.inUse = root.opened
  }

  Process {
    id: statusProc
    command: ["omarchy-camera-status", "--watch"]
    running: true
    stdout: SplitParser {
      onRead: function(line) { root.update(line) }
    }
    onExited: restartTimer.start()
  }

  Timer {
    id: restartTimer
    interval: 5000
    onTriggered: statusProc.running = true
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.disabled ? "󱜷" : "󰖠"
    active: root.inUse && !root.disabled
    tooltipText: root.disabled ? "Camera disabled" : (root.inUse ? "Camera in use by " + root.appNames : "Camera ready")
    onPressed: root.bar.run("omarchy-toggle-camera")
  }
}
