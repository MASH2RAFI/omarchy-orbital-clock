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

function findBarEntry(shell, pluginId) {
  var config = shell && shell.shellConfig ? shell.shellConfig : null
  if (!config || !config.bar || !config.bar.layout) return null
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var arr = config.bar.layout[sections[s]] || []
    for (var i = 0; i < arr.length; i++) {
      var entry = arr[i]
      if (entry && String(entry.id || "") === pluginId) return entry
    }
  }
  return null
}

function entryOrDefault(shell, pluginId) {
  var pluginEntry = findEntry(shell, pluginId)
  var barEntry = findBarEntry(shell, pluginId)
  if (!pluginEntry && !barEntry) return { id: pluginId }
  if (!barEntry) return pluginEntry || { id: pluginId }
  if (!pluginEntry) return barEntry
  var merged = { id: pluginId }
  for (var key in pluginEntry) if (key !== "id") merged[key] = pluginEntry[key]
  for (var bkey in barEntry) if (bkey !== "id") merged[bkey] = barEntry[bkey]
  return merged
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
    clockEnabled: true,
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
