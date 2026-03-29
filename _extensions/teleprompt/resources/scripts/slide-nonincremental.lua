local non_incremental
-- Reference: https://github.com/orgs/quarto-dev/discussions/7509#discussioncomment-7511231

check_slide = function(h)
  local incremental_ori = PANDOC_WRITER_OPTIONS.incremental
  if h.level == 1 or h.level == 2 then
    if h.classes:includes("nonincremental") then
      _, i = h.classes:find("nonincremental")
      h.classes:remove(i)
      non_incremental = true
      return h
    else
      non_incremental = not incremental_ori
    end
  end
end

wrap_div = function(l)
  if non_incremental then
    return pandoc.Div(l, {class = "nonincremental"}), false
  end
end

return{
  traverse = 'topdown',
  Header = check_slide,
  BulletList = wrap_div
}