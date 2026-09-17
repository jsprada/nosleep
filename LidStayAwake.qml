import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Bar toggle that keeps the laptop running while the lid is closed.
// See lid-stay-awake.sh for how the actual inhibitor lock is held.
BarWidget {
  id: root
  moduleName: "lid-stay-awake"

  property bool stayingAwake: false

  // Resolves next to this file regardless of what directory name the plugin
  // is installed under.
  readonly property string scriptPath: {
    var url = Qt.resolvedUrl("lid-stay-awake.sh").toString()
    return url.indexOf("file://") === 0 ? decodeURIComponent(url.slice(7)) : url
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (statusProc.running) return
    statusProc.command = ["bash", root.scriptPath, "--status"]
    statusProc.running = true
  }

  function toggle() {
    if (toggleProc.running) return
    toggleProc.command = ["bash", root.scriptPath, "--toggle"]
    toggleProc.running = true
  }

  Component.onCompleted: refresh()

  Process {
    id: statusProc
    onExited: function(exitCode) { root.stayingAwake = exitCode === 0 }
  }

  Process {
    id: toggleProc
    onExited: function() { root.refresh() }
  }

  // Catches the lock being released some other way (e.g. the held process
  // was killed outside this widget), so the icon doesn't go stale.
  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "lid-stay-awake"

    function status(): string {
      return JSON.stringify({ active: root.stayingAwake })
    }

    function toggle(): string {
      root.toggle()
      return root.stayingAwake ? "disabled" : "enabled"
    }

    function refresh(): void {
      root.refresh()
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌢"
    active: root.stayingAwake
    dimmed: !root.stayingAwake
    tooltipText: root.stayingAwake
      ? "Allow lid close to suspend the laptop"
      : "Keep the laptop running with the lid closed"
    onPressed: root.toggle()
  }
}
