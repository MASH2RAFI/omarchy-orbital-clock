import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "FontOptions.js" as Fonts
import "ClockModel.js" as Clock
import "ClockTheme.js" as Theme
import "PluginConfig.js" as Config

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool closingFromHost: false

  readonly property bool openedState: root.opened
  readonly property string pluginId: manifest && manifest.id ? manifest.id : "mashrafi.orbital-clock"
  readonly property bool popupBlocked: positionField.popupOpen
    || centerLayoutField.popupOpen
    || screenModeField.popupOpen
    || accentField.popupOpen
    || clockFontField.popupOpen
    || labelFontField.popupOpen
  readonly property color scrim: Color.menu.scrim
  readonly property color cardBackground: Color.popups.background
  readonly property var cardBorderSpec: Border.surfaceSpec(
    "popups", "border", Color.popups.border, Math.max(1, Style.space(2))
  )
  readonly property int cardPadding: Style.spacing.panelPadding + Style.space(6)
  readonly property int contentGap: Style.space(16)
  readonly property int scrollBottomPad: Style.space(12)

  readonly property var fakeBar: QtObject {
    readonly property color foreground: Color.foreground
    readonly property color background: Color.background
    readonly property color urgent: Color.urgent
    readonly property string fontFamily: Style.font.family
    readonly property string position: "top"
    readonly property bool vertical: false
    readonly property int barSize: Style.bar.sizeHorizontal
  }

  readonly property var positionOptions: [
    { value: "top-left", label: "Top left" },
    { value: "top-center", label: "Top center" },
    { value: "top-right", label: "Top right" },
    { value: "middle-left", label: "Middle left" },
    { value: "middle-center", label: "Middle center" },
    { value: "middle-right", label: "Middle right" },
    { value: "bottom-left", label: "Bottom left" },
    { value: "bottom-center", label: "Bottom center" },
    { value: "bottom-right", label: "Bottom right" }
  ]

  readonly property var accentOptions: Theme.accentModeOptions()
  readonly property var layoutStyleOptions: Clock.layoutStyleOptions()
  readonly property var screenModeOptions: Clock.screenModeOptions()

  property string settingsPage: "general"
  property var draft: Clock.readSettings({})

  readonly property var clockFontOptions: Fonts.fontOptions(Fonts.CLOCK_FONTS, draft.clockFont)
  readonly property var labelFontOptions: Fonts.fontOptions(Fonts.LABEL_FONTS, draft.labelFont)

  function pluginEntry() {
    return Config.entryOrDefault(shell, root.pluginId)
  }

  function allScreenNames() {
    var names = []
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; i++) {
      var screen = screens[i]
      if (screen && screen.name) names.push(String(screen.name))
    }
    return names
  }

  function isDraftMonitorSelected(name) {
    return Clock.monitorListIncludes(root.draft.selectedMonitors, name)
  }

  function focusedMonitorName() {
    return Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
  }

  function isMonitorChecked(name, screen) {
    name = String(name || "")
    if (root.draft.screenMode === "all") return true
    if (root.draft.screenMode === "selected")
      return root.isDraftMonitorSelected(name)
    return Clock.shouldShowOnScreen(
      screen,
      root.draft.screenMode,
      "",
      root.focusedMonitorName(),
      root.draft.selectedMonitors
    )
  }

  function beginCustomMonitorSelection() {
    if (root.draft.screenMode === "selected") return
    var list = []
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; i++) {
      var screen = screens[i]
      if (!screen || !screen.name) continue
      var name = String(screen.name)
      if (root.isMonitorChecked(name, screen)) list.push(name)
    }
    root.patchDraft({ selectedMonitors: list, screenMode: "selected" })
  }

  function setDraftMonitorSelected(name, on) {
    name = String(name || "")
    if (name === "") return
    root.beginCustomMonitorSelection()
    var list = root.draft.selectedMonitors.slice()
    var idx = list.indexOf(name)
    if (on && idx < 0) list.push(name)
    else if (!on && idx >= 0) list.splice(idx, 1)
    root.patchDraft({ selectedMonitors: list })
  }

  function toggleDraftMonitor(name, screen) {
    root.setDraftMonitorSelected(name, !root.isMonitorChecked(name, screen))
  }

  function selectAllMonitors() {
    root.patchDraft({ screenMode: "selected", selectedMonitors: root.allScreenNames() })
  }

  function selectNoMonitors() {
    root.patchDraft({ screenMode: "selected", selectedMonitors: [] })
  }

  function applyDraft(entry) {
    draft = Clock.readSettings(entry)
  }

  function patchDraft(updates, save) {
    if (save === undefined) save = true
    draft = Clock.mergeSettings(root.pluginId, draft, updates)
    if (save) persist()
  }

  function syncFromConfig() {
    applyDraft(pluginEntry())
  }

  function resetToDefaults() {
    applyDraft(Config.defaultSettings())
    persist()
  }

  function refreshRateForScreen(screen) {
    return Clock.refreshRateForMonitor(Hyprland.monitorFor(screen))
  }

  function persist() {
    if (!shell || typeof shell.updateEntryInline !== "function") return
    shell.updateEntryInline(root.pluginId, Clock.settingsToEntry(root.pluginId, draft))
  }

  function open(payloadJson) {
    closingFromHost = false
    syncFromConfig()
    root.opened = true
    Qt.callLater(function() {
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    closingFromHost = true
    root.opened = false
    closingFromHost = false
  }

  function requestClose() {
    if (shell && typeof shell.hide === "function") shell.hide(root.pluginId)
    else root.close()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "mashrafi-orbital-clock-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
        root.shell.hide(root.pluginId)
    }

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.requestClose()
    }

    BorderSurface {
      id: card
      anchors.centerIn: parent
      width: Math.min(Style.space(500), panel.width - Style.gapsOut * 6)
      height: Math.min(Style.space(780), panel.height - Style.gapsOut * 6)
      radius: Style.cornerRadius
      color: root.cardBackground
      borderSpec: root.cardBorderSpec
      padding: root.cardPadding

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      FocusScope {
        id: contentScope
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        focus: true

        readonly property real previewHeight: Style.space(112)
        readonly property real footerReserve: Math.max(settingsFooter.implicitHeight, 88)
        readonly property real scrollHeight: Math.max(
          160,
          height
            - titleBlock.height
            - pageTabs.height
            - previewFrame.height
            - footerReserve
            - root.contentGap * 4
        )

        PanelKeyCatcher {
          id: keyCatcher
          anchors.fill: parent
          blocked: root.popupBlocked
          onCloseRequested: root.requestClose()
        }

        Column {
          anchors.fill: parent
          spacing: root.contentGap

          Text {
            id: titleBlock
            width: parent.width
            text: "Orbital Clock"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            topPadding: Style.space(2)
          }

          Row {
            id: pageTabs
            width: parent.width
            spacing: Style.spacing.sm

            Button {
              width: (parent.width - parent.spacing * 2) / 3
              text: "General"
              bordered: root.settingsPage === "general"
              focusable: true
              onClicked: root.settingsPage = "general"
            }

            Button {
              width: (parent.width - parent.spacing * 2) / 3
              text: "Fonts & sizes"
              bordered: root.settingsPage === "fonts"
              focusable: true
              onClicked: root.settingsPage = "fonts"
            }

            Button {
              width: (parent.width - parent.spacing * 2) / 3
              text: "Monitors"
              bordered: root.settingsPage === "monitors"
              focusable: true
              onClicked: root.settingsPage = "monitors"
            }
          }

          BorderSurface {
            id: previewFrame
            width: parent.width
            height: contentScope.previewHeight
            radius: Style.cornerRadius
            color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.55)
            borderSpec: Border.localOrSurfaceSpec(
              "popups", "border", Color.popups.border, Color.foreground, Style.normalBorderWidth
            )

            Item {
              id: previewClip
              anchors.fill: parent
              anchors.margins: Style.space(10)
              clip: true

              Item {
                id: previewScaler
                scale: Math.min(
                  previewClip.width / Math.max(1, previewFace.implicitWidth),
                  previewClip.height / Math.max(1, previewFace.implicitHeight)
                ) * 0.9
                transformOrigin: Item.TopLeft
                x: (previewClip.width - previewFace.implicitWidth * scale) / 2
                y: (previewClip.height - previewFace.implicitHeight * scale) / 2

                OrbitalClockFace {
                  id: previewFace
                  position: root.draft.position
                  centerLayout: root.draft.centerLayout
                  ringDiameter: root.draft.ringDiameter
                  ringGap: root.draft.ringGap
                  ringArcDegrees: root.draft.ringArcDegrees
                  ringTransparency: root.draft.ringTransparency
                  scaleFactor: root.draft.scale * 0.38
                  hourScaleFactor: root.draft.hourScale
                  dateScaleFactor: root.draft.dateScale
                  subtimeScaleFactor: root.draft.subtimeScale
                  ringLabelScaleFactor: root.draft.ringLabelScale
                  availableHeight: 420
                  availableWidth: 560
                  use24h: root.draft.use24h
                  showSeconds: root.draft.showSeconds
                  showDate: root.draft.showDate
                  accentMode: root.draft.accentMode
                  clockFont: root.draft.clockFont
                  labelFont: root.draft.labelFont
                  lowPower: true
                }
              }
            }
          }

          Item {
            id: scrollHost
            width: parent.width
            height: contentScope.scrollHeight

            ScrollView {
              id: generalScroll
              anchors.fill: parent
              clip: true
              visible: root.settingsPage === "general"
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
              id: generalPage
              width: generalScroll.availableWidth
              spacing: root.contentGap

              Item {
                width: parent.width
                height: Style.space(4)
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Changes apply immediately. Right-click the clock on your wallpaper to reopen this menu."
                color: Qt.darker(Color.foreground, 1.35)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Layout"
              }

              Dropdown {
                id: positionField
                width: parent.width
                label: "Position"
                value: root.draft.position
                options: root.positionOptions
                onChanged: function(v) {
                  root.patchDraft({
                    position: v,
                    ringArcDegrees: Clock.defaultArcDegreesForPosition(v)
                  })
                }
              }

              Dropdown {
                id: centerLayoutField
                width: parent.width
                label: "Layout style"
                value: root.draft.centerLayout
                options: root.layoutStyleOptions
                onChanged: function(v) {
                  root.patchDraft({ centerLayout: Clock.normalizeLayoutStyle(v) })
                }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Rings"
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring diameter"
                helpText: "Outer ring size relative to screen height — independent of layout size and ring spacing."
                minimum: 0.25
                maximum: 0.55
                step: 0.01
                value: root.draft.ringDiameter
                valueText: Math.round(root.draft.ringDiameter * 100) + "%"
                onMoved: function(v) {
                  root.patchDraft({ ringDiameter: Clock.clampRingDiameter(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ ringDiameter: Clock.clampRingDiameter(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring spacing"
                helpText: "Gap between the minute and seconds rings in pixels — independent of layout size."
                minimum: 24
                maximum: 100
                step: 1
                value: root.draft.ringGap
                valueText: Math.round(root.draft.ringGap) + "px"
                onMoved: function(v) {
                  root.patchDraft({ ringGap: Clock.clampRingGap(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ ringGap: Clock.clampRingGap(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring arc"
                helpText: "How much of the ring is visible, centered on the dial focus. 360° shows the full circle."
                minimum: 30
                maximum: 360
                step: 5
                value: root.draft.ringArcDegrees
                valueText: Math.round(root.draft.ringArcDegrees) + "°"
                onMoved: function(v) {
                  root.patchDraft({
                    ringArcDegrees: Clock.clampRingArcDegrees(v, root.draft.position)
                  }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({
                    ringArcDegrees: Clock.clampRingArcDegrees(v, root.draft.position)
                  })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring transparency"
                helpText: "Fade both rings together. 0% hides the rings; 100% is fully visible."
                minimum: 0
                maximum: 1
                step: 0.01
                livePreview: false
                value: root.draft.ringTransparency
                valueText: Math.round(root.draft.ringTransparency * 100) + "%"
                onReleased: function(v) {
                  root.patchDraft({ ringTransparency: Clock.clampRingOpacity(v) })
                }
              }

              Toggle {
                width: parent.width
                label: "Seconds ring"
                description: "Show the outer seconds ring and capsule."
                checked: root.draft.showSeconds
                onClicked: {
                  root.patchDraft({ showSeconds: !root.draft.showSeconds })
                }
              }

              Dropdown {
                id: accentField
                width: parent.width
                label: "Ring colors"
                value: root.draft.accentMode
                options: root.accentOptions
                onChanged: function(v) {
                  root.patchDraft({ accentMode: Theme.normalizeAccentMode(v) })
                }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Hour & date"
              }

              Toggle {
                width: parent.width
                label: "24-hour clock"
                description: "Show hour in 24-hour format instead of 12-hour."
                checked: root.draft.use24h
                onClicked: {
                  root.patchDraft({ use24h: !root.draft.use24h })
                }
              }

              Toggle {
                width: parent.width
                label: "Date block"
                description: "Show date and weekday with the hour."
                checked: root.draft.showDate
                onClicked: {
                  root.patchDraft({ showDate: !root.draft.showDate })
                }
              }

              PanelSeparator { width: parent.width }

              Item {
                width: parent.width
                height: root.scrollBottomPad
              }
            }
            }

            ScrollView {
              id: fontsScroll
              anchors.fill: parent
              clip: true
              visible: root.settingsPage === "fonts"
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
              id: fontsPage
              width: fontsScroll.availableWidth
              spacing: root.contentGap

              Item {
                width: parent.width
                height: Style.space(4)
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Font and scale controls are independent — adjust each without affecting ring diameter or spacing."
                color: Qt.darker(Color.foreground, 1.35)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Sizes"
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Layout size"
                helpText: "Capsule chrome and dial padding."
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.scale
                valueText: root.draft.scale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ scale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ scale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring label size"
                helpText: "00–59 tick labels on the rings."
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.ringLabelScale
                valueText: root.draft.ringLabelScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ ringLabelScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ ringLabelScale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Hour size"
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.hourScale
                valueText: root.draft.hourScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ hourScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ hourScale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Date size"
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.dateScale
                valueText: root.draft.dateScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ dateScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ dateScale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Subtime size"
                helpText: "Minute/second line under the hour and capsule text."
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.subtimeScale
                valueText: root.draft.subtimeScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ subtimeScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ subtimeScale: Clock.roundScale(v) })
                }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Fonts"
              }

              FontDropdown {
                id: clockFontField
                width: parent.width
                label: "Hour & date font"
                value: root.draft.clockFont
                options: root.clockFontOptions
                maxVisibleRows: 6
                onChanged: function(v) {
                  root.patchDraft({ clockFont: v })
                }
              }

              FontDropdown {
                id: labelFontField
                width: parent.width
                label: "Ring label font"
                value: root.draft.labelFont
                options: root.labelFontOptions
                maxVisibleRows: 6
                onChanged: function(v) {
                  root.patchDraft({ labelFont: v })
                }
              }

              PanelSeparator { width: parent.width }

              Item {
                width: parent.width
                height: root.scrollBottomPad
              }
            }
            }

            ScrollView {
              id: monitorsScroll
              anchors.fill: parent
              clip: true
              visible: root.settingsPage === "monitors"
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
              id: monitorsPage
              width: monitorsScroll.availableWidth
              spacing: root.contentGap

              Item {
                width: parent.width
                height: Style.space(4)
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Control which outputs show the clock and how each screen sizes the dial."
                color: Qt.darker(Color.foreground, 1.35)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Monitors"
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: Quickshell.screens.length + " monitor"
                  + (Quickshell.screens.length === 1 ? "" : "s") + " detected — choose where the clock appears."
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }

              Row {
                width: parent.width
                spacing: Style.spacing.sm

                Button {
                  text: "Select all"
                  bordered: true
                  onClicked: root.selectAllMonitors()
                }

                Button {
                  text: "Select none"
                  bordered: true
                  onClicked: root.selectNoMonitors()
                }
              }

              Repeater {
                model: Quickshell.screens

                BorderSurface {
                  required property var modelData
                  width: monitorsPage.width
                  radius: Style.cornerRadius
                  color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.35)
                  borderSpec: Border.localOrSurfaceSpec(
                    "popups", "border", Color.popups.border, Color.foreground, Style.normalBorderWidth
                  )
                  padding: Style.space(10)
                  implicitHeight: screenRow.implicitHeight + padding * 2

                  Column {
                    id: screenRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacing.xs

                    Text {
                      width: parent.width
                      text: modelData.name || "Unknown"
                      color: Color.foreground
                      font.family: Style.font.family
                      font.pixelSize: Style.font.body
                      font.bold: true
                    }

                    Text {
                      width: parent.width
                      text: modelData.width + " × " + modelData.height + " px · "
                        + Clock.formatRefreshRate(root.refreshRateForScreen(modelData))
                      color: Qt.darker(Color.foreground, 1.35)
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                    }

                    Toggle {
                      width: parent.width
                      label: "Show clock on this monitor"
                      checked: root.isMonitorChecked(modelData.name, modelData)
                      onClicked: root.toggleDraftMonitor(modelData.name, modelData)
                    }
                  }
                }
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                visible: root.draft.screenMode === "selected" && root.draft.selectedMonitors.length === 0
                text: "No monitors selected — the clock will be hidden on every output."
                color: Color.urgent
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Display preset"
              }

              Dropdown {
                id: screenModeField
                width: parent.width
                label: "Quick preset"
                value: root.draft.screenMode
                options: root.screenModeOptions
                onChanged: function(v) {
                  var mode = Clock.normalizeScreenMode(v)
                  var monitors = root.draft.selectedMonitors
                  if (mode === "all")
                    monitors = root.allScreenNames()
                  else if (mode === "selected" && monitors.length === 0)
                    monitors = root.allScreenNames()
                  root.patchDraft({ screenMode: mode, selectedMonitors: monitors })
                }
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Use the toggles above to pick monitors directly. Presets override that selection — All shows every output; Custom keeps your picks; others follow primary, focused, or external rules."
                color: Qt.darker(Color.foreground, 1.45)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Ring repaint matches each monitor refresh rate via Hyprland. The settings preview stays on a slower tick."
                color: Qt.darker(Color.foreground, 1.45)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Per-monitor sizing"
              }

              Toggle {
                width: parent.width
                label: "Scale per monitor"
                description: "Adjust clock size by each monitor height relative to the reference below."
                checked: root.draft.perMonitorScale
                onClicked: {
                  root.patchDraft({ perMonitorScale: !root.draft.perMonitorScale })
                }
              }

              NumberField {
                width: parent.width
                label: "Reference height (px)"
                value: root.draft.scaleReferenceHeight
                from: 720
                to: 2160
                stepSize: 10
                onModified: function(v) {
                  root.patchDraft({ scaleReferenceHeight: Clock.clampReferenceHeight(v) })
                }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Placement"
              }

              NumberField {
                width: parent.width
                label: "Edge margin (px)"
                value: root.draft.margin
                from: 0
                to: 240
                stepSize: 1
                onModified: function(v) {
                  root.patchDraft({ margin: v })
                }
              }

              NumberField {
                width: parent.width
                label: "Bar padding (px, 0 = auto)"
                value: root.draft.barPadding
                from: 0
                to: 240
                stepSize: 1
                onModified: function(v) {
                  root.patchDraft({ barPadding: v })
                }
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Bar padding adds extra inset when the Omarchy bar shares the same edge. 0 auto-detects."
                color: Qt.darker(Color.foreground, 1.45)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              Item {
                width: parent.width
                height: root.scrollBottomPad
              }
            }
            }
          }

          Column {
            id: settingsFooter
            width: parent.width
            spacing: Style.spacing.sm

            Button {
              width: parent.width
              text: "Reset to defaults"
              bordered: true
              focusable: true
              onClicked: root.resetToDefaults()
            }

            Button {
              width: parent.width
              text: "Close"
              focusable: true
              onClicked: root.requestClose()
            }
          }
        }
      }
    }
  }
}
