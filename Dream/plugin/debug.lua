--[[
  * Dream官方插件
  * 在聊天界面执行lua语句
]]

dolua = {}

function dolua.main(i)
  local str = i.fromParams
  if str ~= "" then
    local start = os.clock()
    local G = table.clone(_G)
    G["msg"] = table.clone(i)
    local res,info = rawload(str,"bt",G)
    if not res then
      return "Error："..dream.error(info,false)
    end
    local type_data = type(info)
    collectgarbage("collect")
    i = tostring(tostring(info))
    local endl = os.clock()
    return "loadTime："..endl-start.."s\n返回类型："..type_data.."\n返回："..i
  end
end
dream.keyword.set("debug",">",dolua.main,true)
dream.command.set("debug","do",dolua.main,true)

return {
  id = "debug",
  version = "2.0",
  help = [[在聊天界面执行lua代码]],
  author = "筑梦师V2.0",
  mode = true
}