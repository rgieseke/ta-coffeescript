-- The coffeescript module for the
-- [Textadept](http://code.google.com/p/textadept/) editor.
-- It provides utilities for editing
-- [CoffeeScript](http://jashkenas.github.com/coffee-script/) code.<br>
-- It contains additional key commands, indentation support and
-- snippets, the latter based on Jeremy Ashkenas'
-- [Textmate bundle](https://github.com/jashkenas/coffee-script-tmbundle).
--
-- The source is on
-- [GitHub](https://github.com/rgieseke/textadept-coffeescript),
-- released under the
-- [MIT license](http://www.opensource.org/licenses/mit-license.php).
--
-- ## Installation
-- Download an
-- [archived](https://github.com/rgieseke/textadept-coffeescript/archives/master)
-- version or clone the git repository into your `.textadept` directory:
--     cd ~/.textadept/modules
--     git clone \
--       https://github.com/rgieseke/textadept-coffeescript.git \
--       coffeescript
--

module('_m.coffeescript', package.seeall)


-- ## Settings

-- Local variables.
local m_editing, m_run = _m.textadept.editing, _m.textadept.run
-- Comment string (uses lexer name).
m_editing.comment_string.coffeescript = '# '
-- Run command (uses file extension).
m_run.run_command.coffee = 'coffee -p %(filename)'

-- Sets default buffer properties for CoffeeScript files.
function set_buffer_properties()

end


-- ## Commands.

-- Control structures after which indentation should be increased. Loops can
-- be used as an expression, so the pattern need to start with a variable
-- name, see
-- [Loops and Comprehensions](http://jashkenas.github.com/coffee-script/#loops).
local control_structure_patterns = {
  '^%s*class',
  '^%s*%w*%s?=?%s?for',
  '^%s*if',
  '^%s*else',
  '^%s*switch',
  '^%s*when',
  '^%s*%w*%s?=?%s?while',
  '^%s*until',
  '^%s*loop',
  '^%s*try',
  '^%s*catch',
  '^%s*finally',
  '[%-=]>$',
  '[=:]$'
}

-- Increase indentation level after new line if line contains `for`,
-- `if`, etc., but only if at the end of a line.
local function indent()
  local buffer = buffer
  local current_pos = buffer.current_pos
  local line_num = buffer:line_from_position(current_pos)
  local col = buffer.column[current_pos]
  if col == 0 or buffer.current_pos ~= buffer.line_end_position[line_num] then
    return false
  end
  local line = buffer:get_line(line_num)
  local line_indentation = buffer.line_indentation
  for _, patt in ipairs(control_structure_patterns) do
    if line:find(patt) then
      local indent = line_indentation[line_num]
      buffer:begin_undo_action()
      buffer:new_line()
      line_indentation[line_num + 1] = indent + buffer.indent
      buffer:line_end()
      buffer:end_undo_action()
      return true
    end
  end
  return false
end

-- Insert clipboard content enclosed in backticks for raw JavaScript.
function insert_raw_js(args)
  local buffer = buffer
  buffer:begin_undo_action()
  buffer:add_text('``')
  buffer:char_left()
  buffer:paste()
  buffer:char_right()
  buffer:end_undo_action()
end

-- Insert [heredoc](http://jashkenas.github.com/coffee-script/#strings).<br>
-- Parameter:<br>
-- _char_: `"`, `'` or `#`
function insert_heredoc(char)
  local buffer = buffer
  buffer:begin_undo_action()
  local current_pos = buffer.current_pos
  local indentation = buffer.column[current_pos]
  local space = string.rep(" ", indentation)
  buffer:add_text(char:rep(3).."\n"..space.."\n"..space..char:rep(3))
  buffer:line_up()
  buffer:end_undo_action()
end


-- ## Key Commands

-- CoffeeScript-specific key commands.<br>
-- On the Mac the `Command` key is used instead of `Alt`.
_G.keys.coffeescript = {
  -- `Alt/⌘`+`L`, `M` Open this module for editing.
  al = {
    m = { io.open_file,
          (_USERHOME..'/modules/coffeescript/init.lua'):iconv('UTF-8', _CHARSET) },
    },
  -- `Ctrl`+`J` Insert clipboard contents enclosed in backticks for raw
  --   JavaScript.
  cj =  insert_raw_js,
  ['\n'] = indent,
  -- `Alt/⌘`+`"` Insert heredoc.
  ['a"'] = { insert_heredoc, '"' },
    -- `Alt/⌘`+`'` Insert heredoc.
  ["a'"] = { insert_heredoc, "'" },
    -- `Alt/⌘`+`#`: Insert block comment.
  ['a#'] = { insert_heredoc, '#' },
}


-- ## Snippets.

-- Container for Coffeescript-specific snippets.
if type(_G.snippets) == 'table' then
  _G.snippets.coffeescript = {
    -- Bound function.
    bfun = "%1((%2(args))) =>\n\t%0",
    -- Class.
    cla = [[
class %1(ClassName)%2( extends %3(Ancestor))
	%4(constructor: (%5(args)) ->
		%6(# body...))
	%0]],
    -- Else if.
    elif = "else if %1(condition)\n\t",
    -- Function.
    fun = [[
%1(name) = (%2(args)) ->
	%0]],
    -- If ... else.
    ife = [[
if %1(condition)
	%2
else
	%0]],
    -- If.
    ['if'] = [[
if %1(condition)
	%0]],
  -- Interpolated code in double-quoted strings.
  ['#'] = "#{ %0 }",
  -- Array comprehension.
  fora = "for %1(name) in %2(array)\n\t%0",
  -- Object comprehension.
  foro = "for %1(key), %2(value) of %3(Object)\n\t%0",
  -- Range comprehension (exclusive).
  forrex = "for %1(name) in [%2(start)...%3(finish)]%4( by %5(step))\n\t%0",
  -- Range comprehension (inclusive).
  forr = [[
for %1(name) in [%2(start)..%3(finish)]%4( by %5(step))
	%0]],
  -- Switch.
  swi = [[
switch %1(object)
	when %2(value)
		%0]],
  -- Ternary if.
  ifte = "if %1(condition) then %2(value) else %0",
  -- Try ... catch.
  try = [[
try
	%1
catch %2(error)
	%0]],
  -- Unless.
  unl = "%1(action) unless %0",
  -- Console.log.
  log = "console.log",
  c = "console.log",
  -- Require.
  req = "require",
  }
end
