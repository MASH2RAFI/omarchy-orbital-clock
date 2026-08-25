.pragma library

function findEntry(shell, pluginId) {
  var config = shell && shell.shellConfig ? shell.shellConfig : null
  if (!config || !Array.isArray(config.plugins)) return null
  for (var i = 0; i < config.plugins.length; i++) {
    var entry = config.plugins[i]
    if (entry && String(entry.id || "") === pluginId) return entry
  }
  return null
}

function entryOrDefault(shell, pluginId) {
  var entry = findEntry(shell, pluginId)
  return entry || { id: pluginId }
}

function defaultSettings() {
  return {
    scale: 1,
    hourScale: 1,
    dateScale: 1,
    subtimeScale: 1,
    ringLabelScale: 1,
    position: "middle-right",
    centerLayout: "orbit",
    use24h: false,
    showSeconds: true,
    showDate: true,
    accentMode: "contrast",
    margin: 12,
    barPadding: 0,
    ringDiameter: 0.40,
    ringGap: 48,
    ringArcDegrees: 0,
    ringTransparency: 1,
    minuteRingOpacity: 1,
    secondRingOpacity: 1,
    screenMode: "all",
    selectedMonitors: [],
    perMonitorScale: false,
    scaleReferenceHeight: 1080,
    clockFont: "Liberation Sans",
    labelFont: "JetBrainsMono Nerd Font,JetBrainsMono NF"
  }
}
