--[[
  * Dream官方插件
  * 作者：筑梦师V2.0
  * 最后更新：2024-07-19
  * master认证
  * bot指令重定向
  * 设置通知窗口
  * 群插件开关
  * 关于更新的help
  * 插件列表
  * 插件基本信息
  * Send指令美化
  * 临时全局禁用/启用
  * help指令兼容，可查看插件帮助文档
  * group指令兼容溯洄
  * black list指令优化
]]

command = {}

-- 词条配置部分 --
dream.bot = "试作型" 
-- bot指令在前面加的东西

command.OnStr = "true" 
-- 对群内骰子开启的称呼

command.OffStr = "false" 
-- 对群内骰子关闭的称呼

command.DreamBotStr_Group = "{DiceName}目前供职于{groups}个群\n在其中的{Onnum}个群中处于开启状态\n在其中的{Offnum}个群中处于关闭状态\n在本群是否开启：{OnOrOff}" 
-- 在群发送bot的词条

command.DreamBotStr_Empty = "{DiceName}目前供职于{groups}个群\n在其中的{Onnum}个群中处于开启状态\n在其中的{Offnum}个群中处于关闭状态" -- 在私聊发送bot的词条

-- {Onnum}和{Offnum}在command.DreamBotStr_Empty和command.DreamBotStr_Group项目中随意使用

-- {groups}是仅限于bot词条的特殊函数：群数量
-- {DiceName}是全局特殊函数：骰娘名称
-- {Offnum} or {Onnum}：群内本骰娘关闭的群数量和群内本骰娘开启的群数量

-- 函数注册及指令注册 --

function command.dream_bot(msg)
  local dir = dream.api.agreement(dream.api.getDiceQQ())
  local i = dream.execute("ls "..dir.."/contacts/groups")
  local file = io.open(dream.setting.path.."/list","w")
  file:write(i)
  file:close()
  file = io.open(dream.setting.path.."/list","r")
  local groups = 0
  for k,v in file:lines() do
    groups = groups + 1
  end
  dream.execute("rm "..dream.setting.path.."/list")
  local _,Offnum = sdk.readSystemConfig("WHITE_LIST"):gsub("#","")
  Onnum = groups - Offnum
  local data = {}
  data[true] = command.OnStr
  data[false] = command.OffStr
  local bot
  if dream.bot == nil then
    bot = ""
  else
    bot = dream.bot
  end
  if msg.isGroup then
    dream.api.sendMessage(bot..dream.version.."\n"..command.DreamBotStr_Group:gsub("{groups}",groups):gsub("{Offnum}",Offnum):gsub("{Onnum}",Onnum):gsub("{DiceName}",msg.fromDiceName):gsub("{OnOrOff}",data[dream.api.thisGroupisOn(msg.fromGroup)]),msg) -- 调用指令执行接口强行发送bot内容，无视群内骰子是否开启
  else
    dream.api.sendMessage(bot..dream.version.."\n"..command.DreamBotStr_Empty:gsub("{groups}",groups):gsub("{Offnum}",Offnum):gsub("{Onnum}",Onnum):gsub("{DiceName}",msg.fromDiceName),msg)
  end
end
dream.replace.set("command","dream bot",command.dream_bot)

function command.bot(msg)
  if msg.fromParams ~= nil then
    msg.fromParams = msg.fromParams:gsub(" ","") -- 替换空格
  end
  if msg.fromParams == "on" then
    return "bot on"
  elseif msg.fromParams == "off" then
    return "bot off"
  elseif msg.fromParams == "exit" then
    return "dismiss"
  elseif msg.fromParams == "" then
    dream.api.eventMsg("replace","dream bot",msg)
    return "指令重定向完毕[bot]"
  elseif msg.fromParams == dream.api.getDiceQQ() then
    dream.api.eventMsg("dream bot","replace",msg)
    return "指令重定向完毕[bot]"
  elseif msg.fromParams == dream.api.getDiceQQ():sub(#dream.api.getDiceQQ()-3,-1) then
    dream.api.eventMsg("dream bot","replace",msg)
    return "指令重定向完毕[bot]" 
  else
    return "指令重定向完毕[bot]" 
  end
end
dream.replace.set("command","bot",command.bot)

function command.ZhaoDiceBot(msg)
  return "bot"
end
dream.replace.set("command","zhaodice bot",command.ZhaoDiceBot)

function command.about(msg)
  dream.api.eventMsg("dream bot","replace",msg)
  return "指令重定向完毕[about]" 
end
dream.replace.set("command","about",command.about)

function command.robot(msg)
  dream.api.eventMsg("dream bot","replace",msg)
  return "指令重定向完毕[robot]" 
end
dream.replace.set("command","robot",command.robot)

function command.master(msg)
  local key = msg.fromParams:gsub(" ","")
  if key == "delete" then
    local f = dream.file.read(dream.setting.path.."/data/setting.json")
    if not f then
      return msg.fromMsg
    end
    f = dream.json.decode(f)
    for i=1,#f.admin do
      if f.admin[i] == msg.fromQQ then
        table.remove(f.admin,i)
        dream.sendMaster(msg.fromNick.."("..msg.fromQQ..")已放弃["..msg.fromDiceName.."]的["..dream.masterNick.."]权限…")
      end
    end
    f = dream.json.encode(f)
    dream.file.write(dream.setting.path.."/data/setting.json",f)
    return "指令重定向完毕[master]"
  end
  if not dream.math.isNumber(key) then
    return msg.fromMsg
  end
  local file = io.open(dream.setting.path.."/data/setting.json","r")
  local tab
  if file ~= nil then
    tab = file:read("*a")
    file:close()
    tab = dream.json.decode(tab)
    if tab["admin"] then
      for i=1,#tab["admin"] do
        if tab["admin"][i] == msg.fromQQ then
          dream.api.sendMessage("您已经认证成为"..dream.nick.."的"..dream.masterNick.."！",msg)
          return "指令重定向完毕[master]"
        end
      end
    end
  end
  if tab["key"] == key then
    if tab["admin"] == nil then
      tab["admin"] = {}
    end
    tab["admin"][#tab["admin"]+1] = msg.fromQQ
    tab["key"] = math.random(1,9)..math.random(1,9)..math.random(1,9)..math.random(1,9)..math.random(1,9)..math.random(1,9)
    while tab["key"] == key do
      tab["key"] = math.random(1,9)..math.random(1,9)..math.random(1,9)..math.random(1,9)..math.random(1,9)..math.random(1,9)
    end
    dream.log("密钥["..key.."]已废除，新密钥为["..tab["key"].."]")
    tab = dream.json.encode(tab)
    local file = io.open(dream.setting.path.."/data/setting.json","w")
    file:write(tab)
    file:close()
    dream.sendMaster("已自动更新密钥，具体请前往控制台查看")
    dream.sendMaster(msg.fromNick.."("..msg.fromQQ..")通过了密钥认证，荣升为Master√")
    dream.api.sendMessage("认证成功√你就是"..dream.nick.."的"..dream.masterNick.."√",msg)
    dream.api.sendMessage("具体教程已移动至官方群，此处仅提供一个网址用于访问星骰论坛：\nhttps://astral.snoweven.com/\nDream是基于原生AstralDice的框架，由Lua编写而成。但请注意，AstralDice的Lua由java编写而成，可能与标准的CLua略有差异！\nGithub：https://github.com/zmsv/Dream\n开发者：筑梦师V2.0(2967713804)&乐某人(1877942599)",msg)
    return "指令重定向完毕[master]"
  else
    return msg.fromMsg
  end
end
dream.replace.set("command","master",command.master)

function command.dream_system(msg)
  if not dream.deter.master(msg.fromQQ) then
    return "指令重定向完毕[system]"
  end
  local i = msg.fromParams:gsub(" ","")
  if i:sub(1,4) == "load" then
    sdk.system.load()
    dream.api.sendMessage(msg.fromDiceName.."重载完毕√",msg)
    local notice = dream.api.getNotice()
    local b
    for i=1,#notice do
      if notice[i] == msg.fromGroup then
        b = true
        break
      end
    end
    if not b then
      dream.sendMaster(msg.fromNick.."["..dream.masterNick.."]重载【"..msg.fromDiceName.."】完毕√")
    end
    return "指令重定向完毕[system]"
  elseif i:sub(1,6) == "reload" then
    sdk.system.reload()
    dream.api.sendMessage(msg.fromDiceName.."重启完毕√",msg)
    dream.execute("rm -r "..dream.api.agreement(dream.api.getDiceQQ()).."/contacts")
    return "指令重定向完毕[system]"
  elseif i == "state" then
    local file = io.open(dream.setting.path.."/data/setting.json","r")
    local tab = file:read("*a")
    file:close()
    tab = dream.json.decode(tab)
    local time = tab.time
    time = os.time() - time
    local hour = dream.math.getInt(time / 3600)
    local min = dream.math.getInt((time - hour*3600) / 60)
    local sec = time - hour*3600 - min*60
    collectgarbage("collect")
    dream.api.sendMessage("本地时间:"..os.date("%Y-%m-%d %H:%M:%S").."\n内存占用:"..dream.math.topercent(dream.system.Memory("used"),dream.system.Memory("total")).."\nDream版本:"..dream._VERSION.."\n距上次重载/重启时长:"..hour.."时"..min.."分"..sec.."秒",msg)
    return "指令重定向完毕[system]"
  else
    return msg.fromMsg
  end
end
dream.replace.set("command","system",command.dream_system)

function command.dream_admin_add_notice(msg)
  local groups = dream.api.getNotice()
  local add = msg.fromParams:match("([0-9]+)")
  local file
  local tab
  if not groups[1] then
    file = io.open(dream.setting.path.."/data/setting.json","r")
    if not file then
      tab = {}
      tab.notice = {}
      tab.notice[#tab.notice+1] = add
      tab = dream.json.encode(tab)
      file = io.open(dream.setting.path.."/data/setting.json","w")
      file:write(tab)
      file:close()
      dream.sendMaster(dream.masterNick..msg.fromNick.."("..msg.fromQQ..")将群"..add.."设为通知窗口")
      return "已将群"..add.."设为通知窗口√"
    else
      tab = file:read("*a")
      file:close()
      tab = dream.json.decode(tab)
      tab.notice = {}
      tab.notice[#tab.notice+1] = add
      tab = dream.json.encode(tab)
      file = io.open(dream.setting.path.."/data/setting.json","w")
      file:write(tab)
      file:close()
      dream.sendMaster(dream.masterNick..msg.fromNick.."("..msg.fromQQ..")将群"..add.."设为通知窗口")
      return "已将群"..add.."设为通知窗口√"
    end
  else
    for i=1,#groups do
      if groups[i] == add then
        return "您已将此群("..add..")设为通知窗口！"
      end
    end
    file = io.open(dream.setting.path.."/data/setting.json","r")
    tab = file:read("*a")
    file:close()
    tab = dream.json.decode(tab)
    tab.notice[#tab.notice+1] = add
    tab = dream.json.encode(tab)
    file = io.open(dream.setting.path.."/data/setting.json","w")
    file:write(tab)
    file:close()
    dream.sendMaster(dream.masterNick..msg.fromNick.."("..msg.fromQQ..")将群"..add.."设为通知窗口")
    return "已将群"..add.."设为通知窗口√"
  end
end
dream.command.set("command","dream notice +",command.dream_admin_add_notice,true)

function command.dream_admin_delete_notice(msg)
  local groups = dream.api.getNotice()
  local delete = msg.fromParams:match("([0-9]+)")
  local file
  local tab
  local num
  if not groups[1] then
    return "通知窗口"..delete.."不存在×"
  else
    file = io.open(dream.setting.path.."/data/setting.json","r")
    tab = file:read("*a")
    file:close()
    tab = dream.json.decode(tab)
    for i=1,#tab.notice do
      if tab.notice[i] == delete then
        table.remove(tab.notice,i)
        tab = dream.json.encode(tab)
        file = io.open(dream.setting.path.."/data/setting.json","w")
        file:write(tab)
        file:close()
        dream.sendMaster(dream.masterNick..msg.fromNick.."("..msg.fromQQ..")将通知窗口"..delete.."移出")
        return "已移出通知窗口"..delete.."√"
      end
    end
  end
  return "通知窗口"..delete.."不存在×"
end
dream.command.set("command","dream notice -",command.dream_admin_delete_notice,true)

function command.dream_plugin_state(msg)
  if not msg.isGroup then
    return "此指令只有群聊方可使用"
  elseif ((not dream.api.permission(msg.fromGroup,msg.fromQQ)) or dream.deter.master(msg.fromQQ)) == false then
    return "此指令只有"..dream.masterNick.."方可使用"
  end
  local tbl = {
    ["on"] = "开启",
    ["off"] = "关闭"
  }
  local tab = dream.string.part(msg.fromParams," ")
  if not tab[1] then
    return "缺少必要参数[插件ID]"
  elseif not tab[2] then
    return "缺少必要参数[状态码]"
  end
  local id,i,group = tab[1],tab[2],tab[3]
  if i ~= "on" and i ~= "off" then
    i = "off"
  end
  if dream.math.isNumber(group) then
    if not dream.deter.master(msg.fromQQ) then
      return "权限不足！你不是"..msg.fromDiceName.."的"..dream.masterNick.."！"
    end
    dream.plugin.setConfig(id,group,i)
    dream.sendMaster(msg.fromNick.."["..dream.masterNick.."]已"..tbl[i].."插件["..id.."]对群["..group.."]的响应")
    return "修改群["..group.."]插件["..id.."]开关："..i
  end
  dream.plugin.setConfig(id,msg.fromGroup,i)
  return "修改群["..msg.fromGroup.."]插件["..id.."]开关："..i
end
dream.command.set("command","dream plugin state ",command.dream_plugin_state)

function command.dream_plugin_list(msg)
  local list = dream.execute("ls "..dream.setting.path.."/config")
  if not list then
    return "当前未加载任何插件"
  end
  list = dream.string.part(list,"\n")
  for i=1,#list do
    if list[i] == "Plugin" then
      table.remove(list,i)
    elseif list[i] == "Event" then
      table.remove(list,i)
    end
  end
  local txt
  local tab = {
    [true] = "enable",
    [false] = "disable"
  }
  for i=1,#list do
    local id = list[i]
    txt = (txt or "")
    if txt ~= "" then
      txt = txt.."\n"
    end
    txt = txt.."["..i.."] - "..id.."["..tab[dream.plugin.getSetting(id,"mode")].."] v"..dream.plugin.getSetting(id,"version").."\nauthor: "..dream.plugin.getSetting(id,"author").."\nGroupState: "..(dream.plugin.getConfig(id,msg.fromGroup) or "on")
  end
  return "当前共载入了"..#list.."个插件:\n"..txt
end
dream.command.set("command","dream plugin list",command.dream_plugin_list)

function command.dream_plugin_help(msg)
  local Msg
  if msg.fromParams then
    Msg = msg.fromParams:gsub(" ","")
  else
    return ""
  end
  local list = dream.execute("ls "..dream.setting.path.."/config")
  if not list then
    return "当前未加载任何插件！"
  end
  local plugin_list = dream.string.part(list,"\n")
  for i=1,#plugin_list do
    if Msg == plugin_list[i] then
      local help = ""
      if type(dream.plugin.getSetting(plugin_list[i],"help")) == "table" then
        for k,v in pairs(dream.plugin.getSetting(plugin_list[i],"help")) do
          help = help.."\n"..k.."："..v
        end
      else
        help = dream.plugin.getSetting(plugin_list[i],"help")
      end
      return "plugin："..Msg.."\nauthor："..dream.plugin.getSetting(plugin_list[i],"author").."\nversion："..dream.plugin.getSetting(plugin_list[i],"version").."\nhelp："..help
    end
  end
  return "未载入插件["..Msg.."]"
end
dream.command.set("command","dream plugin help",command.dream_plugin_help,true)

function command.send(msg)
  local from
  if msg.isGroup then
    from = "Group"
  else
    from = "Empty"
  end
  local MSG = msg.fromParams
  local MSG = "类型：Send\n窗口："..from.."\n发送人："..msg.fromNick.."("..msg.fromQQ..")\n消息：\n"..MSG
  dream.sendMaster(MSG,msg)
  return "已发送消息至Master√"
end
dream.command.set("command","send",command.send)

function command.setAble(msg)
  local tab = dream.string.part(msg.fromParams," ")
  local tbl = {
    ["true"] = true,
    ["false"] = false
  }
  if #tab < 2 then
    return "缺失参数"
  elseif tbl[tab[2]] == nil then
    return "不正确的参数["..tab[2].."]"
  end
  local list = dream.api.getPluginsList()
  for i=1,#list do
    if tab[1] == list[i] then
      break
    elseif i == #list then
      return "不正确的插件ID["..tab[1].."]"
    end
  end
  tab[2] = tbl[tab[2]]
  dream.plugin.setSetting(tab[1],"mode",tab[2])
  local able = {
    [true] = "启用",
    [false] = "禁用"
  }
  dream.sendMaster(msg.fromNick.."["..dream.masterNick.."]已临时修改插件全局开关，插件["..tab[1].."]已"..able[tab[2]])
  return "临时修改插件全局开关完毕，插件["..tab[1].."]已"..able[tab[2]]
end
dream.command.set("command","dream plugin able",command.setAble,true)

function command.help(msg)
  local i = msg.fromParams
  if i:sub(1,1) == " " then
    i = i:sub(2,-1)
  elseif i == "" then
    return "help"
  end
  if dream.plugin.getSetting(i,"help") then
    dream.api.sendMessage(dream.plugin.getSetting(i,"help"),msg)
    return "指令重定向完毕[help]"
  end
  return msg.fromMsg
end
dream.replace.set("command","help",command.help)

function command.group(msg)
  if not msg.isGroup then
    dream.api.sendMessage("群管理命令\n查询潜水群成员:\ngroup diver\n设置群员名片:\ngroup card [用户QQ] [名片]\n为群加减设置，需要对应权限:\ngroup +/-[群管词条]\n例: group +禁用回复 //关闭本群自定义回复\n群管词条: 停用指令/禁用回复/禁用jrrp/禁用draw/禁用help/禁用ob",msg)
    return "指令重定向完毕[group]"
  end
  local i = msg.fromParams
  if i:sub(1,1) == " " then
    i = i:sub(2,-1)
  elseif i:gsub(" ","") == "" then
    dream.api.sendMessage("群管理命令\n查询潜水群成员:\ngroup diver\n设置群员名片:\ngroup card [用户QQ] [名片]\n为群加减设置，需要对应权限:\ngroup +/-[群管词条]\n例: group +禁用回复 //关闭本群自定义回复\n群管词条: 停用指令/禁用回复/禁用jrrp/禁用draw/禁用help/禁用ob",msg)
    return "指令重定向完毕[group]"
  end
  if i:sub(1,5) == "diver" then
    local list = dream.api.getMembersList(msg.fromGroup)
    list = table.sort(list,"lastSpeakTimestamp")
    local res
    local l = 0
    for i=#list,1,-1 do
      if (os.time() - list[i]["lastSpeakTimestamp"]) < 2592000 then
        break
      end
      l = l + 1
      local name = list[i]["nameCard"]
      if name == "" then
        name = list[i]["nick"]
      end
      if not res then
        res = name.."("..list[i]["uin"]..")最后发言于:"..os.date("%Y-%m-%d %H:%M:%S",list[i]["lastSpeakTimestamp"])
      else
        res = res.."\n"..name.."("..list[i]["uin"]..")最后发言于:"..os.date("%Y-%m-%d %H:%M:%S",list[i]["lastSpeakTimestamp"])
      end
    end
    if not res then
      dream.api.sendMessage("本群并无潜水人员呢",msg)
      return "指令重定向完毕[group]"
    end
    local tab = {}
    tab[1] = ""
    res = dream.string.part(res,"\n")
    for i=1,#res do
      if tab[#tab] == "" then
        tab[#tab] = res[i].."\n"
      else
        tab[#tab] = tab[#tab]..res[i].."\n"
      end
      if i % 200 == 0 then
        tab[#tab] = tab[#tab].."#{MULT}"
        tab[#tab+1] = ""
      elseif i % 10 == 0 then
        tab[#tab+1] = ""
      end
    end
    dream.api.sendMessage("本群总共有"..l.."位潜水人员#{SPLIT}"..table.concat(tab,"#{SPLIT}"),msg)
    return "指令重定向完毕[group]"
  else
    return msg.fromMsg
  end
end
dream.replace.set("command","group",command.group)

function command.black(msg)
  local i = msg.fromParams
  if i:sub(1,1) == " " then
    i = i:sub(2,-1)
  elseif i:gsub(" ","") == "" then
    return "black"
  end
  if i:sub(1,4) == "list" then
    local list = dream.api.getBlackList()
    local tab = {"#{MULT}【用户黑名单】"}
    local tbl = {"#{MULT}【群聊黑名单】"}
    for i=1,#list do
      local time = tostring(list[i].time)
      time = time:sub(1,10)
      if list[i].blackGroup == 0 then
        tab[#tab+1] = "日期："..os.date("%Y-%m-%d %H:%M:%S",time).."\n用户ID："..list[i].blackQQ.."\n谁操作的："..list[i].operator.."\n被黑原因："..list[i].Reason.."\n全球编码："..list[i].UUID.."\n解黑指令：!black rm "..list[i].UUID
      elseif list[i].blackQQ == 0 then
        tbl[#tbl+1] = "日期："..os.date("%Y-%m-%d %H:%M:%S",time).."\n用户ID："..list[i].blackGroup.."\n谁操作的："..list[i].operator.."\n被黑原因："..list[i].Reason.."\n全球编码："..list[i].UUID.."\n解黑指令：!black rm "..list[i].UUID
      end
    end
    local res = {}
    local i = 1
    while true do
      local ind,cnt
      if i > #tab+#tbl then
        break
      elseif i > #tab then
        ind = i - #tab
        cnt = table.clone(tbl)
      else
        ind = i
        cnt = table.clone(tab)
      end
      if #cnt == 1 then
        cnt[1] = ""
      end
      if (#res+1) % 100 == 0 then
        res[#res+1] = "#{MULT}"..cnt[ind]
      else
        res[#res+1] = cnt[ind]
      end
      i = i + 1
    end
    if #tab-1 == 0 and #tbl-1 == 0 then
      dream.api.sendMessage("无任何黑名单记录",msg)
    else
      dream.api.sendMessage("当前黑名单总共有"..(#tab-1).."名用户\n当前黑名单总共有"..(#tbl-1).."个群聊"..table.concat(res,"#{SPLIT}"),msg)
    end
    return "指令重定向完毕[black]"
  else
    return msg.fromMsg
  end
end
dream.replace.set("command","black",command.black,true)

function command.dream_update(msg)
  local id = msg.fromParams:gsub(" ","")
  if not dream.math.isNumber(id) then
    return "同步骰娘["..id.."]的dream框架失败：账号id错误"
  elseif not io.open(dream.api.getDiceDir():gsub(dream.api.getDiceQQ(),id).."/custom/dream.toml","r") then
    return "同步骰娘["..id.."]的dream框架失败：账号id可能不存在或骰娘并未安装dream框架"
  elseif id == dream.api.getDiceQQ() then
    return "同步失败，该骰娘是本身×"
  end
  local f = dream.file.read(dream.setting.path:gsub(dream.api.getDiceQQ(),id).."/data/dream.toml")
  local r = dream.file.read(dream.setting.path:gsub(dream.api.getDiceQQ(),id).."/dream.lua")
  if r == nil then
    return "同步骰娘["..id.."]的dream框架失败：骰娘并未安装dream框架"
  elseif f == nil then
    f = dream.file.read(dream.api.getDiceQQ():gsub(dream.api.getDiceQQ(),id).."/custom/dream.toml")
    f = dream.toml.parse(f)
    f = {lua = f.lua}
    f = dream.toml.encode(f)
  end
  dream.file.write(dream.api.getDiceDir().."/custom/dream.toml",f)
  dream.file.write(dream.setting.path.."/dream.lua",r)
  return "同步框架完毕！请使用 .system load 命令重载插件"
end
dream.command.set("command","dream update",command.dream_update,true)

return {
  id = "command",
  version = 6.0,
  help = [[Dream官方插件
* 作者：筑梦师V2.0
* 最后更新：2024-07-19
* master认证
* bot指令重定向
* 设置通知窗口
* 群插件开关
* 关于更新的help
* 插件列表
* 插件基本信息
* Send指令美化
* 临时全局禁用/启用
* help指令兼容，可查看插件帮助文档
* group指令兼容溯洄
* black list指令优化]],
  author = "筑梦师V2.0",
  mode = true
}