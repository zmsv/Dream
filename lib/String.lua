local String = {}

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

function String.GetBytes(char)
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

function String.sub(str,BeginIndex, EndIndex)
  BeginIndex = BeginIndex or 1
  EndIndex = EndIndex or -1
  if BeginIndex < 1 then
    BeginIndex = 1
  elseif BeginIndex > #str then
    return ""
  elseif EndIndex < -1 then
    EndIndex = -1
  end
  local x = function(str)
    return String.GetBytes(str)
  end
  local str_backup = str
  local str = str:gsub(".",x)
  local txt = ""
  repeat
    local i = 1
    txt = txt..str:sub(i,i)
    if str:sub(i,i) == "1" then
      str = str:sub(i+1,-1)
    elseif str:sub(i,i) == "2" then
      str = str:sub(i+2,-1)
    elseif str:sub(i,i) == "3" then
      str = str:sub(i+3,-1)
    elseif str:sub(i,i) == "4" then
      str = str:sub(i+4,-1)
    end
  until(str:sub(i,i) == "")
  str = txt
  local tab = {}
  local v = 1
  for i=1,#str do
    tab[i] = str_backup:sub(v,v+str:sub(i,i)-1)
    str_backup = str_backup:sub(v+str:sub(i,i))
  end
  if EndIndex == -1 then
    EndIndex = #str
  elseif EndIndex > #str then
    return ""
  end
  txt = ""
  for i=BeginIndex,EndIndex do
    txt = txt..tab[i]
  end
  return txt
end

function String.rep(str,rep)
  str = str:gsub("\n","\\n"):gsub(rep,"\n")
  local i = 1
  local tab = {}
  repeat
    tab[i] = tab[i] or ""
    if String.sub(str,1,1) == "\n" then
      i = i + 1
    else
      tab[i] = tab[i]..String.sub(str,1,1)
    end
    str = String.sub(str,2,-1)
  until(#str == 0)
  for k,v in pairs(tab) do
    if v == "" then
      tab[k] = nil
    end
  end
  return tab
end

return String
