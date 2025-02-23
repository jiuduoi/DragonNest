--[[
-- added by wsh @ 2017-12-01
-- UILogin控制层
--]]
local UILoginCtrl = BaseClass("UILoginCtrl", UIBaseCtrl)
local MsgIDDefine = require "Net.Config.MsgIDDefine"

local json = require("rapidjson")
local util = require("xlua.util")
local yield_return = (require "cs_coroutine").yield_return
local MsgIDMap = require("Net/Config/MsgIDMap")

local function OnConnect(self, sender, result, msg)
    Logger.Log("连接结果" .. result .. msg)
    if result < 0 then
        Logger.LogError("Connect err : " .. msg)
        return
    end

    -- -- TODO：
    -- local msd_id = MsgIDDefine.LOGIN_REQ_GET_UID
    -- local msg = {}
    -- msg.plat_account = "455445"
    -- msg.from_svrid = 4001
    -- msg.device_id = ""
    -- msg.device_model = "All Series (ASUS)"
    -- msg.mobile_type = ""
    -- msg.plat_token = ""
    -- msg.app_ver = ""
    -- msg.package_id = ""
    -- msg.res_ver = ""
    -- HallConnector:GetInstance():SendMessage(msd_id, msg)

    msg = MsgIDMap[MsgIDDefine.QueryGateArg].argMsg
    msg.type = LoginType_pb.LOGIN_PASSWORD
    msg.platid = PlatType_pb.PLAT_ANDROID
    msg.version = "0.0.0"
    msg.account = "a456456"
    msg.password = "456456"
    msg.openid = "a456456"
    msg.token = ""
    msg.pf = ""

    HallConnector:GetInstance():SendMessage(MsgIDDefine.QueryGateArg, msg)
end

local function OnClose(self, sender, result, msg)
    Logger.Log("连接关闭 result:" .. result .. "msg:" .. msg)
end

local function WebRequest(url, callback)
    --print("开始协同。。。。")
    local co =
        coroutine.create(
        function()
            local request = CS.UnityEngine.Networking.UnityWebRequest.Get(url)
            yield_return(request:SendWebRequest())
            if (request.isNetworkError or request.isHttpError) then
                print(request.error)
            else
                callback(request.downloadHandler.text)
                print("" .. request.downloadHandler.text)
            end
        end
    )
    assert(coroutine.resume(co))
end

local function ConnectServer(self)
    ---	HallConnector:GetInstance():Connect("192.168.1.245", 10020, Bind(self, OnConnect), Bind(self, OnClose))
    HallConnector:GetInstance():Connect("10.161.21.113", 25001, Bind(self, OnConnect), Bind(self, OnClose))
end
local function LoginDragonServer(self)
    ConnectServer(self)
end

local function LogindatangServer(self)
    --print("登录")
    local appid = ""

    local userId = ""

    local userName = "PC"

    local passWord = "123456"

    local tourist = "1"

    local token = ""

    local time = os.time()
    local key = "QYQDGAMEDshEFWOKE7Y6GAEDE-WAN-0668-2625-7DGAMESZEFovDDe777"
    local sign =
        CS.GameUtility.MD5(
        string.format("%s%s%s%s%s%s%s%s", appid, userId, userName, passWord, tourist, token, time, key)
    )

    local url =
        string.format(
        "http://127.0.0.1:8000/login?appid=%s&userId=%s&userName=%s&passWord=%s&tourist=%s&token=%s&time=%s&sign=%s",
        appid,
        userId,
        userName,
        passWord,
        tourist,
        token,
        time,
        sign
    )
    print("url========:" .. url)
    local msg = {}
    WebRequest(
        url,
        function(data)
            --print("----------"..data)
            --解析json的时候需要注意的是Json的结构形式
            local jsdata = json.decode(data)
            print(jsdata["userId"])
            self.userId = tonumber(jsdata["userId"])
            --print(' self.model.userId ' .. model.userId)
            self.key = jsdata["key"]
            self.time = tonumber(jsdata["time"])
            self.sign = jsdata["sign"]
            --print(jsdata['serverList'])
            local serList = json.decode(jsdata["serverList"])
            self.serverNo = tonumber(serList[1]["serverNo"])
            self.IP = serList[1]["gameHost"]
            self.port = tonumber(serList[1]["gamePort"])
            local flag = HallConnector:GetInstance():Connect(self.IP, self.port)
            if (flag) then
                print("-----------")
                msg = MsgIDMap[MsgIDDefine.C_LoginGame]
                msg.userId = tonumber(self.userId)
                msg.key = self.key
                msg.time = tostring(self.time)
                msg.sign = self.sign
                msg.serverNo = self.serverNo
                HallConnector:GetInstance():SendMessage(MsgIDDefine.C_LoginGame, msg)
            end
        end
    )
end

local function OnClose(self, sender, result, msg)
    if result < 0 then
        Logger.LogError("Close err : " .. msg)
        return
    end
end

local function LoginServer(self, name, password)
    -- 合法性检验
    if string.len(name) > 20 or string.len(name) < 1 then
        -- TODO：错误弹窗
        Logger.LogError("name length err!")
        return
    end
    if string.len(password) > 20 or string.len(password) < 1 then
        -- TODO：错误弹窗
        Logger.LogError("password length err!")
        return
    end
    -- 检测是否有汉字
    for i = 1, string.len(name) do
        local curByte = string.byte(name, i)
        if curByte > 127 then
            -- TODO：错误弹窗
            Logger.LogError("name err : only ascii can be used!")
            return
        end
    end

    ClientData:GetInstance():SetAccountInfo(name, password)

    -- TODO start socket
    --ConnectServer(self)
    SceneManager:GetInstance():SwitchScene(SceneConfig.HomeScene)
end

local function ChooseServer(self)
    UIManager:GetInstance():OpenWindow(UIWindowNames.UILoginServer)
end
local function SendSelectRoleNew(self)
    local tmpMsg = MsgIDMap[MsgIDDefine.SelectRoleNew].argMsg
    tmpMsg.index = 6---传从0开始的索引
	 
    -- HallConnector:GetInstance():SendMessage(MsgIDDefine.SelectRoleNew, tmpMsg)
end






UILoginCtrl.LoginServer = LoginServer
UILoginCtrl.ChooseServer = ChooseServer
UILoginCtrl.LogindatangServer = LogindatangServer
UILoginCtrl.LoginDragonServer = LoginDragonServer
UILoginCtrl.SendSelectRoleNew = SendSelectRoleNew

return UILoginCtrl
