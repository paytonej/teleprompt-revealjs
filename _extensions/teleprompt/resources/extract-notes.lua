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

local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function resolve_output_dir(output_file)
  if file_exists(output_file) then
    return dirname(output_file)
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
          local note_doc = pandoc.Pandoc(el.content, doc.meta)
          local text = pandoc.write(note_doc, "plain")
          text = text:gsub("^%s+", ""):gsub("%s+$", "")
          if text ~= "" then
            table.insert(notes, text)
          end
          break
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