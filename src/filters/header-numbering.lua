-- Pandoc Lua filter for preserving header numbering
-- This filter processes headers and maintains their original numbering format

local header_counters = {}

function Header(elem)
  local level = elem.level
  local text = pandoc.utils.stringify(elem.content)

  -- Check if header already has numbering (contains Chinese chapter numbering or Arabic numbering)
  local has_chinese_chapter = text:match("^第[一二三四五六七八九十百千万零壹贰叁肆伍陆柒捌玖拾%d]+章")
  local has_arabic_numbering = text:match("^%d+%.%d*")
  local has_simple_numbering = text:match("^%d+%.")

  -- If header already has numbering, preserve it as-is
  if has_chinese_chapter or has_arabic_numbering or has_simple_numbering then
    return elem
  end

  -- Initialize counters if not exists
  if not header_counters[level] then
    header_counters[level] = 0
  end

  -- Reset lower level counters when a higher level header appears
  for i = level + 1, 6 do
    header_counters[i] = 0
  end

  -- Increment current level counter
  header_counters[level] = header_counters[level] + 1

  -- Generate numbering based on level
  local numbering = ""
  if level == 1 then
    -- First level: 第X章 format
    local chinese_numbers = {"一", "二", "三", "四", "五", "六", "七", "八", "九", "十"}
    if header_counters[level] <= 10 then
      numbering = "第" .. chinese_numbers[header_counters[level]] .. "章 "
    else
      numbering = "第" .. header_counters[level] .. "章 "
    end
  elseif level == 2 then
    -- Second level: X.1 format
    local parent = header_counters[1] or 1
    numbering = parent .. "." .. header_counters[level] .. ". "
  elseif level == 3 then
    -- Third level: X.Y.Z format
    local parent1 = header_counters[1] or 1
    local parent2 = header_counters[2] or 1
    numbering = parent1 .. "." .. parent2 .. "." .. header_counters[level] .. ". "
  elseif level >= 4 then
    -- Fourth level and below: build full numbering chain
    numbering = ""
    for i = 1, level do
      if i == 1 then
        numbering = numbering .. (header_counters[i] or 1)
      else
        numbering = numbering .. "." .. (header_counters[i] or 1)
      end
    end
    numbering = numbering .. ". "
  end

  -- Create new content with numbering
  local new_content = {}
  table.insert(new_content, pandoc.Str(numbering))

  -- Add original content
  for _, inline in ipairs(elem.content) do
    table.insert(new_content, inline)
  end

  -- Return modified header
  return pandoc.Header(level, new_content, elem.attr)
end

-- Return the filter
return {
  {Header = Header}
}
