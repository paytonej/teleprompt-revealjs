---@diagnostic disable: undefined-global
-- notes-as-subtitle.lua
-- Converts ::: {.notes} divs into:
--   1. A speaker <aside class="notes"> element (hidden, for speaker view)
--   2. A hidden <div class="slide-subtitle-data"> with the && segments as JSON
--   3. Invisible phantom <span class="fragment"> elements to cover any && segments
--      that exceed the slide's visual fragment count (so every && maps to one click)
-- Additionally, writes a plain-text notes file alongside the source document.

-- ── helpers ───────────────────────────────────────────────────────────────────

local function split_on_ampersand(text)
  local parts = {}
  for part in (text .. " && "):gmatch("(.-)%s*&&%s*") do
    part = part:match("^%s*(.-)%s*$")
    if part ~= "" then
      table.insert(parts, part)
    end
  end
  return parts
end

local function json_string(s)
  s = s:gsub('\\', '\\\\')
  s = s:gsub('"',  '\\"')
  s = s:gsub('\r', '')
  s = s:gsub('\n', ' ')
  return '"' .. s .. '"'
end

local function json_array(arr)
  local items = {}
  for _, s in ipairs(arr) do
    table.insert(items, json_string(s))
  end
  return "[" .. table.concat(items, ",") .. "]"
end

-- HTML-encode double-quotes so the JSON can live safely in a double-quoted attribute
local function attr_encode(s)
  return (s:gsub('"', '&quot;'))
end

-- ── fragment counting ─────────────────────────────────────────────────────────

local function count_effective_fragments(blocks)
  local count = 0
  for _, b in ipairs(blocks) do
    if b.t == "Div" then
      local is_fragment, is_tabset = false, false
      for _, cls in ipairs(b.classes) do
        if cls == "fragment"     then is_fragment = true end
        if cls == "panel-tabset" then is_tabset   = true end
      end

      if is_fragment then count = count + 1 end

      if is_tabset then
        local tab_count = 0
        for _, inner in ipairs(b.content) do
          if inner.t == "Header" and inner.level == 3 then
            tab_count = tab_count + 1
          end
        end
        count = count + math.max(0, tab_count - 1)
      end

      count = count + count_effective_fragments(b.content)
    elseif b.t == "CodeBlock" then
      local cln = b.attr.attributes["code-line-numbers"]
      if cln and cln ~= "false" and cln ~= "true" and cln ~= "" then
        local _, n = cln:gsub("|", "")
        count = count + n
      end
    end
  end
  return count
end

-- ── txt file helpers ──────────────────────────────────────────────────────────

local function basename_no_ext(path)
  local name = path:gsub(".*[/\\]", "")
  return (name:gsub("%.[^.]+$", ""))
end

local function normalize(path)
  return (path:gsub("\\", "/"))
end

local function write_notes_txt(notes_list, output_file)
  if #notes_list == 0 then return end

  -- QUARTO_DOCUMENT_PATH is the absolute path of the source file's directory.
  -- Using it means the txt file lands next to the .qmd source inside its
  -- subdir so that rename-subtitled.sh can find and move it.
  local out_dir = os.getenv("QUARTO_DOCUMENT_PATH")
  if not out_dir or out_dir == "" then
    local dir = normalize(output_file):match("^(.*)/[^/]+$")
    out_dir = (dir and dir ~= "") and dir
           or os.getenv("QUARTO_PROJECT_OUTPUT_DIR")
           or "."
  end
  out_dir = normalize(out_dir):gsub("/$", "")

  local path = out_dir .. "/" .. basename_no_ext(output_file) .. "_notes.txt"
  local f = io.open(path, "w")
  if not f then return end

  for i, text in ipairs(notes_list) do
    f:write(string.format("Slide %d\n", i))
    f:write(text .. "\n")
    f:write(string.rep("-", 40) .. "\n")
  end
  f:close()
end

-- ── document filter ───────────────────────────────────────────────────────────

function Pandoc(doc)
  local blocks     = doc.blocks
  local new_blocks = pandoc.Blocks({})
  local i, n       = 1, #blocks
  local notes_list = {}   -- plain-text notes collected for the txt file

  local function is_slide_header(b)
    return b.t == "Header" and (b.level == 1 or b.level == 2)
  end

  while i <= n do
    local block = blocks[i]

    if not is_slide_header(block) then
      new_blocks:insert(block)
      i = i + 1
    else
      local header        = block
      local slide_content = {}
      local j             = i + 1
      while j <= n do
        if is_slide_header(blocks[j]) then break end
        table.insert(slide_content, blocks[j])
        j = j + 1
      end

      -- Find the first .notes div in this slide
      local notes_idx, notes_div = nil, nil
      for k, b in ipairs(slide_content) do
        if b.t == "Div" then
          for _, cls in ipairs(b.classes) do
            if cls == "notes" then
              notes_idx, notes_div = k, b
              break
            end
          end
        end
        if notes_idx then break end
      end

      new_blocks:insert(header)

      if notes_div then
        -- Subtitle segments (split on &&)
        local parts = split_on_ampersand(pandoc.utils.stringify(notes_div))

        -- Plain text for the txt file
        local plain = pandoc.write(pandoc.Pandoc(notes_div.content, doc.meta), "plain")
        plain = plain:match("^%s*(.-)%s*$")
        if plain ~= "" then
          table.insert(notes_list, plain)
        end

        -- Count click-advances in the non-notes content
        local non_notes = {}
        for k, b in ipairs(slide_content) do
          if k ~= notes_idx then table.insert(non_notes, b) end
        end
        local visual_clicks = count_effective_fragments(non_notes)
        local n_phantom     = math.max(0, (#parts - 1) - visual_clicks)

        -- Speaker notes HTML (hidden; shown in speaker view only)
        local notes_html = pandoc.write(pandoc.Pandoc(notes_div.content, doc.meta), "html")

        -- Subtitle data attribute
        local json = attr_encode(json_array(parts))

        -- Emit slide content, substituting the notes div with the three injections
        for k, b in ipairs(slide_content) do
          if k == notes_idx then
            new_blocks:insert(pandoc.RawBlock("html",
              '<aside class="notes">' .. notes_html .. '</aside>'))
            new_blocks:insert(pandoc.RawBlock("html",
              '<div class="slide-subtitle-data" data-subtitles="' .. json .. '" hidden></div>'))
            if n_phantom > 0 then
              local spans = {}
              for _ = 1, n_phantom do
                table.insert(spans,
                  '<span class="fragment subtitle-phantom" aria-hidden="true"></span>')
              end
              new_blocks:insert(pandoc.RawBlock("html",
                '<div class="subtitle-phantoms" aria-hidden="true">'
                .. table.concat(spans) .. '</div>'))
            end
          else
            new_blocks:insert(b)
          end
        end
      else
        for _, b in ipairs(slide_content) do
          new_blocks:insert(b)
        end
      end

      i = j
    end
  end

  -- Write the plain-text notes file
  local output_file = (PANDOC_STATE and PANDOC_STATE.output_file) or "output.html"
  write_notes_txt(notes_list, output_file)

  return pandoc.Pandoc(new_blocks, doc.meta)
end
