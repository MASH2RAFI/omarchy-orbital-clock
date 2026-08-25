import QtQuick
import qs.Commons
import "ClockModel.js" as Clock
import "ClockTheme.js" as Theme

Item {
  id: face
  clip: false

  property bool active: true
  property bool use24h: true
  property bool showSeconds: true
  property bool showDate: true
  property real scaleFactor: 1
  property real hourScaleFactor: 1
  property real dateScaleFactor: 1
  property real subtimeScaleFactor: 1
  property real ringLabelScaleFactor: 1
  property real availableHeight: 0
  property real availableWidth: 0
  property int screenMargin: 0
  property var screenInsets: ({ top: 0, right: 0, bottom: 0, left: 0 })
  property string position: "middle-right"
  property string centerLayout: "orbit"
  property string clockFont: "Liberation Sans"
  property string labelFont: "JetBrainsMono Nerd Font,JetBrainsMono NF"
  property real ringDiameter: 0.40
  property real ringGap: 48
  property int ringArcDegrees: 180
  property real ringTransparency: 1
  property string accentMode: "contrast"
  property bool lowPower: false
  property real screenRefreshRate: 60

  property real timeMs: Date.now()

  readonly property int ringTickMs: Clock.tickIntervalMs(
    face.screenRefreshRate, face.lowPower, face.showSeconds
  )
  readonly property real layoutScale: Clock.clampScale(face.scaleFactor)
  readonly property real hourScale: Clock.clampTextScale(face.hourScaleFactor)
  readonly property real dateScale: Clock.clampTextScale(face.dateScaleFactor)
  readonly property real subtimeScale: Clock.clampTextScale(face.subtimeScaleFactor)
  readonly property real ringLabelScale: Clock.clampTextScale(face.ringLabelScaleFactor)
  readonly property var now: Clock.partsAt(face.timeMs, face.use24h)
  readonly property var spec: Clock.layoutSpec(face.position, face.centerLayout, face.ringArcDegrees)
  readonly property bool fullRing: face.spec.fullRing
  readonly property real ringFocusAngle: face.spec.focusAngle
  readonly property var ringArc: Clock.resolvedArcBounds(face.spec)
  readonly property real labelPad: Math.round(12 * face.layoutScale)
  readonly property real ringLabelBleed: Math.round(22 * face.ringLabelScale)
  readonly property real verticalInset: Math.round(44 * face.layoutScale)
  readonly property real heightFit: Clock.clampRingDiameter(face.ringDiameter)
  readonly property real fitOuterRadius: Clock.fitOuterRadiusForPosition(
    face.availableWidth,
    face.availableHeight,
    face.heightFit,
    face.labelPad,
    face.verticalInset,
    face.position,
    face.screenMargin,
    face.screenInsets
  )
  readonly property real secondRadius: Math.max(80, face.fitOuterRadius)
  readonly property real ringGapPx: Clock.clampRingGap(face.ringGap)
  readonly property real minuteRadius: Math.max(64, face.secondRadius - face.ringGapPx)
  readonly property real dialSize: Math.round(face.secondRadius * 2 + face.labelPad * 2)
  readonly property real hourSize: Clock.hourSizeFromScale(face.hourScale, face.spec.hourSizeFactor)
  readonly property real centerDateGap: Math.round(12 * face.dateScale)
  readonly property real centerDateH: face.showDate
    ? Clock.centerDateBlockHeight(face.use24h, face.dateScale)
    : 0
  readonly property real dateColumnH: Clock.dateColumnHeight(face.use24h, face.dateScale)
  readonly property real subtimeH: Math.round(13 * face.subtimeScale)
  readonly property int columnSpacing: Math.round(7 * Math.max(face.hourScale, face.dateScale, face.subtimeScale))
  readonly property real hourOnlyH: face.hourSize + Math.round(12 * face.hourScale)
  readonly property real minuteCapsuleAngle: face.spec.singleCapsule
    ? face.spec.minuteCapsuleAngle
    : (face.spec.showCapsules ? face.spec.minuteCapsuleAngle : face.ringFocusAngle)
  readonly property real secondCapsuleAngle: face.spec.showCapsules && !face.spec.singleCapsule
    ? face.spec.secondCapsuleAngle
    : face.ringFocusAngle
  readonly property real hourW: Math.max(Math.round(face.hourSize * 0.78), hourColumn.implicitWidth)
  readonly property real hourH: face.hourOnlyH
  readonly property real pillWidth: Math.round(42 * face.layoutScale)
  readonly property var geo: Clock.clockGeometry(
    face.position,
    face.secondRadius,
    face.labelPad,
    face.hourW,
    face.hourOnlyH,
    face.showDate && face.spec.dateBelowDial,
    face.centerDateGap,
    face.centerDateH,
    face.ringLabelBleed,
    {
      dateInColumn: face.showDate && face.spec.dateInHourColumn,
      dateColumnH: face.dateColumnH,
      dateAboveHour: face.spec.dateAboveHour,
      showCenterSubtime: face.spec.showCenterSubtime,
      hourSize: face.hourSize,
      columnSpacing: face.columnSpacing,
      subtimeH: face.subtimeH
    }
  )
  readonly property real minuteProgress: Clock.minuteProgress(face.now)
  readonly property real secondProgress: Clock.secondProgress(face.now)
  readonly property var colors: Theme.palette(face.accentMode, {
    foreground: Color.foreground,
    background: Color.background,
    muted: Color.muted,
    accent: Color.accent
  })
  readonly property real ringStrength: face.spec.ringStrength * face.ringTransparency
  readonly property var capsuleAngles: Clock.capsuleRenderAngles(
    face.minuteCapsuleAngle,
    face.secondCapsuleAngle,
    face.spec.singleCapsule
  )
  readonly property real minuteCapsuleRenderAngle: face.capsuleAngles.minute
  readonly property real secondCapsuleRenderAngle: face.capsuleAngles.second
  readonly property bool sunburstCapsules: face.spec.variant === "sunburst"
  readonly property string subtimeText: face.showSeconds
    ? (face.now.mm + ":" + face.now.ss)
    : face.now.mm

  implicitWidth: Math.max(1, geo.width)
  implicitHeight: Math.max(1, geo.height)

  function themedInk(color, alpha) {
    return Theme.ink(color, alpha)
  }

  readonly property string minuteCapsuleText: {
    if (face.spec.singleCapsule) return face.subtimeText
    if (face.sunburstCapsules)
      return Clock.ringLabelAtWorldAngle(
        face.minuteCapsuleRenderAngle, face.minuteProgress, face.ringFocusAngle)
    return face.now.mm
  }

  readonly property string secondCapsuleText: {
    if (face.sunburstCapsules)
      return Clock.ringLabelAtWorldAngle(
        face.secondCapsuleRenderAngle, face.secondProgress, face.ringFocusAngle)
    return face.now.ss
  }

  function capsulePoint(radius, angle) {
    return Qt.point(
      face.geo.dialX + face.geo.cx + Math.cos(angle) * radius,
      face.geo.dialY + face.geo.cy + Math.sin(angle) * radius
    )
  }

  function markRingDirty() {
    rings.repaint()
  }

  function refreshTime() {
    face.timeMs = Date.now()
    rings.repaint()
  }

  Timer {
    id: ringTick
    interval: face.ringTickMs
    running: face.active
    repeat: true
    triggeredOnStart: true
    onTriggered: face.refreshTime()
  }

  onRingTickMsChanged: ringTick.restart()
  onActiveChanged: if (face.active) ringTick.restart()

  Item {
    id: dialBlock
    z: 1
    x: face.geo.dialX
    y: face.geo.dialY
    width: face.geo.dialW
    height: face.geo.height
    clip: false

    RingCanvas {
      id: rings
      width: parent.width
      height: face.geo.dialH
      cx: face.geo.cx
      cy: face.geo.cy
      minuteRadius: face.minuteRadius
      secondRadius: face.secondRadius
      minuteProgress: face.minuteProgress
      secondProgress: face.secondProgress
      focusAngle: face.ringFocusAngle
      fullRing: face.fullRing
      showSeconds: face.showSeconds
      ringStrength: face.ringStrength
      ringColor: face.colors.minuteRing
      labelScale: face.ringLabelScale
      chromeScale: face.layoutScale
      labelFont: face.labelFont
      arcFrom: face.ringArc.from
      arcTo: face.ringArc.to
      showGuideRing: face.spec.showGuideRing
      arcEmphasis: face.spec.arcEmphasis === true
      arcEdgeFade: face.spec.arcEdgeFade
    }

    Connections {
      target: face
      function onGeoChanged() { face.markRingDirty() }
      function onSpecChanged() { face.markRingDirty() }
      function onColorsChanged() { face.markRingDirty() }
      function onRingStrengthChanged() { face.markRingDirty() }
      function onShowSecondsChanged() { face.markRingDirty() }
      function onLabelFontChanged() { face.markRingDirty() }
    }

    Connections {
      target: Color
      function onForegroundChanged() { face.markRingDirty() }
      function onBackgroundChanged() { face.markRingDirty() }
      function onMutedChanged() { face.markRingDirty() }
      function onAccentChanged() { face.markRingDirty() }
    }

    Component.onCompleted: face.markRingDirty()

    Column {
      id: hourColumn
      z: 3
      x: face.geo.hourX
      y: face.geo.hourY
      spacing: face.columnSpacing

      DateColumn {
        visible: face.showDate && face.spec.dateInHourColumn && face.spec.dateAboveHour
        parts: face.now
        use24h: face.use24h
        uiScale: face.dateScale
        clockFont: face.clockFont
        labelFont: face.labelFont
        primaryColor: face.colors.datePrimary
        mutedColor: face.colors.dateMuted
      }

      Text {
        visible: face.spec.showCenterSubtime && face.spec.dateAboveHour
        anchors.horizontalCenter: parent.horizontalCenter
        text: face.subtimeText
        color: face.colors.subtime
        font.family: face.labelFont
        font.pixelSize: Math.round(13 * face.subtimeScale)
        font.weight: Font.Medium
        font.letterSpacing: 1.4
        renderType: Text.NativeRendering
        antialiasing: true
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: face.now.hourLabel
        color: face.colors.hour
        font.family: face.clockFont
        font.pixelSize: face.hourSize
        font.weight: Font.Black
        font.letterSpacing: -3 * face.hourScale
        renderType: Text.NativeRendering
        antialiasing: true
      }

      Text {
        visible: face.spec.showCenterSubtime && !face.spec.dateAboveHour
        anchors.horizontalCenter: parent.horizontalCenter
        text: face.subtimeText
        color: face.colors.subtime
        font.family: face.labelFont
        font.pixelSize: Math.round(13 * face.subtimeScale)
        font.weight: Font.Medium
        font.letterSpacing: 1.4
        renderType: Text.NativeRendering
        antialiasing: true
      }

      DateColumn {
        visible: face.showDate && face.spec.dateInHourColumn && !face.spec.dateAboveHour
        parts: face.now
        use24h: face.use24h
        uiScale: face.dateScale
        clockFont: face.clockFont
        labelFont: face.labelFont
        primaryColor: face.colors.datePrimary
        mutedColor: face.colors.dateMuted
      }
    }
  }

  TimeCapsule {
    id: minutePill
    z: 10
    visible: face.spec.showCapsules
    uiScale: face.layoutScale
    textScale: face.subtimeScale
    width: face.spec.singleCapsule ? Math.round(62 * face.layoutScale) : face.pillWidth
    fontFamily: face.clockFont
    fontSize: 15
    textColor: face.colors.minuteCapsuleText
    fillColor: face.themedInk(face.colors.capsuleFill, 0.96)
    borderColor: face.themedInk(face.colors.capsuleBorder, 0.55)
    text: face.minuteCapsuleText

    readonly property point focusPos: face.capsulePoint(
      face.spec.singleCapsule ? face.secondRadius : face.minuteRadius,
      face.minuteCapsuleRenderAngle
    )
    x: focusPos.x - width / 2
    y: focusPos.y - height / 2
  }

  TimeCapsule {
    id: secondPill
    visible: face.showSeconds && face.spec.showCapsules && !face.spec.singleCapsule
    z: 11
    uiScale: face.layoutScale
    textScale: face.subtimeScale
    width: face.pillWidth
    fontFamily: face.clockFont
    fontSize: 14
    fontWeight: Font.Medium
    textColor: face.colors.secondCapsuleText
    fillColor: face.themedInk(face.colors.capsuleFill, 0.96)
    borderColor: face.themedInk(face.colors.capsuleBorder, 0.45)
    text: face.secondCapsuleText

    readonly property point focusPos: face.capsulePoint(
      face.secondRadius,
      face.secondCapsuleRenderAngle
    )
    x: focusPos.x - width / 2
    y: focusPos.y - height / 2
  }

  DateColumn {
    id: centerDateBlock
    visible: face.showDate && face.spec.dateBelowDial
    z: 3
    anchors.horizontalCenter: dialBlock.horizontalCenter
    y: dialBlock.y + dialBlock.height + face.centerDateGap
    parts: face.now
    use24h: face.use24h
    uiScale: face.dateScale
    clockFont: face.clockFont
    labelFont: face.labelFont
    dateFontSize: 12
    dayFontSize: 20
    primaryColor: face.colors.datePrimary
    mutedColor: face.colors.dateMuted
  }
}
