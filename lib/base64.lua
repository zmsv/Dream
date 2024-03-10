-- 本库是筑梦师(2967713804)为Dream提供的base64支持
-- 将持续更新

local base64 = {}

base64.chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

--[[
utf-8编码规则
单字节 - 0起头
   1字节  0xxxxxxx   0 - 127
多字节 - 第一个字节n个1加1个0起头
   2 字节 110xxxxx   192 - 223
   3 字节 1110xxxx   224 - 239
   4 字节 11110xxx   240 - 247
可能有1-4个字节
--]]
function base64.GetBytes(char)
   if not char then
      return 0
   end
   local code = string.byte(char)
   if code < 127 then
      return 1
   elseif code <= 223 then
      return 2
   elseif code <= 239 then
      return 3
   elseif code <= 247 then
      return 4
   else
      -- 讲道理不会走到这里^_^
      return 0
   end
end

local function StrTenToTwo_Int(str,eigtht_bool)
  local back = tonumber(str)
  local num
  local num_str
  local b
  local txt = ""
  local i
  while true do
    num = back / 2
    num_str = dream.tostring(num)
    i = tonumber(num_str:match("(.+)[.].+")) or num
    if i < 1 then
      b = true
    else
      b = false
    end
    if num_str:match(".+[.](.+)") == nil then
      txt = txt.."0"
    else
      txt = txt.."1"
    end
    back = tonumber(num_str:match("(.+)[.].+")) or num
    if b then
      break
    end
  end
  txt = string.reverse(txt)
  if eigtht_bool == nil then
    eigtht_bool = true
  end
  if eigtht_bool then
    if #txt < 8 then
      while #txt < 8 do
        txt = "0"..txt
      end
    end
  else
    if #txt < 6 then
      while #txt < 6 do
        txt = "0"..txt
      end
    end
  end
  return txt
end

local function StrTenToTwo_Float(str)
  local back = tonumber(str)
  local num
  local num_str
  local b
  local txt = ""
  local i
  while true do
    num = tonumber(back) * 2
    num_str = dream.tostring(num)
    i = tonumber(num_str:match(".+[.](.+)"))
    if i == nil then
      b = true
    else
      b = false
    end
    i = num_str:match("(.+)[.].+")
    if not i then
      txt = txt.."1"
    else
      txt = txt.."0"
    end
    if b then
      break
    end
    back = "0."..num_str:match(".+[.](.+)")
  end
  return txt
end

-- 十进制转二进制
function base64.StrTenToTwo(str,eigtht_bool)
  if eigtht_bool == nil then
    eigtht_bool = true
  else
    eigtht_bool = false
  end
  local i = dream.tostring(str)
  local num_float
  local num_int -- 赋值前列出所有局部变量是个好习惯
  num_float = string.match(i,".+[.](.+)")
  num_int = string.match(i,"(.+)[.].+")
  if num_float == nil then -- 有先判断是否为浮点数
    return StrTenToTwo_Int(i,eigtht_bool)
  else
    num_float = "0."..num_float
    if num_int == nil then
      return "0."..StrTenToTwo_Float(num_float)
    else
      return StrTenToTwo_Int(num_int,eigtht_bool).."."..StrTenToTwo_Float(num_float)
    end
  end
end

function base64.StrTwoToTen(str)
  local str = dream.tostring(str)
  local v = #str
  local num = 0
  local n = -1
  for i=v,1,-1 do
    n = n + 1
    num = num + tonumber(str:sub(i,i)) * (2^n)
  end
  return num
end

local function getBase64Chars()
  local i = #base64.chars
  local tab = {}
  for v=1,i do
    tab[v] = base64.chars:sub(v,v)
  end
  return tab
end

function base64.encode(str)
  local tab = {}
  local txt = ""
  local char = getBase64Chars()
  local StrTwo = {}
  local x = function(t)
    t = t:byte()
    t = base64.StrTenToTwo(t)
    return t
  end
  str = str:gsub(".",x).."0000" -- 扩充表的手段
  i = 1
  n = 1
  repeat
    tab[n] = str:sub(i,i+5)
    i = i + 6
    n = n + 1
  until(str:sub(i,i+5) == "")
  n = 0
  for i=1,4 do
    if tab[i] == nil then
      tab[i] = "="
    elseif #tab[i] < 6 then
      while #tab[i] < 6 do
        tab[i] = tab[i].."0"
      end
    end
  end
  for i=1,#tab do
    if tab[i] ~= "=" then
      tab[i] = base64.StrTwoToTen(tab[i]+1)
      tab[i] = char[tab[i]]
    end
  end
  txt = ""
  for i=1,#tab do
    txt = txt..tab[i]
  end
  return txt
end

function base64.decode(str)
  local char = getBase64Chars()
  local txt = ""
  local tab = {}
  local n = 0
  local x = function(t)
    local v
    if t == "=" then
      return ""
    end
    for i=1,#char do
      if char[i] == t then
        v = base64.StrTenToTwo(i-1,false)
        return v
      end
    end
    return 0
  end
  str = str:gsub(".",x)
  i = 1
  n = 1
  repeat
    tab[n] = base64.StrTwoToTen(str:sub(i,i+7))
    i = i + 8
    n = n + 1
  until(str:sub(i,i+7) == "")
  for i=1,#tab do
    txt = txt..string.char(tab[i])
  end
  return txt
end

return base64
