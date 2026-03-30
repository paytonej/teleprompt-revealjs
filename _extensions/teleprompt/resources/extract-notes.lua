-- extract-notes.lua
-- Extract ::: {.notes} fenced divs from the Pandoc AST and write a plain-text file.

local function basename_no_ext(path)
  local name = path:gsub(".*[/\\]", "")
  return (name:gsub("%.[^.]+$", ""))
end

local function dirname(path)
  local dir = path:match("^(.*)[/\\][^/\\]+$")
  return dir or "."
end

local function join_path(a, b)
  if a:sub(-1) == "/" then
    return a .. b
  end
  return a .. "/" .. b
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function dir_exists(path)
  local ok, _, code = os.rename(path, path)
  if ok then
    return true
  end
  return code == 13
end

local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function render_blocks_as_html(blocks, meta)
  local note_doc = pandoc.Pandoc(blocks, meta)
  return pandoc.write(note_doc, "html")
end

local function resolve_output_dir(output_file)
  -- Quarto usually sets this for project renders; prefer it when available.
  local quarto_out = os.getenv("QUARTO_PROJECT_OUTPUT_DIR")
  if quarto_out and quarto_out ~= "" and dir_exists(quarto_out) then
    return quarto_out
  end

  -- If output_file already has a directory component, use it directly.
  local out_dir = dirname(output_file)
  if out_dir and out_dir ~= "." and dir_exists(out_dir) then
    return out_dir
  end

  if file_exists(output_file) then
    return dirname(output_file)
  end

  -- Common Quarto project default.
  if dir_exists("_output") then
    return "_output"
  end

  local cmd = "find . -maxdepth 4 -type f -name " .. shell_quote(output_file)
  local p = io.popen(cmd)
  if p then
    local found = p:read("*l")
    p:close()
    if found and found ~= "" then
      return dirname(found)
    end
  end

  return "."
end

function Pandoc(doc)
  local notes = {}

  doc:walk({
    Div = function(el)
      for _, class in ipairs(el.classes) do
        if class == "notes" then
          local text = pandoc.write(pandoc.Pandoc(el.content, doc.meta), "plain")
          text = text:gsub("^%s+", ""):gsub("%s+$", "")
          if text ~= "" then
            table.insert(notes, text)
          end

          -- Convert source ::: {.notes} blocks into reveal presenter notes.
          -- These are hidden on the slide and visible in speaker view.
          local html = render_blocks_as_html(el.content, doc.meta)
          return pandoc.RawBlock("html", '<aside class="notes">' .. html .. '</aside>')
        end
      end
      return nil
    end
  })

  if #notes == 0 then
    return doc
  end

  local output_file = (PANDOC_STATE and PANDOC_STATE.output_file) or "notes.html"
  local output_dir = resolve_output_dir(output_file)
  local outname = join_path(output_dir, basename_no_ext(output_file) .. "_notes.txt")
  local out = io.open(outname, "w")
  if not out then
    return doc
  end

  for i, note in ipairs(notes) do
    out:write(string.format("Slide %d\n", i))
    out:write(note .. "\n")
    out:write(string.rep("-", 40) .. "\n")
  end
  out:close()

  return doc
end