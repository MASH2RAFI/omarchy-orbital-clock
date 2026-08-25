.pragma library

var CLOCK_FONTS = [
  { value: "Liberation Sans", label: "Liberation Sans" },
  { value: "Adwaita Sans", label: "Adwaita Sans" },
  { value: "Nimbus Sans", label: "Nimbus Sans" },
  { value: "Nimbus Sans Narrow", label: "Nimbus Sans Narrow" },
  { value: "Noto Sans", label: "Noto Sans" },
  { value: "Liberation Serif", label: "Liberation Serif" },
  { value: "Nimbus Roman", label: "Nimbus Roman" },
  { value: "iA Writer Quattro S", label: "iA Writer Quattro" },
  { value: "iA Writer Duospace", label: "iA Writer Duospace" },
  { value: "Cantarell", label: "Cantarell" },
  { value: "DejaVu Sans", label: "DejaVu Sans" },
  { value: "DejaVu Serif", label: "DejaVu Serif" },
  { value: "Ubuntu", label: "Ubuntu" },
  { value: "Roboto", label: "Roboto" },
  { value: "Inter", label: "Inter" }
]

var LABEL_FONTS = [
  { value: "JetBrainsMono Nerd Font,JetBrainsMono NF", label: "JetBrains Mono Nerd" },
  { value: "Liberation Mono", label: "Liberation Mono" },
  { value: "Adwaita Mono", label: "Adwaita Mono" },
  { value: "Nimbus Mono PS", label: "Nimbus Mono" },
  { value: "iA Writer Mono S", label: "iA Writer Mono" },
  { value: "iA Writer Duo S", label: "iA Writer Duo" },
  { value: "Noto Sans Mono", label: "Noto Sans Mono" },
  { value: "DejaVu Sans Mono", label: "DejaVu Sans Mono" },
  { value: "Ubuntu Mono", label: "Ubuntu Mono" },
  { value: "Roboto Mono", label: "Roboto Mono" },
  { value: "Fira Mono", label: "Fira Mono" },
  { value: "Source Code Pro", label: "Source Code Pro" },
  { value: "Cascadia Mono", label: "Cascadia Mono" },
  { value: "Hack", label: "Hack" }
]

function fontOptions(baseOptions, currentValue) {
  var value = String(currentValue || "")
  if (!value) return baseOptions.slice()

  for (var i = 0; i < baseOptions.length; i++) {
    if (baseOptions[i].value === value) return baseOptions.slice()
  }

  var out = baseOptions.slice()
  out.unshift({ value: value, label: value + " (current)" })
  return out
}
