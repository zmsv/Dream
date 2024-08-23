local startTime = os.clock() -- 在32位操作系统有溢出风险
local endTime
dream.api = {}
dream.event = {}
dream.orderLoader = {}
dream.nick = ZhaoDiceSDK.readSystemConfig("DICE_NAME") -- 你的骰娘名称
dream.masterNick = "管理员"
dream.stranger = "无名氏" -- 获取昵称失败时对用户的称呼【调用dream.api.getUserNick时使用】
dream._VERSION = "ver4.9.1(201)"
dream.version = "Dream by 筑梦师V2.0&乐某人 "..dream._VERSION.."[2024-08-23 10:43:01] for AstralDice" -- 别改，这是版本号和出处，起码给开发者一点尊重

-- dream基本库 --
function rawload(str,mode,env)
  mode = mode or "bt"
  env = env or table.clone(_G)
  env["dream"] = dream
  dream.file.write(dream.setting.path.."/data/rawload.lua",str)
  local a,b = loadfile(dream.setting.path.."/data/rawload.lua",mode,env)
  --local i = "loadfile(\""..dream.setting.path.."/data/rawload.lua\")"
  if not a then
    return false,b
  end
  local a,b = pcall(a)
  if not a then
    return false,b
  end
  return true,b
end

function dream.log(str,event)
  local event = event or "Dream"
  local i
  if type(str) ~= "string" or type(str) ~= "number" then
    i = tostring(str)
  else
    i = str
  end
  print("["..event.."]"..str)
end

function dream.tonumber(str,n)
  local num = nil
  if type(str) == "string" then
    if dream.math.isNumber(str) then
      num = str + 1
      num = num - 1
    end
  elseif type(str) == "number" then
    num = str
  else
    return nil
  end
  if type(n) == "number" then
    num = dream.math.num2toHex(num,n)
    if n == 2 then
      return bit32.tobit(num)
    else
      return num
    end
  else
    return num
  end
end

tonumber = dream.tonumber

function dream.tostring(msg)
  local msg = msg
  if type(msg) == "nil" then
    return "nil"
  elseif type(msg) == "string" then
    return msg
  elseif type(msg) == "number" then
    return ""..msg
  elseif type(msg) == "boolean" then
    if msg then
      return "true"
    else
      return "false"
    end
  elseif type(msg) == "table" then
    if getmetatable(msg) then
      local metatable = getmetatable(msg)
      if metatable.__tostring then
        return metatable.__tostring(msg)
      else
        return dream.TableToString(msg)
      end
    else
      return dream.TableToString(msg)
    end
  elseif dream.search(msg) then
    local i = dream.search(msg)
    local tab = {}
    i = i:gsub(".",function(x)
      tab[#tab+1] = x:byte()
    end)
    i = 0
    for x=1,#tab do
      i = i + tonumber(tab[x])
    end
    i = dream.math.num2toHex(i,16)
    return type(msg)..":0x"..i:lower()
  else -- local value
    return "local:"..type(msg)
  end
end
tostring = dream.tostring

function dream.toboolean(str)
  if str == "true" then
    return true
  elseif str == "false" then
    return false
  else
    return nil
  end
end

function dream.require(name)
  local path = dream.setting.path.."/lib/"..name
  local res,info = loadfile(path)
  if res then
    res,info = pcall(res)
    if res then
      return info
    end
    info = dream.error(info,false)
    dream.sendError("运行库["..path.."]时发生意外错误！错误信息：\n"..info)
  else
    info = dream.error(info,false)
    dream.sendError("运行库["..path.."]时发生意外错误！错误信息：\n"..info)
  end
end

function dream.error(errorInfo,b) -- 捕获错误信息并打印至控制台
  if b == nil then
    b = true
  elseif type(b) ~= "boolean" then
    b = true
  elseif errorInfo == nil then
    errorInfo = ""
  end
  local line = string.match(errorInfo,":([1-9]+):.+$")
  local a
  if line == nil then
    a = errorInfo
  else
    local x = string.match(errorInfo,":"..line..":(.+)$") or string.match(errorInfo,":"..line.." (.+)$")
    if x:sub(1,1) == " " then
      x = x:sub(2,-1)
    end
    a = "line:"..line.." "..x
  end
  local str
  if line then
    str = errorInfo:match("^@"..dream.setting.path.."/(.+):"..line)
  end
  if str then
    a = dream.setting.path.."/"..str.."\n"..a
  end
  if not b then
    return a
  else
    print("[error]\n"..os.date("%Y-%m-%d %H:%M").."\n"..a)
  end
end

function dream.sendError(str)
  dream.sendMaster("[error]\n"..os.date("%Y-%m-%d %H:%M").."\n"..str)
end

function dream.list(type_,tab,vis)
  local tab = tab or _G
  local vis = vis or {[_G] = true}
  if type_ == nil then
    return nil
  end
  local list = setmetatable({},{__add = function(oldtable,newtable)
    for k,v in pairs(newtable) do
      oldtable[k] = v
    end
    return oldtable
  end})
  for k,v in pairs(tab) do
    if type(v) == type_ then
      list[dream.search(v)] = v
    elseif type(v) == "table" then
      if not vis[v] then
        vis[v] = true
        local newlist = dream.list(type_,v,vis)
        list = list + newlist
      end
    end
  end
  return list
end

function dream.search(value,tab,prefix,vis)
  local tab = tab or _G
  local prefix = prefix or "_G"
  local vis = vis or {[_G] = true}
  if value == nil then
    return nil
  end
  for k,v in pairs(tab) do
    if v == value then
      return prefix.."."..k
    elseif type(v) == "table" then
      if not vis[v] then
        vis[v] = true
        local i = dream.search(value,v,prefix.."."..k,vis)
        if i then
          return i
        end
      end
    end
  end
  return nil
end

function dream.get(k,G)
  local G = G or {}
  if _G[k] then
    return _G[k]
  elseif G[k] then
    return G[k]
  end
  local tab = dream.string.part(k,".")
  local v = _G[tab[1]] or G[tab[1]]
  for i=2,#tab do
    v = v[tab[i]]
  end
  return v
end

function dream.TableToString(tab,l,vis)
  if type(tab) ~= "table" then
    error("non-table type")
  end
  local i
  if l then
    i = l.."  "
  else
    i = "  "
  end
  local vis = vis or {}
  local str = "{"
  for k,v in pairs(tab) do
    local j
    if type(k) == "function" then
      j = "function"
    else
      j = dream.json.encode(k)
    end
    if type(v) == "table" then
      if vis[v] then
        error("circular references")
      else
        vis[v] = true
      end
      str = str.."\n"..i.."["..j.."]"..i:sub(1,#i/2).."->"..i:sub(1,#i/2)..dream.TableToString(v,i,vis)
    else
      if type(v) == "function" then
        r = "function"
      else
        r = dream.json.encode(v)
      end
      str = str.."\n"..i.."["..j.."]"..i:sub(1,#i/2).."->"..i:sub(1,#i/2)..r
    end
  end
  if str ~= "{" then
    return str.."\n"..i:sub(1,#i-2).."}"
  else
    return "{}"
  end
end

function dream.escape(tab,source)
  for k,v in pairs(tab) do
    source = source:gsub("{"..k.."}",v)
  end
  return source
end

function pairs(tab)
  return next,tab,nil
end

local rawloadfile = loadfile
function loadfile(fileName,mode,env)
  local mode = mode or "bt"
  local env = env or _ENV
  local a,b = rawloadfile(fileName,mode,env)
  if b then
    b = b:gsub("^.+:([0-9]+):(.+)$",function(x,y)
      return "@"..fileName..":"..x..":"..y
    end)
    b = b:gsub("^.+:([0-9]+) (.+)$",function(x,y)
      return "@"..fileName..":"..x..":"..y
    end)
  end
  return a,b
end

local rawpcall = pcall
function pcall(func,...)
  local a,b = rawpcall(func,...)
  if not a then
    b = b:gsub("^@(.+):([0-9]+) (.+)$",function(s,x,y)
      return "@"..s..":"..x..":"..y
    end)
  end
  return a,b
end

-- 优化原生库
local char = string.char
function string.char(x)
  x = dream.math.pos(x) or -1
  if x < 0 or x > 256 then
    return nil
  end
  return char(x)
end

function math.log10(n)
  if type(n) ~= "number" then
    return nil
  end
  local i = 2
  while true do
    if 10 ^ i > n then
      return nil
    elseif 10 ^ i == n then
      return i
    end
    i = i + 1
  end
end

local httpGet = ZhaoDiceSDK.network.httpGet
function ZhaoDiceSDK.network.httpGet(url)
  if httpGet(url) == "" then
    return nil
  else
    return httpGet(url)
  end
end
sdk = ZhaoDiceSDK

local rawostime = os.time
function os.time()
  return tonumber(string.format("%u",rawostime()))
end

function dream.execute(cmd)
  local f = io.open(dream.setting.path.."/sh.sh","w")
  f:write(cmd)
  f:close()
  local f = io.popen("sh "..dream.setting.path.."/sh.sh","rb")
  local txt = f:read("*a")
  return txt
end

function dream.unzip(dir,d)
  return dream.execute("unzip "..dir.." -d "..d)
end

-- table新增库
function table.type(tab)
  if type(tab) ~= "table" then
    return nil
  end
  local dataType
  for k,v in pairs(tab) do
    dataType = dataType or type(k)
    if dataType ~= type(k) then
      return nil
    end
  end
  if dataType == "number" then
    return "array"
  else
    return "object"
  end
end

function table.add(tab,tbl)
  if table.type(tab) == "array" and table.type(tbl) == "array" then
    for i=#tab+1,#tbl+#tab do
      local v = nil
      if type(tbl[i-#tab]) == "table" then
        v = table.clone(tbl[i-#tab])
      else
        v = tbl[i-#tab]
      end
      tab[i] = v
    end
    return tab
  end
  for k,v in pairs(tbl) do
    if not tab[k] then
      if type(v) == "table" then
        tab[k] = table.clone(v)
      else
        tab[k] = v
      end
    elseif type(tab[k]) ~= "table" or type(v) ~= "table" then
      if type(v) == "table" then
        tab[k] = table.clone(v)
      else
        tab[k] = v
      end
    elseif table.type(tab[k]) == "array" and table.type(v) == "array" then
      for x,y in pairs(v) do
        if type(y) ~= "table" then
          tab[k][#tab[k]+1] = y
        else
          tab[k][#tab[k]+1] = table.clone(y)
        end
      end
    elseif table.type(tab[k]) == "object" and table.type(v) == "object" then
      tab[k] = table.add(tab[k],v)
    else
      tab[k] = table.clone(v)
    end
  end
  return tab
end

function table.random(tab)
  local i = math.random(1,table.getNumber(tab))
  local l = 1
  for k,v in pairs(tab) do
    if i == l then
      return {k,v}
    end
    l = l + 1
  end
end

function table.getNumber(tab)
  local i = 0
  for k,v in pairs(tab) do
    i = i + 1
  end
  return i
end

function table.gsub(tab,index,s)
  for k,v in pairs(tab) do
    v = v:gsub(index,s)
    tab[k] = v
  end
  return tab
end

function table.orderly(tab)
  local tbl = {}
  local i = 0
  for k,v in pairs(tab) do
    if k > i then
      i = k
    end
  end
  for ind=1,i do
    if tab[ind] ~= nil then
      table.insert(tbl,tab[ind])
    end
  end
  return tbl
end

function table.sort(tab,id)
  tab = table.orderly(tab)
  local tbl = {}
  for i=1,#tab do
    if not tbl[1] then
      table.insert(tbl,tab[i])
    else
      local ind
      for l=1,#tbl do
        if id == nil then
          if tbl[l] >= tab[i] then
            ind = l
          end
        else
          if tbl[l][id] >= tab[i][id] then
            ind = l
          end
        end
      end
      ind = ind or 0
      table.insert(tbl,ind+1,tab[i])
    end
  end
  return tbl
end

function table.clone(tab,vis)
  local vis = vis or {}
  if vis[tab] then
    return vis[tab]
  end
  local clone = {}
  vis[tab] = clone
  for k,v in pairs(tab) do
    if type(v) == "table" then
      clone[k] = table.clone(v,vis)
    else
      clone[k] = v
    end
  end
  return clone
end

local tab_num = function(tab)
  local i = 0
  for k,v in pairs(tab) do
    i = i + 1
  end
  return i
end

function table.equal(tab,tbl,vis)
  local vis = vis or {}
  local tab = table.clone(tab)
  local tbl = table.clone(tbl)
  if (type(tab) ~= "table") or (type(tbl) ~= "table") then
    return false
  elseif tab == tbl then
    return true -- 地址相等
  elseif vis[tab] or vis[tbl] then
    return true
  end
  if tab_num(tab) < tab_num(tbl) then
    local rawtab,rawtbl = table.clone(tab),table.clone(tbl)
    tab = table.clone(rawtbl)
    tbl = table.clone(rawtab)
  end
  vis[tab] = true
  vis[tbl] = true
  for k,v in pairs(tab) do
    if (type(tab[k]) == "table") and (type(tbl[k]) == "table") then
      if not table.equal(tab[k],tbl[k],vis) then
        return false
      end
    elseif tab[k] ~= tbl[k] then
      return false
    end
  end
  return true
end

function table.unTab(tab,i)
  if tab[i] then
    return tab[i],table.unTab(tab,i+1)
  end
  return nil
end

function unpack(tab,i,j)
  local tab = table.orderly(tab)
  local i = i or 1
  local j = j or #tab
  if i < 1 or j < 1 or i > #tab then
    return nil
  elseif j > #tab then
    j = #tab
  end
  local tbl = {}
  local ind = 1
  for i=i,j do
    tbl[ind] = tab[i]
    ind = ind + 1
  end
  return table.unTab(tbl,1)
end

function pack(...)
  local tbl = {...}
  return tbl
end

-- dream math
dream.math = {}

function dream.math.num2toHex(num,hex)
  if type(num) ~= "number" then
    return nil
  elseif type(hex) ~= "number" then
    return nil
  elseif (hex < 2) or (hex > 16) then
    return nil
  end
  local i = math.floor(num / hex)
  local x = num % hex
  local v = {}
  v[1] = x
  while i >= hex do
    x = i % hex
    v[#v + 1] = x
    i = math.floor(i / hex)
  end
  v[#v + 1] = i
  local hexMap = {0,1,2,3,4,5,6,7,8,9,'A','B',"C",'D','E','F'}
  local txt = ""
  for _,k in ipairs(v) do
    txt = hexMap[k + 1]..txt
  end
  return txt
end

function dream.math.hextoNum2(str,hex)
  if type(hex) ~= "number" then
    return nil
  elseif (hex < 2) or (hex > 16) then
    return nil
  elseif type(str) ~= "string" then
    return nil
  elseif hex > 10 then
    str = string.upper(str)
  end
  local x = function(num)
    local map = {}
    local hexMap = {0,1,2,3,4,5,6,7,8,9,'A','B',"C",'D','E','F'}
    for k,v in pairs(hexMap) do
      map[dream.tostring(v)] = k - 1
    end
    return map[num]
  end
  local n = 0
  local k = 0
  for i=#str,1,-1 do
    local num = x(str:sub(i,i))
    n = n + num*hex^k
    k = k + 1
  end
  return n
end

function dream.math.isNumber(str)
  if type(str) == "number" then
    return true
  elseif type(str) ~= "string" then
    return false
  elseif str:sub(1,1) == "-" then
    str = str:sub(2,-1)
  end
  local str = dream.tostring(str)
  if #str < 1 then
    return false
  elseif dream.math.isFloat(str) then
    return true
  elseif dream.math.isInt(str) then
    return true
  else
    return false
  end
end

function dream.math.isFloat(num)
  local i = load("return [["..num.."]] % 1")
  i,v = pcall(i)
  if not i then
    return false
  elseif v ~= 0 then
    return true
  end
  return false
end

function dream.math.isInt(num)
  local i = load("return [["..num.."]] % 1")
  i,v = pcall(i)
  if not i then
    return false
  elseif v == 0 then
    return true
  end
  return false
end

function dream.math.getFloat(num)
  if not dream.math.isNumber(num) then
    return nil
  elseif not dream.math.isFloat(num) then
    return 0
  else
    return num % 1
  end
end

function dream.math.getInt(num)
  if not dream.math.isNumber(num) then
    return nil
  else
    return num - (num % 1)
  end
end

function dream.math.topercent(n,x)
  if type(n) ~= "number" then
    return nil
  elseif x < n then
    return nil
  end
  n = n/x * 100
  return dream.math.getInt(n).."%"
end

function dream.math.pos(x)
  if dream.math.isNumber(x) then
    x = tostring(x)
    if x:sub(1,1) == "-" then
      return tonumber(x:sub(2,-1))
    else
      return tonumber(x)
    end
  end
end

math.random = sdk.randomInt

-- dream http支持
dream.http = {}

function dream.http.urlencode(url)
  local function x(s)
      return "%%"..string.format("%02X",string.byte(s))
  end
  local tab = {}
  local i = 1
  while i < #url do
    local l = url:sub(i,i)
    l = dream.tostring(l)
    if l:byte() >= 228 and l:byte() <= 233 then
      for n=i+1,i+2 do
        local s = dream.tostring(url:sub(n,n))
        if s:byte() >=128 and s:byte() <= 191 then
           tab[#tab+1] = url:sub(i,i+2)
           i = i + 3
        end
      end
    else
      i = i + 1
    end
  end
  for i=1,#tab do
    for l=1,#tab[i] do
      url = url:gsub(tab[i]:sub(l,l),x(tab[i]:sub(l,l)))
    end
  end
  return url:gsub(" ","+")
end

function dream.http.urldecode(url)
  url = url:gsub("+"," ")
  url = url:gsub("%%%x%x",function(x)
    x = x:sub(2,-1)
    return string.char(dream.math.hextoNum2(x,16))
  end)
  return url
end

function dream.http.get(url)
  if type(url) ~= "string" then
    return nil
  end
  url = dream.http.urlencode(url)
  return dream.execute("curl -L -X GET --compressed \""..url.."\"") or sdk.network.httpGet(url)
end

function dream.http.post(url,data)
  if not url then
    return nil
  elseif not data then
    return nil
  end
  url = dream.http.urlencode(url)
  return dream.execute("curl -L -H Content-Type: application/json -X POST -d '"..data.."' "..url) or ZhaoDiceSDK.network.httpPost(url,data)
end

function dream.http.getFile(url,dir)
  if type(url) ~= "string" then
    return nil
  end
  url = dream.http.urlencode(url)
  return dream.execute("curl -o "..dir.." \""..url.."\"")
end

-- dream json解析/编码库
dream.json = {}

function dream.json.encode(tab,vis)
  local vis = vis or {}
  local dataType = type(tab)
  if dataType == "nil" then
    return "null"
  elseif dataType == "string" then
    local str = tab
    str = str:gsub("\\","\\\\")
    local escape_char_map = {
      [ "\"" ] = "\\\"",
      [ "\b" ] = "\\b",
      [ "\f" ] = "\\f",
      [ "\n" ] = "\\n",
      [ "\r" ] = "\\r",
      [ "\t" ] = "\\t",
      [ "/"] = "\\/"
    }
    for k,v in pairs(escape_char_map) do
      str = str:gsub(k,v)
    end
    return "\""..str.."\""
  elseif dataType == "number" then
    return tab
  elseif dataType == "boolean" then
    local bool = tab
    if bool then
      return "true"
    else
      return "false"
    end
  elseif dataType == "table" then
    if vis[tab] then
      error("circular references")
    else
      vis[tab] = true
    end
    dataType = nil
    local isArray,isObject
    for k,v in pairs(tab) do
      if dataType then
        if dataType ~= type(k) then
          error("wrong key")
        end
      else
        if type(k) ~= "string" then
          if type(k) ~= "number" then
            error("wrong key")
          end
        end
        dataType = type(k)
      end
    end
    if dataType == "number" then
      isArray = true
    else
      isObject = true
    end
    local JsonStr
    if isArray then
      for k,v in pairs(tab) do
        local v = dream.json.encode(v,vis)
        if JsonStr then
          JsonStr = JsonStr..","..v
        else
          JsonStr = v
        end
      end
      return "["..JsonStr.."]"
    elseif isObject then
      for k,v in pairs(tab) do
        local k = dream.json.encode(k,vis)
        local v = dream.json.encode(v,vis)
        if JsonStr then
          JsonStr = JsonStr..","..k..":"..v
        else
          JsonStr = k..":"..v
        end
      end
      if JsonStr then
        return "{"..JsonStr.."}"
      else
        return "{}"
      end
    end
  else
    error("Try converting the "..type(tab).." to a Json string")
  end
end

function dream.json.spree(str,i)
  local b = str:byte(i)
  while str:sub(i,i) == " " or str:sub(i,i) == "\n" or str:sub(i,i) == "\t" or str:sub(i,i) == "\r" do
    i = i + 1
    b = str:byte(i)
  end
  return i,b
end

function dream.json.Error(data,i,err)
  error("解析第"..i.."个字符("..data:sub(i,i)..")时发生致命错误："..err)
end

function dream.json.decode(str,i)
  i = i or 1
  i,b = dream.json.spree(str,i)
  if b == nil then
    dream.json.Error(str,i,"空对象")
  end
  if b == string.byte("{") then
    local tbl = {}
    local j = i + 1
    local i,b = dream.json.spree(str,j)
    if b == string.byte("}") then
      return tbl,i+1
    end
    while true do
      if b == nil then
        dream.json.Error(str,j,"未闭合的对象")
      end
      local k,ind = dream.json.decode(str,j)
      local i,b = dream.json.spree(str,ind)
      if b == string.byte(":") then
        j = i + 1
      elseif k == nil then
        while true do
          if k then
            break
          elseif i > #str then
            dream.json.Error(str,i,"未闭合的对象")
          end
          local o,p = dream.json.spree(str,i)
          if p == string.byte("}") then
            return tbl,o+1
          end
          k,i = dream.json.decode(str,i)
        end
        j = i + 1
      else
        dream.json.Error(str,j,"对象结构错误")
      end
      local v,ind = dream.json.decode(str,j)
      local i,b = dream.json.spree(str,ind)
      tbl[k] = v
      if b == string.byte(",") then
        j = i + 1
      elseif b == string.byte("}") then
        j = i
        break
      else
        dream.json.Error(str,i,"对象结构错误")
      end
    end
    return tbl,j+1
  elseif b == string.byte("[") then
    local arr = {}
    local j = i + 1
    local i,b = dream.json.spree(str,j)
    if b == string.byte("]") then
      return arr,i+1
    end
    while true do
      if b == nil then
        dream.json.Error(str,j,"未闭合的数组")
      end
      local v,ind = dream.json.decode(str,j)
      local i,b = dream.json.spree(str,ind)
      table.insert(arr,v)
      if b == string.byte(",") then
        j = i + 1
      elseif b == string.byte("]") then
        j = i
        break
      elseif v == nil then
        j = i
      else
        dream.json.Error(str,i,"数组结构错误")
      end
    end
    return arr,j+1
  elseif b == string.byte("\"") then
    local j = i
    repeat
      if b == nil then
        dream.json.Error(str,j,"未闭合的字符串")
      elseif b == string.byte("\\") then
        j = j + 2
      else
        j = j + 1
      end
      j,b = dream.json.spree(str,j)
    until b == string.byte("\"")
    local data = str:sub(i+1,j-1)
    local escape_char_map = {
      [ "\"" ] = "\\\"",
      [ "\b" ] = "\\b",
      [ "\f" ] = "\\f",
      [ "\n" ] = "\\n",
      [ "\r" ] = "\\r",
      [ "\t" ] = "\\t",
      [ "/"] = "\\/"
    }
    data = data:gsub("\\\\","\\")
    for k,v in pairs(escape_char_map) do
      data = data:gsub(v,k)
    end
    return data,j+1
  elseif b == 45 or (b >= 48 and b <= 57) then
    local j,b = dream.json.spree(str,i+1)
    if not dream.math.isNumber(str:sub(j,j)) and str:sub(j,j) ~= "." then
      return tonumber(str:sub(i,i)),i+1
    end
    local have = false
    repeat
      if b == nil then
        dream.json.Error(str,j,"json结构错误")
      end
      j = j + 1
      if str:sub(j,j) == "." and have == false then
        j = j + 1
        have = true
      end
    until not dream.math.isNumber(str:sub(j,j))
    local data = str:sub(i,j-1)
    return tonumber(data),j
  elseif str:sub(i,i+3) == "null" then
    return nil,i+4
  elseif str:sub(i,i+3) == "true" then
    return true,i+4
  elseif str:sub(i,i+4) == "false" then
    return false,i+5
  elseif b == string.byte("/") and str:byte(i+1) == string.byte("/") then
    local j = i + 2
    while true do
      if str:byte(j) == string.byte("\n") then
        break
      elseif j > #str then
        dream.json.Error(str,i,"未结束的注释")
      end
      j = j + 1
    end
    return nil,j
  else
    dream.json.Error(str,i,"不识别的Json："..string.char(b))
  end
end
json = dream.json

-- dream toml解析/编码
dream.toml = {}

function dream.toml.En_JSON_like(tab,vis)
  local dataType = type(tab)
  vis = vis or {}
  if dataType == "string" then
    tab = tab:gsub("\\","\\\\")
    local escape_char_map = {
      [ "\"" ] = "\\\"",
      [ "\b" ] = "\\b",
      [ "\f" ] = "\\f",
      [ "\n" ] = "\\n",
      [ "\r" ] = "\\r",
      [ "\t" ] = "\\t"
    }
    for k,v in pairs(escape_char_map) do
      tab = tab:gsub(k,v)
    end
    return "\""..tab.."\""
  elseif dataType == "number" then
    return tab
  elseif dataType == "boolean" then
    return tostring(tab)
  elseif dataType == "table" then
    if vis[tab] then
      error("circular references")
    else
      vis[tab] = true
    end
    if table.type(tab) == "array" then
      local str = "["
      for i=1,#tab do
        str = str..dream.toml.En_JSON_like(tab[i],vis)..","
      end
      return str:sub(1,#str-1).."]"
    elseif table.type(tab) == "object" then
      if table.equal(tab,{}) then
        return "{}"
      end
      local str = "{"
      for k,v in pairs(tab) do
        str = str..k.."="..dream.toml.En_JSON_like(v,vis)..","
      end
      return str:sub(1,#str-1).."}"
    else
      error("mixed tables")
    end
  end
end

function dream.toml.encode(tab,vis,table_name)
  vis = vis or {}
  local dataType = type(tab)
  if dataType == "boolean" then
    return tostring(tab)
  elseif dataType == "number" then
    return tab
  elseif dataType == "string" then
    return '"""'..tab..'"""'
  elseif dataType == "table" then
    if vis[tab] then
      error("circular references")
    else
      vis[tab] = true
    end
    if table.equal(tab,{}) then
      return "{}"
    elseif table.type(tab) == nil then
      error("mixed tables")
    end
    local str = ""
    for k,v in pairs(tab) do
      if type(v) ~= "table" then
        str = str..k.." = "..dream.toml.encode(v,vis).."\n"
      elseif table.type(v) == "object" then
        if table_name then
          str = str.."["..table_name.."."..k.."]\n"
        else
          str = str.."["..k.."]\n"
        end
        for x,y in pairs(v) do
          local dataType = table.type(y)
          if table.type(y) == "array" then
            y = dream.toml.En_JSON_like(y)
          elseif dataType == nil then
            if type(y) ~= "table" then
              y = dream.toml.encode(y,vis)
            else
              y = dream.toml.En_JSON_like(y)
            end
          else
            y = {[x] = y}
            if not table_name then
              y = dream.toml.encode(y,vis,k)
            else
              y = dream.toml.encode(y,vis,table_name.."."..k)
            end
          end
          if dataType == "object" then
            str = str..y.."\n"
          else
            str = str..x.." = "..y.."\n"
          end
        end
        str = str.."\n"
      elseif table.type(v) == "array" then
        for i=1,#v do
          if table.type(v[i]) == "array" or table.type(v[i]) == nil then
            str = str..k.." = "..dream.toml.En_JSON_like(v).."\n"
            break
          elseif table.type(v[i]) == "object" then
            if table_name then
              str = str.."[["..table_name.."."..k.."]]\n"
            else
              str = str.."[["..k.."]]\n"
            end
            for x,y in pairs(v[i]) do
              if not table_name then
                str = str..x.." = "..dream.toml.encode(y,vis,k).."\n"
              else
                str = str..x.." = "..dream.toml.encode(y,vis,table_name.."."..k).."\n"
              end
            end
            str = str.."\n"
          end
        end
      end
    end
    while str:sub(-1,-1) == "\n" do
      str = str:sub(1,#str-1)
    end
    return str
  else
    error("Try converting the "..type(tab).." to a Toml string")
  end
end

function dream.toml.spree(str,i,p)
  local b = str:byte(i)
  if not p then
    while str:sub(i,i) == " " or str:sub(i,i) == "\n" or str:sub(i,i) == "\r" or str:sub(i,i) == "\t" do
      i = i + 1
      b = str:byte(i)
    end
  else
    while str:sub(i,i) == " " or str:sub(i,i) == "\r" or str:sub(i,i) == "\t" do
      i = i + 1
      b = str:byte(i)
    end
  end
  return i,b
end

function dream.toml.Error(data,i,err)
  error("解析第"..i.."个字符("..data:sub(i,i)..")时发生致命错误："..err)
end

function dream.toml.JSON_like(str,i)
  i = i or 1
  local i,b = dream.toml.spree(str,i)
  if b == nil then
    dream.toml.Error(str,i,"空对象")
  end
  if b == string.byte("{") then
    local j = i + 1
    local tbl = {}
    j,b = dream.toml.spree(str,j)
    if b == string.byte("}") then
      return tbl,j+1
    end
    while true do
      local k,v
      if b == nil then
        dream.toml.Error(str,j,"未闭合的对象")
      end
      k,j = dream.toml.JSON_like(str,j)
      j,b = dream.toml.spree(str,j)
      if b ~= string.byte("=") then
        dream.toml.Error(str,j,"对象结构错误")
      else
        j = j + 1
      end
      v,j = dream.toml.JSON_like(str,j)
      j,b = dream.toml.spree(str,j)
      tbl[k] = v
      if b == string.byte(",") then
        j = j + 1
      elseif b == string.byte("}") then
        break
      else
        dream.toml.Error(str,j,"对象结构错误")
      end
    end
    return tbl,j+1
  elseif b == string.byte("[") then
    local j = i + 1
    local arr = {}
    j,b = dream.toml.spree(str,j)
    if b == string.byte("]") then
      return arr,j+1
    end
    while true do
      local v
      if b == nil then
        dream.toml.Error(str,j,"未闭合的数组")
      end
      v,j = dream.toml.JSON_like(str,j)
      j,b = dream.toml.spree(str,j)
      table.insert(arr,v)
      if b == string.byte(",") then
        j = j + 1
      elseif b == string.byte("]") then
        break
      else
        dream.toml.Error(str,j,"数组结构错误")
      end
    end
    return arr,j+1
  elseif b == string.byte("\"") then
    local j = i
    repeat
      if b == nil then
        dream.toml.Error(str,j,"未闭合的字符串")
      elseif str:sub(j,j) == "\\" then
        j = j + 2
      else
        j = j + 1
      end
      j,b = dream.toml.spree(str,j)
    until b == string.byte("\"")
    local str = str:sub(i+1,j-1)
    local escape_char_map = {
      [ "\"" ] = "\\\"",
      [ "\b" ] = "\\b",
      [ "\f" ] = "\\f",
      [ "\n" ] = "\\n",
      [ "\r" ] = "\\r",
      [ "\t" ] = "\\t"
    }
    for k,v in pairs(escape_char_map) do
      str = str:gsub(v,k)
    end
    str = str:gsub("\\\\","\\")
    return str,j+1
  elseif b == 45 or (b >= 48 and b <= 57) then
    local j,b = dream.toml.spree(str,i+1)
    if not dream.math.isNumber(str:sub(j,j)) and str:sub(j,j) ~= "." then
      return tonumber(str:sub(i,i)),i+1
    end
    local have = false
    repeat
      if b == nil then
        dream.toml.Error(str,j,"Toml结构错误")
      end
      j = j + 1
      if str:sub(j,j) == "." and have == false then
        j = j + 1
        have = true
      end
    until not dream.math.isNumber(str:sub(j,j))
    local data = str:sub(i,j-1)
    return tonumber(data),j
  elseif str:sub(i,i+3) == "null" then
    return nil,i+4
  elseif str:sub(i,i+3) == "true" then
    return true,i+4
  elseif str:sub(i,i+4) == "false" then
    return true,i+5
  elseif b == string.byte("#") then
    local j = i + 1
    j,b = dream.toml.spree(str,j)
    if b == string.byte("\n") then
      return nil,j+1
    end
    while true do
      if b == nil then
        dream.toml.Error(str,j,"未结束的注释")
      elseif b == string.byte("\n") then
        break
      end
      j = j + 1
      j,b = dream.toml.spree(str,j)
    end
    return nil,j+1
  else
    local j = i
    repeat
      if b == nil then
        dream.toml.Error(str,j,"未闭合的字符串")
      elseif str:sub(j,j) == "\\" then
        j = j + 2
      else
        j = j + 1
      end
      j,b = dream.toml.spree(str,j)
    until b == string.byte("=") or b == string.byte(",") or b == string.byte("]") or b == string.byte("}")
    local str = str:sub(i,j-1)
    return str,j
  end
end

function dream.toml.decode(str,i,p,de)
  p = p or false
  i = i or 1
  de = de or false
  local i,b = dream.toml.spree(str,i)
  if b == string.byte("[") or b == string.byte("{") then
    i = i + 1
    if p then
      local j = i - 1
      while true do
        i,b = dream.toml.spree(str,i,true)
        if b == string.byte("\n") or b == nil or b == string.byte("#") then
          break
        else
          i = i + 1
        end
      end
      local data = str:sub(j,i-1)
      return dream.toml.JSON_like(data),i
    elseif b == string.byte("{") then
      dream.toml.Error(str,i,"不识别的Toml")
    end
    i,b = dream.toml.spree(str,i)
    if b == string.byte("[") then
      local arr = {}
      local key = {}
      i = i + 1
      while true do
        local v
        if b == nil then
          dream.toml.Error(str,i,"非标准的表写法")
        end
        v,i = dream.toml.decode(str,i)
        table.insert(key,v)
        local j,b = dream.toml.spree(str,i)
        if b == string.byte("]") then
          j = j + 1
          j,b = dream.toml.spree(str,j)
          if b == string.byte("]") then
            i = j + 1
            break
          end
        end
      end
      local tab = arr
      for i=1,#key do
        if not tab[key[i]] then
          tab[key[i]] = {}
        end
        tab = tab[key[i]]
      end
      tab[1] = {}
      tab = tab[1]
      i,b = dream.toml.spree(str,i,true)
      if b ~= string.byte("\n") and b ~= nil then
        dream.toml.Error(str,i,"数组结构错误")
      else
        i = i + 1
      end
      i,b = dream.toml.spree(str,i)
      if b == string.byte("[") then
        return arr,i
      end
      while true do
        local k,v
        if b == nil then
          break
        end
        local j = i
        k,i = dream.toml.decode(str,i)
        if type(k) == "table" then
          return arr,j
        end
        i,b = dream.toml.spree(str,i)
        if b ~= string.byte("=") then
          dream.toml.Error(str,i,"对象结构错误")
        else
          i = i + 1
        end
        v,i = dream.toml.decode(str,i,true)
        tab[k] = v
        i,b = dream.toml.spree(str,i,true)
        local _,r = dream.toml.spree(str,i+1,true)
        if (b == string.byte("\n") and r == string.byte("\n")) or r == nil then
          i = _
          break
        else
          i = i + 1
        end
      end
      return arr,i+1
    else
      local obj = {}
      local key = {}
      if b == string.byte("]") then
        return obj,i+1
      end
      while true do
        local k
        if b == nil then
          dream.toml.Error(str,i,"非标准的表写法")
        end
        k,i = dream.toml.decode(str,i)
        table.insert(key,k)
        i,b = dream.toml.spree(str,i)
        if b == string.byte(".") then
          i = i + 1
        elseif b == string.byte("]") then
          i = i + 1
          break
        end
      end
      local tab = obj
      for i=1,#key do
        if not tab[key[i]] then
          tab[key[i]] = {}
        end
        tab = tab[key[i]]
      end
      i,b = dream.toml.spree(str,i,true)
      if b ~= string.byte("\n") and b ~= nil then
        dream.toml.Error(str,i,"表结构错误")
      else
        i = i + 1
      end
      i,b = dream.toml.spree(str,i)
      if b == string.byte("[") then
        return obj,i
      end
      while true do
        local k,v
        if b == nil then
          break
        end
        local j = i
        k,i = dream.toml.decode(str,i)
        if type(k) == "table" then
          return obj,j
        end
        i,b = dream.toml.spree(str,i)
        if b ~= string.byte("=") then
          dream.toml.Error(str,i,"对象结构错误")
        else
          i = i + 1
        end
        v,i = dream.toml.decode(str,i,true)
        tab[k] = v
        i,b = dream.toml.spree(str,i,true)
        local _,r = dream.toml.spree(str,i+1,true)
        if b == string.byte("\n") and r == string.byte("\n") then
          i = _
          break
        else
          i = i + 1
        end
      end
      return obj,i+1
    end
  elseif b == string.byte("\"") and p == true then
    local back = i
    i = i + 1
    local x,y = dream.toml.spree(str,i)
    j = x + 1
    local o,p = dream.toml.spree(str,j)
    if y == p and y == string.byte("\"") then
      i = back
      j = o + 1
      while true do
        j,b = dream.toml.spree(str,j)
        if b == nil then
          dream.toml.Error(str,j,"未结束的字符串")
        end
        local c,b2 = dream.toml.spree(str,j+1)
        local v,b3 = dream.toml.spree(str,c+1)
        if b == b2 and b == b3 and b == string.byte("\"") then
          j = v
          break
        else
          j = j + 1
        end
      end
      return str:sub(i+3,j-3),j+1
    else
      i = back
      j,b = dream.toml.spree(str,i)
      repeat
        if b == nil then
          dream.toml.Error(str,j,"未闭合的字符串")
        elseif b == "\\" then
          j = j + 2
        else
          j = j + 1
        end
        j,b = dream.toml.spree(str,j)
      until b == string.byte("\"")
      local data = str:sub(i+1,j-1)
      local escape_char_map = {
        [ "\"" ] = "\\\"",
        [ "\b" ] = "\\b",
        [ "\f" ] = "\\f",
        [ "\n" ] = "\\n",
        [ "\r" ] = "\\r",
        [ "\t" ] = "\\t"
      }
      for k,v in pairs(escape_char_map) do
        data = data:gsub(v,k)
      end
      data = data:gsub("\\\\","\\")
      return data,j+1
    end
  elseif b == string.byte("\'") and p == true then
    local back = i
    i = i + 1
    local x,y = dream.toml.spree(str,i)
    j = x + 1
    local o,p = dream.toml.spree(str,j)
    if y == p and y == string.byte("\'") then
      i = back
      j = o + 1
      while true do
        j,b = dream.toml.spree(str,j)
        if b == nil then
          dream.toml.Error(str,j,"未结束的字符串")
        end
        local c,b2 = dream.toml.spree(str,j+1)
        local v,b3 = dream.toml.spree(str,c+1)
        if b == b2 and b == b3 and b == string.byte("\'") then
          j = v
          break
        else
          j = j + 1
        end
      end
      return str:sub(i+3,j-3),j+1
    else
      i = back
      j,b = dream.toml.spree(str,i)
      repeat
        if b == nil then
          dream.toml.Error(str,j,"未闭合的字符串")
        elseif b == "\\" then
          j = j + 2
        else
          j = j + 1
        end
        j,b = dream.toml.spree(str,j)
      until b == string.byte("\'")
      local data = str:sub(i+1,j-1)
      return data,j+1
    end
  elseif b == 45 or (b >= 48 and b <= 57) then
    local j,b = dream.toml.spree(str,i+1)
    if not dream.math.isNumber(str:sub(j,j)) and str:sub(j,j) ~= "." then
      return tonumber(str:sub(i,i)),i+1
    end
    local have = false
    repeat
      if b == nil then
        dream.toml.Error(str,j,"Toml结构错误")
      end
      j = j + 1
      if str:sub(j,j) == "." and have == false then
        j = j + 1
        have = true
      end
    until not dream.math.isNumber(str:sub(j,j))
    local data = str:sub(i,j-1)
    return tonumber(data),j
  elseif str:sub(i,i+3) == "null" then
    return nil,i+4
  elseif str:sub(i,i+3) == "true" then
    return true,i+4
  elseif str:sub(i,i+4) == "false" then
    return false,i+5
  elseif b == string.byte("#") then
    local j = i + 1
    j,b = dream.toml.spree(str,j)
    if b == string.byte("\n") then
      return nil,j+1
    end
    while true do
      if b == nil then
        dream.toml.Error(str,j,"未结束的注释")
      elseif b == string.byte("\n") then
        break
      else
        j = j + 1
      end
      j,b = dream.toml.spree(str,j,true)
    end
    return nil,j+1
  else
    local j = i
    repeat
      if b == nil then
        dream.toml.Error(str,j,"未闭合的字符串")
      else
        j = j + 1
      end
      j,b = dream.toml.spree(str,j)
    until b == string.byte("=") or b == string.byte("]") or b == string.byte("}") or b == string.byte(".") or b == nil
    local k = str:sub(i,j-1)
    while k:sub(1,1) == " " do
      k = k:sub(2,-1)
    end
    while k:sub(-1,-1) == " " do
      k = k:sub(1,#k-1)
    end
    if b ~= string.byte("=") or not de then
      return k,j
    else
      j = j + 1
    end
    local v,j = dream.toml.decode(str,j,true)
    j,b = dream.toml.spree(str,j,true)
    if b ~= string.byte("\n") and b ~= nil then
      dream.toml.Error(str,j,"Toml结构错误")
    end
    return {[k]=v},j
  end
end

function dream.toml.parse(str)
  local tab,i = dream.toml.decode(str,1,nil,true)
  tab = tab or {}
  while i < #str do
    local tbl,b
    tbl,i = dream.toml.decode(str,i,nil,true)
    if tbl then
      tab = table.add(tab,tbl)
    end
    i,b = dream.toml.spree(str,i)
  end
  return tab
end
toml = dream.toml

-- dream base64
dream.base64 = {}

dream.base64.chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function dream.base64.encode(str,chars)
  if not chars or type(chars) ~= "table" or #chars < 64 then
    chars = dream.base64.chars
  else
    for i=1,#chars do
      for j=1,#chars do
        if chars[i] == chars[j] then -- 因为解码，所以不能相同
          -- chars传参格式应为：
          --[[
            chars = {"1","2"}
            也就是array形式，但字节可以变：
            chars = {"1","12"}
            填充64个数据才能通过，并且各个值不相同
          ]]
          chars = dream.base64.chars
          break
        end
      end
    end
  end
  if chars == dream.base64.chars then
    chars = dream.string.toTable(chars)
  end
  str = str:gsub(".",function(x)
    return bit32.tobit(tonumber(x:byte(),2))
  end)
  str = dream.string.toTable(str)
  while true do
    if #str % 6 == 0 then
      break
    end
    table.insert(str,"0")
  end
  str = table.concat(str)
  local tab = {}
  local i = 1
  while true do
    if str:sub(i,i+5) == "" then
      break
    end
    tab[#tab+1] = str:sub(i,i+5)
    tab[#tab] = "00"..tab[#tab]
    tab[#tab] = dream.math.hextoNum2(tab[#tab],2)
    tab[#tab] = chars[tab[#tab]+1]
    i = i + 6
  end
  if #tab < 4 then
    while true do
      if #tab >= 4 then
        break
      end
      table.insert(tab,"=")
    end
  end
  return table.concat(tab)
end

function dream.base64.decode(str,chars)
  if not chars or type(chars) ~= "table" or #chars < 64 then
    chars = dream.base64.chars
  else
    for i=1,#chars do
      for j=1,#chars do
        if chars[i] == chars[j] then
          chars = dream.base64.chars
          break
        end
      end
    end
  end
  if chars == dream.base64.chars then
    chars = dream.string.toTable(chars)
  end
  tab = dream.string.toTable(str)
  for i=1,#tab do
    if not tab[i]:find("^["..table.concat(chars).."]$") then
      tab[i] = ""
    end
  end
  str = table.concat(tab)
  local i = 1
  local tab = {}
  while true do
    if i > #str then
      break
    end
    for l=1,#chars do
      if str:sub(i,i+#chars[l]-1) == chars[l] then
        table.insert(tab,tonumber(l-1,2):sub(3,-1))
      end
    end
    i = i + 1
  end
  local str = table.concat(tab)
  tab = {}
  i = 1
  while true do
    if str:sub(i,i+7) == "" then
      break
    end
    tab[#tab+1] = str:sub(i,i+7)
    tab[#tab] = dream.math.hextoNum2(tab[#tab],2)
    tab[#tab] = string.char(tab[#tab])
    i = i + 8
  end
  return table.concat(tab)
end

-- dream md5
dream.md5 = {}

function dream.md5.encode(str,p)
  p = p or 32
  x = function(str,i)
    if str:sub(i,i+1) == "" then
      return ""
    end
    return str:sub(i,i+1)..x(str,i-2)
  end
  str = str:gsub(".",function(x)
    return tonumber(x:byte(),16)
  end)
  str = dream.string.toTable(str)
  local i = #str/2*8
  str[#str+1] = "8"
  str[#str+1] = "0"
  i = tonumber(i,16)
  i = dream.string.toTable(i)
  while true do
    if #i == 16 then
      break
    end
    table.insert(i,1,"0")
  end
  i = table.concat(i)
  i = x(i,#i-1)
  while true do
    if #str % 112 == 0 then
      break
    end
    str[#str+1] = "0"
  end
  str = table.concat(str)..i
  local i = 1
  local M = {}
  while true do
    if str:sub(i,i+7) == "" then
      break
    end
    M[#M+1] = str:sub(i,i+7)
    M[#M] = x(M[#M],#M[#M]-1)
    i = i + 8
  end
  local A = 0x67452301
  local B = 0xEFCDAB89
  local C = 0x98BADCFE
  local D = 0x10325476
  local K = {
    0xd76aa478,
    0xe8c7b756,
    0x242070db,
    0xc1bdceee,
    0xf57c0faf,
    0x4787c62a,
    0xa8304613,
    0xfd469501,
    0x698098d8,
    0x8b44f7af,
    0xffff5bb1,
    0x895cd7be,
    0x6b901122,
    0xfd987193,
    0xa679438e,
    0x49b40821,
    0xf61e2562,
    0xc040b340,
    0x265e5a51,
    0xe9b6c7aa,
    0xd62f105d,
    0x02441453,
    0xd8a1e681,
    0xe7d3fbc8,
    0x21e1cde6,
    0xc33707d6,
    0xf4d50d87,
    0x455a14ed,
    0xa9e3e905,
    0xfcefa3f8,
    0x676f02d9,
    0x8d2a4c8a,
    0xfffa3942,
    0x8771f681,
    0x6d9d6122,
    0xfde5380c,
    0xa4beea44,
    0x4bdecfa9,
    0xf6bb4b60,
    0xbebfbc70,
    0x289b7ec6,
    0xeaa127fa,
    0xd4ef3085,
    0x04881d05,
    0xd9d4d039,
    0xe6db99e5,
    0x1fa27cf8,
    0xc4ac5665,
    0xf4292244,
    0x432aff97,
    0xab9423a7,
    0xfc93a039,
    0x655b59c3,
    0x8f0ccc92,
    0xffeff47d,
    0x85845dd1,
    0x6fa87e4f,
    0xfe2ce6e0,
    0xa3014314,
    0x4e0811a1,
    0xf7537e82,
    0xbd3af235,
    0x2ad7d2bb,
    0xeb86d391,
  }
  local r = {7,12,17,22,5,9,14,20,4,11,16,23,6,10,15,21}
  local s = {}
  local ind = 1
  local j = 1
  for i=1,64 do
    if ind <= 4 then
      for i=j,j+3 do
        s[#s+1] = r[i]
      end
      ind = ind + 1
    else
      ind = 1
      j = j + 4
    end
  end
  local lift = function(v,s)
    return bit32.bor(bit32.lshift(bit32.band(v,0xffffffff),s),bit32.rshift(bit32.band(v,0xffffffff),32-s))
  end
  local index = {
    0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
    1,6,11,0,5,10,15,4,9,14,3,8,13,2,7,12,
    5,8,11,14,1,4,7,10,13,0,3,6,9,12,15,2,
    0,7,14,5,12,3,10,1,8,15,6,13,4,11,2,9
  }
  local fun = function(tab,i,l)
    local res = {}
    for i=i,l do
      res[#res+1] = tab[i]
    end
    return res
  end
  for i=1,#M/16 do
    local a,b,c,d = A,B,C,D
    for l=1,64 do
      local o = i * 16
      local p = o - 15
      local k = K[l]
      local S = s[l]
      local M = fun(M,p,o)
      local m = M[index[l]+1]
      local F
      m = dream.math.hextoNum2(m,16)
      if l <= 16 then
        F = function()
          return bit32.bor(bit32.band(b,c),bit32.band(bit32.bnot(b),d))
        end
      elseif l <= 32 then
        F = function()
          return bit32.bor(bit32.band(d,b),bit32.band(c,bit32.bnot(d)))
        end
      elseif l <= 48 then
        F = function()
          return bit32.bxor(bit32.bxor(b,c),d)
        end
      else
        F = function()
          return bit32.bxor(c,bit32.bor(b,bit32.bnot(d)))
        end
      end
      a = a + F() + k + m
      a = lift(a,S) + b
      a = bit32.band(a,0xffffffff)
      local back_b,back_c,back_d = b,c,d
      b = a
      c = back_b
      d = back_c
      a = back_d
    end
    A = A + a
    B = B + b
    C = C + c
    D = D + d
    A = bit32.band(A,0xffffffff)
    B = bit32.band(B,0xffffffff)
    C = bit32.band(C,0xffffffff)
    D = bit32.band(D,0xffffffff)
  end
  A,B,C,D = tonumber(A,16),tonumber(B,16),tonumber(C,16),tonumber(D,16)
  local str = x(A,#A-1)..x(B,#B-1)..x(C,#C-1)..x(D,#D-1)
  x = nil
  if p == 32 then
    return str
  elseif p == 16 then
    return str:sub(9,24)
  else
    return str
  end
end

-- dream string
dream.string = {}

function dream.string.format(str,env)
  if str == "" then
    return str
  end
  local tab = dream.string.toTable(str)
  local tbl = {}
  local i = 1
  while true do
    if i > #tab then
      break
    elseif tab[i] == "{" then
      local ind
      for l=i+1,#tab do
        if tab[l] == "}" then
          ind = l
          break
        end
      end
      if ind then
        local str = table.concat(tab,"",i,ind)
        tbl[#tbl+1] = str
      end
    end
    i = i + 1
  end
  for i=1,#tbl do
    str = str:gsub(tbl[i],tostring(dream.get(tbl[i]:sub(2,#tbl[i]-1),env)))
  end
  return str
end

function dream.string.random(...)
  local tab = pack(...)
  return table.random(tab)
end

function dream.string.encode(str)
  local map = {
    [ "\b" ] = "\\b",
    [ "\f" ] = "\\f",
    [ "\n" ] = "\\n",
    [ "\r" ] = "\\r",
    [ "\t" ] = "\\t"
  }
  for k,v in pairs(map) do
    str = str:gsub(k,v)
  end
  return str
end

function dream.string.decode(str)
  local map = {
    [ "\b" ] = "\\b",
    [ "\f" ] = "\\f",
    [ "\n" ] = "\\n",
    [ "\r" ] = "\\r",
    [ "\t" ] = "\\t"
  }
  for v,k in pairs(map) do
    str = str:gsub(k,v)
  end
  return str
end

function dream.string.find(str,v)
  local i = 1
  local r = 0
  while i <= #str do
    if str:sub(i,i+#v-1) == v then
      r = r + 1
    end
    i = i + 1
  end
  return r
end

function dream.string.toTable(str)
  local i = 1
  local tab = {}
  while true do
    if i > #str then
      break
    end
    local l = str:sub(i,i)
    local len = dream.utf8.len(l)
    table.insert(tab,str:sub(i,i+len-1))
    i = i + len
  end
  return tab
end

function dream.string.sub(str,start,endl)
  local tab = dream.string.toTable(str)
  local endl = endl or #tab
  if endl == -1 then
    endl = #tab
  end
  if start == -1 then
    start = #tab
  end
  if start > #tab or start < 1 or endl > #tab or endl < 1 then
    return ""
  end
  local start = start or error("The starting index is missing")
  return table.concat(tab,"",start,endl)
end

function dream.string.part(str,id)
  local i = 1
  local l = #id
  local tab = {}
  local start = 1
  while true do
    if i > #str then
      break
    elseif str:sub(i,i+l-1) == id then
      table.insert(tab,str:sub(start,i-1))
      start = i + l
      if i > #str then
        break
      end
    elseif i == #str then
      table.insert(tab,str:sub(start,i))
    end
    i = i + 1
  end
  return tab
end

function dream.string.len(str)
  local tab = dream.string.toTable(str)
  return #tab
end

-- dream unicode
dream.unicode = {}

function dream.unicode.tobit(char) -- 补齐bit32.tobit
  if type(char) ~= "string" then
    char = tostring(char)
  end
  while (#char % 8) ~= 0 do
    char = "0"..char
  end
  return char
end
bit32.tobit = dream.unicode.tobit

function dream.unicode.encode(char)
  if type(char) ~= "string" then
    error("The value that should be Char turns out to be Sterling")
  end
  local encode = function(char)
    local len = dream.utf8.len(char)
    local char = char:gsub(".",function(x)
      x = x:byte()
      x = dream.math.num2toHex(x,2)
      if #x < 8 then
        while #x < 8 do
          x = "0"..x
        end
      end
      return x
    end)
    if len == 1 then
      char = "0"..char:sub(2,-1)
    elseif len == 2 then
      char = char:sub(6,16)
    elseif len == 3 then
      char = char:sub(5,8)..char:sub(11,16)..char:sub(19,24)
    elseif len == 4 then
      char = char:sub(6,8)..char:sub(11,16)..char:sub(19,24)..char:sub(27,32)
    end
    char = dream.math.hextoNum2(char,2)
    char = dream.math.num2toHex(char,16)
    while #char < 4 do
      char = "0"..char
    end
    return char
  end
  local tab = dream.string.toTable(char)
  for i=1,#tab do
    tab[i] = encode(tab[i])
  end
  return table.concat(tab)
end

function dream.unicode.toutf8(char)
  while true do
    if #char % 4 == 0 then
      break
    end
    char = "0"..char
  end
  local fun = function(char) -- 单独四个unicode转utf8
    char = dream.math.hextoNum2(char,16)
    local t = tonumber(char)
    char = dream.math.num2toHex(char,2)
    char = bit32.tobit(char)
    local x = char:sub(1,1)
    if t < 0x00 or t > 0x10FFFF then
      error("not unicode")
    elseif t <= 0x007F then
      char = "0"..char:sub(2,#char)
    elseif t <= 0x07FF then
      char = "110"..char:sub(6,10).."10"..char:sub(11,16)
    elseif t <= 0xFFFF then
      char = "1110"..char:sub(1,4).."10"..char:sub(5,10).."10"..char:sub(11,16)
    elseif t <= 0x10FFFF then
      char = "11110"..char:sub(1,3).."10"..char:sub(4,9).."10"..char:sub(10,15).."10"..char:sub(16,21)
    end
    local i = char
    char = dream.math.hextoNum2(char,2)
    char = dream.math.num2toHex(char,16)
    return char
  end
  local res = {}
  local i = 1
  while true do
    if char:sub(i,i+3) == "" then
      break
    end
    res[#res+1] = char:sub(i,i+3)
    i = i + 4
  end
  for i=1,#res do
    res[i] = fun(res[i])
  end
  return table.concat(res)
end

function dream.unicode.decode(char)
  while true do
    if #char % 4 == 0 then
      break
    end
    char = "0"..char
  end
  local res = {}
  char = dream.string.toTable(char)
  local i = 1
  while true do
    if i > #char then
      break
    end
    res[#res+1] = char[i]..char[i+1]..char[i+2]..char[i+3]
    i = i + 4
  end
  for i=1,#res do
    local str = res[i]
    res[i] = ""
    print(str)
    str = dream.unicode.toutf8(str)
    local ind = 1
    while true do
      if str:sub(ind,ind+1) == "" then
        break
      end
      local l = str:sub(ind,ind+1)
      l = dream.math.hextoNum2(l,16)
      l = string.char(l)
      res[i] = res[i]..l
      ind = ind + 2
    end
  end
  return table.concat(res)
end

-- dream utf8
dream.utf8 = {}

function dream.utf8.len(char)
  local x = char:byte()
  if x < 127 then
    return 1
  elseif x <= 223 then
    return 2
  elseif x <= 239 then
    return 3
  elseif x <= 247 then
    return 4
  else
    return 0
  end
end

function dream.utf8.encode(char)
  char = dream.unicode.encode(char)
  return dream.unicode.toutf8(char)
end

function dream.utf8.decode(char)
  while true do
    if #char % 2 == 0 then
      break
    end
    char = "0"..char -- 高位补0
  end
  local res = {}
  local i = 1
  while true do
    if i > #char then
      break
    end
    res[#res+1] = char:sub(i,i+1)
    i = i + 2
  end
  for i=1,#res do
    res[i] = dream.math.hextoNum2(res[i],16)
    res[i] = string.char(res[i])
  end
  return table.concat(res)
end

function dream.utf8.tounicode(char)
  char = dream.utf8.decode(char)
  return dream.unicode.encode(char) -- 解出来之后重新编码即可
end

-- dream html
dream.html = {}

function dream.html.encode(char)
  if type(char) ~= "string" then
    return nil
  end
  char = char:gsub(".",function(x)
    local a = x:byte()
    return "&#"..a..";"
  end)
  return char
end

function dream.html.decode(char)
  local char = char:gsub("&#([0-9]+);",function(x)
    return x:char()
  end)
  return char
end

-- dream system
dream.system = {}

function dream.system.Memory(index)
  local free = dream.execute("free")
  free = dream.string.part(free,"\n")
  free[1] = free[1]:sub(3,-1)
  free[2] = free[2]:sub(5,-1)
  free[3] = free[3]:sub(17,-1)
  free[4] = free[4]:sub(6,-1)
  for i=1,3 do
    free[i+1] = free[i+1]:sub(8,-1)
  end
  for i=1,#free do
    local tab = {}
    local l = 1
    local f = {}
    while l <= #free[i] do
      if free[i]:sub(l,l) ~= " " then
        table.insert(tab,free[i]:sub(l,l))
      elseif free[i]:sub(l,l) == " " and free[i]:sub(l-1,l-1) ~= " " then
        table.insert(f,table.concat(tab,""))
        tab = {}
      end
      l = l + 1
    end
    if dream.json.encode(tab) ~= "{}" then
      table.insert(f,table.concat(tab,""))
    end
    free[i] = f
  end
  for i=1,#free[1] do
    free[1][free[1][i]] = free[2][i]
    free[1][i] = nil
  end
  table.remove(free,2)
  free[2]["-buffers/cache"] = free[2][1]
  free[2]["+buffers/cache"] = free[2][2]
  free[2][1],free[2][2] = nil,nil
  table.remove(free,3)
  local tab = {}
  for i=1,#free do
    for k,v in pairs(free[i]) do
      tab[k] = tonumber(v)
    end
  end
  return tab[index]
end

function dream.system.load(func)
  local j = dream.file.read(dream.setting.path.."/data/system.json") or "{}"
  j = dream.json.decode(j)
  j.load = j.load or {}
  local i = dream.search(func)
  if not i then
    dream.sendMaster("请使用全局函数注册load事件！")
    return false
  end
  j.load[#j.load+1] = i
  j = dream.json.encode(j)
  dream.file.write(dream.setting.path.."/data/system.json",j)
  return true
end

local rawsdk_system_load = sdk.system.load
function sdk.system.load()
  local j = dream.file.read(dream.setting.path.."/data/system.json")
  local f = dream.file.read(dream.setting.path.."/data/timer.json")
  if j then
    j = dream.json.decode(j)
    if j.load then
      for i=1,#j.load do
        local func = dream.get(j.load[i])
        local a,b = pcall(func)
        if not a then
          dream.sendMaster(dream.nick.."调用函数["..j.load[i].."]失败！："..dream.error(b,false))
        end
      end
    end
  end
  if f then
    f = dream.json.decode(f)
    f = {timer = f}
    local d = dream.file.read(dream.api.getDiceDir().."/custom/dream.toml")
    d = dream.toml.parse(d)
    d = {lua = d.lua}
    dream.file.write(dream.setting.path.."/data/dream.toml",dream.toml.encode(d))
    d = table.add(d,f)
    d = dream.toml.encode(d)
    dream.file.write(dream.api.getDiceDir().."/custom/dream.toml",d)
  else
    local d = dream.file.read(dream.api.getDiceDir().."/custom/dream.toml")
    d = dream.toml.parse(d)
    d = {lua = d.lua}
    d = dream.toml.encode(d)
    dream.file.write(dream.api.getDiceDir().."/custom/dream.toml",d)
  end
  rawsdk_system_load()
end

function dream.system.reload(func)
  local j = dream.file.read(dream.setting.path.."/data/system.json") or "{}"
  j = dream.json.decode(j)
  j.reload = j.reload or {}
  local i = dream.search(func)
  if not i then
    dream.sendMaster("请使用全局函数注册reload事件！")
    return false
  end
  j.reload[#j.reload+1] = i
  j = dream.json.encode(j)
  dream.file.write(dream.setting.path.."/data/system.json",j)
  return true
end

local rawsdk_system_reload = sdk.system.reload
function sdk.system.reload()
  local j = dream.file.read(dream.setting.path.."/data/system.json")
  local f = dream.file.read(dream.setting.path.."/data/timer.json")
  if j then
    j = dream.json.decode(j)
    if j.reload then
      for i=1,#j.reload do
        local func = dream.get(j.reload[i])
        local a,b = pcall(func)
        if not a then
          dream.sendMaster(dream.nick.."调用函数["..j.reload[i].."]失败！："..dream.error(b,false))
        end
      end
    end
  end
  if f then
    f = dream.json.decode(f)
    f = {timer = f}
    local d = dream.file.read(dream.api.getDiceDir().."/custom/dream.toml")
    d = dream.toml.parse(d)
    d = {lua = d.lua}
    dream.file.write(dream.setting.path.."/data/dream.toml",dream.toml.encode(d))
    d = table.add(d,f)
    d = dream.toml.encode(d)
    dream.file.write(dream.api.getDiceDir().."/custom/dream.toml",d)
  else
    local d = dream.file.read(dream.api.getDiceDir().."/custom/dream.toml")
    d = dream.toml.parse(d)
    d = {lua = d.lua}
    d = dream.toml.encode(d)
    dream.file.write(dream.api.getDiceDir().."/custom/dream.toml",d)
  end
  rawsdk_system_reload()
end

-- dream.file
dream.file = {}

function dream.file.read(path,p)
  local file = io.open(path,"r")
  if not file then
    return nil
  end
  local p = p or "*a"
  local res = file:read(p)
  file:close()
  return res
end

function dream.file.write(path,str,p)
  if type(str) ~= "string" then
    str = tostring(str)
  end
  local p = p or "w"
  local file = io.open(path,p)
  if not file then
    return false
  end
  file:write(str)
  file:close()
end

function dream.file.line(path,i)
  local file = io.open(path,"r")
  if not file then
    return nil
  end
  if i then
    i = tonumber(i)
    local ind = 0
    local res
    for line in file:lines() do
      ind = ind + 1
      if ind == i then
        res = line
        break
      end
    end
    file:close()
    return res
  else
    local n = 0
    for line in file:lines() do
      n = n + 1
    end
    return n
  end
end

-- dream timer 时间调速器/定时插件
dream.timer = {}

function dream.timer.init() -- 初始化时间调度器
  local __index = {}
  function __index:name(str)
    self.timer[1].name = str
  end
  function __index:exp(...)
    local tab = pack(...)
    if #tab ~= 6 then
      error("时间配置的格式为“秒 分 时 日 月 周”\n如果你需要的时间非定值，则需要将参数改为\"*\"或\"?\"\n下面是一个在每周周一的10点的时间调度器\n\"0 0 10 * * 1\"\n周的位置可以变成英文，如：\n\"0 0 10 * * MON\"\n但是你【不能直接将你写好的时间调度器当做参数直接传入】，你需要分割参数，将“秒 分 时 日 月 周”分别做为一个参数传入，比如：dream.timer.init():exp(\"0\",\"0\",\"10\",\"*\",\"*\",\"1\")")
    end
    self.timer[1].expression = table.concat(tab," ")
  end
  function __index:js(code,...)
    local tab,str = pack(...),nil
    if code == "dream.api.sendGroupMessage" then
      str = "Lib.sendGroupMessage(\""..tab[1].."\",\""..tab[2].."\")"
    elseif code == "dream.api.sendUserMessage" then
      if tab[3] then
        str = "Lib.sendPrivateMessage(\""..tab[1].."\",\""..tab[3].."\",\""..tab[2].."\")"
      else
        str = "Lib.sendFriendPrivateMessage(\""..tab[1].."\",\""..tab[2].."\")"
      end
    end
    self.timer[1].js[#self.timer[1].js+1] = str
  end
  function __index:apply()
    local tab = table.clone(self.timer)
    tab[1].js = "\n"..table.concat(tab[1].js,"\n").."\n"
    local f = dream.file.read(dream.setting.path.."/data/timer.json") or "{}"
    f = dream.json.decode(f)
    for i=1,#f do
      if f[i].name == tab[1].name then
        error("应用该时间调度器失败：已有相同名称的时间调度器，请重新命名或使用dream.timer.remove函数删除该时间调度器")
      end
    end
    f = table.add(f,tab)
    f = dream.json.encode(f)
    dream.file.write(dream.setting.path.."/data/timer.json",f)
  end
  local tab = setmetatable({
    timer = {{
      name = "",
      expression = "",
      js = {}
    }}
  },{__index = __index})
  return tab
end

function dream.timer.remove(id)
  local f = dream.file.read(dream.setting.path.."/data/timer.json") or "{}"
  f = dream.json.decode(f)
  for i=1,#f do
    if f[i].name == id then
      table.remove(f,i)
      break
    end
  end
  f = dream.json.encode(f)
  if f == "{}" then
    dream.execute("rm "..dream.setting.path.."/data/timer.json")
  else
    dream.file.write(dream.setting.path.."/data/timer.json",f)
  end
end

function dream.timer.list()
  local f = dream.file.read(dream.setting.path.."/data/timer.json") or "{}"
  f = dream.json.decode(f)
  if table.equal(f,{}) then
    return nil
  end
  for k,v in pairs(f) do
    while v.js:sub(1,1) == "\n" do
      v.js = v.js:sub(2,-1)
    end
    while v.js:sub(-1,-1) == "\n" do
      v.js = v.js:sub(1,#v.js-1)
    end
    v.js = dream.string.part(v.js,"\n")
    for i=1,#v.js do
      v.js[i] = v.js[i]:gsub("^Lib.sendGroupMessage%((.+)%,(.+)%)$",function(r,x)
        return "dream.api.sendGroupMessage("..r..","..x..")"
      end)
      v.js[i] = v.js[i]:gsub("^Lib.sendFriendPrivateMessage%((.+)%,(.+)%)$",function(r,x)
        return "dream.api.sendUserMessage("..r..","..x..")"
      end)
      v.js[i] = v.js[i]:gsub("^Lib.sendPrivateMessage%((.+)%,(.+)%,(.+)%)$",function(r,x,i)
        return "dream.api.sendUserMessage("..r..","..i..","..x..")"
      end)
    end
    f[k].lua = table.concat(table.clone(v.js),"\n")
    f[k].js = nil
  end
  return f
end

-- dream api
-- 鸣谢 星瑚∞ 提供的图片处理方法
function dream.api.pic(data)
  data = data:gsub("%[(mirai:image:{.-}%..-),.-%]", "%[%1%]")
  return data
end

local index_to_format = function(x)
  if x:sub(1,1) == "/" then
    x = x:sub(2,-1)
  end
  local v = "../../../../../../"
  return v..x
end

function dream.api.picture(i)
  return "#{PICTURE-"..index_to_format(i).."}"
end

function dream.api.file(i,d)
  return "#{FILE-"..index_to_format(i).."***"..d.."}"
end

function dream.api.voice(i)
  return "#{VOICE-"..index_to_format(i).."}"
end

function dream.api.video(i,d)
  return "#{VIDEO-"..index_to_format(i).."***"..index_to_format(d).."}"
end

function dream.api.format(i)
  i = i:gsub("#","\\#"):gsub("}","\\}"):gsub("%[","\\%["):gsub("%]","\\%]")
  return i
end

function dream.api.BotRecall(str,i)
  return str.."#{RECALL-"..tonumber(i).."}"
end

function dream.api.avatar(qq)
  return "#{PICTURE-http://q2.qlogo.cn/headimg_dl?dst_uin="..qq.."&spec=640}"
end

function dream.api.getDiceQQ()
  return ZhaoDiceSDK.storage.path:match("_([0-9]+)")
end

function dream.api.today()
  return os.date("%Y-%m-%d")
end

function dream.api.getDiceDir()
  return sdk.storage.path:match("(.+)/.+/.+")
end

function dream.api.jrrp(id) -- 可以加盐
  if type(id) ~= "string" then
    return 0
  end
  local md5 = os.date("%Y-%m-%d")..id
  md5 = dream.md5.encode(md5):lower()
  local i = md5:sub(1,2)
  i = load("return 0x"..i)()
  i = bit32.band(i,0xff)
  i = i / 0xff * 99 + 1
  local l = i % 1
  i = i - l
  return i
end

function dream.api.getInviterList()
  local path = dream.api.getDiceDir().."/data/blackList.json"
  local res = dream.file.read(path)
  res = dream.json.decode(res)
  return res.inviterList
end

function dream.api.getBlackList()
  local path = dream.api.getDiceDir().."/data/blackList.json"
  local res = dream.file.read(path)
  res = dream.json.decode(res)
  return res.blackList
end

function dream.api.getPluginsList()
  local list = dream.execute("ls "..dream.setting.path.."/config")
  if not list then
    return {}
  end
  return dream.string.part(list,"\n")
end

function dream.api.unUnicode(msg)
  local i = 1
  while true do
    if i > #msg then
      break
    end
    local l = msg:sub(i,i+1)
    if l == "\\u" then
      unicode = msg:sub(i+2,i+5)
      msg = msg:gsub(l..unicode,dream.unicode.decode(unicode))
      i = i + #dream.unicode.decode(unicode)
    else
      i = i + 1
    end
  end
  return msg
end

function dream.api.setUserConf(setting,str,qq,fileName)
  local fileName = fileName or "user"
  if fileName ~= "user" then
    local l = dream.string.part(fileName,"/")
    local path = dream.setting.path.."/storage"
    for i=1,#l-1 do
      dream.execute("mkdir "..path.."/"..l[i])
      path = path.."/"..l[i]
    end
  end
  local file = io.open(dream.setting.path.."/storage/"..fileName..".json","r")
  if file == nil then
    local tbl = {}
    local i = #tbl + 1
    tbl[i] = {}
    tbl[i]["id"] = qq
    tbl[i][setting] = str
    tbl = dream.json.encode(tbl)
    local file = io.open(dream.setting.path.."/storage/"..fileName..".json","w")
    file:write(tbl)
    file:close()
  else
    tbl = file:read("*a")
    file:close()
    tbl = dream.json.decode(tbl)
    for i=1,#tbl do
      if tbl[i]["id"] == qq then
        l = i
        break
      else
        l = i + 1
      end
    end
    if l > #tbl then
      tbl[l] = {}
      tbl[l]["id"] = qq
    end
    tbl[l][setting] = str
    tbl = dream.json.encode(tbl)
    local file = io.open(dream.setting.path.."/storage/"..fileName..".json","w")
    file:write(tbl)
    file:close()
  end
  return nil
end

function dream.api.getUserConf(setting,qq,fileName)
  local fileName = fileName or "user"
  local file = io.open(dream.setting.path.."/storage/"..fileName..".json","r")
  if file == nil then
    return nil
  end
  tbl = file:read("*a")
  file:close()
  tbl = dream.json.decode(tbl)
  for i=1,#tbl do
    if tbl[i]["id"] == qq then
      l = i
      break
    else
      l = i + 1
    end
  end
  if l > #tbl then
    return nil
  end
  return tbl[l][setting]
end
  
function dream.api.agreement(qq)
  local path = "/storage/emulated/0/AstralDice/.MiraiCache/"..qq
  local f1 = path.."/ANDROID_PHONE/contacts/friends.json"
  local f2 = path.."/ANDROID_PAD/contacts/friends.json"
  local f3 = path.."/ANDROID_WATCH/contacts/friends.json"
  if  io.open(f1,"r") then
    return path.."/ANDROID_PHONE"
  elseif io.open(f2,"r") then
    return path.."/ANDROID_PAD"
  elseif io.open(f3,"r") then
    return path.."/ANDROID_WATCH"
  end
  return false
end

dream.deter = {}
function dream.deter.master(qq)
  local list = dream.api.getAdmin()
  if not list[1] then
    return false
  end
  for i=1,#list do
    if list[i] == tostring(qq) then
      return true
    end
  end
  return false
end

function dream.api.eventMsg(type_cmd,cmd,msg)
  local tab = {
    "keyword",
    "command",
    "replace"
  }
  msg.fromMsg = cmd
  for i=1,#tab do
    if type_cmd == tab[i] then
      break
    elseif i == #tab then
      return false
    end
  end
  local path = dream.setting.path.."/data/"..type_cmd..".json"
  local tab = dream.file.read(path)
  if not tab then
    return false
  end
  tab = dream.json.decode(tab)
  for k,v in pairs(tab) do
    if cmd:sub(1,#k) == k then
      msg.fromParams = msg.fromMsg:sub(#k+1,-1)
      if type_cmd == "replace" then
        dream.get(v)(msg)
      else
        dream.api.sendMessage(dream.get(v)(msg),msg)
      end
    end
  end
end

function dream.sendMaster(str)
  local list = dream.api.getAdmin()
  if dream.api.getNotice()[1] then
    dream.api.sendGroupMessage(str)
    return nil
  elseif not list[1] then
    dream.log(dream.nick.."未拥有任何"..dream.masterNick.."！不进行任何回复！")
    return nil
  end
  for i=1,#list do
    dream.api.sendUserMessage(str,list[i])
  end
  return nil
end

function dream.api.sendMessage(str,msg)
  if msg == nil then
    dream.error("参数缺失:<msg>")
  end
  if msg.isGroup then
    dream.api.sendGroupMessage(str,msg.fromGroup)
  elseif msg.isGroup == false then
    dream.api.sendUserMessage(str,msg.fromQQ,"")
  end
end

function dream.api.sendGroupMessage(str,num)
  if num == nil then
    local groups = dream.api.getNotice()
    local list = {}
    for i=1,#groups do
      local n = groups[i]
      for x=i+1,#groups do
        if groups[x] == n then
          list[#list+1] = x
        end
      end
    end
    for i=1,#list do
      table.remove(groups,list[i])
    end
    for i=1,#groups do
      ZhaoDiceSDK.chat.sendToGroup(str,groups[i])
    end
  else
    ZhaoDiceSDK.chat.sendToGroup(str,num)
  end
end

function dream.api.sendUserMessage(str,qq,group)
  local group = group or ""
  if group == "" then
    local list = dream.api.getGroupsList()
    for l =1,#list do
      if list[l].uin == tonumber(qq) then
        group = l
        break
      end
    end
  end
  if qq == nil then
    error("参数:<QQ号>缺失！")
  else
    ZhaoDiceSDK.chat.sendToPerson(str,dream.tostring(qq),dream.tostring(group))
  end
end

function dream.api.face(str)
  local tab = dream.module.require("face")
  return tab[str] or ""
end

function dream.api.poke(str)
  local tab = dream.module.require("poke")
  return tab[str] or ""
end

function dream.api.superface(str)
  local tab = dream.module.require("superface")
  return tab[str] or ""
end

function dream.api.getGroupsList()
  local path = dream.api.agreement(dream.api.getDiceQQ()).."/contacts/groups/"
  local list = dream.execute("ls "..path)
  if not list then
    return {}
  end
  list = dream.string.part(list,"\n")
  for i=1,#list do
    list[i] = list[i]:match("(.+)%..+")
  end
  return list
end

function dream.api.getMembersList(group)
  local path = dream.api.agreement(dream.api.getDiceQQ()).."/contacts/groups/"..group..".json"
  local file = io.open(path,"r")
  if file == nil then
    return {}
  end
  local tab = file:read("*a")
  file:close()
  tab = dream.json.decode(tab)
  return tab.list
end

function dream.api.getMembersNumber(group)
  local path = dream.api.agreement(dream.api.getDiceQQ()).."/contacts/groups/"..group..".json"
  if not dream.file.read(path) then
    return 0
  end
  local i = dream.file.line(path,2):sub(#"    \"troopMemberNumSeq\": "+1,-1)
  return tonumber(i:match("([0-9]+)"))
end

function dream.api.getFriendsList()
  local path = dream.api.agreement(dream.api.getDiceQQ()).."/contacts/friends.json"
  local file = io.open(path,"r")
  if file == nil then
    return {}
  end
  local tab = file:read("*a")
  file:close()
  tab = dream.json.decode(tab)
  return tab.friendList or tab.list
end

function dream.api.getUserNick(qq)
  local list = dream.api.getFriendsList()
  for l=1,#list do
    if list[l].uin == tonumber(qq) then
      return list[l].nick
    end
  end
  list = dream.api.getGroupsList()
  for k=1,#list do
    local i = dream.api.getMembersList(list[k])
    for l = 1,#i do
      if i[l].uin == tonumber(qq) then
        return i[l].nick
      end
    end
  end
  return dream.stranger
end

function dream.api.getNotice()
  local file = io.open(dream.setting.path.."/data/setting.json","r")
  if file == nil then
    return {}
  end
  local tab = file:read("*a")
  file:close()
  tab = dream.json.decode(tab)
  if not tab.notice then
    return {}
  else
    if not tab.notice[1] then
      return {}
    end
    return tab.notice
  end
end

function dream.api.getAdmin()
  local file = io.open(dream.setting.path.."/data/setting.json","r")
  if file == nil then
    return {}
  end
  local tab = file:read("*a")
  file:close()
  tab = dream.json.decode(tab)
  if not tab.admin then
    return {}
  else
    return tab.admin
  end
end

function dream.api.thisGroupisOn(group)
  if sdk.readSystemConfig("WHITE_LIST"):find("#"..group) then
    return false
  else
    return true
  end
end

function dream.api.permission(group,id,permission)
  local permission = permission or "MEMBER"
  local list = dream.api.getMembersList(group)
  if not list then
    error("failed to get the list of group members")
  end
  local num
  for i=1,#list do
    if dream.tostring(list[i].uin) == dream.tostring(id) then
      num = i
      break
    end
  end
  if list[num].permission == permission then
    return true
  else
    return false
  end
end

function dream.api.getMemberJoinTime(group,qq)
  if not group then
    return 0
  elseif not qq then
    return 0
  end
  local list = dream.api.getMembersList(group)
  for l=1,#list do
    if list[l].uin == tonumber(qq) then
      return os.date("*t",list[l].joinTimestamp)
    end
  end
  return 0
end

function dream.api.getMemberLastTime(group,qq)
  if not group then
    return 0
  elseif not qq then
    return 0
  end
  local list = dream.api.getMembersList(group)
  for l=1,#list do
    if list[l].uin == tonumber(qq) then
      return os.date("*t",list[l].lastSpeakTimestamp)
    end
  end
  return 0
end

-------------------------------------
dream.execute("mkdir "..dream.setting.path.."/plugin")
dream.execute("mkdir "..dream.setting.path.."/lib")
dream.execute("mkdir "..dream.setting.path.."/data")
dream.execute("mkdir "..dream.setting.path.."/config")
dream.execute("mkdir "..dream.setting.path.."/module")
dream.execute("mkdir "..dream.setting.path.."/storage")

print(dream.version)
dream.log("尝试构建骰娘["..dream.nick.."]…")
dream.log("正在加载 "..#dream.api.getGroupsList().." 个群")
dream.log("正在加载 "..#dream.api.getFriendsList().." 个好友")
dream.log("加载完毕！当前Dream版本为["..dream._VERSION.."]，请确保版本为最新版！")
dream.log("更新请前往群243093229或找寻[筑梦师V2.0](2967713804)以获取最新版")
----------------------------------------
commands = setmetatable({},{__newindex = function(self,i,v)
  if type(v) == "function" then
    dream.command.set("Plugin",i,v)
  else
    rawset(self,i,v)
  end
end})
msg_order = setmetatable({},{__newindex = function(self,i,v)
  if type(v) == "function" then
    dream.keyword.set("Plugin",i,v)
  else
    rawset(self,i,v)
  end
end})
replaces = setmetatable({},{__newindex = function(self,i,v)
  if type(v) == "function" then
    dream.replace.set("Plugin",i,v)
  else
    rawset(self,i,v)
  end
end})

-- dream module
dream.module = {}

function dream.module.require(name)
  local file = io.open(dream.setting.path.."/module/"..name..".module","r")
  if not file then
    error("read module ["..name.."] failed!: Data source not found")
  end
  local mod = {}
  local n = 0
  for line in file:lines() do
    n = n + 1
    local k = line:match("^(.+)=")
    local v
    if not k then
      error("line:"..n..":the data does not meet expectations")
    else
      v = line:match("^"..k.."=(.+)$"):gsub(" ","")
    end
    mod[k] = v
  end
  return mod
end

function dream.module.set(k,v,name)
  if not k then
    error("the key must not be empty!")
  elseif not v then
    error("the value must not be empty!")
  end
  name = name or "dream"
  local file = io.open(dream.setting.path.."/module/"..name..".module","r")
  local str
  if file then
    str = file:read("*a")
    str = str.."\n"..k.."="..v
    file:close()
  else
    str = k.."="..v
  end
  local file = io.open(dream.setting.path.."/module/"..name..".module","w")
  file:write(str)
  file:close()
end

dream.plugin = {}
-- 指令封装 --
function dream.plugin.key(id,cmd,func,cmd_type,perm,isWhole)
  perm = perm or false
  isWhole = isWhole or false
  if cmd_type == "keyword" then
    cmd_type = "_keyword_"
  elseif cmd_type == "command" then
    cmd_type = "_command_"
  elseif cmd_type == "replace" then
    cmd_type = "_replace_"
  end
  local key = cmd_type..cmd
  _G["dream.pluginList"] = _G["dream.pluginList"] or {}
  _G["dream.pluginList"][func] = key
  _G[key] = function(msg)
    msg.fromDiceName = dream.nick
    msg.fromJrrp = dream.api.jrrp(msg.fromQQ)
    if not msg.isGroup then
      msg.fromGroup = ""
    end
    local map = {
      ["\\%["] = "%[",
      ["\\%]"] = "%]",
      ["\\,"] = "%,",
      ["\\:"] = "%:",
      ["\\#"] = "#"
    }
    for k,v in pairs(map) do
      cmd = cmd:gsub(k,v)
    end
    msg.CommandThis = cmd
    for k,v in pairs(map) do
      msg.fromMsg = msg.fromMsg:gsub(k,v)
      msg.fromParams = msg.fromParams:gsub(k,v)
    end
    local x = function(msg,id)
      if #msg == 0 then
        return msg
      end
      for i=1,#msg do
        if msg:sub(i,i+1) == dream.string.encode(id) then
          if msg:sub(i-1,i-1) ~= "\\" then
            msg = msg:sub(1,i-1)..id..msg:sub(i+2,-1)
          end
        end
      end
      return msg
    end
    msg.fromMsg = x(msg.fromMsg,"\n")
    msg.fromMsg = x(msg.fromMsg,"\r")
    msg.fromMsg = msg.fromMsg:gsub("\\\\","\\")
    msg.fromParams = x(msg.fromParams,"\n")
    msg.fromParams = x(msg.fromParams,"\r")
    msg.fromParams = msg.fromParams:gsub("\\\\","\\")
    if cmd_type == "_keyword_" then
      msg.fromParams = msg.fromMsg:sub(#msg.CommandThis+1,#msg.fromMsg)
    end
    if dream.plugin.getSetting(id,"mode") == false then
      return ""
    elseif dream.plugin.getConfig(id,msg.fromGroup) == "off" then
      return ""
    elseif perm == true then
      local b = dream.deter.master(msg.fromQQ)
      if not b then
        return ""
      end
    elseif isWhole then
      if msg.fromMsg ~= cmd then
        return ""
      end
    end
    log = function(str)
      print("["..cmd_type:gsub("_","").."]./"..id..":"..str)
    end
    local a,b = pcall(func,msg)
    if a then
      local tab = dream.file.read(dream.setting.path.."/data/data.json") or "{}"
      tab = dream.json.decode(tab)
      local i = cmd_type:sub(2,#cmd_type-1)
      tab[i] = b
      tab = dream.json.encode(tab)
      dream.file.write(dream.setting.path.."/data/data.json",tab)
      return b
    else
      local from
      local funcName
      if msg.isGroup then
        from = "群("..msg.fromGroup..")"
      else
        from = "私聊("..msg.fromQQ..")"
      end
      for k,v in pairs(dream.list("function")) do
        if v == func then
          funcName = k
          break
        end
      end
      funcName = funcName:match("^_G.(.+)$")
      dream.log("报错函数:"..funcName.."\n触发窗口:"..from.."\n触发人:"..msg.fromNick.."("..msg.fromQQ..")\n原消息:"..msg.fromMsg.."\n错误信息:\n"..dream.error(b,false),"error")
      dream.sendError("报错函数:"..funcName.."\n触发窗口:"..from.."\n触发人:"..msg.fromNick.."("..msg.fromQQ..")\n原消息:"..msg.fromMsg.."\n错误信息:\n"..dream.error(b,false))
    end
  end
  return key
end

dream.keyword = {}
dream.command = {}
dream.replace = {}

local function format_order(x)
  local map = {
    ["\\%["] = "%[",
    ["\\%]"] = "%]",
    ["\\,"] = "%,",
    ["\\:"] = "%:",
    ["\\#"] = "#"
  }
  for k,v in pairs(map) do
    x = x:gsub(v,k)
  end
  return x
end

local order_write_data = function(cmd_type,cmd,func)
  local path = dream.setting.path.."/data/"..cmd_type..".json"
  local tab = dream.file.read(path)
  if not dream.file.read(path) then
    tab = {}
  else
    tab = dream.json.decode(tab)
  end
  tab[cmd] = dream.search(func):sub(4,-1)
  tab = dream.json.encode(tab)
  dream.file.write(path,tab)
end

function dream.keyword.set(id,cmd,func,perm,isWhole)
  local key = dream.plugin.key(id,cmd,func,"keyword",perm,isWhole)
  order_write_data("keyword",cmd,func)
  msg_order[cmd] = key
end

function dream.command.set(id,cmd,func,perm,isWhole)
  local key = dream.plugin.key(id,cmd,func,"command",perm,isWhole)
  order_write_data("command",cmd,func)
  commands[cmd] = key
end

function dream.replace.set(id,cmd,func,perm,isWhole)
  local key = dream.plugin.key(id,cmd,func,"replace",perm,isWhole)
  order_write_data("replace",cmd,func)
  replaces[cmd] = key
end

-- 事件 --
dream.event = {}
-- 事件msg处理/封装
function dream.event.message(tab)
  local function text_mirai(str,i)
    local start
    local num = 0
    local isMirai = false
    while true do
      if i > #str then
        return nil
      end
      local res = str:sub(i,i+6)
      if isMirai then
        res = str:sub(i,i)
        if res == "]" then
          num = num - 1
        elseif res == "[" then
          num = num + 1
        end
        if num == 0 then
          return start,i
        end
      elseif isMirai == false and res == "[mirai:" then
        start = i
        num = num + 1
        isMirai = not isMirai
      end
      i = i + 1
    end
  end
  local msg = {}
  msg.sender = {
    id = tab.fromQQ,
    nick = tab.fromNick,
    jrrp = tab.fromJrrp,
    AtMe = tab.isAtMe
  }
  msg.group = {}
  if tab.isGroup then
    msg.group.id = tab.fromGroup
  end
  msg.message = {}
  local i = 1
  while true do
    if i > #tab.fromMsg then
      break
    elseif not text_mirai(tab.fromMsg,i) then
      msg.message[#msg.message+1] = {
        type = "text",
        txt = tab.fromMsg:sub(i,-1)
      }
      break
    else
      local r,v = text_mirai(tab.fromMsg,i)
      if r ~= i then
        msg.message[#msg.message+1] =     {
          type = "text",
          txt = tab.fromMsg:sub(i,r-1)
        }
      end
      msg.message[#msg.message+1] = {
        type = "mirai",
        txt = tab.fromMsg:sub(r,v):gsub(" ","")
      }
      i = v + 1
    end
  end
  local index = {}
  function index:send(str) -- 发送消息
    dream.api.sendMessage(str,tab)
  end
  function index:reply(str) -- 回复消息
    dream.api.sendMessage(str.."#{REPLY-"..tab.fromQQ.."}",tab)
  end
  function index:type() -- 消息类型
    if tab.isGroup then
      return "GroupMessage"
    else
      return "FriendMessage"
    end
  end
  function index:block() --阻塞后续插件运行
    local event = dream.file.read(dream.setting.path.."/data/event.json") or "{}"
    event = dream.json.decode(event)
    event.mode = true
    dream.file.write(dream.setting.path.."/data/event.json",dream.json.encode(event))
  end
  function index:getFriendsList()
    return dream.api.getFriendsList()
  end
  function index:getMembersList()
    if tab.isGroup then
      return dream.api.getMembersList(tab.fromGroup)
    end
    return {}
  end
  msg = setmetatable(msg,{__index = index})
  return msg
end

function dream.event.Listen(prior,Type,func)
  if Type ~= "GroupMessage" and Type ~= "FriendMessage" then
    return nil
  end
  local event = dream.file.read(dream.setting.path.."/data/event.json") or "{}"
  event = dream.json.decode(event)
  if event.mode == nil then
    event.mode = false
  end
  event[Type] = event[Type] or {}
  event[Type][#event[Type]+1] = {
    func = dream.search(func):sub(4,-1),
    prior = prior
  }
  event[Type] = table.sort(event[Type],"prior")
  dream.file.write(dream.setting.path.."/data/event.json",dream.json.encode(event))
end

function dream.event.loader(msg)
  local index
  if msg.isGroup then
    index = "GroupMessage"
  else
    index = "FriendMessage"
  end
  local event = dream.file.read(dream.setting.path.."/data/event.json") or "{}"
  event = dream.json.decode(event)
  if not event[index] then
    return nil
  end
  local tab = dream.event.message(msg)
  for i=#event[index],1,-1 do
    local a,b = pcall(dream.get(event[index][i]["func"]),tab)
    if not a then
      local from
      local funcName = event[index][i]["func"]
      if msg.isGroup then
        from = "群("..msg.fromGroup..")"
      else
        from = "私聊("..msg.fromQQ..")"
      end
      dream.log("报错函数:"..funcName.."\n触发窗口:"..from.."\n触发人:"..msg.fromNick.."("..msg.fromQQ..")\n原消息:"..msg.fromMsg.."\n错误信息:\n"..dream.error(b,false),"error")
      dream.sendError("报错函数:"..funcName.."\n触发窗口:"..from.."\n触发人:"..msg.fromNick.."("..msg.fromQQ..")\n原消息:"..msg.fromMsg.."\n错误信息:\n"..dream.error(b,false))
    end
    local res = dream.file.read(dream.setting.path.."/data/event.json") or "{}"
    res = dream.json.decode(res)
    if res.mode then -- 阻塞后续插件
      res.mode = false
      dream.file.write(dream.setting.path.."/data/event.json",dream.json.encode(res))
      break
    end
  end
end

-- 插件 --

-- 插件基本信息 --

-- 写插件基本信息
function dream.plugin.setSetting(id,key,value)
  local tab = dream.file.read(dream.setting.path.."/config/"..id.."/setting.json")
  if not tab then
    return false
  end
  tab = dream.json.decode(tab)
  tab[key] = value
  tab = dream.json.encode(tab)
  dream.file.write(dream.setting.path.."/config/"..id.."/setting.json",tab)
end

-- 读插件基本信息
function dream.plugin.getSetting(id,key)
  local tab = dream.file.read(dream.setting.path.."/config/"..id.."/setting.json")
  if not tab then
    return nil
  end
  tab = dream.json.decode(tab)
  if tab[key] ~= nil then
    return tab[key]
  else
    return nil
  end
end

-- 设置配置值
function dream.plugin.setConfig(id,key,value)
  local tab = dream.file.read(dream.setting.path.."/config/"..id.."/setting.json")
  if not tab then
    dream.execute("mkdir "..dream.setting.path.."/config/"..id)
    tab = {}
  else
    tab = dream.json.decode(tab)
  end
  if not tab.config then
    tab.config = {}
  end
  tab.config[key] = value
  tab = dream.json.encode(tab)
  dream.file.write(dream.setting.path.."/config/"..id.."/setting.json",tab)
end

-- 读取配置值
function dream.plugin.getConfig(id,key)
  local file = io.open(dream.setting.path.."/config/"..id.."/setting.json","r")
  if file == nil then
    return nil
  end
  local tab = file:read("*a")
  file:close()
  tab = dream.json.decode(tab)
  if tab.config == nil then
    return nil
  elseif tab.config[key] == nil then
    return nil
  else
    return tab.config[key]
  end
end

-- 删除配置
function dream.plugin.removeConfig(id,key)
  local file = io.open(dream.setting.path.."/config/"..id.."/setting.json","r")
  if file == nil then
    return nil
  end
  local tab = file:read("*a")
  file:close()
  tab = dream.json.decode(tab)
  if tab.config[key] ~= nil then
    tab.config[key] = nil
  end
  tab = dream.json.encode(tab)
  file = io.open(dream.setting.path.."/config/"..id.."/setting.json","w")
  file:write(tab)
  file:close()
end

-- 初始化部分 --
local function init()
  local file = io.open(dream.setting.path.."/data/setting.json","r")
  local key = math.random(1,9)..math.random(1,9)..math.random(1,9)..math.random(1,9)..math.random(1,9)..math.random(1,9)
  local time = os.time()
  if file == nil then
    local tab = {}
    tab["key"] = key
    tab["time"] = time
    tab = dream.json.encode(tab)
    file = io.open(dream.setting.path.."/data/setting.json","w")
    file:write(tab)
    file:close()
    dream.log("检测到骰娘["..dream.nick.."]未拥有"..dream.masterNick.."，自动生成密钥进行"..dream.masterNick.."授权保护")
    dream.log("Key:"..key)
  else
    local tab = file:read("*a")
    file:close()
    tab = dream.json.decode(tab)
    tab["key"] = key
    tab["time"] = time
    tab = dream.json.encode(tab)
    file = io.open(dream.setting.path.."/data/setting.json","w")
    file:write(tab)
    file:close()
    dream.log("检测到骰娘["..dream.nick.."]已拥有"..dream.masterNick.."，自动生成密钥进行"..dream.masterNick.."授权保护")
    dream.log("Key:"..key)
  end
end

local function loader()
  dream.execute("mkdir "..dream.setting.path.."/loader")
  local path = dream.setting.path.."/loader"
  local f = dream.execute("ls "..path)
  if f then
    f = dream.string.part(f,"\n")
    for i=1,#f do
      local a,b = loadfile(path.."/"..f[i])
      if a then
        a()
        local n = f[i]:match("(.+)%..+$") or f[i]
        dream.orderLoader[n] = {}
        dream.log("插件加载器["..n.."]导入成功√")
      else
        local n = f[i]:match("(.+)%..+$") or f[i]
        dream.log("导入指令加载器["..n.."]失败！错误信息: "..b)
        dream.sendError("导入指令加载器["..n.."]失败！错误信息: "..b)
      end
    end
  end
end

-- 插件导入
local function setSetting(setting)
  if setting["id"] == nil then
    dream.sendError("请先配置id！")
    return
  end
  local setting_ = {"id","help","version","author","mode"}
  local bool
  local tab = {}
  for k,v in pairs(setting_) do
    if setting[v] == nil then
      bool = false
      dream.sendError("插件["..setting["id"].."]配置项 "..v.." 不存在！")
      break
    else
      if v == "version" then
        if type(setting[v]) ~= "string" then
          tab[v] = dream.tostring(setting[v])
        else
          tab[v] = setting[v]
        end
      else
        tab[v] = setting[v]
      end
    end
  end
  if bool == false then
    dream.sendError("插件["..setting["id"].."]有配置项不存在或不正确，故dream终止插件导入")
    error()
  end
  dream.execute("mkdir "..dream.setting.path.."/config/"..setting["id"])
  local file = io.open(dream.setting.path.."/config/"..setting["id"].."/setting.json","r")
  local config
  if file == nil then
    tab = dream.json.encode(tab)
  else
    config = dream.json.decode(file:read("*a"))
    file:close()
    for k,v in pairs(tab) do
      config[k] = tab[k]
    end
    config["version"] = dream.tostring(tab["version"])
    tab = dream.json.encode(config)
  end
  file = io.open(dream.setting.path.."/config/"..setting["id"].."/setting.json","w")
  file:write(tab)
  file:close()
end

local function PluginLoader()
  dream.log("尝试导入"..dream.setting.path.."/plugin目录下的所有lua文件…")
  dream.execute("rm "..dream.setting.path.."/data/command.json")
  dream.execute("rm "..dream.setting.path.."/data/keyword.json")
  dream.execute("rm "..dream.setting.path.."/data/replace.json")
  dream.execute("rm "..dream.setting.path.."/data/event.json")
  dream.execute("rm "..dream.setting.path.."/data/system.json")
  local list = dream.execute("ls "..dream.setting.path.."/plugin")
  if list == false then
    dream.log("未检测到任何插件","PluginLoader")
    dream.log("正在自动退出…","PluginLoader")
    dream.sendMaster(os.date("%Y-%m-%d %H:%M:%S").."\n"..dream.version.."\n插件载入完毕√\n共加载了0个插件")
    return
  end
  list = dream.string.part(list,"\n")
  local num = 0
  local num_true = 0
  local num_false = 0
  local plugin_list = {}
  local tab = {}
  for i=1,#list do
    local line = list[i]
    local rawline = line
    local line = line:match("(.+)%..+") or line
    log = function(str)
      print("[DreamPlugin]./"..line..":"..str)
    end
    num = num + 1
    local a,b = loadfile(dream.setting.path.."/plugin/"..rawline)
    if a then
      a,b = pcall(a)
      if not a then
        b = dream.error(b,false)
        num_false = num_false + 1
        dream.log("./"..line..":failed to load\n"..b,"PluginLoader")
        dream.sendError("./"..line..":failed to load\n"..b)
        tab[#tab+1] = rawline
      elseif b ~= nil then
        num_true = num_true + 1
        setSetting(b)
        plugin_list[#plugin_list+1] = b.id
        dream.log("./"..line..": Plugin loaded","PluginLoader")
      elseif b == nil then
        num_true = num_true + 1
        dream.log("./"..line..": not Plugin config","PluginLoader")
      end
    else
      b = dream.error(b,false)
      num_false = num_false + 1
      dream.log("./"..line..":failed to load\n"..b,"PluginLoader")
      dream.sendError("./"..line..":failed to load\n"..b)
      tab[#tab+1] = rawline
    end
  end
  local list = dream.string.part(dream.execute("ls "..dream.setting.path.."/config"),"\n")
  for i=1,#list do
    for n=1,#plugin_list do
      if list[i] == plugin_list[n] then
        break
      elseif n == #plugin_list then
        dream.execute("rm -r "..dream.setting.path.."/config/"..list[i])
      end
    end
  end
  local function x()
    if tab[1] then
      local txt
      for i=1,#tab do
        if not txt then
          txt = tab[i]
        else
          txt = txt.."\n"..tab[i]
        end
      end
      return "\n"..txt
    else
      return ""
    end
  end
  dream.sendMaster(os.date("%Y-%m-%d %H:%M:%S").."\n"..dream.version.."\n插件载入完毕√\n共载入插件"..num.."个\n载入成功"..num_true.."个\n载入失败"..num_false.."个"..x())
end

local face = [[惊讶=[mirai:face:0]
撇嘴=[mirai:face:1]
色=[mirai:face:2]
发呆=[mirai:face:3]
得意=[mirai:face:4]
流泪=[mirai:face:5]
害羞=[mirai:face:6]
闭嘴=[mirai:face:7]
睡=[mirai:face:8]
大哭=[mirai:face:9]
尴尬=[mirai:face:10]
发怒=[mirai:face:11]
调皮=[mirai:face:12]
呲牙=[mirai:face:13]
微笑=[mirai:face:14]
难过=[mirai:face:15]
酷=[mirai:face:16]
抓狂=[mirai:face:18]
吐=[mirai:face:19]
偷笑=[mirai:face:20]
可爱=[mirai:face:21]
白眼=[mirai:face:22]
傲慢=[mirai:face:23]
饥饿=[mirai:face:24]
困=[mirai:face:25]
惊恐=[mirai:face:26]
流汗=[mirai:face:27]
憨笑=[mirai:face:28]
悠闲=[mirai:face:29]
奋斗=[mirai:face:30]
咒骂=[mirai:face:31]
疑问=[mirai:face:32]
嘘=[mirai:face:33]
晕=[mirai:face:34]
折磨=[mirai:face:35]
衰=[mirai:face:36]
骷髅=[mirai:face:37]
敲打=[mirai:face:38]
再见=[mirai:face:39]
发抖=[mirai:face:41]
爱情=[mirai:face:42]
跳跳=[mirai:face:43]
猪头=[mirai:face:46]
拥抱=[mirai:face:49]
蛋糕=[mirai:face:53]
闪电=[mirai:face:54]
炸弹=[mirai:face:55]
刀=[mirai:face:56]
足球=[mirai:face:57]
便便=[mirai:face:59]
咖啡=[mirai:face:60]
饭=[mirai:face:61]
玫瑰=[mirai:face:63]
凋谢=[mirai:face:64]
爱心=[mirai:face:66]
心碎=[mirai:face:67]
礼物=[mirai:face:69]
太阳=[mirai:face:74]
月亮=[mirai:face:75]
赞=[mirai:face:76]
踩=[mirai:face:77]
握手=[mirai:face:78]
胜利=[mirai:face:79]
飞吻=[mirai:face:85]
怄火=[mirai:face:86]
西瓜=[mirai:face:89]
冷汗=[mirai:face:96]
擦汗=[mirai:face:97]
抠鼻=[mirai:face:98]
鼓掌=[mirai:face:99]
糗大了=[mirai:face:100]
坏笑=[mirai:face:101]
左哼哼=[mirai:face:102]
右哼哼=[mirai:face:103]
哈欠=[mirai:face:104]
鄙视=[mirai:face:105]
委屈=[mirai:face:106]
快哭了=[mirai:face:107]
阴险=[mirai:face:108]
亲亲=[mirai:face:109]
左亲亲=[mirai:face:109]
吓=[mirai:face:110]
可怜=[mirai:face:111]
菜刀=[mirai:face:112]
啤酒=[mirai:face:113]
篮球=[mirai:face:114]
乒乓=[mirai:face:115]
示爱=[mirai:face:116]
瓢虫=[mirai:face:117]
抱拳=[mirai:face:118]
勾引=[mirai:face:119]
拳头=[mirai:face:120]
差劲=[mirai:face:121]
爱你=[mirai:face:122]
不=[mirai:face:123]
好=[mirai:face:124]
转圈=[mirai:face:125]
磕头=[mirai:face:126]
回头=[mirai:face:127]
跳绳=[mirai:face:128]
挥手=[mirai:face:129]
激动=[mirai:face:130]
街舞=[mirai:face:131]
献吻=[mirai:face:132]
左太极=[mirai:face:133]
右太极=[mirai:face:134]
双喜=[mirai:face:136]
鞭炮=[mirai:face:137]
灯笼=[mirai:face:138]
K歌=[mirai:face:140]
喝彩=[mirai:face:144]
祈祷=[mirai:face:145]
爆筋=[mirai:face:146]
棒棒糖=[mirai:face:147]
喝奶=[mirai:face:148]
飞机=[mirai:face:151]
钞票=[mirai:face:158]
药=[mirai:face:168]
手枪=[mirai:face:169]
茶=[mirai:face:171]
眨眼睛=[mirai:face:172]
泪奔=[mirai:face:173]
无奈=[mirai:face:174]
卖萌=[mirai:face:175]
小纠结=[mirai:face:176]
喷血=[mirai:face:177]
斜眼笑=[mirai:face:178]
doge=[mirai:face:179]
惊喜=[mirai:face:180]
骚扰=[mirai:face:181]
笑哭=[mirai:face:182]
我最美=[mirai:face:183]
河蟹=[mirai:face:184]
羊驼=[mirai:face:185]
幽灵=[mirai:face:187]
蛋=[mirai:face:188]
菊花=[mirai:face:190]
红包=[mirai:face:192]
大笑=[mirai:face:193]
不开心=[mirai:face:194]
冷漠=[mirai:face:197]
呃=[mirai:face:198]
好棒=[mirai:face:199]
拜托=[mirai:face:200]
点赞=[mirai:face:201]
无聊=[mirai:face:202]
托脸=[mirai:face:203]
吃=[mirai:face:204]
送花=[mirai:face:205]
害怕=[mirai:face:206]
花痴=[mirai:face:207]
小样儿=[mirai:face:208]
飙泪=[mirai:face:210]
我不看=[mirai:face:211]
托腮=[mirai:face:212]
啵啵=[mirai:face:214]
糊脸=[mirai:face:215]
拍头=[mirai:face:216]
扯一扯=[mirai:face:217]
舔一舔=[mirai:face:218]
蹭一蹭=[mirai:face:219]
拽炸天=[mirai:face:220]
顶呱呱=[mirai:face:221]
抱抱=[mirai:face:222]
暴击=[mirai:face:223]
开枪=[mirai:face:224]
撩一撩=[mirai:face:225]
拍桌=[mirai:face:226]
拍手=[mirai:face:227]
恭喜=[mirai:face:228]
干杯=[mirai:face:229]
嘲讽=[mirai:face:230]
哼=[mirai:face:231]
佛系=[mirai:face:232]
掐一掐=[mirai:face:233]
惊呆=[mirai:face:234]
颤抖=[mirai:face:235]
啃头=[mirai:face:236]
偷看=[mirai:face:237]
扇脸=[mirai:face:238]
原谅=[mirai:face:239]
喷脸=[mirai:face:240]
生日快乐=[mirai:face:241]
头撞击=[mirai:face:242]
甩头=[mirai:face:243]
扔狗=[mirai:face:244]
加油必胜=[mirai:face:245]
加油抱抱=[mirai:face:246]
口罩护体=[mirai:face:247]
搬砖中=[mirai:face:260]
忙到飞起=[mirai:face:261]
脑阔疼=[mirai:face:262]
沧桑=[mirai:face:263]
捂脸=[mirai:face:264]
辣眼睛=[mirai:face:265]
哦哟=[mirai:face:266]
头秃=[mirai:face:267]
问号脸=[mirai:face:268]
暗中观察=[mirai:face:269]
emm=[mirai:face:270]
吃瓜=[mirai:face:271]
呵呵哒=[mirai:face:272]
我酸了=[mirai:face:273]
太南了=[mirai:face:274]
辣椒酱=[mirai:face:276]
汪汪=[mirai:face:277]
汗=[mirai:face:278]
打脸=[mirai:face:279]
击掌=[mirai:face:280]
无眼笑=[mirai:face:281]
敬礼=[mirai:face:282]
狂笑=[mirai:face:283]
面无表情=[mirai:face:284]
摸鱼=[mirai:face:285]
魔鬼笑=[mirai:face:286]
哦=[mirai:face:287]
请=[mirai:face:288]
睁眼=[mirai:face:289]
敲开心=[mirai:face:290]
震惊=[mirai:face:291]
让我康康=[mirai:face:292]
摸锦鲤=[mirai:face:293]
期待=[mirai:face:294]
拿到红包=[mirai:face:295]
真好=[mirai:face:296]
拜谢=[mirai:face:297]
元宝=[mirai:face:298]
牛啊=[mirai:face:299]
胖三斤=[mirai:face:300]
好闪=[mirai:face:301]
左拜年=[mirai:face:302]
右拜年=[mirai:face:303]
红包包=[mirai:face:304]
右亲亲=[mirai:face:305]
牛气冲天=[mirai:face:306]
喵喵=[mirai:face:307]
求红包=[mirai:face:308]
谢红包=[mirai:face:309]
新年烟花=[mirai:face:310]
打call=[mirai:face:311]
变形=[mirai:face:312]
嗑到了=[mirai:face:313]
仔细分析=[mirai:face:314]
加油=[mirai:face:315]
我没事=[mirai:face:316]
菜狗=[mirai:face:317]
崇拜=[mirai:face:318]
比心=[mirai:face:319]
庆祝=[mirai:face:320]
老色痞=[mirai:face:321]
拒绝=[mirai:face:322]
嫌弃=[mirai:face:323]
吃糖=[mirai:face:324]
惊吓=[mirai:face:325]
生气=[mirai:face:326]
加一=[mirai:face:327]
错号=[mirai:face:328]
对号=[mirai:face:329]
完成=[mirai:face:330]
明白=[mirai:face:331]
举牌牌=[mirai:face:332]
烟花=[mirai:face:333]
虎虎生威=[mirai:face:334]
豹富=[mirai:face:336]
花朵脸=[mirai:face:337]
我想开了=[mirai:face:338]
舔屏=[mirai:face:339]
热化了=[mirai:face:340]
打招呼=[mirai:face:341]
酸Q=[mirai:face:342]
我方了=[mirai:face:343]
大怨种=[mirai:face:344]
红包多多=[mirai:face:345]
你真棒棒=[mirai:face:346]
大展宏兔=[mirai:face:347]
福萝卜=[mirai:face:348] ]]
local file = io.open(dream.setting.path.."/module/face.module","w")
file:write(face)
file:close()

local poke = [[戳一戳=[mirai:poke:,1,-1]
比心=[mirai:poke:,2,-1]
点赞=[mirai:poke:,3,-1]
心碎=[mirai:poke:,4,-1]
666=[mirai:poke:,5,-1]
放大招=[mirai:poke:,6,-1]
宝贝球=[mirai:poke:,126,2011]
玫瑰花=[mirai:poke:,126,2007]
召唤术=[mirai:poke:,126,2006]
让你皮=[mirai:poke:,126,2009]
结印=[mirai:poke:,126,2005]
手雷=[mirai:poke:,126,2004]
勾引=[mirai:poke:,126,2003]
抓一下=[mirai:poke:,126,2001]
碎屏=[mirai:poke:,126,2002]
敲门=[mirai:poke:,126,2000] ]]
file = io.open(dream.setting.path.."/module/poke.module","w")
file:write(poke)
file:close()

local superface=[[流泪=[mirai:superface:5,16,1,]
打call=[mirai:superface:311,1,1,]
变形=[mirai:superface:312,2,1,]
仔细分析=[mirai:superface:314,4,1,]
菜汪=[mirai:superface:317,7,1,]
崇拜=[mirai:superface:318,8,1,]
比心=[mirai:superface:319,9,1]
庆祝=[mirai:superface:320,10,1,]
吃糖=[mirai:superface:324,12,1,]
惊吓=[mirai:superface:325,14,1,]
花朵脸=[mirai:superface:337,22,1,]
我想开了=[mirai:superface:338,20,1,]
舔屏=[mirai:superface:339,21,1,]
打招呼=[mirai:superface:341,24,1]
酸Q=[mirai:superface:342,26,1,]
我方了=[mirai:superface:343,27,1,]
大怨种=[mirai:superface:344,28,1,]
红包多多=[mirai:superface:345,29,1,]
你真棒棒=[mirai:superface:346,25,1,]
戳一戳=[mirai:superface:181,37,1,]
太阳=[mirai:superface:74,35,1,]
月亮=[mirai:superface:75,36,1,]
敲敲=[mirai:superface:351,30,1,]
坚强=[mirai:superface:349,32,1,]
贴贴=[mirai:superface:350,31,1,]
略略略=[mirai:superface:395,41,1,]
篮球=[mirai:superface:114,31,2,1]
生气=[mirai:superface:326,15,1,]
蛋糕=[mirai:superface:53,17,1,]
鞭炮=[mirai:superface:137,18,1,]
烟花=[mirai:superface:333,19,1,]
接龙=[mirai:superface:392,28,3,0] ]]
file = io.open(dream.setting.path.."/module/superface.module","w")
file:write(superface)
file:close()

init()
PluginLoader()
setSetting({
  id = "Plugin",
  version = "∞",
  help = [[Dream快捷指令写入]],
  author = "任何人",
  mode = true
})
setSetting({
  id = "Event",
  version = "∞",
  help = [[Dream事件监听器]],
  author = "筑梦师V2.0",
  mode = true
})
dream.keyword.set("Event","",dream.event.loader)

endTime = os.clock()
local time = endTime-startTime
time = tostring(time):gsub("%.","",1)
dream.sendMaster(os.date("%Y-%m-%d %H:%M:%S").." "..dream.nick.."初始化完成，用时"..time.."毫秒")