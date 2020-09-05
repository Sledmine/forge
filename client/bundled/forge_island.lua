
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------

do
    local searchers = package.searchers or package.loaders
    local origin_seacher = searchers[2]
    searchers[2] = function(path)
        local files =
        {
------------------------
-- Modules part begin --
------------------------

["inspect"] = function()
--------------------
-- Module: 'inspect'
--------------------
local inspect ={
  _VERSION = 'inspect.lua 3.1.0',
  _URL     = 'http://github.com/kikito/inspect.lua',
  _DESCRIPTION = 'human-readable representations of tables',
  _LICENSE = [[
    MIT LICENSE

    Copyright (c) 2013 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local tostring = tostring

inspect.KEY       = setmetatable({}, {__tostring = function() return 'inspect.KEY' end})
inspect.METATABLE = setmetatable({}, {__tostring = function() return 'inspect.METATABLE' end})

local function rawpairs(t)
  return next, t, nil
end

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns a regular quoted string
local function smartQuote(str)
  if str:match('"') and not str:match("'") then
    return "'" .. str .. "'"
  end
  return '"' .. str:gsub('"', '\\"') .. '"'
end

-- \a => '\\a', \0 => '\\0', 31 => '\31'
local shortControlCharEscapes = {
  ["\a"] = "\\a",  ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
  ["\r"] = "\\r",  ["\t"] = "\\t", ["\v"] = "\\v"
}
local longControlCharEscapes = {} -- \a => nil, \0 => \000, 31 => \031
for i=0, 31 do
  local ch = string.char(i)
  if not shortControlCharEscapes[ch] then
    shortControlCharEscapes[ch] = "\\"..i
    longControlCharEscapes[ch]  = string.format("\\%03d", i)
  end
end

local function escape(str)
  return (str:gsub("\\", "\\\\")
             :gsub("(%c)%f[0-9]", longControlCharEscapes)
             :gsub("%c", shortControlCharEscapes))
end

local function isIdentifier(str)
  return type(str) == 'string' and str:match( "^[_%a][_%a%d]*$" )
end

local function isSequenceKey(k, sequenceLength)
  return type(k) == 'number'
     and 1 <= k
     and k <= sequenceLength
     and math.floor(k) == k
end

local defaultTypeOrders = {
  ['number']   = 1, ['boolean']  = 2, ['string'] = 3, ['table'] = 4,
  ['function'] = 5, ['userdata'] = 6, ['thread'] = 7
}

local function sortKeys(a, b)
  local ta, tb = type(a), type(b)

  -- strings and numbers are sorted numerically/alphabetically
  if ta == tb and (ta == 'string' or ta == 'number') then return a < b end

  local dta, dtb = defaultTypeOrders[ta], defaultTypeOrders[tb]
  -- Two default types are compared according to the defaultTypeOrders table
  if dta and dtb then return defaultTypeOrders[ta] < defaultTypeOrders[tb]
  elseif dta     then return true  -- default types before custom ones
  elseif dtb     then return false -- custom types after default ones
  end

  -- custom types are sorted out alphabetically
  return ta < tb
end

-- For implementation reasons, the behavior of rawlen & # is "undefined" when
-- tables aren't pure sequences. So we implement our own # operator.
local function getSequenceLength(t)
  local len = 1
  local v = rawget(t,len)
  while v ~= nil do
    len = len + 1
    v = rawget(t,len)
  end
  return len - 1
end

local function getNonSequentialKeys(t)
  local keys, keysLength = {}, 0
  local sequenceLength = getSequenceLength(t)
  for k,_ in rawpairs(t) do
    if not isSequenceKey(k, sequenceLength) then
      keysLength = keysLength + 1
      keys[keysLength] = k
    end
  end
  table.sort(keys, sortKeys)
  return keys, keysLength, sequenceLength
end

local function countTableAppearances(t, tableAppearances)
  tableAppearances = tableAppearances or {}

  if type(t) == 'table' then
    if not tableAppearances[t] then
      tableAppearances[t] = 1
      for k,v in rawpairs(t) do
        countTableAppearances(k, tableAppearances)
        countTableAppearances(v, tableAppearances)
      end
      countTableAppearances(getmetatable(t), tableAppearances)
    else
      tableAppearances[t] = tableAppearances[t] + 1
    end
  end

  return tableAppearances
end

local copySequence = function(s)
  local copy, len = {}, #s
  for i=1, len do copy[i] = s[i] end
  return copy, len
end

local function makePath(path, ...)
  local keys = {...}
  local newPath, len = copySequence(path)
  for i=1, #keys do
    newPath[len + i] = keys[i]
  end
  return newPath
end

local function processRecursive(process, item, path, visited)
  if item == nil then return nil end
  if visited[item] then return visited[item] end

  local processed = process(item, path)
  if type(processed) == 'table' then
    local processedCopy = {}
    visited[item] = processedCopy
    local processedKey

    for k,v in rawpairs(processed) do
      processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
      if processedKey ~= nil then
        processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
      end
    end

    local mt  = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
    if type(mt) ~= 'table' then mt = nil end -- ignore not nil/table __metatable field
    setmetatable(processedCopy, mt)
    processed = processedCopy
  end
  return processed
end



-------------------------------------------------------------------

local Inspector = {}
local Inspector_mt = {__index = Inspector}

function Inspector:puts(...)
  local args   = {...}
  local buffer = self.buffer
  local len    = #buffer
  for i=1, #args do
    len = len + 1
    buffer[len] = args[i]
  end
end

function Inspector:down(f)
  self.level = self.level + 1
  f()
  self.level = self.level - 1
end

function Inspector:tabify()
  self:puts(self.newline, string.rep(self.indent, self.level))
end

function Inspector:alreadyVisited(v)
  return self.ids[v] ~= nil
end

function Inspector:getId(v)
  local id = self.ids[v]
  if not id then
    local tv = type(v)
    id              = (self.maxIds[tv] or 0) + 1
    self.maxIds[tv] = id
    self.ids[v]     = id
  end
  return tostring(id)
end

function Inspector:putKey(k)
  if isIdentifier(k) then return self:puts(k) end
  self:puts("[")
  self:putValue(k)
  self:puts("]")
end

function Inspector:putTable(t)
  if t == inspect.KEY or t == inspect.METATABLE then
    self:puts(tostring(t))
  elseif self:alreadyVisited(t) then
    self:puts('<table ', self:getId(t), '>')
  elseif self.level >= self.depth then
    self:puts('{...}')
  else
    if self.tableAppearances[t] > 1 then self:puts('<', self:getId(t), '>') end

    local nonSequentialKeys, nonSequentialKeysLength, sequenceLength = getNonSequentialKeys(t)
    local mt                = getmetatable(t)

    self:puts('{')
    self:down(function()
      local count = 0
      for i=1, sequenceLength do
        if count > 0 then self:puts(',') end
        self:puts(' ')
        self:putValue(t[i])
        count = count + 1
      end

      for i=1, nonSequentialKeysLength do
        local k = nonSequentialKeys[i]
        if count > 0 then self:puts(',') end
        self:tabify()
        self:putKey(k)
        self:puts(' = ')
        self:putValue(t[k])
        count = count + 1
      end

      if type(mt) == 'table' then
        if count > 0 then self:puts(',') end
        self:tabify()
        self:puts('<metatable> = ')
        self:putValue(mt)
      end
    end)

    if nonSequentialKeysLength > 0 or type(mt) == 'table' then -- result is multi-lined. Justify closing }
      self:tabify()
    elseif sequenceLength > 0 then -- array tables have one extra space before closing }
      self:puts(' ')
    end

    self:puts('}')
  end
end

function Inspector:putValue(v)
  local tv = type(v)

  if tv == 'string' then
    self:puts(smartQuote(escape(v)))
  elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
         tv == 'cdata' or tv == 'ctype' then
    self:puts(tostring(v))
  elseif tv == 'table' then
    self:putTable(v)
  else
    self:puts('<', tv, ' ', self:getId(v), '>')
  end
end

-------------------------------------------------------------------

function inspect.inspect(root, options)
  options       = options or {}

  local depth   = options.depth   or math.huge
  local newline = options.newline or '\n'
  local indent  = options.indent  or '  '
  local process = options.process

  if process then
    root = processRecursive(process, root, {}, {})
  end

  local inspector = setmetatable({
    depth            = depth,
    level            = 0,
    buffer           = {},
    ids              = {},
    maxIds           = {},
    newline          = newline,
    indent           = indent,
    tableAppearances = countTableAppearances(root)
  }, Inspector_mt)

  inspector:putValue(root)

  return table.concat(inspector.buffer)
end

setmetatable(inspect, { __call = function(_, ...) return inspect.inspect(...) end })

return inspect


end,

["glue"] = function()
--------------------
-- Module: 'glue'
--------------------

-- Lua extended vocabulary of basic tools.
-- Written by Cosmin Apreutesei. Public domain.
-- Modifications by Sled

local glue = {}

local min, max, floor, ceil, log =
	math.min, math.max, math.floor, math.ceil, math.log
local select, unpack, pairs, rawget = select, unpack, pairs, rawget

--math -----------------------------------------------------------------------

function glue.round(x, p)
	p = p or 1
	return floor(x / p + .5) * p
end

function glue.floor(x, p)
	p = p or 1
	return floor(x / p) * p
end

function glue.ceil(x, p)
	p = p or 1
	return ceil(x / p) * p
end

glue.snap = glue.round

function glue.clamp(x, x0, x1)
	return min(max(x, x0), x1)
end

function glue.lerp(x, x0, x1, y0, y1)
	return y0 + (x-x0) * ((y1-y0) / (x1 - x0))
end

function glue.nextpow2(x)
	return max(0, 2^(ceil(log(x) / log(2))))
end

--varargs --------------------------------------------------------------------

if table.pack then
	glue.pack = table.pack
else
	function glue.pack(...)
		return {n = select('#', ...), ...}
	end
end

--always use this because table.unpack's default j is #t not t.n.
function glue.unpack(t, i, j)
	return unpack(t, i or 1, j or t.n or #t)
end

--tables ---------------------------------------------------------------------

--count the keys in a table with an optional upper limit.
function glue.count(t, maxn)
	local maxn = maxn or 1/0
	local n = 0
	for _ in pairs(t) do
		n = n + 1
		if n >= maxn then break end
	end
	return n
end

--reverse keys with values.
function glue.index(t)
	local dt={}
	for k,v in pairs(t) do dt[v]=k end
	return dt
end

--put keys in a list, optionally sorted.
local function desc_cmp(a, b) return a > b end
function glue.keys(t, cmp)
	local dt={}
	for k in pairs(t) do
		dt[#dt+1]=k
	end
	if cmp == true or cmp == 'asc' then
		table.sort(dt)
	elseif cmp == 'desc' then
		table.sort(dt, desc_cmp)
	elseif cmp then
		table.sort(dt, cmp)
	end
	return dt
end

--stateless pairs() that iterate elements in key order.
function glue.sortedpairs(t, cmp)
	local kt = glue.keys(t, cmp or true)
	local i = 0
	return function()
		i = i + 1
		return kt[i], t[kt[i]]
	end
end

--update a table with the contents of other table(s).
function glue.update(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t then
			for k,v in pairs(t) do dt[k]=v end
		end
	end
	return dt
end

--add the contents of other table(s) without overwrite.
function glue.merge(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t then
			for k,v in pairs(t) do
				if rawget(dt, k) == nil then dt[k]=v end
			end
		end
	end
	return dt
end

--get the value of a table field, and if the field is not present in the
--table, create it as an empty table, and return it.
function glue.attr(t, k, v0)
	local v = t[k]
	if v == nil then
		if v0 == nil then
			v0 = {}
		end
		v = v0
		t[k] = v
	end
	return v
end

--lists ----------------------------------------------------------------------

--extend a list with the elements of other lists.
function glue.extend(dt,...)
	for j=1,select('#',...) do
		local t=select(j,...)
		if t then
			local j = #dt
			for i=1,#t do dt[j+i]=t[i] end
		end
	end
	return dt
end

--append non-nil arguments to a list.
function glue.append(dt,...)
	local j = #dt
	for i=1,select('#',...) do
		dt[j+i] = select(i,...)
	end
	return dt
end

--insert n elements at i, shifting elemens on the right of i (i inclusive)
--to the right.
local function insert(t, i, n)
	if n == 1 then --shift 1
		table.insert(t, i, false)
		return
	end
	for p = #t,i,-1 do --shift n
		t[p+n] = t[p]
	end
end

--remove n elements at i, shifting elements on the right of i (i inclusive)
--to the left.
local function remove(t, i, n)
	n = min(n, #t-i+1)
	if n == 1 then --shift 1
		table.remove(t, i)
		return
	end
	for p=i+n,#t do --shift n
		t[p-n] = t[p]
	end
	for p=#t,#t-n+1,-1 do --clean tail
		t[p] = nil
	end
end

--shift all the elements on the right of i (i inclusive) to the left
--or further to the right.
function glue.shift(t, i, n)
	if n > 0 then
		insert(t, i, n)
	elseif n < 0 then
		remove(t, i, -n)
	end
	return t
end

--map f over t or extract a column from a list of records.
function glue.map(t, f, ...)
	local dt = {}
	if #t == 0 then --treat as hashmap
		if type(f) == 'function' then
			for k,v in pairs(t) do
				dt[k] = f(k, v, ...)
			end
		else
			for k,v in pairs(t) do
				local sel = v[f]
				if type(sel) == 'function' then --method to apply
					dt[k] = sel(v, ...)
				else --field to pluck
					dt[k] = sel
				end
			end
		end
	else --treat as array
		if type(f) == 'function' then
			for i,v in ipairs(t) do
				dt[i] = f(v, ...)
			end
		else
			for i,v in ipairs(t) do
				local sel = v[f]
				if type(sel) == 'function' then --method to apply
					dt[i] = sel(v, ...)
				else --field to pluck
					dt[i] = sel
				end
			end
		end
	end
	return dt
end

--arrays ---------------------------------------------------------------------

--scan list for value. works with ffi arrays too given i and j.
function glue.indexof(v, t, eq, i, j)
	i = i or 1
	j = j or #t
	if eq then
		for i = i, j do
			if eq(t[i], v) then
				return i
			end
		end
	else
		for i = i, j do
			if t[i] == v then
				return i
			end
		end
	end
end

--- Return the index of a table/array if value exists
---@param array table
---@param value any
function glue.arrayhas(array, value)
	for k,v in pairs(array) do
		if (v == value) then return k end
	end
	return nil
end

--- Get the new values of an array
---@param oldarray table
---@param newarray table
function glue.arraynv(oldarray, newarray)
	local newvalues = {}
	for k,v in pairs(newarray) do
		if (not glue.arrayhas(oldarray, v)) then
			glue.append(newvalues, v)
		end
	end
	return newvalues
end

--reverse elements of a list in place. works with ffi arrays too given i and j.
function glue.reverse(t, i, j)
	i = i or 1
	j = (j or #t) + 1
	for k = 1, (j-i)/2 do
		t[i+k-1], t[j-k] = t[j-k], t[i+k-1]
	end
	return t
end

--- Get all the values of a key recursively
---@param t table
---@param dp any
function glue.childsbyparent(t, dp)
    for p,ch in pairs(t) do
		if (p == dp) then
			return ch
		end
		if (ch) then
			local found = glue.childsbyparent(ch, dp)
			if (found) then
				return found
			end
		end
    end
    return nil
end

-- Get the key of a value recursively
---@param t table
---@param dp any
function glue.parentbychild(t, dp)
    for p,ch in pairs(t) do
		if (ch[dp]) then
			return p
		end
		if (ch) then
			local found = glue.parentbychild(ch, dp)
			if (found) then
				return found
			end
		end
    end
    return nil
end

--- Split a list/array into small parts of given size
---@param list table
---@param chunks number
function glue.chunks(list, chunks)
	local chunkcounter = 0
	local chunk = {}
	local chunklist = {}
	-- Append chunks to the list in the specified amount of elements
	for k,v in pairs(list) do
		if (chunkcounter == chunks) then
			glue.append(chunklist, chunk)
			chunk = {}
			chunkcounter = 0
		end
		glue.append(chunk, v)
		chunkcounter = chunkcounter + 1
	end
	-- If there was a chunk that was not completed append it
	if (chunkcounter ~= 0) then
		glue.append(chunklist, chunk)
	end
	return chunklist
end

--binary search for an insert position that keeps the table sorted.
--works with ffi arrays too if lo and hi are provided.
local cmps = {}
cmps['<' ] = function(t, i, v) return t[i] <  v end
cmps['>' ] = function(t, i, v) return t[i] >  v end
cmps['<='] = function(t, i, v) return t[i] <= v end
cmps['>='] = function(t, i, v) return t[i] >= v end
local less = cmps['<']
function glue.binsearch(v, t, cmp, lo, hi)
	lo, hi = lo or 1, hi or #t
	cmp = cmp and cmps[cmp] or cmp or less
	local len = hi - lo + 1
	if len == 0 then return nil end
	if len == 1 then return not cmp(t, lo, v) and lo or nil end
	while lo < hi do
		local mid = floor(lo + (hi - lo) / 2)
		if cmp(t, mid, v) then
			lo = mid + 1
			if lo == hi and cmp(t, lo, v) then
				return nil
			end
		else
			hi = mid
		end
	end
	return lo
end

--strings --------------------------------------------------------------------

--string submodule. has its own namespace which can be merged with _G.string.
glue.string = {}

--- Split a string list/array given a separator string
function glue.string.split(s, sep)
    if (sep == nil or sep == '') then return 1 end
    local position, array = 0, {}
    for st, sp in function() return string.find(s, sep, position, true) end do
        table.insert(array, string.sub(s, position, st-1))
        position = sp + 1
    end
    table.insert(array, string.sub(s, position))
    return array
end

--split a string by a separator that can be a pattern or a plain string.
--return a stateless iterator for the pieces.
local function iterate_once(s, s1)
	return s1 == nil and s or nil
end
function glue.string.gsplit(s, sep, start, plain)
	start = start or 1
	plain = plain or false
	if not s:find(sep, start, plain) then
		return iterate_once, s:sub(start)
	end
	local done = false
	local function pass(i, j, ...)
		if i then
			local seg = s:sub(start, i - 1)
			start = j + 1
			return seg, ...
		else
			done = true
			return s:sub(start)
		end
	end
	return function()
		if done then return end
		if sep == '' then done = true; return s:sub(start) end
		return pass(s:find(sep, start, plain))
	end
end

--split a string into lines, optionally including the line terminator.
function glue.lines(s, opt)
	local term = opt == '*L'
	local patt = term and '([^\r\n]*()\r?\n?())' or '([^\r\n]*)()\r?\n?()'
	local next_match = s:gmatch(patt)
	local empty = s == ''
	local ended --string ended with no line ending
	return function()
		local s, i1, i2 = next_match()
		if s == nil then return end
		if s == '' and not empty and ended then s = nil end
		ended = i1 == i2
		return s
	end
end

--string trim12 from lua wiki.
function glue.string.trim(s)
	local from = s:match('^%s*()')
	return from > #s and '' or s:match('.*%S', from)
end

--escape a string so that it can be matched literally inside a pattern.
local function format_ci_pat(c)
	return ('[%s%s]'):format(c:lower(), c:upper())
end
function glue.string.esc(s, mode) --escape is a reserved word in Terra
	s = s:gsub('%%','%%%%'):gsub('%z','%%z')
		:gsub('([%^%$%(%)%.%[%]%*%+%-%?])', '%%%1')
	if mode == '*i' then s = s:gsub('[%a]', format_ci_pat) end
	return s
end

--string or number to hex.
function glue.string.tohex(s, upper)
	if type(s) == 'number' then
		return (upper and '%08.8X' or '%08.8x'):format(s)
	end
	if upper then
		return (s:gsub('.', function(c)
		  return ('%02X'):format(c:byte())
		end))
	else
		return (s:gsub('.', function(c)
		  return ('%02x'):format(c:byte())
		end))
	end
end

--hex to binary string.
function glue.string.fromhex(s)
	if #s % 2 == 1 then
		return glue.string.fromhex('0'..s)
	end
	return (s:gsub('..', function(cc)
	  return string.char(tonumber(cc, 16))
	end))
end

function glue.string.starts(s, p) --5x faster than s:find'^...' in LuaJIT 2.1
	return s:sub(1, #p) == p
end

function glue.string.ends(s, p)
	return p == '' or s:sub(-#p) == p
end

function glue.string.subst(s, t) --subst('{foo} {bar}', {foo=1, bar=2}) -> '1 2'
	return s:gsub('{([_%w]+)}', t)
end

--publish the string submodule in the glue namespace.
glue.update(glue, glue.string)

--iterators ------------------------------------------------------------------

--run an iterator and collect the n-th return value into a list.
local function select_at(i,...)
	return ...,select(i,...)
end
local function collect_at(i,f,s,v)
	local t = {}
	repeat
		v,t[#t+1] = select_at(i,f(s,v))
	until v == nil
	return t
end
local function collect_first(f,s,v)
	local t = {}
	repeat
		v = f(s,v); t[#t+1] = v
	until v == nil
	return t
end
function glue.collect(n,...)
	if type(n) == 'number' then
		return collect_at(n,...)
	else
		return collect_first(n,...)
	end
end

--closures -------------------------------------------------------------------

--no-op filters.
function glue.pass(...) return ... end
function glue.noop() return end

--memoize for 0, 1, 2-arg and vararg and 1 retval functions.
local function memoize0(fn) --for strict no-arg functions
	local v, stored
	return function()
		if not stored then
			v = fn(); stored = true
		end
		return v
	end
end
local nilkey = {}
local nankey = {}
local function memoize1(fn) --for strict single-arg functions
	local cache = {}
	return function(arg)
		local k = arg == nil and nilkey or arg ~= arg and nankey or arg
		local v = cache[k]
		if v == nil then
			v = fn(arg); cache[k] = v == nil and nilkey or v
		else
			if v == nilkey then v = nil end
		end
		return v
	end
end
local function memoize2(fn) --for strict two-arg functions
	local cache = {}
	return function(a1, a2)
		local k1 = a1 ~= a1 and nankey or a1 == nil and nilkey or a1
		local cache2 = cache[k1]
		if cache2 == nil then
			cache2 = {}
			cache[k1] = cache2
		end
		local k2 = a2 ~= a2 and nankey or a2 == nil and nilkey or a2
		local v = cache2[k2]
		if v == nil then
			v = fn(a1, a2)
			cache2[k2] = v == nil and nilkey or v
		else
			if v == nilkey then v = nil end
		end
		return v
	end
end
local function memoize_vararg(fn, minarg, maxarg)
	local cache = {}
	local values = {}
	return function(...)
		local key = cache
		local narg = min(max(select('#',...), minarg), maxarg)
		for i = 1, narg do
			local a = select(i,...)
			local k = a ~= a and nankey or a == nil and nilkey or a
			local t = key[k]
			if not t then
				t = {}; key[k] = t
			end
			key = t
		end
		local v = values[key]
		if v == nil then
			v = fn(...); values[key] = v == nil and nilkey or v
		end
		if v == nilkey then v = nil end
		return v
	end
end
local memoize_narg = {[0] = memoize0, memoize1, memoize2}
local function choose_memoize_func(func, narg)
	if narg then
		local memoize_narg = memoize_narg[narg]
		if memoize_narg then
			return memoize_narg
		else
			return memoize_vararg, narg, narg
		end
	else
		local info = debug.getinfo(func, 'u')
		if info.isvararg then
			return memoize_vararg, info.nparams, 1/0
		else
			return choose_memoize_func(func, info.nparams)
		end
	end
end
function glue.memoize(func, narg)
	local memoize, minarg, maxarg = choose_memoize_func(func, narg)
	return memoize(func, minarg, maxarg)
end

--memoize a function with multiple return values.
function glue.memoize_multiret(func, narg)
	local memoize, minarg, maxarg = choose_memoize_func(func, narg)
	local function wrapper(...)
		return glue.pack(func(...))
	end
	local func = memoize(wrapper, minarg, maxarg)
	return function(...)
		return glue.unpack(func(...))
	end
end

local tuple_mt = {__call = glue.unpack}
function tuple_mt:__tostring()
	local t = {}
	for i=1,self.n do
		t[i] = tostring(self[i])
	end
	return string.format('(%s)', table.concat(t, ', '))
end
function glue.tuples(narg)
	return glue.memoize(function(...)
		return setmetatable(glue.pack(...), tuple_mt)
	end)
end

--objects --------------------------------------------------------------------

--set up dynamic inheritance by creating or updating a table's metatable.
function glue.inherit(t, parent)
	local meta = getmetatable(t)
	if meta then
		meta.__index = parent
	elseif parent ~= nil then
		setmetatable(t, {__index = parent})
	end
	return t
end

--prototype-based dynamic inheritance with __call constructor.
function glue.object(super, o, ...)
	o = o or {}
	o.__index = super
	o.__call = super and super.__call
	glue.update(o, ...) --add mixins, defaults, etc.
	return setmetatable(o, o)
end

local function install(self, combine, method_name, hook)
	rawset(self, method_name, combine(self[method_name], hook))
end
local function before(method, hook)
	if method then
		return function(self, ...)
			hook(self, ...)
			return method(self, ...)
		end
	else
		return hook
	end
end
function glue.before(self, method_name, hook)
	install(self, before, method_name, hook)
end
local function after(method, hook)
	if method then
		return function(self, ...)
			method(self, ...)
			return hook(self, ...)
		end
	else
		return hook
	end
end
function glue.after(self, method_name, hook)
	install(self, after, method_name, hook)
end
local function override(method, hook)
	local method = method or glue.noop
	return function(...)
		return hook(method, ...)
	end
end
function glue.override(self, method_name, hook)
	install(self, override, method_name, hook)
end

--return a metatable that supports virtual properties.
--can be used with setmetatable() and ffi.metatype().
function glue.gettersandsetters(getters, setters, super)
	local get = getters and function(t, k)
		local get = getters[k]
		if get then return get(t) end
		return super and super[k]
	end
	local set = setters and function(t, k, v)
		local set = setters[k]
		if set then set(t, v); return end
		rawset(t, k, v)
	end
	return {__index = get, __newindex = set}
end

--i/o ------------------------------------------------------------------------

--check if a file exists and can be opened for reading or writing.
function glue.canopen(name, mode)
	local f = io.open(name, mode or 'rb')
	if f then f:close() end
	return f ~= nil and name or nil
end

--read a file into a string (in binary mode by default).
function glue.readfile(name, mode, open)
	open = open or io.open
	local f, err = open(name, mode=='t' and 'r' or 'rb')
	if not f then return nil, err end
	local s, err = f:read'*a'
	if s == nil then return nil, err end
	f:close()
	return s
end

--read the output of a command into a string.
function glue.readpipe(cmd, mode, open)
	return glue.readfile(cmd, mode, open or io.popen)
end

--like os.rename() but behaves like POSIX on Windows too.
if jit then

	local ffi = require'ffi'

	if ffi.os == 'Windows' then

		ffi.cdef[[
			int MoveFileExA(
				const char *lpExistingFileName,
				const char *lpNewFileName,
				unsigned long dwFlags
			);
			int GetLastError(void);
		]]

		local MOVEFILE_REPLACE_EXISTING = 1
		local MOVEFILE_WRITE_THROUGH    = 8
		local ERROR_FILE_EXISTS         = 80
		local ERROR_ALREADY_EXISTS      = 183

		function glue.replacefile(oldfile, newfile)
			if ffi.C.MoveFileExA(oldfile, newfile, 0) ~= 0 then
				return true
			end
			local err = ffi.C.GetLastError()
			if err == ERROR_FILE_EXISTS or err == ERROR_ALREADY_EXISTS then
				if ffi.C.MoveFileExA(oldfile, newfile,
					bit.bor(MOVEFILE_WRITE_THROUGH, MOVEFILE_REPLACE_EXISTING)) ~= 0
				then
					return true
				end
				err = ffi.C.GetLastError()
			end
			return nil, 'WinAPI error '..err
		end

	else

		function glue.replacefile(oldfile, newfile)
			return os.rename(oldfile, newfile)
		end

	end

end

--write a string, number, table or the results of a read function to a file.
--uses binary mode by default.
function glue.writefile(filename, s, mode, tmpfile)
	if tmpfile then
		local ok, err = glue.writefile(tmpfile, s, mode)
		if not ok then
			return nil, err
		end
		local ok, err = glue.replacefile(tmpfile, filename)
		if not ok then
			os.remove(tmpfile)
			return nil, err
		else
			return true
		end
	end
	local f, err = io.open(filename, mode=='t' and 'w' or 'wb')
	if not f then
		return nil, err
	end
	local ok, err
	if type(s) == 'table' then
		for i = 1, #s do
			ok, err = f:write(s[i])
			if not ok then break end
		end
	elseif type(s) == 'function' then
		local read = s
		while true do
			ok, err = xpcall(read, debug.traceback)
			if not ok or err == nil then break end
			ok, err = f:write(err)
			if not ok then break end
		end
	else --string or number
		ok, err = f:write(s)
	end
	f:close()
	if not ok then
		os.remove(filename)
		return nil, err
	else
		return true
	end
end

--virtualize the print function.
function glue.printer(out, format)
	format = format or tostring
	return function(...)
		local n = select('#', ...)
		for i=1,n do
			out(format((select(i, ...))))
			if i < n then
				out'\t'
			end
		end
		out'\n'
	end
end

--dates & timestamps ---------------------------------------------------------

--compute timestamp diff. to UTC because os.time() has no option for UTC.
function glue.utc_diff(t)
   local d1 = os.date( '*t', 3600 * 24 * 10)
   local d2 = os.date('!*t', 3600 * 24 * 10)
	d1.isdst = false
	return os.difftime(os.time(d1), os.time(d2))
end

--overloading os.time to support UTC and get the date components as separate args.
function glue.time(utc, y, m, d, h, M, s, isdst)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, y, m, d, h, M, s, isdst = nil, utc, y, m, d, h, M, s
	end
	if type(y) == 'table' then
		local t = y
		if utc == nil then utc = t.utc end
		y, m, d, h, M, s, isdst = t.year, t.month, t.day, t.hour, t.min, t.sec, t.isdst
	end
	local utc_diff = utc and glue.utc_diff() or 0
	if not y then
		return os.time() + utc_diff
	else
		s = s or 0
		local t = os.time{year = y, month = m or 1, day = d or 1, hour = h or 0,
			min = M or 0, sec = s, isdst = isdst}
		return t and t + s - floor(s) + utc_diff
	end
end

--get the time at the start of the week of a given time, plus/minus a number of weeks.
function glue.sunday(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year, d.month, d.day - (d.wday - 1) + (offset or 0) * 7)
end

--get the time at the start of the day of a given time, plus/minus a number of days.
function glue.day(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year, d.month, d.day + (offset or 0))
end

--get the time at the start of the month of a given time, plus/minus a number of months.
function glue.month(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year, d.month + (offset or 0))
end

--get the time at the start of the year of a given time, plus/minus a number of years.
function glue.year(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year + (offset or 0))
end

--error handling -------------------------------------------------------------

--allocation-free assert() with string formatting.
--NOTE: unlike standard assert(), this only returns the first argument
--to avoid returning the error message and it's args along with it so don't
--use it with functions returning multiple values when you want those values.
function glue.assert(v, err, ...)
	if v then return v end
	err = err or 'assertion failed!'
	if select('#',...) > 0 then
		err = string.format(err, ...)
	end
	error(err, 2)
end

--pcall with traceback. LuaJIT and Lua 5.2 only.
local function pcall_error(e)
	return debug.traceback('\n'..tostring(e))
end
function glue.pcall(f, ...)
	return xpcall(f, pcall_error, ...)
end

local function unprotect(ok, result, ...)
	if not ok then return nil, result, ... end
	if result == nil then result = true end --to distinguish from error.
	return result, ...
end

--wrap a function that raises errors on failure into a function that follows
--the Lua convention of returning nil,err on failure.
function glue.protect(func)
	return function(...)
		return unprotect(pcall(func, ...))
	end
end

--pcall with finally and except "clauses":
--		local ret,err = fpcall(function(finally, except)
--			local foo = getfoo()
--			finally(function() foo:free() end)
--			except(function(err) io.stderr:write(err, '\n') end)
--		emd)
--NOTE: a bit bloated at 2 tables and 4 closures. Can we reduce the overhead?
local function fpcall(f,...)
	local fint, errt = {}, {}
	local function finally(f) fint[#fint+1] = f end
	local function onerror(f) errt[#errt+1] = f end
	local function err(e)
		for i=#errt,1,-1 do errt[i](e) end
		for i=#fint,1,-1 do fint[i]() end
		return tostring(e) .. '\n' .. debug.traceback()
	end
	local function pass(ok,...)
		if ok then
			for i=#fint,1,-1 do fint[i]() end
		end
		return ok,...
	end
	return pass(xpcall(f, err, finally, onerror, ...))
end

function glue.fpcall(...)
	return unprotect(fpcall(...))
end

--fcall is like fpcall() but without the protection (i.e. raises errors).
local function assert_fpcall(ok, ...)
	if not ok then error(..., 2) end
	return ...
end
function glue.fcall(...)
	return assert_fpcall(fpcall(...))
end

--modules --------------------------------------------------------------------

--create a module table that dynamically inherits another module.
--naming the module returns the same module table for the same name.
function glue.module(name, parent)
	if type(name) ~= 'string' then
		name, parent = parent, name
	end
	if type(parent) == 'string' then
		parent = require(parent)
	end
	parent = parent or _M
	local parent_P = parent and assert(parent._P, 'parent module has no _P') or _G
	local M = package.loaded[name]
	if M then
		return M, M._P
	end
	local P = {__index = parent_P}
	M = {__index = parent, _P = P}
	P._M = M
	M._M = M
	P._P = P
	setmetatable(P, P)
	setmetatable(M, M)
	if name then
		package.loaded[name] = M
		P[name] = M
	end
	setfenv(2, P)
	return M, P
end

--setup a module to load sub-modules when accessing specific keys.
function glue.autoload(t, k, v)
	local mt = getmetatable(t) or {}
	if not mt.__autoload then
		local old_index = mt.__index
	 	local submodules = {}
		mt.__autoload = submodules
		mt.__index = function(t, k)
			--overriding __index...
			if type(old_index) == 'function' then
				local v = old_index(t, k)
				if v ~= nil then return v end
			elseif type(old_index) == 'table' then
				local v = old_index[k]
				if v ~= nil then return v end
			end
			if submodules[k] then
				local mod
				if type(submodules[k]) == 'string' then
					mod = require(submodules[k]) --module
				else
					mod = submodules[k](k) --custom loader
				end
				submodules[k] = nil --prevent loading twice
				if type(mod) == 'table' then --submodule returned its module table
					assert(mod[k] ~= nil) --submodule has our symbol
					t[k] = mod[k]
				end
				return rawget(t, k)
			end
		end
		setmetatable(t, mt)
	end
	if type(k) == 'table' then
		glue.update(mt.__autoload, k) --multiple key -> module associations.
	else
		mt.__autoload[k] = v --single key -> module association.
	end
	return t
end

--portable way to get script's directory, based on arg[0].
--NOTE: the path is not absolute, but relative to the current directory!
--NOTE: for bundled executables, this returns the executable's directory.
local dir = rawget(_G, 'arg') and arg[0]
	and arg[0]:gsub('[/\\]?[^/\\]+$', '') or '' --remove file name
glue.bin = dir == '' and '.' or dir

--portable way to add more paths to package.path, at any place in the list.
--negative indices count from the end of the list like string.sub().
--index 'after' means 0.
function glue.luapath(path, index, ext)
	ext = ext or 'lua'
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local paths = glue.collect(glue.gsplit(package.path, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. psep .. 'init.' .. ext)
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.path = table.concat(paths, tsep)
end

--portable way to add more paths to package.cpath, at any place in the list.
--negative indices count from the end of the list like string.sub().
--index 'after' means 0.
function glue.cpath(path, index)
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local ext = package.cpath:match('%.([%a]+)%'..tsep..'?') --dll | so | dylib
	local paths = glue.collect(glue.gsplit(package.cpath, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.cpath = table.concat(paths, tsep)
end

--allocation -----------------------------------------------------------------

--freelist for Lua tables.
local function create_table()
	return {}
end
function glue.freelist(create, destroy)
	create = create or create_table
	destroy = destroy or glue.noop
	local t = {}
	local n = 0
	local function alloc()
		local e = t[n]
		if e then
			t[n] = false
			n = n - 1
		end
		return e or create()
	end
	local function free(e)
		destroy(e)
		n = n + 1
		t[n] = e
	end
	return alloc, free
end

--ffi ------------------------------------------------------------------------

if jit then

local ffi = require'ffi'

--static, auto-growing buffer allocation pattern (ctype must be vla).
function glue.buffer(ctype)
	local vla = ffi.typeof(ctype)
	local buf, len = nil, -1
	return function(minlen)
		if minlen == false then
			buf, len = nil, -1
		elseif minlen > len then
			len = glue.nextpow2(minlen)
			buf = vla(len)
		end
		return buf, len
	end
end

--like glue.buffer() but preserves data on reallocations
--also returns minlen instead of capacity.
function glue.dynarray(ctype)
	local buffer = glue.buffer(ctype)
	local elem_size = ffi.sizeof(ctype, 1)
	local buf0, minlen0
	return function(minlen)
		local buf, len = buffer(minlen)
		if buf ~= buf0 and buf ~= nil and buf0 ~= nil then
			ffi.copy(buf, buf0, minlen0 * elem_size)
		end
		buf0, minlen0 = buf, minlen
		return buf, minlen
	end
end

local intptr_ct = ffi.typeof'intptr_t'
local intptrptr_ct = ffi.typeof'const intptr_t*'
local intptr1_ct = ffi.typeof'intptr_t[1]'
local voidptr_ct = ffi.typeof'void*'

--x86: convert a pointer's address to a Lua number.
local function addr32(p)
	return tonumber(ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p)))
end

--x86: convert a number to a pointer, optionally specifying a ctype.
local function ptr32(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	return ffi.cast(ctype, addr)
end

--x64: convert a pointer's address to a Lua number or possibly string.
local function addr64(p)
	local np = ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p))
   local n = tonumber(np)
	if ffi.cast(intptr_ct, n) ~= np then
		--address too big (ASLR? tagged pointers?): convert to string.
		return ffi.string(intptr1_ct(np), 8)
	end
	return n
end

--x64: convert a number or string to a pointer, optionally specifying a ctype.
local function ptr64(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	if type(addr) == 'string' then
		return ffi.cast(ctype, ffi.cast(voidptr_ct,
			ffi.cast(intptrptr_ct, addr)[0]))
	else
		return ffi.cast(ctype, addr)
	end
end

glue.addr = ffi.abi'64bit' and addr64 or addr32
glue.ptr = ffi.abi'64bit' and ptr64 or ptr32

end --if jit

if bit then

	local band, bor, bnot = bit.band, bit.bor, bit.bnot

	--extract the bool value of a bitmask from a value.
	function glue.getbit(from, mask)
		return band(from, mask) == mask
	end

	--set a single bit of a value without affecting other bits.
	function glue.setbit(over, mask, yes)
		return bor(yes and mask or 0, band(over, bnot(mask)))
	end

	local function bor_bit(bits, k, mask, strict)
		local b = bits[k]
		if b then
			return bit.bor(mask, b)
		elseif strict then
			error(string.format('invalid bit %s', k))
		else
			return mask
		end
	end
	function glue.bor(flags, bits, strict)
		local mask = 0
		if type(flags) == 'number' then
			return flags --passthrough
		elseif type(flags) == 'string' then
			for k in flags:gmatch'[^%s]+' do
				mask = bor_bit(bits, k, mask, strict)
			end
		elseif type(flags) == 'table' then
			for k,v in pairs(flags) do
				k = type(k) == 'number' and v or k
				mask = bor_bit(bits, k, mask, strict)
			end
		else
			error'flags expected'
		end
		return mask
	end

end

return glue

end,

["json"] = function()
--------------------
-- Module: 'json'
--------------------
--
-- json.lua
--
-- Copyright (c) 2019 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\\\",
  [ "\"" ] = "\\\"",
  [ "\b" ] = "\\b",
  [ "\f" ] = "\\f",
  [ "\n" ] = "\\n",
  [ "\r" ] = "\\r",
  [ "\t" ] = "\\t",
}

local escape_char_map_inv = { [ "\\/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return escape_char_map[c] or string.format("\\u%04x", c:byte())
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end


function json.encode(val)
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(3, 6),  16 )
  local n2 = tonumber( s:sub(9, 12), 16 )
  -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local has_unicode_escape = false
  local has_surrogate_escape = false
  local has_escape = false
  local last
  for j = i + 1, #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")
    end

    if last == 92 then -- "\\" (escape char)
      if x == 117 then -- "u" (unicode escape sequence)
        local hex = str:sub(j + 1, j + 5)
        if not hex:find("%x%x%x%x") then
          decode_error(str, j, "invalid unicode escape in string")
        end
        if hex:find("^[dD][89aAbB]") then
          has_surrogate_escape = true
        else
          has_unicode_escape = true
        end
      else
        local c = string.char(x)
        if not escape_chars[c] then
          decode_error(str, j, "invalid escape char '" .. c .. "' in string")
        end
        has_escape = true
      end
      last = nil

    elseif x == 34 then -- '"' (end of string)
      local s = str:sub(i + 1, j - 1)
      if has_surrogate_escape then
        s = s:gsub("\\u[dD][89aAbB]..\\u....", parse_unicode_escape)
      end
      if has_unicode_escape then
        s = s:gsub("\\u....", parse_unicode_escape)
      end
      if has_escape then
        s = s:gsub("\\.", escape_char_map_inv)
      end
      return s, j + 1

    else
      last = x
    end
  end
  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end


return json

end,

["lua-redux"] = function()
--------------------
-- Module: 'lua-redux'
--------------------
local ActionTypes = {
  INIT = "@@lua-redux/INIT"
}

local function inverse(table)
  local newTable = { }
  for k, v in pairs(table) do
    newTable[v] = k
  end
  return newTable
end

local function createStore(reducer, preloadedState)
  local store = {
    reducer = reducer,
    state = preloadedState,
    subscribers = {}
  }

  function store:subscribe(callback)
    local i = table.insert(self.subscribers, callback)
    return function()
      table.remove(self.subscribers, inverse(self.subscribers)[callback])
    end
  end
  function store:dispatch(action)
    self.state = self.reducer(self.state, action)
    for k, v in pairs(self.subscribers) do
      v()
    end
  end
  function store:getState()
    return self.state
  end
  function store:replaceReducer(reducer)
    self.reducer = reducer
    self:dispatch({
      type = ActionTypes.INIT
    })
  end

  store:dispatch({
    type = ActionTypes.INIT
  })

  return store
end

return {
  ActionTypes = ActionTypes,
  createStore = createStore
}

end,

["nlua-blam"] = function()
--------------------
-- Module: 'nlua-blam'
--------------------
------------------------------------------------------------------------------
-- Blam! library for Chimera/SAPP Lua scripting
-- Sledmine, JerryBrick
-- Version 4.2
-- Improves memory handle and provides standard functions for scripting
------------------------------------------------------------------------------
local luablam = {version = 4.1}

------------------------------------------------------------------------------
-- Useful functions for internal use
------------------------------------------------------------------------------

-- From legacy glue library!
--- String or number to hex
local function tohex(s, upper)
    if type(s) == "number" then
        return (upper and "%08.8X" or "%08.8x"):format(s)
    end
    if upper then
        return (s:sub(".", function(c)
            return ("%02X"):format(c:byte())
        end))
    else
        return (s:gsub(".", function(c)
            return ("%02x"):format(c:byte())
        end))
    end
end

--- Hex to binary string
local function fromhex(s)
    if #s % 2 == 1 then
        return fromhex("0" .. s)
    end
    return (s:gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

------------------------------------------------------------------------------
-- Blam! engine data
------------------------------------------------------------------------------

-- Address list
local addressList = {
    tagDataHeader = 0x40440000,
    cameraType = 0x00647498, -- from Giraffe
    gamePaused = 0x004ACA79,
    gameOnMenus = 0x00622058
}

-- Provide global tag classes by default
local tagClasses = {
    actorVariant = "actv",
    actor = "actr",
    antenna = "ant!",
    biped = "bipd",
    bitmap = "bitm",
    cameraTrack = "trak",
    colorTable = "colo",
    continuousDamageEffect = "cdmg",
    contrail = "cont",
    damageEffect = "jpt!",
    decal = "deca",
    detailObjectCollection = "dobc",
    deviceControl = "ctrl",
    deviceLightFixture = "lifi",
    deviceMachine = "mach",
    device = "devi",
    dialogue = "udlg",
    effect = "effe",
    equipment = "eqip",
    flag = "flag",
    fog = "fog ",
    font = "font",
    garbage = "garb",
    gbxmodel = "mod2",
    globals = "matg",
    glow = "glw!",
    grenadeHudInterface = "grhi",
    hudGlobals = "hudg",
    hudMessageText = "hmt ",
    hudNumber = "hud#",
    itemCollection = "itmc",
    item = "item",
    lensFlare = "lens",
    lightVolume = "mgs2",
    light = "ligh",
    lightning = "elec",
    materialEffects = "foot",
    meter = "metr",
    modelAnimations = "antr",
    modelCollisiionGeometry = "coll",
    model = "mode",
    multiplayerScenarioDescription = "mply",
    object = "obje",
    particleSystem = "pctl",
    particle = "part",
    physics = "phys",
    placeHolder = "plac",
    pointPhysics = "pphy",
    preferencesNetworkGame = "ngpr",
    projectile = "proj",
    scenarioStructureBsp = "sbsp",
    scenario = "scnr",
    scenery = "scen",
    shaderEnvironment = "senv",
    shaderModel = "soso",
    shaderTransparentChicagoExtended = "scex",
    shaderTransparentChicago = "schi",
    shaderTransparentGeneric = "sotr",
    shaderTransparentGlass = "sgla",
    shaderTransparentMeter = "smet",
    shaderTransparentPlasma = "spla",
    shaderTransparentWater = "swat",
    shader = "shdr",
    sky = "sky ",
    soundEnvironment = "snde",
    soundLooping = "lsnd",
    soundScenery = "ssce",
    sound = "snd!",
    spheroid = "boom",
    stringList = "str#",
    tagCollection = "tagc",
    uiWidgetCollection = "Soul",
    uiWidgetDefinition = "DeLa",
    unicodeStringList = "ustr",
    unitHudInterface = "unhi",
    unit = "unit",
    vehicle = "vehi",
    virtualKeyboard = "vcky",
    weaponHudInterface = "wphi",
    weapon = "weap",
    weatherParticleSystem = "rain",
    wind = "wind"
}

-- Provide global object classes by default
local objectClasses = {
    biped = 0,
    vehicle = 1,
    weapon = 2,
    equipment = 3,
    garbage = 4,
    projectile = 5,
    scenery = 6,
    machine = 7,
    control = 8,
    lightFixture = 9,
    placeHolder = 10,
    soundScenery = 11
}

-- Camera types
local cameraTypes = {
    scripted = 1, -- 22192
    firstPerson = 2, -- 30400
    devcam = 3, -- 30704
    thirdPerson = 4, -- 31952
    deadCamera = 5 -- 23776
}

local netgameFlagTypes = {
    ctfFlag = 0,
    ctfVehicle = 1,
    ballSpawn = 2,
    raceTrack = 3,
    raceVehicle = 4,
    vegasBank = 5,
    teleportFrom = 6,
    teleportTo = 7,
    hillFlag = 8
}

local netgameEquipmentTypes = {
    none = 0,
    ctf = 1,
    slayer = 2,
    oddball = 3,
    koth = 4,
    race = 5,
    terminator = 6,
    stub = 7,
    ignored1 = 8,
    ignored2 = 9,
    ignored3 = 10,
    ignored4 = 11,
    allGames = 12,
    allExceptCtf = 13,
    allExceptRaceCtf = 14
}

-- Console colors
local consoleColors = {
    success = {1, 0.235, 0.82, 0},
    warning = {1, 0.94, 0.75, 0.098},
    error = {1, 1, 0.2, 0.2},
    unknow = {1, 0.66, 0.66, 0.66}
}

------------------------------------------------------------------------------
-- SAPP API bindings
------------------------------------------------------------------------------

if (api_version) then
    -- Create and bind Chimera functions to the ones in SAPP

    --- Return the memory address of a tag given tag id or type and path
    ---@param tag string | number
    ---@param path string
    ---@return number
    function get_tag(tag, path)
        if (not path) then
            return lookup_tag(tag)
        else
            return lookup_tag(tag, path)
        end
    end

    --- Execute a game command or script block
    ---@param command string
    function execute_script(command)
        return execute_command(command)
    end

    --- Return the address of the object memory given object id
    ---@param objectId number
    ---@return number
    function get_object(objectId)
        if (objectId) then
            local object_memory = get_object_memory(objectId)
            if (object_memory ~= 0) then
                return object_memory
            end
        end
        return nil
    end

    --- Delete an object given object id
    ---@param objectId number
    function delete_object(objectId)
        destroy_object(objectId)
    end

    --- Print text into console
    ---@param message string
    function console_out(message)
        cprint(message)
    end

    print("Chimera API functions are available now with LuaBlam!")
end

------------------------------------------------------------------------------
-- Generic functions
------------------------------------------------------------------------------

--- Verify if the given variable is a number
---@param var any
---@return boolean
local function isNumber(var)
    return (type(var) == "number")
end

--- Verify if the given variable is a string
---@param var any
---@return boolean
local function isString(var)
    return (type(var) == "string")
end

--- Verify if the given variable is a boolean
---@param var any
---@return boolean
local function isBoolean(var)
    return (type(var) == "boolean")
end

--- Verify if the given variable is a table
---@param var any
---@return boolean
local function isTable(var)
    return (type(var) == "table")
end

--- Remove spaces and tabs from the beginning and the end of a string
---@param str string
---@return string
local function trim(str)
    return str:match "^%s*(.*)":match "(.-)%s*$"
end

--- Verify if the value is valid
---@param var any
---@return boolean
local function isValid(var)
    return (var and var ~= "" and var ~= 0)
end

------------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------------

--- Convert tag class int to string
---@param tagClassInt number
---@return string
local function tagClassFromInt(tagClassInt)
    if (tagClassInt) then
        local tagClassHex = tohex(tagClassInt)
        local tagClass = ""
        if (tagClassHex) then
            local byte = ""
            for char in string.gmatch(tagClassHex, ".") do
                byte = byte .. char
                if (#byte % 2 == 0) then
                    tagClass = tagClass .. string.char(tonumber(byte, 16))
                    byte = ""
                end
            end
        end
        return tagClass
    end
    return nil
end

--- Return the current existing objects in the current map, ONLY WORKS FOR CHIMERA!!!
---@return table
local function getObjects()
    local currentObjectsList = {}
    for i = 0, 2047 do
        if (get_object(i)) then
            currentObjectsList[#currentObjectsList + 1] = i
        end
    end
    return currentObjectsList
end

--- Return the string of a unicode string given address
---@param address number
---@return string
local function readUnicodeString(address)
    local stringAddress = read_dword(address)
    local length = stringAddress / 2
    local output = ""
    for i = 1, length do
        local char = read_string(stringAddress + (i - 1) * 0x2)
        if (char == "") then
            break
        end
        output = output .. char
    end
    return output
end

--- Writes a unicode string in a given address
---@param address number
---@param newString string
local function writeUnicodeString(address, newString)
    local stringAddress = read_dword(address)
    for i = 1, #newString do
        write_string(stringAddress + (i - 1) * 0x2, newString:sub(i, i))
        if (i == #newString) then
            write_byte(stringAddress + #newString * 0x2, 0x0)
        end
    end
end

-- Local reference to the original console_out function
local original_console_out = console_out

--- Print a console message. It also supports multi-line messages!
---@param message string
local function consoleOutput(message, ...)
    -- Put the extra arguments into a table
    local args = {...}

    if (message == nil or #args > 5) then
        consoleOutput(debug.traceback("Wrong number of arguments on console output function", 2),
                      consoleColors.error)
    end

    -- Output color
    local colorARGB = {1, 1, 1, 1}

    -- Get the output color from arguments table
    if (isTable(args[1])) then
        colorARGB = args[1]
    elseif (#args == 3 or #args == 4) then
        colorARGB = args
    end

    -- Set alpha channel if not set
    if (#colorARGB == 3) then
        table.insert(colorARGB, 1, 1)
    end

    if (isString(message)) then
        -- Explode the string!!
        for line in message:gmatch("([^\n]+)") do
            -- Trim the line
            local trimmedLine = trim(line)

            -- Print the line
            original_console_out(trimmedLine, table.unpack(colorARGB))
        end
    else
        original_console_out(message, table.unpack(colorARGB))
    end
end

--- Convert booleans to bits and bits to booleans
---@param bitOrBool number
---@return boolean | number
local function b2b(bitOrBool)
    if (bitOrBool == 1) then
        return true
    elseif (bitOrBool == 0) then
        return false
    elseif (bitOrBool == true) then
        return 1
    elseif (bitOrBool == false) then
        return 0
    end
    error("B2B error, expected boolean or bit value, got " .. tostring(bitOrBool) .. " " ..
                  type(bitOrBool))
end

------------------------------------------------------------------------------
-- Objects data binding
------------------------------------------------------------------------------

-- Data types operations
local dataOperations = {
    bit = {read_bit, write_bit},
    byte = {read_byte, write_byte},
    short = {read_short, write_short},
    word = {read_word, write_word},
    int = {read_int, write_int},
    dword = {read_dword, write_dword},
    float = {read_float, write_float},
    string = {read_string, write_string},
    ustring = {
        readUnicodeString,
        writeUnicodeString
    }
}

-- Magic luablam metatable
local dataBindingMetaTable = {
    __newindex = function(object, property, propertyValue)
        local propertyData = object.structure[property]
        if (propertyData) then
            local dataType = propertyData.type
            local operation = dataOperations[dataType]
            if (dataType == "bit") then
                local bitLevel = propertyData.bitLevel
                operation[2](object.address + propertyData.offset, bitLevel, b2b(propertyValue))
            elseif (dataType == "list") then
                operation = dataOperations[propertyData.elementsType]
                local listCount = read_byte(object.address + propertyData.offset - 0x4)
                local listAddress = read_dword(object.address + propertyData.offset)
                -- // FIXME: What tha heck i means here Jerry???
                for i = 1, listCount do
                    if (propertyValue[i] ~= nil) then
                        operation[2](listAddress + 0xC + propertyData.jump * (i - 1),
                                     propertyValue[i])
                    else
                        if (i > #propertyValue) then
                            break
                        end
                    end
                end
            elseif (dataType == "table") then
                local elementsCount = read_byte(object.address + propertyData.offset - 0x4)
                local firstElement = read_dword(object.address + propertyData.offset)
                -- // TODO: Some values here were renamed, check if they are accurate
                for i = 1, elementsCount do
                    local elementAddress = firstElement + (i - 1) * propertyData.jump
                    if (propertyValue[i]) then
                        for subProperty, subPropertyValue in pairs(propertyValue[i]) do
                            local fieldData = propertyData.rows[subProperty]
                            if (fieldData) then
                                operation = dataOperations[fieldData.type]
                                if (fieldData.type == "bit") then
                                    operation[2](elementAddress + fieldData.offset,
                                                 fieldData.bitLevel, b2b(subPropertyValue))
                                else
                                    operation[2](elementAddress + fieldData.offset, subPropertyValue)
                                end
                            end
                        end
                    else
                        if (i > #propertyValue) then
                            break
                        end
                    end
                end
            else
                operation[2](object.address + propertyData.offset, propertyValue)
            end
        else
            local errorMessage = "Unable to write an invalid property ('" .. property .. "')"
            consoleOutput(debug.traceback(errorMessage, 2), consoleColors.error)
        end
    end,
    __index = function(object, property)
        local objectStructure = object.structure
        local propertyData = objectStructure[property]
        if (propertyData) then
            local dataType = propertyData.type
            local operation = dataOperations[dataType]
            if (dataType == "bit") then
                local bitLevel = propertyData.bitLevel
                return b2b(operation[1](object.address + propertyData.offset, bitLevel))
            elseif (dataType == "list") then
                operation = dataOperations[propertyData.elementsType]
                local listCount = read_byte(object.address + propertyData.offset - 0x4)
                local listAddress = read_dword(object.address + propertyData.offset)
                local list = {}
                for i = 1, listCount do
                    list[i] = operation[1](listAddress + 0xC + propertyData.jump * (i - 1))
                end
                return list
            elseif (dataType == "table") then
                local table = {}
                local elementsCount = read_byte(object.address + propertyData.offset - 0x4)
                local firstElement = read_dword(object.address + propertyData.offset)
                for elementPosition = 1, elementsCount do
                    local elementAddress = firstElement + (elementPosition - 1) * propertyData.jump
                    table[elementPosition] = {}
                    -- // FIXME: What tha heck Jerry means here with k,v ???!!!
                    for k, v in pairs(propertyData.rows) do
                        operation = dataOperations[v.type]
                        if (v.type == "bit") then
                            table[elementPosition][k] =
                                b2b(operation[1](elementAddress + v.offset, v.bitLevel))
                        else
                            table[elementPosition][k] = operation[1](elementAddress + v.offset)
                        end
                    end
                end
                return table
            else
                if (not operation) then
                    console_out(property)
                end
                return operation[1](object.address + propertyData.offset)
            end
        else
            local errorMessage = "Unable to read an invalid property ('" .. property .. "')"
            consoleOutput(debug.traceback(errorMessage, 2), consoleColors.error)
        end
    end
}

------------------------------------------------------------------------------
-- Object functions
------------------------------------------------------------------------------

--- Create a LuaBlam object
---@param address number
---@param struct table
---@return table
local function createObject(address, struct)
    -- Create object
    local object = {}

    -- Set up legacy values
    object.address = address
    object.structure = struct

    -- Set mechanisim to bind properties to memory
    setmetatable(object, dataBindingMetaTable)

    return object
end

--- Return a dump of a given LuaBlam object
---@param object table
---@return table
local function dumpObject(object)
    local dump = {}
    for k, v in pairs(object.structure) do
        dump[k] = object[k]
    end
    return dump
end

------------------------------------------------------------------------------
-- Object structures
------------------------------------------------------------------------------

--- Return a extended parent structure with another given structure
---@param parent table
---@param structure table
---@return table
local function extendStructure(parent, structure)
    local extendedStructure = {}
    for k, v in pairs(parent) do
        extendedStructure[k] = v
    end
    for k, v in pairs(structure) do
        extendedStructure[k] = v
    end
    return extendedStructure
end

---@class blamObject
---@field address number
---@field tagId number Object tag ID
---@field hasCollision boolean Check if object has or has not collision
---@field isOnGround boolean Is the object touching ground
---@field ignoreGravity boolean Make object to ignore gravity
---@field isInWater boolean Is the object touching on water
---@field dynamicShading boolean Enable disable dynamic shading for lightmaps
---@field isNotCastingShadow boolean Enable/disable object shadow casting
---@field frozen boolean Freeze/unfreeze object existence
---@field isOutSideMap boolean Is object outside/inside bsp
---@field isCollideable boolean Enable/disable object shadow casting
---@field model number Gbxmodel tag ID
---@field health number Current health of the object
---@field shield number Current shield of the object
---@field redA number Red color channel for A modifier
---@field greenA number Green color channel for A modifier
---@field blueA number Blue color channel for A modifier
---@field x number Current position of the object on X axis
---@field y number Current position of the object on Y axis
---@field z number Current position of the object on Z axis
---@field xVel number Current velocity of the object on X axis
---@field yVel number Current velocity of the object on Y axis
---@field zVel number Current velocity of the object on Z axis
---@field vX number Current x value in first rotation vector
---@field vY number Current y value in first rotation vector
---@field vZ number Current z value in first rotation vector
---@field v2X number Current x value in second rotation vector
---@field v2Y number Current y value in second rotation vector
---@field v2Z number Current z value in second rotation vector
---@field yawVel number Current velocity of the object in yaw
---@field pitchVel number Current velocity of the object in pitch
---@field rollVel number Current velocity of the object in roll
---@field locationId number Current id of the location in the map
---@field boundingRadius number Radius amount of the object in radians
---@field type number Object type
---@field team number Object multiplayer team
---@field playerId number Current player id if the object
---@field parentId number Current parent id of the object
---@field attachedToObjectId number Current id
---@field isHealthEmpty boolean Is the object health deploeted, also marked as "dead"
---@field animationTagId number Current animation tag ID
---@field animation number Current animation index
---@field animationFrame number Current animation frame
---@field regionPermutation1 number
---@field regionPermutation2 number
---@field regionPermutation3 number
---@field regionPermutation4 number
---@field regionPermutation5 number
---@field regionPermutation6 number
---@field regionPermutation7 number
---@field regionPermutation8 number

-- blamObject structure
local objectStructure = {
    tagId = {type = "dword", offset = 0x0},
    hasCollision = {
        type = "bit",
        offset = 0x10,
        bitLevel = 0
    },
    isOnGround = {
        type = "bit",
        offset = 0x10,
        bitLevel = 1
    },
    ignoreGravity = {
        type = "bit",
        offset = 0x10,
        bitLevel = 2
    },
    isInWater = {
        type = "bit",
        offset = 0x10,
        bitLevel = 3
    },
    isStationary = {
        type = "bit",
        offset = 0x10,
        bitLevel = 5
    },
    dynamicShading = {
        type = "bit",
        offset = 0x10,
        bitLevel = 14
    },
    isNotCastingShadow = {
        type = "bit",
        offset = 0x10,
        bitLevel = 18
    },
    frozen = {
        type = "bit",
        offset = 0x10,
        bitLevel = 20
    },
    isOutSideMap = {
        type = "bit",
        offset = 0x10,
        bitLevel = 21
    },
    isCollideable = {
        type = "bit",
        offset = 0x10,
        bitLevel = 24
    },
    model = {type = "dword", offset = 0x34},
    health = {type = "float", offset = 0xE0},
    shield = {type = "float", offset = 0xE4},
    redA = {type = "float", offset = 0x1B8},
    greenA = {type = "float", offset = 0x1BC},
    blueA = {type = "float", offset = 0x1C0},
    x = {type = "float", offset = 0x5C},
    y = {type = "float", offset = 0x60},
    z = {type = "float", offset = 0x64},
    xVel = {type = "float", offset = 0x68},
    yVel = {type = "float", offset = 0x6C},
    zVel = {type = "float", offset = 0x70},
    vX = {type = "float", offset = 0x74},
    vY = {type = "float", offset = 0x78},
    vZ = {type = "float", offset = 0x7C},
    v2X = {type = "float", offset = 0x80},
    v2Y = {type = "float", offset = 0x84},
    v2Z = {type = "float", offset = 0x88},
    yawVel = {type = "float", offset = 0x8C},
    pitchVel = {type = "float", offset = 0x90},
    rollVel = {type = "float", offset = 0x94},
    locationId = {type = "dword", offset = 0x98},
    boundingRadius = {
        type = "float",
        offset = 0xAC
    },
    type = {type = "word", offset = 0xB4},
    team = {type = "word", offset = 0xB8},
    playerId = {type = "dword", offset = 0xC0},
    parentId = {type = "dword", offset = 0xC4},
    attachedToObjectId = {type = "dword", offset = 0x11C},
    -- Experimental name properties
    isHealthEmpty = {
        type = "bit",
        offset = 0x106,
        bitLevel = 2
    },
    animationTagId = {
        type = "dword",
        offset = 0xCC
    },
    animation = {type = "word", offset = 0xD0},
    animationFrame = {
        type = "word",
        offset = 0xD2
    },
    regionPermutation1 = {
        type = "byte",
        offset = 0x180
    },
    regionPermutation2 = {
        type = "byte",
        offset = 0x181
    },
    regionPermutation3 = {
        type = "byte",
        offset = 0x182
    },
    regionPermutation4 = {
        type = "byte",
        offset = 0x183
    },
    regionPermutation5 = {
        type = "byte",
        offset = 0x184
    },
    regionPermutation6 = {
        type = "byte",
        offset = 0x185
    },
    regionPermutation7 = {
        type = "byte",
        offset = 0x186
    },
    regionPermutation8 = {
        type = "byte",
        offset = 0x187
    }
}

-- Biped structure (extends object structure)
local bipedStructure = extendStructure(objectStructure, {
    invisible = {
        type = "bit",
        offset = 0x204,
        bitLevel = 4
    },
    noDropItems = {
        type = "bit",
        offset = 0x204,
        bitLevel = 20
    },
    ignoreCollision = {
        type = "bit",
        offset = 0x4CC,
        bitLevel = 3
    },
    flashlight = {
        type = "bit",
        offset = 0x204,
        bitLevel = 19
    },
    cameraX = {type = "float", offset = 0x230},
    cameraY = {type = "float", offset = 0x234},
    cameraZ = {type = "float", offset = 0x238},
    crouchHold = {
        type = "bit",
        offset = 0x208,
        bitLevel = 0
    },
    jumpHold = {
        type = "bit",
        offset = 0x208,
        bitLevel = 1
    },
    actionKeyHold = {
        type = "bit",
        offset = 0x208,
        bitLevel = 14
    },
    actionKey = {
        type = "bit",
        offset = 0x208,
        bitLevel = 6
    },
    meleeKey = {
        type = "bit",
        offset = 0x208,
        bitLevel = 7
    },
    reloadKey = {
        type = "bit",
        offset = 0x208,
        bitLevel = 10
    },
    weaponPTH = {
        type = "bit",
        offset = 0x208,
        bitLevel = 11
    },
    weaponSTH = {
        type = "bit",
        offset = 0x208,
        bitLevel = 12
    },
    flashlightKey = {
        type = "bit",
        offset = 0x208,
        bitLevel = 4
    },
    grenadeHold = {
        type = "bit",
        offset = 0x208,
        bitLevel = 13
    },
    crouch = {type = "byte", offset = 0x2A0},
    shooting = {type = "float", offset = 0x284},
    weaponSlot = {type = "byte", offset = 0x2A1},
    zoomLevel = {type = "byte", offset = 0x320},
    invisibleScale = {
        type = "byte",
        offset = 0x37C
    },
    primaryNades = {type = "byte", offset = 0x31E},
    secondaryNades = {
        type = "byte",
        offset = 0x31F
    }
})

-- Tag data header structure
local tagDataHeaderStructure = {
    array = {type = "dword", offset = 0x0},
    scenario = {type = "dword", offset = 0x4},
    count = {type = "word", offset = 0xC}
}

-- Tag structure
local tagHeaderStructure = {
    class = {type = "dword", offset = 0x0},
    index = {type = "word", offset = 0xC},
    id = {type = "word", offset = 0xE},
    fullId = {type = "dword", offset = 0xC},
    path = {type = "dword", offset = 0x10},
    data = {type = "dword", offset = 0x14},
    indexed = {type = "dword", offset = 0x18}
}

-- tagCollection structure
local tagCollectionStructure = {
    count = {type = "byte", offset = 0x0},
    tagList = {
        type = "list",
        offset = 0x4,
        elementsType = "dword",
        jump = 0x10
    }
}

-- UnicodeStringList structure
local unicodeStringListStructure = {
    count = {type = "byte", offset = 0x0},
    stringList = {
        type = "list",
        offset = 0x4,
        elementsType = "ustring",
        jump = 0x14
    }
}

-- UI Widget Definition structure
local uiWidgetDefinitionStructure = {
    type = {type = "word", offset = 0x0},
    controllerIndex = {
        type = "word",
        offset = 0x2
    },
    name = {type = "string", offset = 0x4},
    boundsY = {type = "short", offset = 0x24},
    boundsX = {type = "short", offset = 0x26},
    height = {type = "short", offset = 0x28},
    width = {type = "short", offset = 0x2A},
    backgroundBitmap = {
        type = "word",
        offset = 0x44
    },
    eventType = {type = "byte", offset = 0x03F0},
    tagReference = {type = "word", offset = 0x400},
    childWidgetsCount = {
        type = "dword",
        offset = 0x03E0
    },
    childWidgetsList = {
        type = "list",
        offset = 0x03E4,
        elementsType = "dword",
        jump = 0x50
    }
}

-- uiWidgetCollection structure
local uiWidgetCollectionStructure = {
    count = {type = "byte", offset = 0x0},
    tagList = {
        type = "list",
        offset = 0x4,
        elementsType = "dword",
        jump = 0x10
    }
}

-- Weapon HUD Interface structure
local weaponHudInterfaceStructure = {
    crosshairs = {type = "word", offset = 0x84},
    defaultBlue = {type = "byte", offset = 0x208},
    defaultGreen = {type = "byte", offset = 0x209},
    defaultRed = {type = "byte", offset = 0x20A},
    defaultAlpha = {type = "byte", offset = 0x20B},
    sequenceIndex = {
        type = "short",
        offset = 0x22A
    }
}

-- Scenario structure
local scenarioStructure = {
    sceneryPaletteCount = {
        type = "byte",
        offset = 0x021C
    },
    sceneryPaletteList = {
        type = "list",
        offset = 0x0220,
        elementsType = "dword",
        jump = 0x30
    },
    spawnLocationCount = {
        type = "byte",
        offset = 0x354
    },
    spawnLocationList = {
        type = "table",
        offset = 0x358,
        jump = 0x34,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8},
            rotation = {
                type = "float",
                offset = 0xC
            },
            teamIndex = {
                type = "byte",
                offset = 0x10
            },
            bspIndex = {
                type = "short",
                offset = 0x12
            },
            type = {type = "byte", offset = 0x14}
        }
    },
    vehicleLocationCount = {
        type = "byte",
        offset = 0x240
    },
    vehicleLocationList = {
        type = "table",
        offset = 0x244,
        jump = 0x78,
        rows = {
            type = {type = "word", offset = 0x0},
            nameIndex = {
                type = "word",
                offset = 0x2
            },
            x = {type = "float", offset = 0x8},
            y = {type = "float", offset = 0xC},
            z = {type = "float", offset = 0x10},
            yaw = {type = "float", offset = 0x14},
            pitch = {
                type = "float",
                offset = 0x18
            },
            roll = {type = "float", offset = 0x1C}
        }
    },
    netgameFlagsCount = {
        type = "byte",
        offset = 0x378
    },
    netgameFlagsList = {
        type = "table",
        offset = 0x37C,
        jump = 0x94,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8},
            rotation = {
                type = "float",
                offset = 0xC
            },
            type = {type = "byte", offset = 0x10},
            teamIndex = {
                type = "word",
                offset = 0x12
            }
        }
    },
    netgameEquipmentCount = {
        type = "byte",
        offset = 0x384
    },
    netgameEquipmentList = {
        type = "table",
        offset = 0x388,
        jump = 0x90,
        rows = {
            levitate = {
                type = "bit",
                offset = 0x0,
                bitLevel = 0
            },
            type1 = {type = "word", offset = 0x4},
            type2 = {type = "word", offset = 0x6},
            type3 = {type = "word", offset = 0x8},
            type4 = {type = "word", offset = 0xA},
            teamIndex = {
                type = "byte",
                offset = 0xC
            },
            spawnTime = {
                type = "word",
                offset = 0xE
            },
            x = {type = "float", offset = 0x40},
            y = {type = "float", offset = 0x44},
            z = {type = "float", offset = 0x48},
            facing = {
                type = "float",
                offset = 0x4C
            },
            itemCollection = {
                type = "dword",
                offset = 0x5C
            }
        }
    }
}

-- Scenery structure
local sceneryStructure = {
    model = {type = "word", offset = 0x28 + 0xC},
    modifierShader = {
        type = "word",
        offset = 0x90 + 0xC
    }
}

-- Collision Model structure
local collisionGeometryStructure = {
    vertexCount = {type = "byte", offset = 0x408},
    vertexList = {
        type = "table",
        offset = 0x40C,
        jump = 0x10,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8}
        }
    }
}

-- Model Animation structure
local modelAnimationsStructure = {
    fpAnimationCount = {
        type = "byte",
        offset = 0x90
    },
    fpAnimationList = {
        type = "list",
        offset = 0x94,
        elementsType = "byte",
        jump = 0x2
    },
    animationCount = {
        type = "byte",
        offset = 0x74
    },
    animationList = {
        type = "table",
        offset = 0x78,
        jump = 0xB4,
        rows = {
            name = {type = "string", offset = 0x0},
            type = {type = "word", offset = 0x20},
            frameCount = {
                type = "byte",
                offset = 0x22
            },
            nextAnimation = {
                type = "byte",
                offset = 0x38
            },
            sound = {type = "byte", offset = 0x3C}
        }
    }
}

-- Weapon structure
local weaponStructure = {
    model = {type = "dword", offset = 0x34}
}

-- Model structure
local modelStructure = {
    nodeCount = {type = "dword", offset = 0xB8},
    nodeList = {
        type = "table",
        offset = 0xBC,
        jump = 0x9C,
        rows = {
            x = {type = "float", offset = 0x28},
            y = {type = "float", offset = 0x2C},
            z = {type = "float", offset = 0x30}
        }
    },
    regionCount = {type = "dword", offset = 0xC4},
    regionList = {
        type = "table",
        offset = 0xC8,
        jump = 76,
        rows = {
            permutationCount = {
                type = "dword",
                offset = 0x40
            }
        }
    }
}

------------------------------------------------------------------------------
-- Object classes
------------------------------------------------------------------------------

---@return blamObject
local function objectClassNew(address)
    return createObject(address, objectStructure)
end

---@class biped : blamObject
---@field invisible boolean Biped invisible state
---@field noDropItems boolean Biped ability to drop items at dead
---@field ignoreCollision boolean Biped ignores collisiion
---@field flashlight boolean Biped has flaslight enabled
---@field cameraX number Current position of the biped  X axis
---@field cameraY number Current position of the biped  Y axis
---@field cameraZ number Current position of the biped  Z axis
---@field crouchHold boolean Biped is holding crouch action
---@field jumpHold boolean Biped is holding jump action
---@field actionKeyHold boolean Biped is holding action key
---@field actionKey boolean Biped pressed action key
---@field meleeKey boolean Biped pressed melee key
---@field reloadKey boolean Biped pressed reload key
---@field weaponPTH boolean Biped is holding primary weapon trigger
---@field weaponSTH boolean Biped is holding secondary weapon trigger
---@field flashlightKey boolean Biped pressed flashlight key
---@field grenadeHold boolean Biped is holding grenade action
---@field crouch number Is biped crouch
---@field shooting number Is biped shooting, 0 when not, 1 when shooting
---@field weaponSlot number Current biped weapon slot
---@field zoomLevel number Current biped weapon zoom level, 0xFF when no zoom, up to 255 when zoomed
---@field invisibleScale number Opacity amount of biped invisiblity
---@field primaryNades number Primary grenades count
---@field secondaryNades number Secondary grenades count
---@field landing number Biped landing state, 0 when landing, stays on 0 when landing hard

---@return biped
local function bipedClassNew(address)
    return createObject(address, bipedStructure)
end

---@class tag
---@field class number Type of the tag
---@field id number Tag ID
---@field path string Path of the tag
---@field indexed boolean Is the tag indexed?

---@return tag
local function tagClassNew(address)
    return createObject(address, tagHeaderStructure)
end

---@class tagCollection
---@field count number Number of tags in the collection
---@field tagList table List of tags

---@return tagCollection
local function tagCollectionNew(address)
    return createObject(address, tagCollectionStructure)
end

---@class unicodeStringList
---@field count number Number of unicode strings
---@field stringList table List of unicode strings

---@return unicodeStringList
local function unicodeStringListClassNew(address)
    return createObject(address, unicodeStringListStructure)
end

---@class uiWidgetDefinition
---@field type number Type of widget
---@field controllerIndex number Index of the player controller
---@field name string Name of the widget
---@field boundsY number Top bound of the widget
---@field boundsX number Left bound of the widget
---@field height number Bottom bound of the widget
---@field width number Right bound of the widget
---@field backgroundBitmap number Tag ID of the background bitmap
---@field eventType number
---@field tagReference number
---@field childWidgetsCount number Number of child widgets
---@field childWidgetsList table tag ID list of the child widgets

---@return uiWidgetDefinition
local function uiWidgetDefinitionClassNew(address)
    return createObject(address, uiWidgetDefinitionStructure)
end

---@class uiWidgetCollection
---@field count number Number of widgets in the collection
---@field tagList table Tag ID list of the widgets

---@return uiWidgetCollection
local function uiWidgetCollectionClassNew(address)
    return createObject(address, uiWidgetCollectionStructure)
end

---@class weaponHudInterface
---@field crosshairs number
---@field defaultBlue number
---@field defaultGreen number
---@field defaultRed number
---@field defaultAlpha number
---@field sequenceIndex number

local function weaponHudInterfaceClassNew(address)
    return createObject(address, weaponHudInterfaceStructure)
end

---@class scenario
---@field sceneryPaletteCount number Number of sceneries in the scenery palette
---@field sceneryPaletteList table Tag ID list of scenerys in the scenery palette
---@field spawnLocationCount number Number of spawns in the scenario
---@field spawnLocationList table List of spawns in the scenario
---@field vehicleLocationCount number Number of vehicles locations in the scenario
---@field vehicleLocationList table List of vehicles locations in the scenario
---@field netgameEquipmentCount number Number of netgame equipments
---@field netgameEquipmentList table List of netgame equipments
---@field netgameFlagsCount number Number of netgame equipments
---@field netgameFlagsList table List of netgame equipments

---@return scenario
local function scenarioClassNew(address)
    return createObject(address, scenarioStructure)
end

---@class scenery
---@field model number
---@field modifierShader number

---@return scenery
local function sceneryClassNew(address)
    return createObject(address, sceneryStructure)
end

---@class collisionGeometry
---@field vertexCount number Number of vertex in the collision geometry
---@field vertexList table List of vertex in the collision geometry

---@return collisionGeometry
local function collisionGeometryClassNew(address)
    return createObject(address, collisionGeometryStructure)
end

---@class modelAnimations
---@field fpAnimationCount number Number of first-person animations
---@field fpAnimationList table List of first-person animations
---@field animationCount number Number of animations of the model
---@field animationList table List of animations of the model

---@return modelAnimations
local function modelAnimationsClassNew(address)
    return createObject(address, modelAnimationsStructure)
end

---@class weapon
---@field model number Tag ID of the weapon model

---@return weapon
local function weaponClassNew(address)
    return createObject(address, weaponStructure)
end

---@class model
---@field nodeCount number Number of nodes
---@field nodeList table List of the model nodes
---@field regionCount number Number of regions
---@field regionList table List of regions
---
---@return model
local function modelClassNew(address)
    return createObject(address, modelStructure)
end

------------------------------------------------------------------------------
-- LuaBlam globals
------------------------------------------------------------------------------

-- Add blam! data tables to library
luablam.addressList = addressList
luablam.tagClasses = tagClasses
luablam.objectClasses = objectClasses
luablam.cameraTypes = cameraTypes
luablam.netgameFlagTypes = netgameFlagTypes
luablam.netgameEquipmentTypes = netgameEquipmentTypes
luablam.consoleColors = consoleColors

-- LuaBlam globals
luablam.tagDataHeader = createObject(addressList.tagDataHeader, tagDataHeaderStructure)

------------------------------------------------------------------------------
-- LuaBlam API
------------------------------------------------------------------------------

-- Add utilities to library
luablam.getObjects = getObjects
luablam.dumpObject = dumpObject
luablam.consoleOutput = consoleOutput

function luablam.isNull(value)
    if (value == 0xFF or value == 0xFFFF or value == 0xFFFFFFFF) then
        return true
    end
    return false
end

--- Get the camera type
---@return number
function luablam.getCameraType()
    local camera = read_word(addressList.cameraType)
    local cameraType = nil

    if (camera == 22192) then
        cameraType = 1
    elseif (camera == 30400) then
        cameraType = 2
    elseif (camera == 30704) then
        cameraType = 3
    elseif (camera == 21952) then
        cameraType = 4
    elseif (camera == 23776) then
        cameraType = 5
    end

    return cameraType
end

--- Create a tag object from a given address. THIS OBJECT IS NOT DYNAMIC.
---@param address integer
---@return tag
function luablam.tag(address)
    if (address and address ~= 0) then
        -- Generate a new tag object from class
        local tag = tagClassNew(address)

        -- Get all the tag info
        local tagInfo = dumpObject(tag)

        -- Set up values
        tagInfo.address = address
        tagInfo.path = read_string(tagInfo.path)
        tagInfo.class = tagClassFromInt(tagInfo.class)

        return tagInfo
    end
    return nil
end

--- Return the address of a tag given tag path (or id) and tag type
---@param tagIdOrPath string | number
---@param class string
---@return tag
function luablam.getTag(tagIdOrPath, class, ...)
    -- Arguments
    local tagId
    local tagPath
    local tagClass = class

    -- Get arguments from table
    if (isNumber(tagIdOrPath)) then
        tagId = tagIdOrPath
    elseif (isString(tagIdOrPath)) then
        tagPath = tagIdOrPath
    end

    if (...) then
        consoleOutput(debug.traceback("Wrong number of arguments on get tag function", 2),
                      consoleColors.error)
    end

    local tagAddress

    -- Get tag address
    if (tagId) then
        if (tagId < 0xFFFF) then
            -- Calculate tag index
            tagId = read_dword(luablam.tagDataHeader.array + (tagId * 0x20 + 0xC))
        end
        tagAddress = get_tag(tagId)
    else
        tagAddress = get_tag(tagClass, tagPath)
    end

    return luablam.tag(tagAddress)
end

--- Create a ingame-object object from a given address
---@param address integer
---@return blamObject
function luablam.object(address)
    if (isValid(address)) then
        return objectClassNew(address)
    end
    return nil
end

--- Create a Biped object from a given address
---@param address number
---@return biped
function luablam.biped(address)
    if (isValid(address)) then
        return bipedClassNew(address)
    end
    return nil
end

--- Create a Unicode String List object from a tag path or id
---@param tag string | number
---@return unicodeStringList
function luablam.unicodeStringList(tag)
    if (isValid(tag)) then
        local unicodeStringListTag = luablam.getTag(tag, tagClasses.unicodeStringList)
        return unicodeStringListClassNew(unicodeStringListTag.data)
    end
    return nil
end

--- Create a UI Widget Definition object from a tag path or id
---@param tag string | number
---@return uiWidgetDefinition
function luablam.uiWidgetDefinition(tag)
    if (isValid(tag)) then
        local uiWidgetDefinitionTag = luablam.getTag(tag, tagClasses.uiWidgetDefinition)
        return uiWidgetDefinitionClassNew(uiWidgetDefinitionTag.data)
    end
    return nil
end

--- Create a UI Widget Collection object from a tag path or id
---@param tag string | number
---@return uiWidgetCollection
function luablam.uiWidgetCollection(tag)
    if (isValid(tag)) then
        local uiWidgetCollectionTag = luablam.getTag(tag, tagClasses.uiWidgetCollection)
        return uiWidgetCollectionClassNew(uiWidgetCollectionTag.data)
    end
    return nil
end

--- Create a Tag Collection object from a tag path or id
---@param tag string | number
---@return tagCollection
function luablam.tagCollection(tag)
    if (isValid(tag)) then
        local tagCollectionTag = luablam.getTag(tag, tagClasses.tagCollection)
        return tagCollectionNew(tagCollectionTag.data)
    end
    return nil
end

--- Create a Weapon HUD Interface object from a tag path or id
---@param tag string | number
---@return weaponHudInterface
function luablam.weaponHudInterface(tag)
    if (isValid(tag)) then
        local weaponHudInterfaceTag = luablam.getTag(tag, tagClasses.weaponHudInterface)
        return weaponHudInterfaceClassNew(weaponHudInterfaceTag.data)
    end
    return nil
end

--- Create a Scenario object from a tag path or id
---@return scenario
function luablam.scenario(tag)
    local scenarioTag = luablam.getTag(tag or 0, tagClasses.scenario)
    return scenarioClassNew(scenarioTag.data)
end

--- Create a Scenery object from a tag path or id
---@param tag string | number
---@return scenery
function luablam.scenery(tag)
    if (isValid(tag)) then
        local sceneryTag = luablam.getTag(tag, tagClasses.scenery)
        return sceneryClassNew(sceneryTag.data)
    end
    return nil
end

--- Create a Collision Geometry object from a tag path or id
---@param tag string | number
---@return collisionGeometry
function luablam.collisionGeometry(tag)
    if (isValid(tag)) then
        local collisionGeometryTag = luablam.getTag(tag, tagClasses.collisionGeometry)
        return collisionGeometryClassNew(collisionGeometryTag.data)
    end
    return nil
end

--- Create a Model Animation object from a tag path or id
---@param tag string | number
---@return modelAnimations
function luablam.modelAnimations(tag)
    if (isValid()) then
        local modelAnimationsTag = luablam.getTag(tag, tagClasses.modelAnimations)
        return modelAnimationsClassNew(modelAnimationsTag.data)
    end
    return nil
end

--- Create a Model Animation object from a tag path or id
---@param tag string | number
---@return weapon
function luablam.weapon(tag)
    if (isValid(tag)) then
        local weaponTag = luablam.getTag(tag, tagClasses.weapon)
        return weaponClassNew(weaponTag)
    end
    return nil
end

--- Create a Model Animation object from a tag path or id
---@param tag string | number
---@return model
function luablam.model(tag)
    if (isValid(tag)) then
        local modelTag = luablam.getTag(tag, tagClasses.model)
        return modelClassNew(modelTag.data)
    end
    return nil
end

------------------------------------------------------------------------------
-- LuaBlam 3.5 compatibility layer
------------------------------------------------------------------------------
---@class blam35
local luablam35 = {}

-- Set compatibility layer version
luablam35.version = 3.5

--- LuaBlam old API binding
---@param class string
---@param param string | number
---@param properties table
---@return table | nil
local function proccessRequestedObject(class, param, properties)
    local object = luablam[class](param)
    if (properties == nil) then
        return luablam.dumpObject(object)
    else
        for k, v in pairs(properties) do
            object[k] = v
        end
    end
end

---@param address number
---@param properties nil | table
---@return blamObject
function luablam35.object(address, properties)
    if (address and address ~= 0) then
        return proccessRequestedObject("object", address, properties)
    end
    return nil
end

---@param address number
---@param properties nil | table
---@return biped
function luablam35.biped(address, properties)
    if (address and address ~= 0) then
        return proccessRequestedObject("biped", address, properties)
    end
    return nil
end

---@param address number
---@param properties nil | table
---@return uiWidgetDefinition
function luablam35.uiWidgetDefinition(address, properties)
    if (address and address ~= 0) then
        local tag = luablam.tag(address)
        return proccessRequestedObject("uiWidgetDefinition", tag.path, properties)
    end
    return nil
end

---@param address number
---@param properties nil | table
---@return weaponHudInterface
function luablam35.weaponHudInterface(address, properties)
    if (address and address ~= 0) then
        local tag = luablam.tag(address)
        return proccessRequestedObject("weaponHudInterface", tag.path, properties)
    end
    return nil
end

---@param address number
---@param properties nil | table
---@return unicodeStringList
function luablam35.unicodeStringList(address, properties)
    if (address and address ~= 0) then
        local tag = luablam.tag(address)
        return proccessRequestedObject("unicodeStringList", tag.path, properties)
    end
    return nil
end

---@param address number
---@param properties nil | table
---@return scenario
function luablam35.scenario(address, properties)
    if (address and address ~= nil) then
        local tag = luablam.tag(address)
        return proccessRequestedObject("scenario", tag.path, properties)
    end
end

---@param address number
---@param properties nil | table
---@return scenery
function luablam35.scenery(address, properties)
    if (address and address ~= 0) then
        local tag = luablam.tag(address)
        return proccessRequestedObject("scenery", tag.path, properties)
    end
    return nil
end

---@param address number
---@param properties nil | table
---@return collisionGeometry
function luablam35.collisionGeometry(address, properties)
    if (address and address ~= 0) then
        local tag = luablam.tag(address)
        return proccessRequestedObject("collisionGeometry", tag.path, properties)
    end

    return nil
end

---@param address number
---@param properties nil | table
---@return modelAnimations
function luablam35.modelAnimations(address, properties)
    if (address and address ~= 0) then
        local tag = luablam.tag(address)
        return proccessRequestedObject("modelAnimations", tag.path, properties)
    end
    return nil
end

---@param address number
---@param properties nil | table
---@return tagCollection
function luablam35.tagCollection(address, properties)
    if (address and address ~= 0) then
        local tag = luablam.tag(address)
        return proccessRequestedObject("tagCollection", tag.path, properties)
    end
    return nil
end

--- Setup LuaBlam 3.5 API
---@return table
function luablam.compat35()
    --- Return the id of a tag given tag type and tag path
    ---@param tagClass string
    ---@param tagPath string
    ---@return number
    get_tag_id = function(tagClass, tagPath)
        local tag = luablam.getTag(tagPath, tagClass)
        if (tag) then
            return tag.fullId
        end
        return nil
    end

    --- Return the simple id of a tag given tag type and tag path
    ---@param type string
    ---@param path string
    ---@return number
    get_simple_tag_id = function(type, path)
        for index = 0, luablam.tagDataHeader.count - 1 do
            local tag = luablam.getTag(index)
            if (tag.path == path) then
                return index
            end
        end
        return nil
    end

    --- Return the tag path given tag id
    ---@param tagId number
    ---@return string
    get_tag_path = function(tagId)
        local tag = luablam.getTag(tagId)
        if (tag) then
            return tag.path
        end
        return nil
    end

    --- Return the type of a tag given tag id
    ---@param tagId number
    ---@return string
    get_tag_type = function(tagId)
        local tag = luablam.getTag(tagId)
        if (tag) then
            return tag.class
        end
        return nil
    end

    --- Return the count of tags in the current map
    ---@return number
    get_tags_count = function()
        return luablam.tagDataHeader.count
    end

    --- Return the current existing objects in the current map
    ---@return table objectsList
    get_objects = function()
        return luablam.getObjects()
    end

    return luablam35
end

------------------------------------------------------------------------------

return luablam

end,

["maethrillian"] = function()
--------------------
-- Module: 'maethrillian'
--------------------
------------------------------------------------------------------------------
-- Maethrillian library
-- Sledmine
-- Version 4.0
-- Encode, decode tools for data manipulation
------------------------------------------------------------------------------
local glue = require "glue"
local maethrillian = {}

--- Compress table data in the given format
---@param inputTable table
---@param requestFormat table
---@param noHex boolean
---@return table
function maethrillian.encodeTable(inputTable, requestFormat, noHex)
    local compressedTable = {}
    for property, value in pairs(inputTable) do
        if (type(value) ~= "table") then
            local expectedProperty
            local encodeFormat
            for formatIndex, format in pairs(requestFormat) do
                if (glue.arrayhas(format, property)) then
                    expectedProperty = format[1]
                    encodeFormat = format[2]
                end
            end
            if (encodeFormat) then
                if (not noHex) then
                    compressedTable[property] = glue.tohex(string.pack(encodeFormat, value))
                else
                    compressedTable[property] = string.pack(encodeFormat, value)
                end
            else
                if (expectedProperty == property) then
                    compressedTable[property] = value
                end
            end
        end
    end
    return compressedTable
end

--- Format table into request string
---@param inputTable table
---@param requestFormat table
---@return string
function maethrillian.tableToRequest(inputTable, requestFormat, separator)
    local requestData = {}
    for property, value in pairs(inputTable) do
        if (requestFormat) then
            for formatIndex, format in pairs(requestFormat) do
                if (glue.arrayhas(format, property)) then
                    requestData[formatIndex] = value
                end
            end
        else
            requestData[#requestData + 1] = value
        end
    end
    return table.concat(requestData, separator)
end

--- Decompress table data given expected encoding format
---@param inputTable table
---@param requestFormat any
function maethrillian.decodeTable(inputTable, requestFormat)
    local dataDecompressed = {}
    for property, encodedValue in pairs(inputTable) do
        -- Get encode format for current value
        local encodeFormat
        for formatIndex, format in pairs(requestFormat) do
            if (glue.arrayhas(format, property)) then
                encodeFormat = format[2]
            end
        end
        if (encodeFormat) then
            -- There is a compression format available
            value = string.unpack(encodeFormat, glue.fromhex(tostring(encodedValue)))
        elseif (tonumber(encodedValue)) then
            -- Convert value into number
            value = tonumber(encodedValue)
        else
            -- Value is just a string
            value = encodedValue
        end
        dataDecompressed[property] = value
    end
    return dataDecompressed
end

--- Transform request into table given
---@param request string
---@param requestFormat table
function maethrillian.requestToTable(request, requestFormat, separator)
    local outputTable = {}
    local splitRequest = glue.string.split(request, separator)
    for index, value in pairs(splitRequest) do
        local currentFormat = requestFormat[index]
        local propertyName = currentFormat[1]
        local encodeFormat = currentFormat[2]
        -- Convert value into number
        local toNumberValue = tonumber(value)
        if (not encodeFormat and toNumberValue) then
            value = toNumberValue
        end
        if (propertyName) then
            outputTable[propertyName] = value
        end
    end
    return outputTable
end

return maethrillian

end,

["forge.commands"] = function()
--------------------
-- Module: 'forge.commands'
--------------------
local inspect = require "inspect"
local glue = require "glue"

local core = require "forge.core"
local features = require "forge.features"

local function forgeCommands(command)
    if (command == "fdebug") then
        debugMode = not debugMode
        configuration.debugMode = debugMode
        console_out("Debug mode: " .. tostring(debugMode))
        return false
    else
        -- Split all the data in the command input
        local splitCommand = glue.string.split(command, " ")

        -- Substract first console command
        local forgeCommand = splitCommand[1]

        if (forgeCommand == "fstep") then
            local newRotationStep = tonumber(splitCommand[2])
            if (newRotationStep) then
                features.printHUD("Rotation step now is " .. newRotationStep .. " degrees.")
                playerStore:dispatch({
                    type = "SET_ROTATION_STEP",
                    payload = {
                        step = newRotationStep
                    }
                })
            else
                playerStore:dispatch({
                    type = "SET_ROTATION_STEP",
                    payload = {step = 3}
                })
            end
            return false
        elseif (forgeCommand == "fdis" or forgeCommand == "fdistance") then
            local newDistance = tonumber(splitCommand[2])
            if (newDistance) then
                features.printHUD("Distance from object has been set to " .. newDistance ..
                                      " units.")
                -- Force distance object update
                playerStore:dispatch({
                    type = "SET_LOCK_DISTANCE",
                    payload = {
                        lockDistance = true
                    }
                })
                local distance = glue.round(newDistance)
                playerStore:dispatch({
                    type = "SET_DISTANCE",
                    payload = {
                        distance = distance
                    }
                })
            else
                local distance = 3
                playerStore:dispatch({
                    type = "SET_DISTANCE",
                    payload = {
                        distance = distance
                    }
                })
            end
            return false
        elseif (forgeCommand == "fsave") then
            core.saveForgeMap()
            return false
        elseif (forgeCommand == "fsnap") then
            configuration.snapMode = not configuration.snapMode
            console_out("Snap Mode: " .. tostring(configuration.snapMode))
            return false
        elseif (forgeCommand == "fauto") then
            configuration.autoSave = not configuration.autoSave
            console_out("Auto Save: " .. tostring(configuration.autoSave))
            return false
        elseif (forgeCommand == "fcast") then
            configuration.objectsCastShadow = not configuration.objectsCastShadow
            console_out("Objects Cast Shadow: " .. tostring(configuration.objectsCastShadow))
            return false
        elseif (forgeCommand == "fload") then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            if (mapName) then
                core.loadForgeMap(mapName)
            else
                console_out("You must specify a forge map name.")
            end
            return false
        elseif (forgeCommand == "flist") then
            for file in hfs.dir(forgeMapsFolder) do
                if (file ~= "." and file ~= "..") then
                    console_out(file)
                end
            end
            return false
        elseif (forgeCommand == "fname") then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), " "):gsub(",", " ")
            forgeStore:dispatch({
                type = "SET_MAP_NAME",
                payload = {mapName = mapName}
            })
            return false
        elseif (forgeCommand == "fdesc") then
            local mapDescription = table.concat(glue.shift(splitCommand, 1, -1), " "):gsub(",", " ")
            forgeStore:dispatch({
                type = "SET_MAP_DESCRIPTION",
                payload = {
                    mapDescription = mapDescription
                }
            })
            return false
            -------------- DEBUGGING COMMANDS ONLY ---------------
        elseif (forgeCommand == "fmenu") then
            features.openMenu("[shm]\\halo_4\\ui\\shell\\map_vote_menu\\map_vote_menu")
            return false
        elseif (forgeCommand == "fweaps") then
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.weapon) then
                    local tagPath = get_tag_path(tagId)
                    console_out(tagPath)
                end
            end
            return false
        elseif (forgeCommand == "fit") then
            for objectId = 0, #get_objects() - 1 do
                local tempObject = blam35.object(get_object(objectId))
                if (tempObject and tempObject.type == objectClasses.weapon) then
                    delete_object(objectId)
                end
            end
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.itemCollection) then
                    local tagPath = get_tag_path(tagId)
                    console_out(tagPath .. " " .. tagId)
                end
            end
            return false
        elseif (forgeCommand == "fonts") then
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.font) then
                    local tagPath = get_tag_path(tagId)
                    console_out(tagPath .. " " .. tagId)
                end
            end
        elseif (forgeCommand == "fsize") then
            dprint(collectgarbage("count") / 1024)
            return false
        elseif (forgeCommand == "fconfig") then
            loadForgeConfiguration()
            return false
        elseif (forgeCommand == "fweap") then
            local weaponsList = {}
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.weapon) then
                    local tagPath = get_tag_path(tagId)
                    local splitPath = glue.string.split(tagPath, "\\")
                    local weaponTagName = splitPath[#splitPath]
                    weaponsList[weaponTagName] = tagPath
                end
            end

            local weaponName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            local player = blam.biped(get_dynamic_player())
            local weaponResult = weaponsList[weaponName]
            if (weaponResult) then
                local weaponObjectId = core.spawnObject(tagClasses.weapon, weaponResult, player.x, player.y, player.z + 0.5)
            end
            return false
        elseif (forgeCommand == "ftest") then
            -- Run unit testing
            if (debugMode) then
                local tests = require "forge.tests"
                tests.run(true)
                return false
            end
        elseif (forgeCommand == "fbiped") then
            local weaponsList = {}
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.biped) then
                    local tagPath = get_tag_path(tagId)
                    local splitPath = glue.string.split(tagPath, "\\")
                    local weaponTagName = splitPath[#splitPath]
                    weaponsList[weaponTagName] = tagPath
                end
            end

            local weaponName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            local player = blam.biped(get_dynamic_player())
            local weaponResult = weaponsList[weaponName]
            if (weaponResult) then
                local weaponObjectId = core.spawnObject(tagClasses.biped, weaponResult, player.x, player.y, player.z + 0.5)
            end
            return false
        elseif (forgeCommand == "fobject") then
            local weaponsList = {}
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.biped) then
                    local tagPath = get_tag_path(tagId)
                    local splitPath = glue.string.split(tagPath, "\\")
                    local weaponTagName = splitPath[#splitPath]
                    weaponsList[weaponTagName] = tagPath
                end
            end

            local weaponName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            local player = blam35.biped(get_dynamic_player())
            local weaponResult = weaponsList[weaponName]
            if (weaponResult) then
                core.spawnObject(tagClasses.biped, weaponResult, player.x, player.y, player.z)
            end
            return false
        elseif (forgeCommand == "fdump") then
            glue.writefile("player_dump.json", inspect(playerStore:getState()), "t")
            glue.writefile("forge_dump.json", inspect(forgeStore:getState()), "t")
            glue.writefile("events_dump.json", inspect(eventsStore:getState().forgeObjects), "t")
            glue.writefile("debug_dump.txt", debugBuffer, "t")
            return false
        elseif (forgeCommand == "fprint") then
            -- Testing rcon communication
            dprint("[Game Objects]", "category")

            local objects = get_objects()

            -- Debug in game objects count
            dprint("Count: " .. #objects)

            -- Debug list of all the in game objects
            dprint(inspect(objects))

            dprint("[Objects Store]", "category")

            local storeObjects = glue.keys(eventsStore:getState().forgeObjects)

            -- Debug store objects count
            dprint("Count: " .. #storeObjects)

            -- Debug list of all the store objects
            dprint(inspect(storeObjects))

            return false
        elseif (forgeCommand == "fblam") then
            console_out("lua-blam " .. blam35.version)
            return false
        elseif (forgeCommand == "fspawn") then
            -- Get scenario data
            local scenario = blam.scenario(0)

            -- Get scenario player spawn points
            local mapSpawnPoints = scenario.spawnLocationList

            mapSpawnPoints[1].type = 12

            scenario.spawnLocationList = mapSpawnPoints
            return false
        end
    end
    return true
end

return forgeCommands

end,

["forge.constants"] = function()
--------------------
-- Module: 'forge.constants'
--------------------
------------------------------------------------------------------------------
-- Forge Constants
-- Sledmine
-- Constants values
------------------------------------------------------------------------------
local core = require "forge.core"

local constants = {}

-- Constant forge values
constants.maximumBudget = 1024
constants.minimumZSpawnPoint = -18.69
constants.scenerysTagCollectionPath = core.findTag(map .. "_scenerys", tagClasses.tagCollection)

-- Constant ui widget definition values
constants.maximumSidebarSize = 249
constants.minimumSidebarSize = 40
constants.maximumProgressBarSize = 171
constants.maximumLoadingProgressBarSize = 422

local fontTagPath, fontTagId = core.findTag("blender_pro_medium_12", tagClasses.font)
constants.hudFont = fontTagId

--[[local projectileTagPath, projectileTagId = core.findTag("mp_needle", tagClasses.projectile)
constants.forgeProjectileSelector = projectileTagPath]]

-- Constante forge requests data
constants.requests = {
    spawnObject = {
        actionType = "SPAWN_FORGE_OBJECT",
        requestType = "#s",
        requestFormat = {
            {"requestType"},
            {"tagId", "I4"},
            {"x", "f"},
            {"y", "f"},
            {"z", "f"},
            {"yaw"},
            {"pitch"},
            {"roll"},
            {"remoteId", "I4"}
        }
    },
    updateObject = {
        actionType = "UPDATE_FORGE_OBJECT",
        requestType = "#u",
        requestFormat = {
            {"requestType"},
            {"objectId"},
            {"x", "f"},
            {"y", "f"},
            {"z", "f"},
            {"yaw"},
            {"pitch"},
            {"roll"}
        }
    },
    deleteObject = {
        actionType = "DELETE_FORGE_OBJECT",
        requestType = "#d",
        requestFormat = {
            {"requestType"},
            {"objectId"}
        }
    },
    flushForge = {actionType = "FLUSH_FORGE"},
    loadMapScreen = {
        actionType = "LOAD_MAP_SCREEN",
        requestType = "#lm",
        requestFormat = {
            {"requestType"},
            {"objectCount"},
            {"mapName"},
            {"mapDescription"}
        }
    },
    loadVoteMapScreen = {
        actionType = "LOAD_VOTE_MAP_SCREEN",
        requestType = "#lv",
        requestFormat = {{"requestType"}}
    },
    appendVoteMap = {
        actionType = "APPEND_VOTE_MAP",
        requestType = "#av",
        requestFormat = {
            {"requestType"},
            {"mapName"},
            {"mapGametype"},
            {"mapIndex"}
        }
    },
    sendMapVote = {
        actionType = "SEND_MAP_VOTE",
        requestType = "#v",
        requestFormat = {
            {"requestType"},
            {"mapVoted"}
        }
    },
    sendTotalMapVotes = {
        actionType = "SEND_TOTAL_MAP_VOTES",
        requestType = "#sv",
        requestFormat = {
            {"requestType"},
            {"votesMap1"},
            {"votesMap2"},
            {"votesMap3"},
            {"votesMap4"}
        }
    },
    flushVotes = {actionType = "FLUSH_VOTES"}
}

-- Biped tag definitions
constants.bipeds = {
    monitor = core.findTag("monitor", tagClasses.biped),
    spartan = core.findTag("cyborg_mp", tagClasses.biped)
}

-- Weapon hud tag definitions
constants.weaponHudInterfaces = {
    forgeCrosshair = core.findTag("ui\\hud\\forge", tagClasses.weaponHudInterface)
}

constants.bitmaps = {
    forgeLoadingProgress0 = "[shm]\\halo_4\\ui\\shell\\loading_menu\\bitmaps\\forge_loading_progress0",
    forgeLoadingProgress1 = "[shm]\\halo_4\\ui\\shell\\loading_menu\\bitmaps\\forge_loading_progress1"
}

-- UI widget definitions
constants.uiWidgetDefinitions = {
    forgeMenu = "[shm]\\halo_4\\ui\\shell\\forge_menu\\forge_menu",
    voteMenu = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\map_vote_menu",
    objectsList = "[shm]\\halo_4\\ui\\shell\\forge_menu\\category_menu\\category_list",
    amountBar = "[shm]\\halo_4\\ui\\shell\\forge_menu\\budget_dialog\\budget_progress_bar",
    loadingMenu = "[shm]\\halo_4\\ui\\shell\\loading_menu\\loading_menu",
    loadingAnimation = "[shm]\\halo_4\\ui\\shell\\loading_menu\\loading_menu_progress_animation",
    loadingProgress = "[shm]\\halo_4\\ui\\shell\\loading_menu\\loading_progress_bar",
    loadoutMenu = "[shm]\\halo_4\\ui\\shell\\loadout_menu\\loadout_menu_no_background",
    mapsList = "[shm]\\halo_4\\ui\\shell\\pause_game\\forge_options_menu\\maps_list\\maps_list",
    sidebar = "[shm]\\halo_4\\ui\\shell\\pause_game\\forge_options_menu\\forge_map_list_sidebar_bar"
}

-- Unicode string definitions
constants.unicodeStrings = {
    budgetCount = "[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\budget_count",
    forgeList = "[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\elements_text",
    votingList = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\strings\\vote_maps_names",
    votingCountList = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\strings\\vote_maps_count",
    pagination = "[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\pagination",
    mapsList = "[shm]\\halo_4\\ui\\shell\\pause_game\\strings\\maps_name",
    pauseGameStrings = "[shm]\\halo_4\\ui\\shell\\pause_game\\strings\\titles_and_headers"
}

return constants

end,

["forge.core"] = function()
--------------------
-- Module: 'forge.core'
--------------------
------------------------------------------------------------------------------
-- Forge Core
-- Author: Sledmine
-- Version: 2.0
-- Core functionality for Forge
------------------------------------------------------------------------------
-- Lua libraries
local inspect = require "inspect"
local json = require "json"
local glue = require "glue"

-- Halo libraries
local maeth = require "maethrillian"

-- Core module
local core = {}

--- Check if player is looking at object main frame
---@param target number
---@param sensitivity number
---@param zOffset number
-- Credits to Devieth and IceCrow14
function core.playerIsLookingAt(target, sensitivity, zOffset)
    -- Minimum amount for distance scaling
    local baseline_sensitivity = 0.012
    local function read_vector3d(Address)
        return read_float(Address), read_float(Address + 0x4), read_float(Address + 0x8)
    end
    local mainObject = get_dynamic_player()
    local targetObject = get_object(target)
    -- Both objects must exist
    if targetObject and mainObject then
        local player_x, player_y, player_z = read_vector3d(mainObject + 0xA0)
        local camera_x, camera_y, camera_z = read_vector3d(mainObject + 0x230)
        -- Target location 2
        local target_x, target_y, target_z = read_vector3d(targetObject + 0x5C)
        -- 3D distance
        local distance = math.sqrt((target_x - player_x) ^ 2 + (target_y - player_y) ^ 2 +
                                       (target_z - player_z) ^ 2)
        local local_x = target_x - player_x
        local local_y = target_y - player_y
        local local_z = (target_z + zOffset) - player_z
        local point_x = 1 / distance * local_x
        local point_y = 1 / distance * local_y
        local point_z = 1 / distance * local_z
        local x_diff = math.abs(camera_x - point_x)
        local y_diff = math.abs(camera_y - point_y)
        local z_diff = math.abs(camera_z - point_z)
        local average = (x_diff + y_diff + z_diff) / 3
        local scaler = 0
        if distance > 10 then
            scaler = math.floor(distance) / 1000
        end
        local auto_aim = sensitivity - scaler
        if auto_aim < baseline_sensitivity then
            auto_aim = baseline_sensitivity
        end
        if average < auto_aim then
            return true
        end
    end
    return false
end

-- Old internal functions for rotation calculation
--[[
local function rotate(x, y, alpha)
    local cosAlpha = math.cos(math.rad(alpha))
    local sinAlpha = math.sin(math.rad(alpha))
    local t1 = x[1] * sinAlpha
    local t2 = x[2] * sinAlpha
    local t3 = x[3] * sinAlpha
    x[1] = x[1] * cosAlpha + y[1] * sinAlpha
    x[2] = x[2] * cosAlpha + y[2] * sinAlpha
    x[3] = x[3] * cosAlpha + y[3] * sinAlpha
    y[1] = y[1] * cosAlpha - t1
    y[2] = y[2] * cosAlpha - t2
    y[3] = y[3] * cosAlpha - t3
end

function core.eulerToMatrix(yaw, pitch, roll)
    local F = {1, 0, 0}
    local L = {0, 1, 0}
    local T = {0, 0, 1}
    rotate(F, L, yaw)
    rotate(F, T, pitch)
    rotate(T, L, roll)
    return {F[1], -L[1], -T[1], -F[3], L[3], T[3]}, {
        F,
        L,
        T,
    }
end
]]

--- Covert euler into game rotation array, optional rotation matrix
---@param yaw number
---@param pitch number
---@param roll number
---@return table, table
function core.eulerToRotation(yaw, pitch, roll)
    local matrix = {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    }
    local cosPitch = math.cos(math.rad(pitch))
    local sinPitch = math.sin(math.rad(pitch))
    local cosYaw = math.cos(math.rad(yaw))
    local sinYaw = math.sin(math.rad(yaw))
    local cosRoll = math.cos(math.rad(roll))
    local sinRoll = math.sin(math.rad(roll))
    matrix[1][1] = cosPitch * cosYaw
    matrix[1][2] = sinPitch * sinRoll - cosPitch * sinYaw * cosRoll
    matrix[1][3] = cosPitch * sinYaw * sinRoll + sinPitch * cosRoll
    matrix[2][1] = sinYaw
    matrix[2][2] = cosYaw * cosRoll
    matrix[2][3] = -cosYaw * sinRoll
    matrix[3][1] = -sinPitch * cosYaw
    matrix[3][2] = sinPitch * sinYaw * cosRoll + cosPitch * sinRoll
    matrix[3][3] = -sinPitch * sinYaw * sinRoll + cosPitch * cosRoll
    local array = {
        matrix[1][1],
        matrix[2][1],
        matrix[3][1],
        matrix[1][3],
        matrix[2][3],
        matrix[3][3]
    }
    return array, matrix
end

--- Rotate object into desired degrees
---@param objectId number
---@param yaw number
---@param pitch number
---@param roll number
function core.rotateObject(objectId, yaw, pitch, roll)
    local rotation = core.eulerToRotation(yaw, pitch, roll)
    blam35.object(get_object(objectId), {
        vX = rotation[1],
        vY = rotation[2],
        vZ = rotation[3],
        v2X = rotation[4],
        v2Y = rotation[5],
        v2Z = rotation[6]
    })
end

--- Check if current player is using a monitor biped
---@return boolean
function core.isPlayerMonitor(playerIndex)
    local tempObject
    if (playerIndex) then
        tempObject = blam35.object(get_dynamic_player(playerIndex))
    else
        tempObject = blam35.object(get_dynamic_player())
    end
    if (tempObject) then
        local monitorBipedTagId = get_tag_id(tagClasses.biped, constants.bipeds.monitor)
        if (tempObject.tagId == monitorBipedTagId) then
            return true
        end
    end
    return false
end

--- Send a request to the server throug rcon
---@return boolean success
---@return string request
function core.sendRequest(request, playerIndex)
    dprint("-> [ Sending request ]")
    local requestType = glue.string.split(request, "|")[1]
    dprint("Request type: " .. requestType)
    if (requestType) then
        request = "rcon forge '" .. request .. "'"
        dprint("Request: " .. request)
        if (server_type == "local") then
            -- We need to mockup the server response in local mode
            local mockedResponse = string.gsub(string.gsub(request, "rcon forge '", ""), "'", "")
            OnRcon(mockedResponse)
            return true, mockedResponse
        elseif (server_type == "dedicated") then
            -- Player is connected to a server
            execute_script(request)
            return true, request
        elseif (server_type == "sapp") then
            local fixedRequest = string.gsub(request, "rcon forge '", "")
            dprint("Server request: " .. fixedRequest)
            -- We want to broadcast to every player in the server
            if (not playerIndex) then
                gprint(fixedRequest)
            else
                -- We are looking to send data to a specific player
                rprint(playerIndex, fixedRequest)
            end
            return true, fixedRequest
        end
    end
    dprint("Error at trying to send request!!!!", "error")
    return false
end

--- Create a request from a request object
---@param requestTable table
function core.createRequest(requestTable)
    local instanceObject = glue.update({}, requestTable)
    local request
    if (instanceObject) then
        -- Create an object instance to avoid wrong reference asignment
        local requestType = instanceObject.requestType
        if (requestType) then
            if (requestType == constants.requests.spawnObject.requestType) then
                if (server_type == "sapp") then
                    instanceObject.remoteId = requestTable.remoteId
                end
            elseif (requestType == constants.requests.updateObject.requestType) then
                if (server_type ~= "sapp") then
                    -- Desired object id is our remote id
                    instanceObject.objectId = requestTable.remoteId
                end
            elseif (requestType == constants.requests.deleteObject.requestType) then
                if (server_type ~= "sapp") then
                    -- Desired object id is our remote id
                    instanceObject.objectId = requestTable.remoteId
                end
            end
            local requestFormat
            for requestIndex, request in pairs(constants.requests) do
                if (requestType == request.requestType) then
                    requestFormat = request.requestFormat
                end
            end
            local encodedTable = maeth.encodeTable(instanceObject, requestFormat)
            print(inspect(requestTable))
            request = maeth.tableToRequest(encodedTable, requestFormat, "|")
        else
            print(inspect(instanceObject))
            error("There is no request type in this request!")
        end
        return request
    end
    return nil
end

--- Process every request as a server
function core.processRequest(actionType, request, currentRequest, playerIndex)
    dprint("-> [ Receiving request ]")
    dprint("Incoming request: " .. request)
    dprint("Parsing incoming " .. actionType .. " ...", "warning")
    local requestTable = maeth.requestToTable(request, currentRequest.requestFormat, "|")
    if (requestTable) then
        dprint("Done.", "success")
        dprint(inspect(requestTable))
    else
        dprint("Error at converting request.", "error")
        return false, nil
    end
    dprint("Decoding incoming " .. actionType .. " ...", "warning")
    local requestObject = maeth.decodeTable(requestTable, currentRequest.requestFormat)
    if (requestObject) then
        dprint("Done.", "success")
    else
        dprint("Error at decoding request.", "error")
        return false, nil
    end
    if (not ftestingMode) then
        eventsStore:dispatch({
            type = actionType,
            payload = {
                requestObject = requestObject
            },
            playerIndex = playerIndex
        })
    end
    return false, requestObject
end

function core.resetSpawnPoints()
    local scenario = blam.scenario(0)

    local mapSpawnCount = scenario.spawnLocationCount
    local vehicleLocationCount = scenario.vehicleLocationCount

    dprint("Found " .. mapSpawnCount .. " stock player starting points!")
    dprint("Found " .. vehicleLocationCount .. " stock vehicle location points!")
    local mapSpawnPoints = scenario.spawnLocationList
    -- Reset any spawn point, except the first one
    for i = 1, mapSpawnCount do
        -- Disable them by setting type to 0
        mapSpawnPoints[i].type = 0
    end
    local vehicleLocationList = scenario.vehicleLocationList
    for i = 2, vehicleLocationCount do
        -- Disable spawn and try to erase object from the map
        vehicleLocationList[i].type = 65535
        execute_script("object_destroy v" .. vehicleLocationList[i].nameIndex)
    end

    scenario.spawnLocationList = mapSpawnPoints
    scenario.vehicleLocationList = vehicleLocationList
end

function core.flushForge()
    if (eventsStore) then
        local forgeObjects = eventsStore:getState().forgeObjects
        if (#glue.keys(forgeObjects) > 0 and #get_objects() > 0) then
            -- saveForgeMap('unsaved')
            -- execute_script('object_destroy_all')
            for objectId, composedObject in pairs(forgeObjects) do
                delete_object(objectId)
            end
            eventsStore:dispatch({
                type = "FLUSH_FORGE"
            })
        end
    end
end

function core.sendMapData(forgeMap, playerIndex)
    if (server_type == "sapp") then
        local mapDataResponse = {}
        mapDataResponse.requestType = constants.requests.loadMapScreen.requestType
        mapDataResponse.objectCount = #forgeMap.objects
        mapDataResponse.mapName = forgeMap.name
        mapDataResponse.mapDescription = forgeMap.description
        local response = core.createRequest(mapDataResponse)
        core.sendRequest(response, playerIndex)
    end
end

function core.loadForgeMap(mapName)
    if (server_type == "dedicated") then
        console_out("You can not load a map while connected to a server!'")
        return false
    end
    local fmapContent = glue.readfile(forgeMapsFolder .. "\\" .. mapName .. ".fmap", "t")
    if (fmapContent) then
        dprint("Loading forge map...")
        local forgeMap = json.decode(fmapContent)
        if (forgeMap and forgeMap.objects) then
            -- Load data into store
            forgeStore:dispatch({
                type = "SET_MAP_DATA",
                payload = {
                    mapName = forgeMap.name,
                    mapDescription = forgeMap.description
                }
            })
            core.sendMapData(forgeMap)

            -- Reset all spawn points to default
            core.resetSpawnPoints()

            -- Remove menu blur after reloading server on local mode
            if (server_type == "local") then
                execute_script("menu_blur_off")
                core.flushForge()
            end

            for objectId, forgeObject in pairs(forgeMap.objects) do
                local spawnRequest = glue.update({}, forgeObject)
                local objectTagId = get_tag_id(tagClasses.scenery, spawnRequest.tagPath)
                if (objectTagId) then
                    spawnRequest.requestType = constants.requests.spawnObject.requestType
                    spawnRequest.tagPath = nil
                    spawnRequest.tagId = objectTagId
                    eventsStore:dispatch({
                        type = constants.requests.spawnObject.actionType,
                        payload = {
                            requestObject = spawnRequest
                        }
                    })
                else
                    dprint("WARNING!! Object with path '" .. spawnRequest.tagPath ..
                               "' can't be spawn...", "warning")
                end
            end

            if (server_type == "local") then
                execute_script("sv_map_reset")
            end
            dprint("Succesfully loaded '" .. mapName .. "' fmap!")

            return true
        else
            dprint("Error at decoding data from '" .. mapName .. "' forge map...", "error")
        end
    else
        dprint("ERROR!! At trying to load '" .. mapName .. "' as a forge map...", "error")
        if (server_type == "sapp") then
            gprint("ERROR!! At trying to load '" .. mapName .. "' as a forge map...")
        end
    end
    return false
end

function core.saveForgeMap()
    console_out("Saving forge map...")

    local forgeState = forgeStore:getState()

    local mapName = forgeState.currentMap.name
    local mapDescription = forgeState.currentMap.description

    -- List used to store data of every object in the forge map
    local forgeMap = {
        name = mapName,
        author = "",
        description = mapDescription,
        version = "",
        objects = {}
    }

    -- Get the state of the forge objects
    local objectsState = eventsStore:getState().forgeObjects

    -- Iterate through all the forge objects
    for objectId, forgeObject in pairs(objectsState) do
        -- Get scenery tag path to keep compatibility between versions
        local tempObject = blam35.object(get_object(objectId))
        local sceneryPath = get_tag_path(tempObject.tagId)

        -- Create a copy of the composed object in the store to avoid replacing useful values
        local fmapObject = glue.update({}, forgeObject)

        -- Remove all the unimportant data
        fmapObject.objectId = nil
        fmapObject.reflectionId = nil
        fmapObject.remoteId = nil

        -- Add tag path property
        fmapObject.tagPath = sceneryPath

        -- Add forge object to list
        glue.append(forgeMap.objects, fmapObject)
    end

    -- Encode map info as json
    local fmapContent = json.encode(forgeMap)

    -- Fix map name
    mapName = string.gsub(mapName, " ", "_")

    local forgeMapPath = forgeMapsFolder .. "\\" .. mapName .. ".fmap"
    local forgeMapFile = glue.writefile(forgeMapPath, fmapContent, "t")

    -- Check if file was created
    if (forgeMapFile) then
        console_out("Forge map '" .. mapName .. "' has been succesfully saved!", "success")

        -- Reload forge maps list
        loadForgeMaps()

        if (server_type == "local") then
            console_out("Done.", "Saving " .. mapName .. "..", blam.consoleColors.success)
        end
    else
        dprint("ERROR!! At saving '" .. mapName .. "' as a forge map...", "error")
    end
end

--- Super function for debug printing and non self blocking spawning
---@param type string
---@param tagPath string
---@param x number
---@param y number
---@param z number
---@return number | nil objectId
function core.spawnObject(type, tagPath, x, y, z)
    dprint(" -> [ Object Spawning ]")
    dprint("Type:", "category")
    dprint(type)
    dprint("Tag  Path:", "category")
    dprint(tagPath)
    dprint("Position:", "category")
    local positionString = "%s: %s: %s:"
    dprint(positionString:format(x, y, z))
    dprint("Trying to spawn object...", "warning")
    -- Prevent objects from phantom spawning!
    local objectId = spawn_object(type, tagPath, x, y, z)
    if (objectId) then
        local tempObject = blam35.object(get_object(objectId))

        -- Forces the object to render shadow
        if (configuration.objectsCastShadow) then
            blam35.object(get_object(objectId), {
                isNotCastingShadow = false
            })
        end
        if (server_type == "sapp") then
            print("Object is outside map: " .. tostring(tempObject.isOutSideMap))
        end
        if (tempObject.isOutSideMap) then
            dprint("-> Object: " .. objectId .. " is INSIDE map!!!", "warning")

            -- Erase object to spawn it later in a safe place
            delete_object(objectId)

            -- Create new object but now in a safe place
            objectId = spawn_object(type, tagPath, x, y, constants.minimumZSpawnPoint)

            if (objectId) then
                -- Update new object position to match the original
                blam35.object(get_object(objectId), {
                    x = x,
                    y = y,
                    z = z
                })

                -- Forces the object to render shadow
                if (configuration.objectsCastShadow) then
                    blam35.object(get_object(objectId), {
                        isNotCastingShadow = false
                    })
                end
            end
        end

        dprint("-> Object: " .. objectId .. " succesfully spawned!!!", "success")
        return objectId
    end
    dprint("Error at trying to spawn object!!!!", "error")
    return nil
end

--- Apply updates to player spawn points based on a given tag path
---@param tagPath string
---@param forgeObject table
---@param disable boolean
function core.updatePlayerSpawn(tagPath, forgeObject, disable)
    local teamIndex = 0
    local gameType = 0

    -- Get spawn info from tag name
    -- // TODO: Add comment here with all the game types index!
    if (tagPath:find("ctf")) then
        dprint("CTF")
        gameType = 1
    elseif (tagPath:find("slayer")) then
        if (tagPath:find("generic")) then
            dprint("SLAYER")
        else
            dprint("TEAM_SLAYER")
        end
        gameType = 2
    elseif (tagPath:find("oddball")) then
        dprint("ODDBALL")
        gameType = 3
    elseif (tagPath:find("koth")) then
        dprint("KOTH")
        gameType = 4
    elseif (tagPath:find("race")) then
        dprint("RACE")
        gameType = 5
    end

    if (tagPath:find("red")) then
        dprint("RED TEAM SPAWN")
        teamIndex = 0
    elseif (tagPath:find("blue")) then
        dprint("BLUE TEAM SPAWN")
        teamIndex = 1
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    -- Get scenario player spawn points
    local mapSpawnPoints = scenario.spawnLocationList

    -- Object is not already reflecting a spawn point
    if (not forgeObject.reflectionId) then
        for spawnId = 1, #mapSpawnPoints do
            -- If this spawn point is disabled
            if (mapSpawnPoints[spawnId].type == 0) then
                -- Replace spawn point values
                mapSpawnPoints[spawnId].x = forgeObject.x
                mapSpawnPoints[spawnId].y = forgeObject.y
                mapSpawnPoints[spawnId].z = forgeObject.z
                mapSpawnPoints[spawnId].rotation = math.rad(forgeObject.yaw)
                mapSpawnPoints[spawnId].teamIndex = teamIndex
                mapSpawnPoints[spawnId].type = gameType

                -- Debug spawn index
                dprint("Creating spawn replacing index: " .. spawnId, "warning")
                forgeObject.reflectionId = spawnId
                break
            end
        end
    else
        dprint("Erasing spawn with index: " .. forgeObject.reflectionId)
        if (disable) then
            -- Disable or "delete" spawn point by setting type as 0
            mapSpawnPoints[forgeObject.reflectionId].type = 0
            -- Update spawn point list
            scenario.spawnLocationList = mapSpawnPoints
            return true
        end
        -- Replace spawn point values
        mapSpawnPoints[forgeObject.reflectionId].x = forgeObject.x
        mapSpawnPoints[forgeObject.reflectionId].y = forgeObject.y
        mapSpawnPoints[forgeObject.reflectionId].z = forgeObject.z
        mapSpawnPoints[forgeObject.reflectionId].rotation = math.rad(forgeObject.yaw)
        dprint(mapSpawnPoints[forgeObject.reflectionId].type)
        -- Debug spawn index
        dprint("Updating spawn replacing index: " .. forgeObject.reflectionId)
    end
    -- Update spawn point list
    scenario.spawnLocationList = mapSpawnPoints
end

--- Apply updates to netgame flags spawn points based on a tag path
---@param tagPath string
---@param forgeObject table
function core.updateNetgameFlagSpawn(tagPath, forgeObject)
    -- // TODO: Review if some flags use team index as "group index"!
    local teamIndex = 0
    local flagType = 0

    -- Set flag type from tag path
    --[[
        0 = ctf - flag
        1 = ctf - vehicle
        2 = oddball - ball spawn
        3 = race - track
        4 = race - vehicle
        5 = vegas - bank (?) WHAT, I WAS NOT AWARE OF THIS THING!
        6 = teleport from
        7 = teleport to
        8 = hill flag
    ]]
    if (tagPath:find("flag stand")) then
        dprint("FLAG POINT")
        flagType = 0
        -- // TODO: Check if double setting team index against default value is needed!
        if (tagPath:find("red")) then
            dprint("RED TEAM FLAG")
            teamIndex = 0
        else
            dprint("BLUE TEAM FLAG")
            teamIndex = 1
        end
    elseif (tagPath:find("weapons")) then
        -- // TODO: Check and add weapon based netgame flags like oddball!
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    -- Get scenario player spawn points
    local mapNetgameFlagsPoints = scenario.netgameFlagsList

    -- Object is not already reflecting a flag point
    if (not forgeObject.reflectionId) then
        for flagId = 1, #mapNetgameFlagsPoints do
            -- // FIXME: This control block is not neccessary but needs improvements!
            -- If this flag point is using the same flag type
            if (mapNetgameFlagsPoints[flagId].type == flagType and
                mapNetgameFlagsPoints[flagId].teamIndex == teamIndex) then
                -- Replace spawn point values
                mapNetgameFlagsPoints[flagId].x = forgeObject.x
                mapNetgameFlagsPoints[flagId].y = forgeObject.y
                -- Z plus an offset to prevent flag from falling in lower bsp values
                mapNetgameFlagsPoints[flagId].z = forgeObject.z + 0.15
                mapNetgameFlagsPoints[flagId].rotation = math.rad(forgeObject.yaw)
                mapNetgameFlagsPoints[flagId].teamIndex = teamIndex
                mapNetgameFlagsPoints[flagId].type = flagType

                -- Debug spawn index
                dprint("Creating flag replacing index: " .. flagId, "warning")
                forgeObject.reflectionId = flagId
                break
            end
        end
    else
        dprint("Erasing netgame flag with index: " .. forgeObject.reflectionId)
        -- Replace spawn point values
        mapNetgameFlagsPoints[forgeObject.reflectionId].x = forgeObject.x
        mapNetgameFlagsPoints[forgeObject.reflectionId].y = forgeObject.y
        mapNetgameFlagsPoints[forgeObject.reflectionId].z = forgeObject.z
        mapNetgameFlagsPoints[forgeObject.reflectionId].rotation = math.rad(forgeObject.yaw)
        -- Debug spawn index
        dprint("Updating flag replacing index: " .. forgeObject.reflectionId, "warning")
    end
    -- Update spawn point list
    scenario.netgameFlagsList = mapNetgameFlagsPoints
end

--- Apply updates to equipment netgame points based on a given tag path
---@param tagPath string
---@param forgeObject table
---@param disable boolean
function core.updateNetgameEquipmentSpawn(tagPath, forgeObject, disable)
    local itemCollection
    -- Get equipment info from tag name
    if (tagPath:find("assault rifle")) then
        dprint("AR")
        local itemCollectionTagPath = core.findTag("assault rifle", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("battle rifle")) then
        dprint("BR")
        local itemCollectionTagPath = core.findTag("battle rifle", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("dmr")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("dmr", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("needler")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("needler", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("plasma pistol")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("plasma pistol", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("rocket launcher")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("rocket launcher", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("shotgun")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("shotgun", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("sniper rifle")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("sniper rifle", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("frag grenade")) then
        dprint("FRAG GRENADE")
        local itemCollectionTagPath = core.findTag("frag grenades", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("plasma grenade")) then
        dprint("PLASMA GRENADE")
        local itemCollectionTagPath = core.findTag("plasma grenades", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("random weapon spawn")) then
        dprint("RANDOM WEAPON")
        local itemCollectionTagPath = core.findTag("random weapon", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    -- Get scenario player spawn points
    local netgameEquipmentPoints = scenario.netgameEquipmentList

    -- Object is not already reflecting a spawn point
    if (not forgeObject.reflectionId) then
        for equipmentId = 1, #netgameEquipmentPoints do
            -- If this spawn point is disabled
            if (netgameEquipmentPoints[equipmentId].type1 == 0) then
                -- Replace spawn point values
                netgameEquipmentPoints[equipmentId].x = forgeObject.x
                netgameEquipmentPoints[equipmentId].y = forgeObject.y
                netgameEquipmentPoints[equipmentId].z = forgeObject.z + 0.2
                netgameEquipmentPoints[equipmentId].facing = math.rad(forgeObject.yaw)
                netgameEquipmentPoints[equipmentId].type1 = 12
                netgameEquipmentPoints[equipmentId].levitate = true
                netgameEquipmentPoints[equipmentId].itemCollection = itemCollection

                -- Debug spawn index
                dprint("Creating equipment replacing index: " .. equipmentId, "warning")
                forgeObject.reflectionId = equipmentId
                break
            end
        end
    else
        dprint("Erasing netgame equipment with index: " .. forgeObject.reflectionId)
        if (disable) then
            -- // FIXME: Weapon object is not being erased in fact, find a way to delete it!
            -- Disable or "delete" equipment point by setting type as 0
            netgameEquipmentPoints[forgeObject.reflectionId].type1 = 0
            -- Update spawn point list
            scenario.netgameEquipmentList = netgameEquipmentPoints
            return true
        end
        -- Replace spawn point values
        netgameEquipmentPoints[forgeObject.reflectionId].x = forgeObject.x
        netgameEquipmentPoints[forgeObject.reflectionId].y = forgeObject.y
        netgameEquipmentPoints[forgeObject.reflectionId].z = forgeObject.z + 0.2
        netgameEquipmentPoints[forgeObject.reflectionId].facing = math.rad(forgeObject.yaw)
        -- Debug spawn index
        dprint("Updating equipment replacing index: " .. forgeObject.reflectionId)
    end
    -- Update equipment point list
    scenario.netgameEquipmentList = netgameEquipmentPoints
end

--- Enable, update and disable vehicle spawns
-- Must be called after adding scenery object to the store!!
-- @return true if found an available spawn
function core.updateVehicleSpawn(tagPath, forgeObject, disable)
    if (server_type == "dedicated") then
        return true
    end
    local vehicleType = 0
    -- Get spawn info from tag name
    if (tagPath:find("banshee")) then
        dprint("banshee")
        vehicleType = 0
    elseif (tagPath:find("hog")) then
        dprint("hog")
        vehicleType = 1
    elseif (tagPath:find("ghost")) then
        dprint("ghost")
        vehicleType = 2
    elseif (tagPath:find("scorpion")) then
        dprint("scorpion")
        vehicleType = 3
    elseif (tagPath:find("turret spawn")) then
        dprint("turret")
        vehicleType = 4
    elseif (tagPath:find("ball spawn")) then
        dprint("ball")
        vehicleType = 5
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    local vehicleLocationCount = scenario.vehicleLocationCount
    dprint("Maximum count of vehicle spawn points: " .. vehicleLocationCount)

    local vehicleSpawnPoints = scenario.vehicleLocationList

    -- Object exists, it's synced
    if (not forgeObject.reflectionId) then
        for spawnId = 2, #vehicleSpawnPoints do
            if (vehicleSpawnPoints[spawnId].type == 65535) then
                -- Replace spawn point values
                vehicleSpawnPoints[spawnId].x = forgeObject.x
                vehicleSpawnPoints[spawnId].y = forgeObject.y
                vehicleSpawnPoints[spawnId].z = forgeObject.z
                vehicleSpawnPoints[spawnId].yaw = math.rad(forgeObject.yaw)
                vehicleSpawnPoints[spawnId].pitch = math.rad(forgeObject.pitch)
                vehicleSpawnPoints[spawnId].roll = math.rad(forgeObject.roll)

                vehicleSpawnPoints[spawnId].type = vehicleType

                -- Debug spawn index
                dprint("Creating spawn replacing index: " .. spawnId)
                forgeObject.reflectionId = spawnId

                -- Update spawn point list
                scenario.vehicleLocationList = vehicleSpawnPoints

                dprint("object_create_anew v" .. vehicleSpawnPoints[spawnId].nameIndex)
                execute_script("object_create_anew v" .. vehicleSpawnPoints[spawnId].nameIndex)
                -- Stop looking for "available" spawn slots
                break
            end
        end
    else
        dprint(forgeObject.reflectionId)
        if (disable) then
            -- Disable or "delete" spawn point by setting type as 65535
            vehicleSpawnPoints[forgeObject.reflectionId].type = 65535
            -- Update spawn point list
            scenario.vehicleLocationList = vehicleSpawnPoints
            dprint("object_create_anew v" .. vehicleSpawnPoints[forgeObject.reflectionId].nameIndex)
            execute_script("object_destroy v" ..
                               vehicleSpawnPoints[forgeObject.reflectionId].nameIndex)
            return true
        end
        -- Replace spawn point values
        vehicleSpawnPoints[forgeObject.reflectionId].x = forgeObject.x
        vehicleSpawnPoints[forgeObject.reflectionId].y = forgeObject.y
        vehicleSpawnPoints[forgeObject.reflectionId].z = forgeObject.z

        -- REMINDER!!! Check vehicle rotation

        -- Debug spawn index
        dprint("Updating spawn replacing index: " .. forgeObject.reflectionId)

        -- Update spawn point list
        scenario.vehicleLocationList = vehicleSpawnPoints
    end
end

--- Find local object by server id
---@param state table
---@param remoteId number
---@return number
function core.getObjectIdByRemoteId(state, remoteId)
    for k, v in pairs(state) do
        if (v.remoteId == remoteId) then
            return k
        end
    end
    return nil
end

--- Calculate distance between 2 objects
---@param baseObject table
---@param targetObject table
---@return number
function core.calculateDistanceFromObject(baseObject, targetObject)
    local calulcatedX = (targetObject.x - baseObject.x) ^ 2
    local calculatedY = (targetObject.y - baseObject.y) ^ 2
    local calculatedZ = (targetObject.z - baseObject.z) ^ 2
    return math.sqrt(calulcatedX + calculatedY + calculatedZ)
end

function core.findTag(partialName, searchTagType)
    for tagId = 0, get_tags_count() - 1 do
        local tagPath = get_tag_path(tagId)
        local tagType = get_tag_type(tagId)
        if (tagPath and tagPath:find(partialName) and tagType == searchTagType) then
            return tagPath, tagId
        end
    end
    return nil
end

return core

end,

["forge.features"] = function()
--------------------
-- Module: 'forge.features'
--------------------
------------------------------------------------------------------------------
-- Forge Features
-- Sledmine
-- Set of different forge features
------------------------------------------------------------------------------
local glue = require "glue"

local core = require "forge.core"

local features = {}

--- Changes default crosshair values
---@param state number
function features.setCrosshairState(state)
    if (constants.weaponHudInterfaces.forgeCrosshair) then
        local forgeCrosshairAddress = get_tag(tagClasses.weaponHudInterface,
                                              constants.weaponHudInterfaces.forgeCrosshair)
        if (state == 0) then
            blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 64,
                defaultGreen = 169,
                defaultBlue = 255,
                sequenceIndex = 1
            })
        elseif (state == 1) then
            blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 0,
                defaultGreen = 255,
                defaultBlue = 0,
                sequenceIndex = 2
            })
        elseif (state == 2) then
            blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 0,
                defaultGreen = 255,
                defaultBlue = 0,
                sequenceIndex = 3
            })
        elseif (state == 3) then
            blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 255,
                defaultGreen = 0,
                defaultBlue = 0,
                sequenceIndex = 4
            })
        else
            blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 64,
                defaultGreen = 169,
                defaultBlue = 255,
                sequenceIndex = 0
            })
        end
    end
end

function features.unhighlightAll()
    local forgeObjects = eventsStore:getState().forgeObjects
    for objectId, composedObject in pairs(forgeObjects) do
        local tempObject = blam35.object(get_object(objectId))
        -- Object exists
        if (tempObject) then
            local tagType = get_tag_type(tempObject.tagId)
            if (tagType == "scen") then
                blam35.object(get_object(objectId), {
                    health = 0
                })
            end
        end
    end
end

---@param objectId number
---@param transparency number | "0.1" | "0.5" | "1"
function features.highlightObject(objectId, transparency)
    -- Highlight object
    blam35.object(get_object(objectId), {
        health = transparency
    })
end

-- Mod functions
function features.swapBiped()
    features.unhighlightAll()
    if (server_type == "local") then
        local player = blam.biped(get_dynamic_player())
        if (player) then
            playerStore:dispatch({
                type = "SAVE_POSITION"
            })
        end

        -- Avoid annoying low health/shield bug after swaping bipeds
        player.health = 1
        player.shield = 1

        -- Needs kinda refactoring, probably splitting this into LuaBlam
        local globalsTagAddress = get_tag("matg", "globals\\globals")
        local globalsTagData = read_dword(globalsTagAddress + 0x14)
        local globalsTagMultiplayerBipedTagIdAddress = globalsTagData + 0x9BC + 0xC
        --local currentGlobalsBipedTagId = read_dword(globalsTagMultiplayerBipedTagIdAddress)
        for objectId = 0, 2043 do
            local tempObject = blam35.object(get_object(objectId))
            if (tempObject) then
                if (tempObject.tagId == get_tag_id("bipd", constants.bipeds.spartan)) then
                    write_dword(globalsTagMultiplayerBipedTagIdAddress,
                                get_tag_id("bipd", constants.bipeds.monitor))
                    delete_object(objectId)
                elseif (tempObject.tagId == get_tag_id("bipd", constants.bipeds.monitor)) then
                    write_dword(globalsTagMultiplayerBipedTagIdAddress,
                                get_tag_id("bipd", constants.bipeds.spartan))
                    delete_object(objectId)
                end
            end
        end
    else
        dprint("Requesting monitor biped...")
        execute_script("rcon forge #b")
    end
end

--- Forces the game to open a widget given tag path
---@param tagPath string
---@return boolean result susccess
function features.openMenu(tagPath, prevent)
    local uiWidgetTagId = get_tag_id(tagClasses.uiWidgetDefinition, tagPath)
    if (uiWidgetTagId) then
        load_ui_widget(tagPath)
        return true
    end
    return false
end

--- Print formatted text into HUD message output
---@param message string
---@param optional string
function features.printHUD(message, optional, forcedTickCount)
    textRefreshCount = forcedTickCount or 0

    local color = {1, 0.890, 0.949, 0.992}
    if (optional) then
        drawTextBuffer = {
            message:upper() .. "\r" .. optional:upper(),
            0,
            290,
            640,
            480,
            constants.hudFont,
            "center",
            table.unpack(color)
        }
    else
        drawTextBuffer = {
            message:upper(),
            0,
            285,
            640,
            480,
            constants.hudFont,
            "center",
            table.unpack(color)
        }
    end
end

return features

end,

["forge.hook"] = function()
--------------------
-- Module: 'forge.hook'
--------------------
------------------------------------------------------------------------------
-- Forge Hook
-- Author: Sledmine
-- Version: 1.0
-- Every hook executes a function
------------------------------------------------------------------------------
local hook = {}

function hook.attach(hookName, action, param)
    if (get_global(hookName .. "_hook")) then
        execute_script("set " .. hookName .. "_hook " .. " false")
        action(param)
    end
end

return hook

end,

["forge.menu"] = function()
--------------------
-- Module: 'forge.menu'
--------------------
------------------------------------------------------------------------------
-- Forge Menus
-- Author: Sledmine
-- Version: 1.0
-- Menus handler
------------------------------------------------------------------------------
local menu = {}

---@param widgetPath string
---@param widgetCount number
function menu.update(widgetPath, widgetCount)
    blam35.uiWidgetDefinition(get_tag("ui_widget_definition", widgetPath), {
        childWidgetsCount = widgetCount,
        -- Send new event type to force re render
        eventType = 33
    })
end

---@param widgetPath string
function menu.close(widgetPath)
    blam35.uiWidgetDefinition(get_tag("ui_widget_definition", widgetPath), {
        -- Send new event type to force close
        eventType = 33
    })
end

--- Stop the execution of a forced event
---@param widgetPath string
function menu.stop(widgetPath)
    blam35.uiWidgetDefinition(get_tag("ui_widget_definition", widgetPath), {
        -- Send new event type to stop close
        eventType = 32
    })
end

return menu

end,

["forge.tests"] = function()
--------------------
-- Module: 'forge.tests'
--------------------
------------------------------------------------------------------------------
-- Forge Tests
-- Author: Sledmine
-- Version: 1.0
-- Couple of tests for Forge functionality
------------------------------------------------------------------------------
local lu = require "luaunit"
local inspect = require "inspect"

-- Forge modules
local core = require "forge.core"

local features = require "forge.features"

-- Mocked function to redirect print calls to test print
local function tprint(message, ...)
    if (message) then
        if (message:find("Starting")) then
            console_out(message)
            return
        end
        console_out(message)
    end
end

local unit = {}

----------------- Rcon Tests -----------------------
testRcon = {}

function testRcon:setUp()
    -- Patch function if does not exist due to chimera blocking function thing
    if (not OnRcon) then
        OnRcon = function()
        end
    end
    self.expectedDecodeResultSpawn = {
        pitch = 360,
        requestType = "#s",
        remoteId = 1234,
        roll = 360,
        tagId = 1234,
        x = 1,
        y = 2,
        yaw = 360,
        z = 3
    }

    self.expectedDecodeResultUpdate = {
        pitch = 360,
        requestType = "#u",
        roll = 360,
        objectId = 1234,
        x = 1,
        y = 2,
        yaw = 360,
        z = 3
    }

    self.expectedDecodeResultDelete = {
        requestType = "#d",
        objectId = 1234
    }
end

function testRcon:testCallback()
    local decodeResult = OnRcon("I am a callback test!")
    lu.assertEquals(decodeResult, true)
end

function testRcon:testDecodeSpawn()
    local decodeResult, decodeData = OnRcon(
                                         "'#s|d2040000|0000803f|00000040|00004040|360|360|360|d2040000'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultSpawn)
end

function testRcon:testDecodeUpdate()
    local decodeResult, decodeData = OnRcon("'#u|1234|0000803f|00000040|00004040|360|360|360'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultUpdate)
end

function testRcon:testDecodeDelete()
    local decodeResult, decodeData = OnRcon("'#d|1234'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultDelete)
end

----------------- Objects Tests -----------------------

testObjects = {}

function testObjects:testSpawnAndRotateObjects()
    for index, tagPath in pairs(forgeStore:getState().forgeMenu.objectsDatabase) do
        -- Spawn object in the game
        local objectId = core.spawnObject("scen", tagPath, 233, 41,
                                            constants.minimumZSpawnPoint + 1)
        -- Check the object has been spawned
        lu.assertNotIsNil(objectId)
        if (objectId) then
            for i = 1, 1000 do
                core.rotateObject(objectId, math.random(1, 360), math.random(1, 360),
                                  math.random(1, 360))
            end
            delete_object(objectId)
        end
    end
end

function testObjects:testGetNetgameSpawnPoints()
    local scenario = blam.scenario(0)
    console_out(scenario.vehicleLocationCount)
    lu.assertEquals(scenario.vehicleLocationCount, 33)
end

----------------- Request Tests -----------------------

testRequest = {}

function testRequest:setUp()
    self.expectedEncodeSpawnResult = "#s|d2040000|0000803f|00000040|00004040|360|360|360"
    self.expectedEncodeUpdateResult = "#u|1234|0000803f|00000040|00004040|360|360|360"
    self.expectedEncodeDeleteResult = "#d|1234"
end

function testRequest:testSpawnRequestAsClient()
    local objectExample = {
        requestType = "#s",
        tagId = 1234,
        x = 1.0,
        y = 2.0,
        z = 3.0,
        yaw = 360,
        pitch = 360,
        roll = 360
    }
    local request = core.createRequest(objectExample)
    lu.assertEquals(request, self.expectedEncodeSpawnResult)
end

function testRequest:testEncodeUpdateAsClient()
    local objectExample = {
        requestType = "#u",
        x = 1.0,
        y = 2.0,
        z = 3.0,
        yaw = 360,
        pitch = 360,
        roll = 360,
        remoteId = 1234
    }
    local request = core.createRequest(objectExample)
    lu.assertEquals(request, self.expectedEncodeUpdateResult)
end

function testRequest:testEncodeDeleteAsClient()
    local objectExample = {
        requestType = "#d",
        remoteId = 1234
    }
    local request = core.createRequest(objectExample)
    lu.assertEquals(request, self.expectedEncodeDeleteResult)
end

----------------- Menus Tests -----------------------

testMenus = {}

function testMenus:setUp()
    local forgeMenuTagPath = constants.uiWidgetDefinitions.forgeMenu
    self.expectedTagId = get_simple_tag_id(tagClasses.uiWidgetDefinition, forgeMenuTagPath)
end

----------------- Core Functions Tests -----------------------

testCore = {}

function testCore:setUp()
    -- yaw 0, pitch 0, roll 0
    self.case1Array = {1, 0, 0, 0, 0, 1}
    self.case1Matrix = {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    }
    -- yaw 45, pitch 0, roll 0
    self.case2Array = {
        0.70710678118655,
        0.70710678118655,
        0,
        0,
        0,
        1
    }
    self.case2Matrix = {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    }
end

function testCore:testEulerRotation()
    local case1Array, case1Matrix = core.eulerToRotation(0, 0, 0)
    lu.assertEquals(case1Array, self.case1Array, "Rotation array must match", true)
    lu.assertEquals(case1Matrix, self.case1Matrix, "Rotation matrix must match", true)

    -- local case2Array, case2Matrix = core.eulerRotation(45, 0, 0)
    -- lu.assertEquals(case2Array, self.case2Array, "Rotation array must match", true)
    -- lu.assertEquals(case2Matrix, self.case2Matrix, "Rotation matrix must match", true)
end

----------------------------------

function unit.run(output)
    ftestingMode = true
    -- Disable debug printing
    -- debugMode = not debugMode
    local runner = lu.LuaUnit.new()
    if (output) then
        runner:setOutputType("junit", "forge_tests_results")
    end
    runner:runSuite()
    -- Restore debug printing
    -- debugMode = not debugMode
    ftestingMode = false
end

-- Mocked arguments and executions for standalone execution and in game execution
if (not arg) then
    arg = {"-v"}
    -- bprint = print
    print = tprint
else
    unit.run()
end

return unit

end,

["forge.triggers"] = function()
--------------------
-- Module: 'forge.triggers'
--------------------
------------------------------------------------------------------------------
-- Triggers
-- Author: Sledmine
-- Version: 1.0
-- Menu triggers
------------------------------------------------------------------------------
local triggers = {}

---@param triggerName string
---@param triggersNumber number
---@return number
function triggers.get(triggerName, triggersNumber)
    local restoreTriggersState = (function()
        for i = 1, triggersNumber do
            execute_script("set " .. triggerName .. "_trigger_" .. i .. " false")
        end
    end)
    for i = 1, triggersNumber do
        if (get_global(triggerName .. "_trigger_" .. i)) then
            restoreTriggersState()
            return i
        end
    end
    return nil
end

return triggers

end,

["forge.reducers.forgeReducer"] = function()
--------------------
-- Module: 'forge.reducers.forgeReducer'
--------------------
-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Forge modules

local menu = require "forge.menu"

local function forgeReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        ---@class forgeState
        state = {
            mapsMenu = {
                mapsList = {},
                currentMapsList = {},
                currentPage = 1,
                sidebar = {
                    height = constants.maximumSidebarSize,
                    position = 0,
                    slice = 0,
                    overflow = 0
                }
            },
            forgeMenu = {
                desiredElement = "root",
                objectsDatabase = {},
                objectsList = {root = {}},
                currentObjectsList = {},
                currentPage = 1,
                currentBudget = "0",
                currentBarSize = 0
            },
            loadingMenu = {
                loadingObjectPath = "",
                currentBarSize = 422,
                expectedObjects = 1
            },
            currentMap = {
                name = "Unsaved",
                author = "Author: Unknown",
                version = "1.0",
                description = "No description given for this map."
            }
        }
    end
    if (action.type) then
        dprint("[Forge Store]:")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == "UPDATE_MAP_LIST") then
        state.mapsMenu.mapsList = action.payload.mapsList

        -- Sort maps list by alphabetical order
        table.sort(state.mapsMenu.mapsList, function(a, b)
            return a:lower() < b:lower()
        end)

        state.mapsMenu.currentMapsList = glue.chunks(state.mapsMenu.mapsList, 8)
        local totalPages = #state.mapsMenu.currentMapsList
        if (totalPages > 1) then
            local sidebarHeight = glue.floor(constants.maximumSidebarSize / totalPages)
            if (sidebarHeight < constants.minimumSidebarSize) then
                sidebarHeight = constants.minimumSidebarSize
            end
            local spaceLeft = constants.maximumSidebarSize - sidebarHeight
            state.mapsMenu.sidebar.slice = glue.round(spaceLeft / (totalPages - 1))
            local fullSize = sidebarHeight + (state.mapsMenu.sidebar.slice * (totalPages - 1))
            state.mapsMenu.sidebar.overflow = fullSize - constants.maximumSidebarSize
            state.mapsMenu.sidebar.height = sidebarHeight - state.mapsMenu.sidebar.overflow
        end
        return state
    elseif (action.type == "INCREMENT_MAPS_MENU_PAGE") then
        if (state.mapsMenu.currentPage < #state.mapsMenu.currentMapsList) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage + 1
            local newHeight = state.mapsMenu.sidebar.height + state.mapsMenu.sidebar.slice
            local newPosition = state.mapsMenu.sidebar.position + state.mapsMenu.sidebar.slice
            if (state.mapsMenu.currentPage == 3) then
                newHeight = newHeight + state.mapsMenu.sidebar.overflow
            end
            if (state.mapsMenu.currentPage == #state.mapsMenu.currentMapsList - 1) then
                newHeight = newHeight - state.mapsMenu.sidebar.overflow
            end
            state.mapsMenu.sidebar.height = newHeight
            state.mapsMenu.sidebar.position = newPosition
        end
        dprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == "DECREMENT_MAPS_MENU_PAGE") then
        if (state.mapsMenu.currentPage > 1) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage - 1
            local newHeight = state.mapsMenu.sidebar.height - state.mapsMenu.sidebar.slice
            local newPosition = state.mapsMenu.sidebar.position - state.mapsMenu.sidebar.slice
            if (state.mapsMenu.currentPage == 2) then
                newHeight = newHeight - state.mapsMenu.sidebar.overflow
            end
            if (state.mapsMenu.currentPage == #state.mapsMenu.currentMapsList - 2) then
                newHeight = newHeight + state.mapsMenu.sidebar.overflow
            end
            state.mapsMenu.sidebar.height = newHeight
            state.mapsMenu.sidebar.position = newPosition
        end
        dprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == "UPDATE_FORGE_OBJECTS_LIST") then
        state.forgeMenu = action.payload.forgeMenu
        local objectsList = glue.childsbyparent(state.forgeMenu.objectsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        for i = 1, #keysList do
            if (string.sub(keysList[i], 1, 1) == "_") then
                keysList[i] = string.sub(keysList[i], 2, -1)
            end
        end

        -- Create list pagination
        state.forgeMenu.currentObjectsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "INCREMENT_FORGE_MENU_PAGE") then
        dprint("Page:" .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage < #state.forgeMenu.currentObjectsList) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage + 1
        end
        return state
    elseif (action.type == "DECREMENT_FORGE_MENU_PAGE") then
        dprint("Page:" .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage > 1) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage - 1
        end
        return state
    elseif (action.type == "DOWNWARD_NAV_FORGE_MENU") then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = action.payload.desiredElement
        local objectsList = glue.childsbyparent(state.forgeMenu.objectsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        -- Create list pagination
        state.forgeMenu.currentObjectsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "UPWARD_NAV_FORGE_MENU") then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = glue.parentbychild(state.forgeMenu.objectsList,
                                                            state.forgeMenu.desiredElement)
        local objectsList = glue.childsbyparent(state.forgeMenu.objectsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        -- Create list pagination
        state.forgeMenu.currentObjectsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "SET_MAP_NAME") then
        state.currentMap.name = action.payload.mapName
        return state
    elseif (action.type == "SET_MAP_DESCRIPTION") then
        state.currentMap.description = action.payload.mapDescription
        return state
    elseif (action.type == "SET_MAP_DATA") then
        state.currentMap.name = action.payload.mapName
        if (action.payload.mapDescription == "") then
            state.currentMap.description = "No description given for this map."
            return state
        end
        state.currentMap.description = action.payload.mapDescription
        return state
    elseif (action.type == "UPDATE_MAP_INFO") then
        if (action.payload) then
            local expectedObjects = action.payload.expectedObjects
            local mapName = action.payload.mapName
            local mapDescription = action.payload.mapDescription
            if (expectedObjects) then
                state.loadingMenu.expectedObjects = expectedObjects
            end
            if (mapName) then
                state.currentMap.name = mapName
            end
            if (mapDescription) then
                state.currentMap.description = mapDescription
            end
            if (action.payload.loadingObjectPath) then
                state.loadingMenu.loadingObjectPath = action.payload.loadingObjectPath
            end
        end
        if (server_type ~= "sapp") then
            if (eventsStore) then
                if (state.loadingMenu.expectedObjects > 0) then
                    -- Set current budget bar data
                    local objectState = eventsStore:getState().forgeObjects
                    local currentObjects = #glue.keys(objectState)
                    local newBarSize = currentObjects * constants.maximumProgressBarSize /
                                           constants.maximumBudget
                    state.forgeMenu.currentBarSize = glue.floor(newBarSize)
                    state.forgeMenu.currentBudget = tostring(currentObjects)

                    -- Set loading map bar data
                    local expectedObjects = state.loadingMenu.expectedObjects
                    local newBarSize = currentObjects * constants.maximumLoadingProgressBarSize /
                                           expectedObjects
                    state.loadingMenu.currentBarSize = glue.floor(newBarSize)
                    if (state.loadingMenu.currentBarSize >= constants.maximumLoadingProgressBarSize) then
                        menu.close(constants.uiWidgetDefinitions.loadingMenu)
                    end
                else
                    menu.close(constants.uiWidgetDefinitions.loadingMenu)
                end
            end
        end
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint("ERROR!!! The dispatched event does not exist:", "error")
        end
        return state
    end
end

return forgeReducer

end,

["forge.reducers.eventsReducer"] = function()
--------------------
-- Module: 'forge.reducers.eventsReducer'
--------------------
-- Lua libraries
local glue = require "glue"
local inspect = require "inspect"

-- Forge modules
local core = require "forge.core"
local features = require "forge.features"

local function eventsReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {
            forgeObjects = {},
            playerVotes = {},
            mapsList = {
                {
                    mapName = "Begotten",
                    mapGametype = "Team Slayer",
                    mapIndex = 1
                },
                {
                    mapName = "Octagon",
                    mapGametype = "Slayer",
                    mapIndex = 1
                },
                {
                    mapName = "Strong Enough",
                    mapGametype = "CTF",
                    mapIndex = 1
                },
                {
                    mapName = "Castle",
                    mapGametype = "CTF",
                    mapIndex = 1
                }
            }
        }
    end
    if (action.type) then
        dprint("-> [Events Store]")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == constants.requests.spawnObject.actionType) then
        dprint("SPAWNING object to store...", "warning")
        local requestObject = action.payload.requestObject

        -- Create a new object rather than passing it as "reference"
        local forgeObject = glue.update({}, requestObject)

        local tagPath = get_tag_path(requestObject.tagId)

        -- Get all the existent objects in the game before object spawn
        local objectsBeforeSpawn = get_objects()

        -- Spawn object in the game
        local localObjectId = core.spawnObject("scen", tagPath, forgeObject.x, forgeObject.y,
                                               forgeObject.z)

        -- Get all the existent objects in the game after object spawn
        local objectsAfterSpawn = get_objects()

        -- Tricky way to get object local id, due to Chimera 581 API returning a whole id instead of id
        -- Remember objectId is local to this game
        if (server_type ~= "sapp") then
            local newObjects = glue.arraynv(objectsBeforeSpawn, objectsAfterSpawn)
            localObjectId = newObjects[#newObjects]
        end

        -- Set object rotation after creating the object
        core.rotateObject(localObjectId, forgeObject.yaw, forgeObject.pitch, forgeObject.roll)

        -- We are the server so the remote id is the local objectId
        if (server_type == "local" or server_type == "sapp") then
            forgeObject.remoteId = localObjectId
        end

        dprint("objectId: " .. localObjectId)
        dprint("remoteId: " .. forgeObject.remoteId)

        -- Check and take actions if the object is a special netgame object
        if (tagPath:find("spawning")) then
            dprint("-> [Reflecting Spawn]", "warning")
            if (tagPath:find("gametypes")) then
                dprint("GAMETYPE_SPAWN", "category")
                -- Make needed modifications to game spawn points
                core.updatePlayerSpawn(tagPath, forgeObject)
            elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                dprint("VEHICLE_SPAWN", "category")
                core.updateVehicleSpawn(tagPath, forgeObject)
            elseif (tagPath:find("weapons")) then
                dprint("WEAPON_SPAWN", "category")
                core.updateNetgameEquipmentSpawn(tagPath, forgeObject)
            end
        elseif (tagPath:find("objectives")) then
            dprint("-> [Reflecting Flag]", "warning")
            core.updateNetgameFlagSpawn(tagPath, forgeObject)
        end

        -- As a server we have to send back a response/request to the players in the server
        if (server_type == "sapp") then
            local response = core.createRequest(forgeObject)
            core.sendRequest(response)
        end

        -- Clean and prepare object
        forgeObject.tagId = nil

        -- Store the object in our state
        state.forgeObjects[localObjectId] = forgeObject

        -- Update the current map information
        forgeStore:dispatch({
            type = "UPDATE_MAP_INFO"
        })

        return state
    elseif (action.type == constants.requests.updateObject.actionType) then
        local requestObject = action.payload.requestObject
        local targetObjectId =
            core.getObjectIdByRemoteId(state.forgeObjects, requestObject.objectId)
        local forgeObject = state.forgeObjects[targetObjectId]

        if (forgeObject) then
            dprint("UPDATING object from store...", "warning")

            forgeObject.x = requestObject.x
            forgeObject.y = requestObject.y
            forgeObject.z = requestObject.z
            forgeObject.yaw = requestObject.yaw
            forgeObject.pitch = requestObject.pitch
            forgeObject.roll = requestObject.roll

            -- Update object rotation
            core.rotateObject(targetObjectId, forgeObject.yaw, forgeObject.pitch, forgeObject.roll)

            -- Update object position
            blam35.object(get_object(targetObjectId), {
                x = forgeObject.x,
                y = forgeObject.y,
                z = forgeObject.z
            })

            -- Check and take actions if the object is reflecting a netgame point
            if (forgeObject.reflectionId) then
                local tempObject = blam35.object(get_object(targetObjectId))
                local tagPath = get_tag_path(tempObject.tagId)
                if (tagPath:find("spawning")) then
                    dprint("-> [Reflecting Spawn]", "warning")
                    if (tagPath:find("gametypes")) then
                        dprint("GAMETYPE_SPAWN", "category")
                        -- Make needed modifications to game spawn points
                        core.updatePlayerSpawn(tagPath, forgeObject)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        dprint("VEHICLE_SPAWN", "category")
                        core.updateVehicleSpawn(tagPath, forgeObject)
                    elseif (tagPath:find("weapons")) then
                        dprint("WEAPON_SPAWN", "category")
                        core.updateNetgameEquipmentSpawn(tagPath, forgeObject)
                    end
                elseif (tagPath:find("objectives")) then
                    dprint("-> [Reflecting Flag]", "warning")
                    core.updateNetgameFlagSpawn(tagPath, forgeObject)
                end
            end

            -- As a server we have to send back a response/request to the players in the server
            if (server_type == "sapp") then
                print(inspect(requestObject))
                local response = core.createRequest(requestObject)
                core.sendRequest(response)
            end
        else
            dprint("ERROR!!! The required object with Id: " .. requestObject.objectId ..
                       "does not exist.", "error")
        end
        return state
    elseif (action.type == constants.requests.deleteObject.actionType) then
        local requestObject = action.payload.requestObject
        local targetObjectId =
            core.getObjectIdByRemoteId(state.forgeObjects, requestObject.objectId)
        local forgeObject = state.forgeObjects[targetObjectId]

        if (forgeObject) then
            if (forgeObject.reflectionId) then
                local tempObject = blam35.object(get_object(targetObjectId))
                local tagPath = get_tag_path(tempObject.tagId)
                if (tagPath:find("spawning")) then
                    dprint("-> [Reflecting Spawn]", "warning")
                    if (tagPath:find("gametypes")) then
                        dprint("GAMETYPE_SPAWN", "category")
                        -- Make needed modifications to game spawn points
                        core.updatePlayerSpawn(tagPath, forgeObject, true)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        dprint("VEHICLE_SPAWN", "category")
                        core.updateVehicleSpawn(tagPath, forgeObject, true)
                    elseif (tagPath:find("weapons")) then
                        dprint("WEAPON_SPAWN", "category")
                        core.updateNetgameEquipmentSpawn(tagPath, forgeObject, true)
                    end
                end
            end

            dprint("Deleting object from store...", "warning")
            -- // TODO: Add validation to this erasement!
            delete_object(targetObjectId)
            state.forgeObjects[targetObjectId] = nil
            dprint("Done.", "success")

            -- As a server we have to send back a response/request to the players in the server
            if (server_type == "sapp") then
                local response = core.createRequest(requestObject)
                core.sendRequest(response)
            end
        else
            dprint("ERROR!!! The required object with Id: " .. requestObject.objectId ..
                       "does not exist.", "error")
        end
        -- Update the current map information
        forgeStore:dispatch({
            type = "UPDATE_MAP_INFO"
        })

        return state
    elseif (action.type == constants.requests.loadMapScreen.actionType) then
        -- // TODO: This is not ok, this must be split in different reducers
        local requestObject = action.payload.requestObject

        local expectedObjects = requestObject.objectCount
        local mapName = requestObject.mapName
        local mapDescription = requestObject.mapDescription

        forgeStore:dispatch({
            type = "UPDATE_MAP_INFO",
            payload = {
                expectedObjects = expectedObjects,
                mapName = mapName,
                mapDescription = mapDescription
            }
        })

        -- // TODO: This does not end after finishing map loading
        set_timer(140, "forgeAnimation")

        features.openMenu(constants.uiWidgetDefinitions.loadingMenu)

        return state
    elseif (action.type == constants.requests.flushForge.actionType) then
        state.forgeObjects = {}
        return state
    elseif (action.type == constants.requests.loadVoteMapScreen.actionType) then
        if (server_type ~= "sapp") then
            function preventClose()
                features.openMenu(constants.uiWidgetDefinitions.voteMenu)
                return false
            end
            set_timer(5000, "preventClose")
        else
            -- Send vote map menu open request
            local loadMapVoteMenuRequest = {
                requestType = constants.requests.loadVoteMapScreen.requestType
            }
            core.sendRequest(core.createRequest(loadMapVoteMenuRequest))
            -- Send list of all available vote maps
            for mapIndex, map in pairs(state.mapsList) do
                local voteMapOpenRequest = {
                    requestType = constants.requests.appendVoteMap.requestType
                }
                glue.update(voteMapOpenRequest, map)
                core.sendRequest(core.createRequest(voteMapOpenRequest))
            end
        end
        return state
    elseif (action.type == constants.requests.appendVoteMap.actionType) then
        if (server_type ~= "sapp") then
            local params = action.payload.requestObject
            votingStore:dispatch({
                type = "APPEND_MAP_VOTE",
                payload = {
                    map = {
                        name = params.mapName,
                        gametype = params.mapGametype
                    }
                }
            })
        end
        return state
    elseif (action.type == constants.requests.sendTotalMapVotes.actionType) then
        if (server_type == "sapp") then
            local mapVotes = {0, 0, 0, 0}
            for playerIndex, mapIndex in pairs(state.playerVotes) do
                mapVotes[mapIndex] = mapVotes[mapIndex] + 1
            end
            -- Send vote map menu open request
            local sendTotalMapVotesRequest = {
                requestType = constants.requests.sendTotalMapVotes.requestType

            }
            for mapIndex, votes in pairs(mapVotes) do
                sendTotalMapVotesRequest["votesMap" .. mapIndex] = votes
            end
            core.sendRequest(core.createRequest(sendTotalMapVotesRequest))
        else
            local params = action.payload.requestObject
            local votesList = {params.votesMap1, params.votesMap2, params.votesMap3, params.votesMap4}
            votingStore:dispatch({type = "SET_MAP_VOTES_LIST", payload = {votesList = votesList}})
        end
        return state
    elseif (action.type == constants.requests.sendMapVote.actionType) then
        -- // TODO: Add vote map logic to handle player votes
        if (action.playerIndex and server_type == "sapp") then
            local playerName = get_var(action.playerIndex, "$name")
            if (not state.playerVotes[action.playerIndex]) then
                local params = action.payload.requestObject
                state.playerVotes[action.playerIndex] = params.mapVoted
                local mapName = state.mapsList[params.mapVoted].mapName
                local mapGametype = state.mapsList[params.mapVoted].mapGametype
                
                gprint(playerName .. " voted for " .. mapName .. " " .. mapGametype)
                eventsStore:dispatch({
                    type = constants.requests.sendTotalMapVotes.actionType
                })
                local playerVotes = state.playerVotes
                if (#playerVotes > 0) then
                    local mapsList = state.mapsList
                    local mapVotes = {0, 0, 0, 0}
                    for playerIndex, mapIndex in pairs(playerVotes) do
                        mapVotes[mapIndex] = mapVotes[mapIndex] + 1
                    end
                    local mostVotedMapIndex = 1
                    local topVotes = 0
                    for mapIndex, votes in pairs(mapVotes) do
                        if (votes > topVotes) then
                            topVotes = votes
                            mostVotedMapIndex = mapIndex
                        end
                    end
                    local winnerMap = mapsList[mostVotedMapIndex].mapName:gsub(" ", "_"):lower()
                    local winnerGametype = mapsList[mostVotedMapIndex].mapGametype:gsub(" ", "_"):lower()
                    print("Most voted map is: " .. winnerMap)
                    forgeMapName = winnerMap
                    execute_command("sv_map forge_island " .. winnerGametype)
                end
            end
        end
        return state
    elseif (action.type == constants.requests.flushVotes.actionType) then
        state.playerVotes = {}
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint("ERROR!!! The dispatched event does not exist.", "error")
        end
        return state
    end
end

return eventsReducer

end,

["forge.reducers.playerReducer"] = function()
--------------------
-- Module: 'forge.reducers.playerReducer'
--------------------
local glue = require "glue"

-- Forge modules
local core = require "forge.core"


function playerReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        ---@class position
        ---@field x number
        ---@field y number
        ---@field z number
        ---@class playerState
        ---@field position position
        state = {
            lockDistance = true,
            distance = 5,
            attachedObjectId = nil,
            position = nil,
            xOffset = 0,
            yOffset = 0,
            zOffset = 0,
            yaw = 0,
            pitch = 0,
            roll = 0,
            rotationStep = 5,
            currentAngle = "yaw"
        }
    end
    if (action.type == "SET_LOCK_DISTANCE") then
        state.lockDistance = action.payload.lockDistance
        return state
    elseif (action.type == "CREATE_AND_ATTACH_OBJECT") then
        -- // TODO: Send a request to attach this object to a player in the server side
        if (state.attachedObjectId) then
            if (get_object(state.attachedObjectId)) then
                delete_object(state.attachedObjectId)
                state.attachedObjectId = core.spawnObject("scen", action.payload.path,
                                                          state.xOffset, state.yOffset,
                                                          state.zOffset)
            else
                state.attachedObjectId = core.spawnObject("scen", action.payload.path,
                                                          state.xOffset, state.yOffset,
                                                          state.zOffset)
            end
        else
            state.attachedObjectId = core.spawnObject("scen", action.payload.path, state.xOffset,
                                                      state.yOffset, state.zOffset)
        end
        core.rotateObject(state.attachedObjectId, state.yaw, state.pitch, state.roll)
        return state
    elseif (action.type == "ATTACH_OBJECT") then
        state.attachedObjectId = action.payload.objectId
        local fromPerspective = action.payload.fromPerspective
        if (fromPerspective) then
            local player = blam35.biped(get_dynamic_player())
            local tempObject = blam35.object(get_object(state.attachedObjectId))
            if (tempObject) then
                local distance = core.calculateDistanceFromObject(player, tempObject)
                if (configuration.snapMode) then
                    state.distance = glue.round(distance)
                else
                    state.distance = distance
                end
            end
        end
        local forgeObjects = eventsStore:getState().forgeObjects
        local composedObject = forgeObjects[state.attachedObjectId]
        if (composedObject) then
            state.yaw = composedObject.yaw
            state.pitch = composedObject.pitch
            state.roll = composedObject.roll
        end
        return state
    elseif (action.type == "DETACH_OBJECT") then
        if (action.payload) then
            local payload = action.payload
            if (payload.undo) then
                state.attachedObjectId = nil
                return state
            end
        end
        -- Send update request in case of needed
        if (state.attachedObjectId and get_object(state.attachedObjectId)) then
            local forgeObjects = eventsStore:getState().forgeObjects
            local composedObject = forgeObjects[state.attachedObjectId]
            if (not composedObject) then
                -- Object does not exist, create request table and send request
                local requestTable = {}
                requestTable.requestType = constants.requests.spawnObject.requestType
                local tempObject = blam35.object(get_object(state.attachedObjectId))
                requestTable.tagId = tempObject.tagId
                requestTable.x = state.xOffset
                requestTable.y = state.yOffset
                requestTable.z = state.zOffset
                requestTable.yaw = state.yaw
                requestTable.pitch = state.pitch
                requestTable.roll = state.roll
                core.sendRequest(core.createRequest(requestTable))
                delete_object(state.attachedObjectId)
            else
                local requestTable = composedObject
                requestTable.requestType = constants.requests.updateObject.requestType
                local tempObject = blam35.object(get_object(state.attachedObjectId))
                requestTable.x = tempObject.x
                requestTable.y = tempObject.y
                requestTable.z = tempObject.z
                requestTable.yaw = state.yaw
                requestTable.pitch = state.pitch
                requestTable.roll = state.roll
                -- Object already exists, send update request
                core.sendRequest(core.createRequest(requestTable))
            end
            state.attachedObjectId = nil
        end
        return state
    elseif (action.type == "ROTATE_OBJECT") then
        if (state.attachedObjectId and get_object(state.attachedObjectId)) then
            core.rotateObject(state.attachedObjectId, state.yaw, state.pitch, state.roll)
        end
        return state
    elseif (action.type == "DESTROY_OBJECT") then
        -- Delete attached object
        if (state.attachedObjectId and get_object(state.attachedObjectId)) then
            local forgeObjects = eventsStore:getState().forgeObjects
            local composedObject = forgeObjects[state.attachedObjectId]
            if (not composedObject) then
                delete_object(state.attachedObjectId)
            else
                local requestTable = composedObject
                requestTable.requestType = constants.requests.deleteObject.requestType
                requestTable.remoteId = composedObject.remoteId
                core.sendRequest(core.createRequest(requestTable))
            end
        end
        state.attachedObjectId = nil
        return state
    elseif (action.type == "UPDATE_OFFSETS") then
        local player = blam35.biped(get_dynamic_player())
        local xOffset = player.x + player.cameraX * state.distance
        local yOffset = player.y + player.cameraY * state.distance
        local zOffset = player.z + player.cameraZ * state.distance
        if (configuration.snapMode) then
            state.xOffset = glue.round(xOffset)
            state.yOffset = glue.round(yOffset)
            state.zOffset = glue.round(zOffset)
        else
            state.xOffset = xOffset
            state.yOffset = yOffset
            state.zOffset = zOffset
        end
        return state
    elseif (action.type == "UPDATE_DISTANCE") then
        if (state.attachedObjectId) then
            local player = blam35.biped(get_dynamic_player())
            local tempObject = blam35.object(get_object(state.attachedObjectId))
            if (tempObject) then
                local distance = core.calculateDistanceFromObject(player, tempObject)
                if (configuration.snapMode) then
                    state.distance = glue.round(distance)
                else
                    state.distance = distance
                end
            end
        end
        return state
    elseif (action.type == "SET_DISTANCE") then
        state.distance = action.payload.distance
        return state
    elseif (action.type == "CHANGE_ROTATION_ANGLE") then
        if (state.currentAngle == "yaw") then
            state.currentAngle = "pitch"
        elseif (state.currentAngle == "pitch") then
            state.currentAngle = "roll"
        else
            state.currentAngle = "yaw"
        end
        return state
    elseif (action.type == "SET_ROTATION_STEP") then
        state.rotationStep = action.payload.step
        return state
    elseif (action.type == "STEP_ROTATION_DEGREE") then
        local previousRotation = state[state.currentAngle]
        if (previousRotation >= 360) then
            state[state.currentAngle] = 0
        else
            state[state.currentAngle] = previousRotation + state.rotationStep
        end
        return state
    elseif (action.type == "SET_ROTATION_DEGREES") then
        if (action.payload.yaw) then
            state.yaw = action.payload.yaw
        end
        if (action.payload.pitch) then
            state.pitch = action.payload.pitch
        end
        if (action.payload.roll) then
            state.roll = action.payload.roll
        end
        return state
    elseif (action.type == "RESET_ROTATION") then
        state.yaw = 0
        state.pitch = 0
        state.roll = 0
        -- state.currentAngle = 'yaw'
        return state
    elseif (action.type == "SAVE_POSITION") then
        -- Do not forget to migrate this to dumpObject or getAll
        local tempObject = blam35.biped(get_dynamic_player())
        state.position = {
            x = tempObject.x,
            y = tempObject.y,
            z = tempObject.z
        }
        return state
    elseif (action.type == "RESET_POSITION") then
        state.position = nil
        return state
    else
        return state
    end
end

return playerReducer

end,

["forge.reducers.votingReducer"] = function()
--------------------
-- Module: 'forge.reducers.votingReducer'
--------------------
-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Forge modules

local menu = require "forge.menu"

local function votingReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {
            votingMenu = {
                mapsList = {
                    {
                        name = "Forge",
                        gametype = "Slayer"
                    },
                    {
                        name = "Forge",
                        gametype = "Slayer"
                    },
                    {
                        name = "Forge",
                        gametype = "Slayer"
                    },
                    {
                        name = "Forge",
                        gametype = "Slayer"
                    }
                },
                votesList = {0, 0, 0, 0}
            }
        }
    end
    if (action.type) then
        dprint("-> [Voting Store]")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == "APPEND_MAP_VOTE") then
        if (#state.votingMenu.mapsList < 4) then
            local map = action.payload.map
            glue.append(state.votingMenu.mapsList, map)
            dprint(inspect(state.votingMenu.mapsList))
        end
        return state
    elseif (action.type == "SET_MAP_VOTES_LIST") then
        dprint(inspect(action.payload.votesList))
        state.votingMenu.votesList = action.payload.votesList
        return state
    elseif (action.type == "FLUSH_MAP_VOTES") then
        state.votingMenu.mapsList = {}
        state.votingMenu.votesList = {0, 0, 0, 0}
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint("ERROR!!! The dispatched event does not exist:", "error")
        end
        return state
    end
end

return votingReducer

end,

["forge.reflectors.forgeReflector"] = function()
--------------------
-- Module: 'forge.reflectors.forgeReflector'
--------------------
------------------------------------------------------------------------------
-- Forge Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------

local menu = require "forge.menu"

local inspect = require "inspect"

local function forgeReflector()
    -- Get current forge state
    local forgeState = forgeStore:getState()

    local currentObjectsList = forgeState.forgeMenu.currentObjectsList[forgeState.forgeMenu
                                   .currentPage]

    -- Prevent errors objects does not exist
    if (not currentObjectsList) then
        dprint("Current objects list is empty.", "warning")
        currentObjectsList = {}
    end

    -- Forge Menu
    blam35.unicodeStringList(get_tag("unicode_string_list", constants.unicodeStrings.forgeList),
                           {
        stringList = currentObjectsList
    })
    menu.update(constants.uiWidgetDefinitions.objectsList, #currentObjectsList + 2)

    local paginationTextAddress =
        get_tag("unicode_string_list", constants.unicodeStrings.pagination)
    if (paginationTextAddress) then
        local pagination = blam35.unicodeStringList(paginationTextAddress)
        local paginationStringList = pagination.stringList
        paginationStringList[2] = tostring(forgeState.forgeMenu.currentPage)
        paginationStringList[4] = tostring(#forgeState.forgeMenu.currentObjectsList)
        blam35.unicodeStringList(paginationTextAddress, {
            stringList = paginationStringList
        })
    end

    -- Budget count
    -- Update unicode string with current budget value
    local budgetCountAddress = get_tag("unicode_string_list", constants.unicodeStrings.budgetCount)
    local currentBudget = blam35.unicodeStringList(budgetCountAddress)

    currentBudget.stringList = {
        forgeState.forgeMenu.currentBudget,
        "/ " .. tostring(constants.maximumBudget)
    }

    -- Refresh budget count
    blam35.unicodeStringList(budgetCountAddress, currentBudget)
    

    -- Refresh budget bar status
    blam35.uiWidgetDefinition(
        get_tag("ui_widget_definition", constants.uiWidgetDefinitions.amountBar),
        {
            width = forgeState.forgeMenu.currentBarSize
        })

    -- Refresh loading bar size
    blam35.uiWidgetDefinition(get_tag("ui_widget_definition",
                                    constants.uiWidgetDefinitions.loadingProgress),
                            {
        width = forgeState.loadingMenu.currentBarSize
    })

    local currentMapsList = forgeState.mapsMenu.currentMapsList[forgeState.mapsMenu.currentPage]

    -- Prevent errors when maps does not exist
    if (not currentMapsList) then
        dprint("Current maps list is empty.")
        currentMapsList = {}
    end

    -- Refresh available forge maps list
    -- TO DO: Merge unicode string updating with menus updating!
    blam35.unicodeStringList(get_tag("unicode_string_list", constants.unicodeStrings.mapsList),
                           {
        stringList = currentMapsList
    })
    -- Wich ui widget will be updated and how many items it will show
    menu.update(constants.uiWidgetDefinitions.mapsList, #currentMapsList + 3)

    -- Refresh fake sidebar in maps menu
    blam35.uiWidgetDefinition(get_tag("ui_widget_definition", constants.uiWidgetDefinitions.sidebar),
                            {
        height = forgeState.mapsMenu.sidebar.height,
        boundsY = forgeState.mapsMenu.sidebar.position
    })

    -- Refresh current forge map information
    blam35.unicodeStringList(
        get_tag("unicode_string_list", constants.unicodeStrings.pauseGameStrings), {
            stringList = {
                -- Bypass first 3 elements in the string list
                "",
                "",
                "",
                forgeState.currentMap.name,
                forgeState.currentMap.author,
                forgeState.currentMap.version,
                forgeState.currentMap.description
            }
        })
end

return forgeReflector

end,

["forge.reflectors.votingReflector"] = function()
--------------------
-- Module: 'forge.reflectors.votingReflector'
--------------------
------------------------------------------------------------------------------
-- Voting Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------
local glue = require "glue"

local menu = require "forge.menu"

local function votingReflector()
    -- Get current forge state
    local votingState = votingStore:getState()

    
    local votesList = votingState.votingMenu.votesList
    
    for k, v in pairs(votesList) do
        votesList[k] = tostring(v)
    end
    
    -- Voting Menu
    
    -- Get maps vote string list
    local unideStringListAddress = get_tag(tagClasses.unicodeStringList,
    constants.unicodeStrings.votingList)
    
    -- Update maps string list
    local mapsList = votingState.votingMenu.mapsList

    -- Prevent errors objects does not exist
    if (not mapsList) then
        dprint("Current maps vote list is empty.", "warning")
        mapsList = {}
    end
    
    local currentMapsList = {}
    for mapIndex, map in pairs (mapsList) do
        glue.append(currentMapsList, map.name .. "\r" .. map.gametype)
    end
    blam35.unicodeStringList(unideStringListAddress, {
        stringList = currentMapsList
    })

    unideStringListAddress = get_tag(tagClasses.unicodeStringList,
                                     constants.unicodeStrings.votingCountList)

    blam35.unicodeStringList(unideStringListAddress, {
        stringList = votesList
    })

end

return votingReflector

end,

----------------------
-- Modules part end --
----------------------
        }
        if files[path] then
            return files[path]
        else
            return origin_seacher(path)
        end
    end
end
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------
------------------------------------------------------------------------------
-- Forge Island Client Script
-- Sledmine
-- Version 4.0
-- Client side script for Forge Island
------------------------------------------------------------------------------
clua_version = 2.042

-- Lua libraries
local inspect = require "inspect"
local redux = require "lua-redux"
local glue = require "glue"
local json = require "json"

-- Halo Custom Edition libraries
blam = require "nlua-blam"
-- Bind legacy console out to better lua-blam printing function
console_out = blam.consoleOutput
-- Create global reference to tagClasses
objectClasses = blam.objectClasses
tagClasses = blam.tagClasses
-- Bring old api compatibility
blam35 = blam.compat35()
hfs = require "hcefs"

-- Forge modules
local triggers = require "forge.triggers"
local hook = require "forge.hook"
local menu = require "forge.menu"
local features = require "forge.features"
local commands = require "forge.commands"
local core = require "forge.core"

-- Reducers importation
local playerReducer = require "forge.reducers.playerReducer"
local eventsReducer = require "forge.reducers.eventsReducer"
local forgeReducer = require "forge.reducers.forgeReducer"
local votingReducer = require "forge.reducers.votingReducer"

-- Reflectors importation
local forgeReflector = require "forge.reflectors.forgeReflector"
local votingReflector = require "forge.reflectors.votingReflector"

-- Forge default configuration
-- DO NOT MODIFY ON SCRIPT!! use json config file instead
configuration = {
    debugMode = false,
    autoSave = false,
    autoSaveTime = 15000,
    snapMode = false,
    objectsCastShadow = false
}

-- Internal functions
debugBuffer = ""
textRefreshCount = 0

--- Function to send debug messages to console output
---@param message string
---@param color string | "'category'" | "'warning'" | "'error'" | "'success'"
function dprint(message, color)
    if (type(message) == "table") then
        return console_out(inspect(message))
    end
    debugBuffer = debugBuffer .. message .. "\n"
    if (debugMode) then
        if (color == "category") then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == "warning") then
            console_out(message, blam.consoleColors.warning)
        elseif (color == "error") then
            console_out(message, blam.consoleColors.error)
        elseif (color == "success") then
            console_out(message, blam.consoleColors.success)
        else
            console_out(message)
        end
    end
end

---@return boolean
function validateMapName()
    return map == "forge_island_dev" or map == "forge_island" or map == "forge_island_beta"
end

function loadForgeConfiguration()
    local configurationFolder = hfs.currentdir() .. "\\config"
    local configurationFile = glue.readfile(configurationFolder .. "\\forge_island.json")
    if (configurationFile) then
        configuration = json.decode(configurationFile)
    end
end

loadForgeConfiguration()

debugMode = configuration.debugMode

function loadForgeMaps()
    local mapsList = {}
    for file in hfs.dir(forgeMapsFolder) do
        if (file ~= "." and file ~= "..") then
            local splitFileName = glue.string.split(file, ".")
            local extFile = splitFileName[#splitFileName]
            -- Only load files with extension .fmap
            if (extFile == "fmap") then
                local mapName = string.gsub(file, ".fmap", "")
                glue.append(mapsList, mapName)
            end
        end
    end
    -- Dispatch state modification!
    local data = {mapsList = mapsList}
    forgeStore:dispatch({
        type = "UPDATE_MAP_LIST",
        payload = data
    })
end

function autoSaveForgeMap()
    if (configuration.autoSave and core.isPlayerMonitor()) then
        ---@type forgeState
        local forgeState = forgeStore:getState()
        local currentMapName = forgeState.currentMap.name
        if (currentMapName and currentMapName ~= "Unsaved") then
            core.saveForgeMap()
        end
    end
end

function OnMapLoad()
    -- Dinamically load constansts for the current forge map
    constants = require "forge.constants"
    constants.scenarioPath = "[shm]\\halo_4\\maps\\forge_island\\forge_island"
    constants.scenerysTagCollectionPath = "[shm]\\halo_4\\maps\\forge_island\\forge_island_scenerys"

    -- Like Redux we have some kind of store baby!! the rest is pure magic..
    playerStore = redux.createStore(playerReducer)
    forgeStore = redux.createStore(forgeReducer) -- Isolated store for all the Forge 'app' data
    eventsStore = redux.createStore(eventsReducer) -- Unique store for all the Forge Objects
    votingStore = redux.createStore(votingReducer) -- Storage for all the state of map voting

    local forgeState = forgeStore:getState()

    local tagCollectionAddress = get_tag(tagClasses.tagCollection,
                                         constants.scenerysTagCollectionPath)
    local tagCollection = blam35.tagCollection(tagCollectionAddress)

    -- // TODO: Refactor this entire loop, has been implemented from the old script!!!
    -- Iterate over all the sceneries available in the sceneries tag collection
    for i = 1, tagCollection.count do
        local sceneryPath = get_tag_path(tagCollection.tagList[i])

        local sceneriesSplit = glue.string.split(sceneryPath, "\\")
        local sceneryFolderIndex
        for folderNameIndex, folderName in pairs(sceneriesSplit) do
            if (folderName == "scenery") then
                sceneryFolderIndex = folderNameIndex + 1
            end
        end
        local fixedSplittedPath = {}
        for l = sceneryFolderIndex, #sceneriesSplit do
            fixedSplittedPath[#fixedSplittedPath + 1] = sceneriesSplit[l]
        end
        sceneriesSplit = fixedSplittedPath
        local sceneriesSplitLast = sceneriesSplit[#sceneriesSplit]

        forgeState.forgeMenu.objectsDatabase[sceneriesSplitLast] = sceneryPath
        -- Set first level as the root of available current objects
        -- Make a tree iteration to append sceneries
        local treePosition = forgeState.forgeMenu.objectsList.root
        for currentLevel, categoryLevel in pairs(sceneriesSplit) do
            if (categoryLevel:sub(1, 1) == "_") then
                categoryLevel = glue.string.fromhex(tostring((0x2))) .. categoryLevel:sub(2, -1)
            end
            if (not treePosition[categoryLevel]) then
                treePosition[categoryLevel] = {}
            end
            treePosition = treePosition[categoryLevel]
        end
    end

    local availableForgeObjects = #glue.keys(forgeState.forgeMenu.objectsDatabase)
    dprint("Scenery database has " .. availableForgeObjects .. " objects.")

    -- Subscribed function to refresh forge state into the game!
    forgeStore:subscribe(forgeReflector)

    -- Dispatch forge objects list update
    forgeStore:dispatch({
        type = "UPDATE_FORGE_OBJECTS_LIST",
        payload = {
            forgeMenu = forgeState.forgeMenu
        }
    })

    votingStore:subscribe(votingReflector)

    -- Dispatch forge objects list update
    votingStore:dispatch({
        type = "FLUSH_MAP_VOTES"
    })
    --[[votingStore:dispatch({
        type = "APPEND_MAP_VOTE",
        payload = {
            map = {
                name = "Forge",
                gametype = "Slayer"
            }
        }
    })]]

    local isForgeMap = validateMapName()
    if (isForgeMap) then
        -- Forge folders creation
        forgeMapsFolder = hfs.currentdir() .. "\\fmaps"
        local alreadyForgeMapsFolder = not hfs.mkdir(forgeMapsFolder)
        if (not alreadyForgeMapsFolder) then
            console_out("Forge maps folder has been created!")
        end

        configurationFolder = hfs.currentdir() .. "\\config"
        local alreadyConfigurationFolder = not hfs.mkdir(configurationFolder)
        if (not alreadyConfigurationFolder) then
            console_out("Configuratin folder has been created!")
        end

        -- Load all the forge stuff
        loadForgeConfiguration()
        loadForgeMaps()

        -- Start autosave timer
        if (not autoSaveTimer and server_type == "local") then
            autoSaveTimer = set_timer(configuration.autoSaveTime, "autoSaveForgeMap")
        end

        set_callback("tick", "OnTick")
        set_callback("preframe", "OnPreFrame")
        set_callback("rcon message", "OnRcon")
        set_callback("command", "onCommand")

    else
        error("This is not a compatible Forge map!!!")
    end
end

function OnPreFrame()
    local gameOnMenus = read_byte(blam.addressList.gameOnMenus) == 0
    if (drawTextBuffer and not gameOnMenus) then
        draw_text(table.unpack(drawTextBuffer))
    end
end

-- Where the magick happens, tiling!
function OnTick()
    -- Get player object
    ---@type biped
    local player = blam.biped(get_dynamic_player())

    -- Get player forge state
    ---@type playerState
    local playerState = playerStore:getState()
    if (player) then
        local oldPosition = playerState.position
        if (oldPosition) then
            blam35.biped(get_dynamic_player(), {
                x = oldPosition.x,
                y = oldPosition.y,
                z = oldPosition.z + 0.1
            })
            playerStore:dispatch({
                type = "RESET_POSITION"
            })
        end
        if (core.isPlayerMonitor()) then
            -- Provide better movement to monitors
            if (not player.ignoreCollision) then
                blam35.biped(get_dynamic_player(), {
                    ignoreCollision = true
                })
            end

            -- Calculate player point of view
            playerStore:dispatch({
                type = "UPDATE_OFFSETS"
            })

            -- Check if monitor has an object attached
            local attachedObjectId = playerState.attachedObjectId
            if (attachedObjectId) then
                -- Update object position
                blam35.object(get_object(attachedObjectId), {
                    x = playerState.xOffset,
                    y = playerState.yOffset,
                    z = playerState.zOffset
                })
                -- Change rotation angle
                if (player.flashlightKey) then
                    playerStore:dispatch({
                        type = "CHANGE_ROTATION_ANGLE"
                    })
                    features.printHUD("Rotating in " .. playerState.currentAngle)
                elseif (player.actionKeyHold or player.actionKey) then
                    playerStore:dispatch({
                        type = "STEP_ROTATION_DEGREE"
                    })
                    features.printHUD(playerState.currentAngle:upper() .. ": " ..
                                          playerState[playerState.currentAngle])

                    playerStore:dispatch({
                        type = "ROTATE_OBJECT"
                    })
                elseif (player.crouchHold) then
                    playerStore:dispatch({
                        type = "RESET_ROTATION"
                    })
                    playerStore:dispatch({
                        type = "ROTATE_OBJECT"
                    })
                elseif (player.weaponPTH and player.jumpHold) then
                    local forgeObjects = eventsStore:getState().forgeObjects
                    local forgeObject = forgeObjects[attachedObjectId]
                    if (forgeObject) then
                        -- Update object position
                        blam35.object(get_object(attachedObjectId), {
                            x = forgeObject.x,
                            y = forgeObject.y,
                            z = forgeObject.z
                        })
                        core.rotateObject(attachedObjectId, forgeObject.yaw, forgeObject.pitch,
                                          forgeObject.roll)
                        playerStore:dispatch({
                            type = "DETACH_OBJECT",
                            payload = {
                                undo = true
                            }
                        })
                    end
                elseif (player.meleeKey) then
                    playerStore:dispatch({
                        type = "SET_LOCK_DISTANCE",
                        payload = {
                            lockDistance = not playerState.lockDistance
                        }
                    })
                    features.printHUD("Distance from object is " ..
                                          tostring(glue.round(playerState.distance)) .. " units.")
                    if (playerState.lockDistance) then
                        features.printHUD("Push n pull.")
                    else
                        features.printHUD("Closer or further.")
                    end
                elseif (player.jumpHold) then
                    playerStore:dispatch({
                        type = "DESTROY_OBJECT"
                    })
                elseif (player.weaponSTH) then
                    playerStore:dispatch({
                        type = "DETACH_OBJECT"
                    })
                end

                if (not playerState.lockDistance) then
                    playerStore:dispatch({
                        type = "UPDATE_DISTANCE"
                    })
                    playerStore:dispatch({
                        type = "UPDATE_OFFSETS"
                    })
                end

                -- Unhighlight objects
                features.unhighlightAll()

                -- Update crosshair
                features.setCrosshairState(2)

                -- This was disabled because now objects can be spawned everywhere!
                -- if (playerState.zOffset < constants.minimumZSpawnPoint) then
                -- Set crosshair to not allowed
                --    features.setCrosshairState(3)
                -- end

            else

                -- Set crosshair to not selected state
                features.setCrosshairState(0)

                -- Unhighlight objects
                features.unhighlightAll()

                local forgeObjects = eventsStore:getState().forgeObjects

                -- Get if player is looking at some object
                for objectId, composedObject in pairs(forgeObjects) do
                    -- Object exists
                    if (composedObject) then
                        local tempObject = blam35.object(get_object(objectId))
                        local tagType = get_tag_type(tempObject.tagId)
                        if (tagType == tagClasses.scenery) then
                            local isPlayerLookingAt = core.playerIsLookingAt(objectId, 0.047, 0)
                            if (isPlayerLookingAt) then

                                -- Get and parse object name
                                local objectPath =
                                    glue.string.split(get_tag_path(tempObject.tagId), "\\")
                                local objectName = objectPath[#objectPath - 1]
                                local objectCategory = objectPath[#objectPath - 2]

                                if (objectCategory:sub(1, 1) == "_") then
                                    objectCategory = objectCategory:sub(2, -1)
                                end

                                objectName = objectName:gsub("^%l", string.upper)
                                objectCategory = objectCategory:gsub("^%l", string.upper)

                                features.printHUD("NAME:  " .. objectName,
                                                  "CATEGORY:  " .. objectCategory, 25)

                                -- Update crosshair state
                                if (features.setCrosshairState) then
                                    features.setCrosshairState(1)
                                end

                                -- Hightlight the object that the player is looking at
                                if (features.highlightObject) then
                                    features.highlightObject(objectId, 1)
                                end

                                -- Player is taking the object
                                if (player.weaponPTH and not player.jumpHold) then
                                    -- Set lock distance to true, to take object from perspective
                                    playerStore:dispatch(
                                        {
                                            type = "ATTACH_OBJECT",
                                            payload = {
                                                objectId = objectId,
                                                fromPerspective = true
                                            }
                                        })
                                elseif (player.actionKey) then
                                    playerStore:dispatch(
                                        {
                                            type = "SET_ROTATION_DEGREES",
                                            payload = {
                                                yaw = composedObject.yaw,
                                                pitch = composedObject.pitch,
                                                roll = composedObject.roll
                                            }
                                        })
                                    local tagId = blam35.object(get_object(objectId)).tagId
                                    playerStore:dispatch(
                                        {
                                            type = "CREATE_AND_ATTACH_OBJECT",
                                            payload = {
                                                path = get_tag_path(tagId)
                                            }
                                        })
                                end
                                -- Stop searching for other objects
                                break
                            end
                        end
                    end
                end
                -- Open Forge menu by pressing 'Q'
                if (player.flashlightKey) then
                    dprint("Opening Forge menu...")
                    features.openMenu(constants.uiWidgetDefinitions.forgeMenu)
                elseif (player.crouchHold) then
                    features.swapBiped()
                    playerStore:dispatch({
                        type = "DETACH_OBJECT"
                    })
                end
            end
        else
            -- Convert into monitor
            if (player.flashlightKey) then
                features.swapBiped()
            elseif (player.actionKey and player.crouchHold and server_type == "local") then
                core.spawnObject(tagClasses.biped, constants.bipeds.spartan, player.x, player.y,
                                 player.z)
            end
        end
    end

    -- Menu buttons interpcetion

    -- Trigger prefix and how many triggers are being read
    local mapsMenuPressedButton = triggers.get("maps_menu", 10)
    if (mapsMenuPressedButton) then
        if (mapsMenuPressedButton == 9) then
            -- Dispatch an event to increment current page
            forgeStore:dispatch({
                type = "DECREMENT_MAPS_MENU_PAGE"
            })
        elseif (mapsMenuPressedButton == 10) then
            -- Dispatch an event to decrement current page
            forgeStore:dispatch({
                type = "INCREMENT_MAPS_MENU_PAGE"
            })
        else
            local mapName = blam35.unicodeStringList(
                                get_tag("unicode_string_list", constants.unicodeStrings.mapsList))
                                .stringList[mapsMenuPressedButton]
            core.loadForgeMap(mapName)
        end
        dprint("Maps menu:")
        dprint("Button " .. mapsMenuPressedButton .. " was pressed!", "category")
    end

    -- Trigger prefix and how many triggers are being read
    local forgeMenuPressedButton = triggers.get("forge_menu", 9)
    if (forgeMenuPressedButton) then
        local forgeState = forgeStore:getState()
        if (forgeMenuPressedButton == 9) then
            if (forgeState.forgeMenu.desiredElement ~= "root") then
                if (playerState.attachedObjectId) then
                    playerStore:dispatch({
                        type = "DESTROY_OBJECT"
                    })
                else
                    forgeStore:dispatch({
                        type = "UPWARD_NAV_FORGE_MENU"
                    })
                end
            else
                dprint("Closing Forge menu...")
                menu.close(constants.uiWidgetDefinitions.forgeMenu)
            end
        elseif (forgeMenuPressedButton == 8) then
            forgeStore:dispatch({
                type = "INCREMENT_FORGE_MENU_PAGE"
            })
        elseif (forgeMenuPressedButton == 7) then
            forgeStore:dispatch({
                type = "DECREMENT_FORGE_MENU_PAGE"
            })
        else
            local desiredElement = blam35.unicodeStringList(
                                       get_tag(tagClasses.unicodeStringList,
                                               constants.unicodeStrings.forgeList)).stringList[forgeMenuPressedButton]
            local sceneryPath = forgeState.forgeMenu.objectsDatabase[desiredElement]
            if (sceneryPath) then
                dprint(" -> [ Forge Menu ]")
                playerStore:dispatch({
                    type = "CREATE_AND_ATTACH_OBJECT",
                    payload = {path = sceneryPath}
                })
            else
                forgeStore:dispatch({
                    type = "DOWNWARD_NAV_FORGE_MENU",
                    payload = {
                        desiredElement = desiredElement
                    }
                })
            end
        end
        dprint(" -> [ Forge Menu ]")
        dprint("Button " .. forgeMenuPressedButton .. " was pressed!", "category")
    end

    -- Trigger prefix and how many triggers are being read
    local voteMapMenuPressedButton = triggers.get("map_vote_menu", 5)
    if (voteMapMenuPressedButton) then
        local voteMapRequest = {
            requestType = constants.requests.sendMapVote.requestType,
            mapVoted = voteMapMenuPressedButton
        }
        core.sendRequest(core.createRequest(voteMapRequest))
        dprint("Vote Map menu:")
        dprint("Button " .. voteMapMenuPressedButton .. " was pressed!", "category")
    end

    -- Attach respective hooks for menus
    hook.attach("maps_menu", menu.stop, constants.uiWidgetDefinitions.mapsList)
    hook.attach("forge_menu", menu.stop, constants.uiWidgetDefinitions.objectsList)
    hook.attach("forge_menu_close", menu.stop, constants.uiWidgetDefinitions.forgeMenu)
    hook.attach("loading_menu_close", menu.stop, constants.uiWidgetDefinitions.loadingMenu)

    textRefreshCount = textRefreshCount + 1
    -- We need to draw new text this time
    if (textRefreshCount > 30) then
        textRefreshCount = 0
        drawTextBuffer = nil
    end
end

-- This is not a mistake... right?
function forgeAnimation()
    -- // TODO: Update this logic, it is awful!
    if (not lastImage) then
        lastImage = 0
    else
        if (lastImage == 0) then
            lastImage = 1
        else
            lastImage = 0
        end
    end
    -- // TODO: Split this in a better way, it looks horrible!
    -- Animate forge logo
    blam35.uiWidgetDefinition(get_tag("ui_widget_definition",
                                      constants.uiWidgetDefinitions.loadingAnimation), {
        backgroundBitmap = get_tag_id("bitm", constants.bitmaps["forgeLoadingProgress" ..
                                          tostring(lastImage)])
    })
    return true
end

function OnRcon(message)
    local request = string.gsub(message, "'", "")
    local splitData = glue.string.split(request, "|")
    local incomingRequest = splitData[1]
    local actionType
    local currentRequest
    for requestName, request in pairs(constants.requests) do
        if (incomingRequest and incomingRequest == request.requestType) then
            currentRequest = request
            actionType = request.actionType
        end
    end
    if (actionType) then
        return core.processRequest(actionType, request, currentRequest)
    end
    return true
end

function onCommand(command)
    return commands(command)
end

function OnMapUnload()
    -- Flush all the forge objects
    core.flushForge()

    -- Save configuration
    glue.writefile(configurationFolder .. "\\forge_island.json", json.encode(configuration))
end

-- Prepare event callbacks
set_callback("map load", "OnMapLoad")
set_callback("unload", "OnMapUnload")