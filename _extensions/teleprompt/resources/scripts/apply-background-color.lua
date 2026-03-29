---@diagnostic disable: undefined-global

-- Apply global reveal background color from YAML metadata for the teleprompt format.
-- This keeps background-color working even when custom SCSS themes set defaults.

function Pandoc(doc)
  local bg = doc.meta["background-color"] or doc.meta.backgroundColor
  if not bg then
    return doc
  end

  local bg_value = pandoc.utils.stringify(bg)
  if bg_value == "" then
    return doc
  end

  local style = string.format(
    "<style>:root{--r-background-color:%s;} .reveal-viewport{background-color:var(--r-background-color)!important;} .reveal{background-color:var(--r-background-color)!important;}</style>",
    bg_value
  )

  table.insert(doc.blocks, 1, pandoc.RawBlock("html", style))
  return doc
end
