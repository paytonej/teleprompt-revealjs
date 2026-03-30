---@diagnostic disable: undefined-global
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

local function normalize_path(path)
  return (path:gsub("\\", "/"))
end

local function is_absolute_path(path)
  local normalized = normalize_path(path)
  return normalized:match("^/") ~= nil or normalized:match("^[A-Za-z]:/") ~= nil
end

local function parent_dir(path)
  local normalized = normalize_path(path):gsub("/$", "")
  local parent = normalized:match("^(.*)/[^/]+$")
  if not parent or parent == "" then
    return nil
  end
  return parent
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

local function find_project_file()
  local candidates = {
    "_quarto.yml",
    "_quarto.yaml",
  }

  local function find_in_dir(dir)
    for _, candidate in ipairs(candidates) do
      local path = dir and dir ~= "." and join_path(dir, candidate) or candidate
      if file_exists(path) then
        return path
      end
    end
    return nil
  end

  local project_root = os.getenv("QUARTO_PROJECT_ROOT")
  if project_root and project_root ~= "" then
    local from_root = find_in_dir(project_root)
    if from_root then
      return from_root
    end
  end

  local current = "."
  while current do
    local found = find_in_dir(current)
    if found then
      return found
    end

    local next_dir = parent_dir(current)
    if not next_dir or next_dir == current then
      break
    end
    current = next_dir
  end

  return nil
end

local function read_file_text(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local text = file:read("*a")
  file:close()
  return text
end

local function parse_project_output_dir(project_file)
  local text = read_file_text(project_file)
  if not text then
    return nil
  end

  local in_project = false
  local project_indent = nil

  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local indent, key, value = line:match("^(%s*)([^:#][^:]-):%s*(.-)%s*$")
    if key then
      local depth = #indent

      if key == "project" then
        in_project = true
        project_indent = depth
      elseif in_project and depth <= project_indent then
        in_project = false
        project_indent = nil
      end

      if in_project and key == "output-dir" then
        local cleaned = value:gsub("^['\"]", ""):gsub("['\"]$", "")
        if cleaned ~= "" then
          return cleaned
        end
      end
    end
  end

  return nil
end

local function resolve_project_output_dir()
  local project_file = find_project_file()
  if not project_file then
    return nil
  end

  local output_dir = parse_project_output_dir(project_file)
  if not output_dir or output_dir == "" then
    return nil
  end

  if is_absolute_path(output_dir) then
    return output_dir
  end

  local project_dir = dirname(project_file)
  if project_dir == "." then
    return output_dir
  end

  return join_path(project_dir, output_dir)
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

  local project_output_dir = resolve_project_output_dir()
  if project_output_dir and dir_exists(project_output_dir) then
    return project_output_dir
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