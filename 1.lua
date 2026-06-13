-- ==================== INJECTOR SYSTEM (from 1.lua) ====================
do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._MOD_LOADED and _G._MOD_PC == pc then return end
    _G._MOD_LOADED = true
    _G._MOD_PC = pc
end

if not _G.BYPASS_STATE then
    _G.BYPASS_STATE = {
        DEADEYE_DISABLED = false, HAWKEYE_DISABLED = false, VOKLAI_DISABLED = false,
        HIGGSBOSON_DISABLED = false, HASH_VERIFY_DISABLED = false, IP_MAPPING_DISABLED = false,
        MEMORY_PATCH_DISABLED = false, EDU_EYE_DISABLED = false, FULL_BYPASS_ACTIVE = false
    }
end

local require = require
local import = import
local isValid = slua.isValid
local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end

-- bypass helper
local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

-- ========== 8‑LAYER BYPASS FUNCTIONS ==========
local function BypassDeadEye()
    if _G.BYPASS_STATE.DEADEYE_DISABLED then return end
    pcall(function()
        if _G.GameplayCallbacks then
            for _, fn in ipairs({"ReportAimFlow","ReportHitFlow","ReportAttackFlow","OnAimDetected","OnHeadshotDetected","OnPerfectAccuracy"}) do
                if _G.GameplayCallbacks[fn] then _G.GameplayCallbacks[fn] = nop end
            end
        end
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local aimTracker = subsystems:Get("ClientAimTrackingSubsystem")
            if aimTracker then
                aimTracker.GetAimData = function() return {accuracy = math.random(45,65), headshotRate = math.random(15,35)} end
                aimTracker.IsAimNormal = function() return true end
            end
        end
    end)
    _G.BYPASS_STATE.DEADEYE_DISABLED = true
end

local function BypassHawkEye()
    if _G.BYPASS_STATE.HAWKEYE_DISABLED then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local hawkEye = subsystems:Get("ClientHawkEyePatrolSubsystem")
            if hawkEye then
                hawkEye.GetPatrolData = retEmpty
                hawkEye.IsBeingWatched = retFalse
                hawkEye.GetSpectatorCount = retZero
            end
        end
        if _G.GameplayCallbacks then
            for _, fn in ipairs({"SendDSErrorLogToLobby","SendDSHawkEyePatrolLogToLobby","ReportMatchRoomData"}) do
                if _G.GameplayCallbacks[fn] then _G.GameplayCallbacks[fn] = nop end
            end
        end
    end)
    _G.BYPASS_STATE.HAWKEYE_DISABLED = true
end

local function BypassVoklai()
    if _G.BYPASS_STATE.VOKLAI_DISABLED then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local ai = subsystems:Get("ClientAIBehaviourSubsystem")
            if ai then
                ai.GetBehaviorScore = function() return math.random(10,30) end
                ai.IsSuspicious = retFalse
                ai.GetRiskLevel = retZero
            end
            local step = subsystems:Get("ClientStepCheckSubsystem")
            if step then
                step.GetStepDelta = function() return math.random(5,50) end
                step.IsMovementValid = function() return true end
            end
            local speed = subsystems:Get("AntiSpeedHackSubsystem") or subsystems:Get("ClientAntiSpeedHackSubsystem")
            if speed then
                speed.GetSpeed = function() return math.random(300,600) end
                speed.IsSpeedValid = function() return true end
            end
        end
    end)
    _G.BYPASS_STATE.VOKLAI_DISABLED = true
end

local function BypassHiggsBoson()
    if _G.BYPASS_STATE.HIGGSBOSON_DISABLED then return end
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if isValid(pc) then
            if pc.HiggsBoson then
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
            end
            if pc.HiggsBosonComponent then
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent:ControlMHActive(0)
            end
        end
        local higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if higgs then
            higgs.GetNetAvatarItemIDs = function() return {1001,2002,3003,4004,5005} end
            higgs.GetCurWeaponSkinID = function() return 6001 end
            higgs.GetCurItemIDs = function() return {7001,8002} end
            if higgs.BlackList then higgs.BlackList = {} end
        end
        _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
        local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
        mt.__newindex = function() end
        setmetatable(_G.GlobalPlayerCoronaData, mt)
        _G.BlackList = {}
    end)
    _G.BYPASS_STATE.HIGGSBOSON_DISABLED = true
end

local function BypassHashVerification()
    if _G.BYPASS_STATE.HASH_VERIFY_DISABLED then return end
    pcall(function()
        if _G.TssSdk then
            _G.TssSdk.ScanMemory = function() return true, {code=0, msg="clean"} end
            _G.TssSdk.ScanSo = function() return true, {code=0, msg="clean"} end
            _G.TssSdk.ScanFile = function() return true, {code=0} end
            _G.TssSdk.GetRiskFlag = retZero
            _G.TssSdk.VerifyFileHash = function() return true end
        end
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local integrity = subsystems:Get("ClientIntegrityCheckSubsystem")
            if integrity then
                for _, fn in ipairs({"CheckFileHash","VerifyMemory","ScanModules"}) do
                    if integrity[fn] then integrity[fn] = nop end
                end
            end
        end
    end)
    _G.BYPASS_STATE.HASH_VERIFY_DISABLED = true
end

local function BypassIPMapping()
    if _G.BYPASS_STATE.IP_MAPPING_DISABLED then return end
    pcall(function()
        if _G.GameplayCallbacks then
            for _, fn in ipairs({"SendClientDeviceInfo","ReportDeviceFingerprint","SendNetworkInfo","ReportIPAddress","SendMACAddress","ReportHardwareID"}) do
                if _G.GameplayCallbacks[fn] then _G.GameplayCallbacks[fn] = nop end
            end
        end
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local di = subsystems:Get("ClientDeviceInfoSubsystem")
            if di then
                di.GetDeviceID = function() return FakeData.deviceID() end
                di.GetIPAddress = function() return FakeData.ipAddress() end
                di.GetMACAddress = function() return FakeData.macAddress() end
            end
        end
    end)
    _G.BYPASS_STATE.IP_MAPPING_DISABLED = true
end

local function BypassMemoryPatching()
    if _G.BYPASS_STATE.MEMORY_PATCH_DISABLED then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local kc = subsystems:Get("ClientKernelCheckSubsystem")
            if kc then
                kc.IsKernelClean = function() return true end
                kc.GetKernelVersion = function() return FakeData.kernelVersion() end
                kc.IsBootloaderLocked = function() return true end
            end
            local mg = subsystems:Get("ClientMemoryGuardSubsystem")
            if mg then
                mg.IsMemoryClean = function() return true, {code=0} end
                mg.ScanResult = function() return "clean" end
            end
        end
        if _G.TssSdk then
            _G.TssSdk.CheckKernel = function() return true, {status="verified", tampered=false} end
            _G.TssSdk.VerifyBoot = function() return true, {locked=true, verified=true} end
        end
    end)
    _G.BYPASS_STATE.MEMORY_PATCH_DISABLED = true
end

local function BypassEduEye()
    if _G.BYPASS_STATE.EDU_EYE_DISABLED then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local rc = subsystems:Get("ClientRenderCheckSubsystem")
            if rc then
                rc.IsRenderClean = function() return true end
                rc.GetRenderState = function() return "normal" end
            end
            local espd = subsystems:Get("ClientESPDetectionSubsystem")
            if espd then
                espd.HasESP = retFalse
                espd.CheckOverlay = function() return "clean" end
            end
            local whd = subsystems:Get("ClientWallhackDetectionSubsystem")
            if whd then
                whd.IsVisionNormal = function() return true end
                whd.GetVisibilityRate = function() return math.random(60,85) end
            end
        end
    end)
    _G.BYPASS_STATE.EDU_EYE_DISABLED = true
end

local function ApplyAllBypasses()
    if _G.BYPASS_STATE.FULL_BYPASS_ACTIVE then return end
    BypassDeadEye()
    BypassHawkEye()
    BypassVoklai()
    BypassHiggsBoson()
    BypassHashVerification()
    BypassIPMapping()
    BypassMemoryPatching()
    BypassEduEye()
    _G.BYPASS_STATE.FULL_BYPASS_ACTIVE = true
end

-- Network/File blocking
local BLACKLIST_HOSTS = {
    "tss.tencent","syzsdk","gcloud.qq","reportlog","tdos","logupload","feedback.wh","crash2",
    "privacy.qq","anticheatexpert","crashsight","wetest","log.tav","sngd","tracer","intlsdk",
    "igamecj","cdn.club","gpubgm","graph.facebook","calendarpushsubscription","googleads",
    "doubleclick","firebaselogging","firebaseremoteconfig","fonts.googleapis","abs.twimg",
    "dl.listdl","igame.gcloudcs","bugly","beacon","helpshift","tdm","apm","safeguard",
    "weiyun","qzone","tencent-cloud","myapp","idqqimg","gtimg","qqmail","tcdn","cloudctrl",
    "sdkostrace","103.134.189.146","mbgame","csoversea","igame","pubgmobile","down.anticheatexpert.com",
    "asia.csoversea.mbgame.anticheatexpert.com","log.tav.qq","syzsdk.qq","logiservice.qcloud",
    "opensdk.tencent","exp.helpshift","loginsdkapi.zingplay","firebase","googleapis","facebook","gvoice"
}
local function isBlacklisted(str)
    if type(str)~="string" then return false end
    local low = str:lower()
    for _,kw in ipairs(BLACKLIST_HOSTS) do if low:find(kw,1,true) then return true end end
    return false
end
pcall(function()
    if _G.HttpRequest then
        local orig = _G.HttpRequest
        _G.HttpRequest = function(url,...) if isBlacklisted(url) then return nil end return orig(url,...) end
    end
end)

-- Fake data for bypass
local FakeData = {
    deviceID = function()
        local chars = "0123456789ABCDEF"
        local id = ""
        for i=1,32 do id = id .. chars:sub(math.random(1,#chars),math.random(1,#chars)) end
        return id
    end,
    ipAddress = function() return "192.168."..math.random(1,255).."."..math.random(1,255) end,
    macAddress = function() return string.format("%02X:%02X:%02X:%02X:%02X:%02X", math.random(0,255),math.random(0,255),math.random(0,255),math.random(0,255),math.random(0,255),math.random(0,255)) end,
    kernelVersion = function() return "4.19."..math.random(100,200).."-generic" end,
}

-- Persistent bypass timer
local function startPersistentTimer()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if isValid(pc) then
        if _G._permHuntTimer then pcall(function() pc:RemoveGameTimer(_G._permHuntTimer) end) end
        _G._permHuntTimer = pc:AddGameTimer(3.0, true, function()
            pcall(ApplyAllBypasses)
            -- kill leftover report subsystems
            local subMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
            if subMgr and subMgr.Get then
                for _,name in ipairs({"ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem","ClientReportPlayerSubsystem","DSReportPlayerSubsystem","ClientGlueHiaSystem","ClientDataStatistcsSubsystem","ICTLogSubsystem","DSFightTLogSubsystem","DSSecurityTLogSubsystem","AFKReportorSubsystem","BehaviorScoreSubsystem"}) do
                    local sub = subMgr:Get(name)
                    if sub then
                        for k,v in pairs(sub) do
                            if type(v)=="function" and (k:find("Report") or k:find("Send") or k:find("Tick") or k:find("Log")) then
                                pcall(function() sub[k]=nop end)
                            end
                        end
                    end
                end
            end
        end)
        return true
    end
    return false
end

-- initial injection
pcall(ApplyAllBypasses)
local fb = slua_GameFrontendHUD or Game
if fb and isValid(fb) then fb:AddGameTimer(2.0, false, function() startPersistentTimer() end) end

-- ==================== BANGDE ORIGINAL CODE (preserved & enhanced) ====================
local M = {}

function _G.TryBypassMD5()
    if _G.MD5Bypassed then return end
    pcall(function()
        require("client.client_entry")
        if _G.NetUtil then
            _G.NetUtil.check_dh_packet_key = function(packet_key, svr_packet_key_md5, from, dh_ext_info, bReportDSInfo)
                if type(dh_ext_info)=="table" then
                    dh_ext_info.packet_key_md5 = svr_packet_key_md5 or ""
                    dh_ext_info.svr_packet_key_md5 = svr_packet_key_md5 or ""
                end
                return true
            end
            _G.MD5Bypassed = true
        end
    end)
end

function _G.BypassCacheMD5()
    if _G.CacheMD5Bypassed then return end
    pcall(function()
        local CacheMgr = require("common.CustomAsset.CustomAssetCacheManager")
        if CacheMgr then
            CacheMgr._UpdateAssetCacheState = function(self, AssetKey, SuffixType)
                local CacheMetaInfo = self:GetCustomAssetCacheMetaInfo(AssetKey, SuffixType)
                if CacheMetaInfo then
                    CacheMetaInfo.CacheVerifyStatus = CustomAssetDefine.CustomAssetCacheVerifyStatus.Valid
                end
            end
            _G.CacheMD5Bypassed = true
        end
    end)
end

_G.BypassSecurityUtils = function()
    pcall(function()
        local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")        
        if SecurityCommonUtils then
            if SecurityCommonUtils.EStrategyTypeInReplay then
                for k,v in pairs(SecurityCommonUtils.EStrategyTypeInReplay) do
                    SecurityCommonUtils.EStrategyTypeInReplay[k] = 0
                end
            end
            SecurityCommonUtils.LogIf = function() return false end
            SecurityCommonUtils.IsFunctionCheckPass = function() return true end
            SecurityCommonUtils.IsHealthStatusHealthy = function() return true end
            SecurityCommonUtils.IsHealthStatusAlive = function() return true end
            SecurityCommonUtils.IsTrue = function() return true end
            _G.SecurityCommonUtils = SecurityCommonUtils
        end
    end)
end

_G.BypassHiggsComponent = function()
    pcall(function()
        local HiggsComponentClass = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")        
        if HiggsComponentClass then
            local CHiggsBosonComponent = HiggsComponentClass.__index or HiggsComponentClass
            CHiggsBosonComponent.StaticShowSecurityAlertInDev = nop
            CHiggsBosonComponent._ClientShowSecurityAlertWindow = nop
            CHiggsBosonComponent._ReportChatRobot = nop
            CHiggsBosonComponent._ProcessReportChatRobotQueue = nop
            CHiggsBosonComponent.RecordStrategyTimestampInReplay = nop
            CHiggsBosonComponent.SendAntiDataFlow = nop
            CHiggsBosonComponent.SendHitFireBtnFlow = nop
            CHiggsBosonComponent.OnBattleResult = nop
            CHiggsBosonComponent.SendHisarData = nop
            if CHiggsBosonComponent.ClientRPC then
                CHiggsBosonComponent.ClientRPC.RPC_Client_ShowSecurityAlertWindow = nop
                CHiggsBosonComponent.ClientRPC.RPC_Client_ServerNameAck = nop
            end
            if CHiggsBosonComponent.ServerRPC then
                CHiggsBosonComponent.ServerRPC.RPC_Server_TellServerName = nop
            end
        end
    end)
end

function _G.TryShowLegalCredit()  
    if _G.LegalShown then return end 
    pcall(function() 
        local Legal = require("client.slua.logic.common.logic_common_legal_msg") 
        local content = table.concat({
            "THIS FILES DIRECTLY WAS MADE BY @BANGDE_REALONE",
            "If you are using this file but it is NOT from BANGDE or his team, then it can be confirmed that this person is a scammer pretending to be a modder",
            "BE CAREFUL OF SCAMMERS GUYS",
            "DJTEAM CREW:",
            "@BANGDE_REALONE",
            "@JECKYF",
            "JANGAN LUPA JOIN DAN UPGRADE KE VIP SEKARANG JUGA!",
            "NIKMATI FITUR TERBAIK DAN PALING STABIL HANYA DI SINI!",
            "MOD BERKUALITAS TINGGI DAN DIJAMIN AMAN",
            "UPDATE SETIAP HARI DAN FULL SUPPORT 24/7",
            "RASAKAN SENSASI BERMAIN DI LEVEL YANG BERBEDA!",
            "DUKUNG TERUS KARYA ANAK BANGSA!",
            "REAL INDONESIAN MODDERS INDONESIA PRIDE",
            "Enjoy And Keep Safe!"
        }, "\n")
        Legal.ShowOnePopUI({
            tabType = 999,
            title = "CREDIT",
            content = content,
            btnOKText = "OK",
            btnCancleText = "CLOSE",
            acceptFunc = function() end,
            refuseFunc = function() end
        }) 
        _G.LegalShown = true 
    end) 
end

local SettingUtil = require("client.slua.logic.setting.setting_util")
local LegalMsg = require("client.slua.logic.common.logic_common_legal_msg")
local TimeTicker = require("common.time_ticker")
local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
local GraphicConst = require("client.slua.umg.NewSetting.GraphicsNew.GraphicConst")
local FPS_STRINGS = { "15", "20", "25", "30", "40", "60", "90", "120" }

local GSC_FPS = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS"]
    or require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")

if GSC_FPS and GSC_FPS.__inner_impl then
    local impl = GSC_FPS.__inner_impl
    local origCtor = impl.ctor
    impl.ctor = function(self)
        if origCtor then origCtor(self) end
        self.FPSButtons = {}
        for i=1,8 do self.FPSButtons[i] = {false, false} end
    end
    local origRegistEvents = impl.RegistEvents
    impl.RegistEvents = function(self)
        if origRegistEvents then origRegistEvents(self) end
        if self.UIRoot and self.UIRoot.Btn_fpslv8 then
            self.UIRoot:AddControlEventByControl("Btn_fpslv8", "OnClicked", self.ClickFPS, self)
        end
        self:AddCommonEvent(EVENTTYPE_SETTING, EVENTID_SETTING_FPS_LIMIT_CONFIRM, self.OnFPSPopConfirm, self)
    end
    impl.GetMaxFPSLevel = function() return 8,8 end
    impl.CanChangeQualityAndFPSPreCheck = function() return true end
    impl.InitRealSupportFPS = function(self)
        local tbl = {}
        for i=1,8 do tbl[i] = {true, true} end
        GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, tbl, false)
        return tbl
    end
    impl.SetFPSAndQualityEnable = function(self, enable)
        if self.UIRoot and self.UIRoot.Image_Mask then
            self:SetWidgetVisible(self.UIRoot.Image_Mask, false)
        end
    end
    impl.UpdateSelectedFPSState = function(self, level)
        local names = {[2]="NodeFps20",[3]="NodeFps25",[4]="NodeFps30",[5]="NodeFps40",[6]="NodeFps60",[7]="NodeFps90",[8]="NodeFps120"}
        if not names[level] then return end
        for k,v in pairs(names) do
            if self.UIRoot[v] then
                self:WidgetSelfHit(self.UIRoot[v])
                self.UIRoot[v]:SetIsEnabled(true)
                local sw = self.UIRoot["WidgetSwitcher_"..k]
                if sw then sw:SetActiveWidgetIndex(k==level and 0 or 1) end
            end
        end
    end
    local origUpdateUI = impl.UpdateUI
    impl.UpdateUI = function(self)
        if origUpdateUI then pcall(origUpdateUI, self) end
        self:SelfHitTestInvisible()
        self:InitRealSupportFPS()
        self:SetFPSAndQualityEnable(true)
        local tgt = 8
        if GraphicSettingDB then
            if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab)==2 then
                tgt = GraphicSettingDB:GetUIData(GraphicSettingDB.LobbyFPS) or 8
            else
                tgt = GraphicSettingDB:GetUIData(GraphicSettingDB.SelectedFPS) or 8
            end
        end
        self:UpdateSelectedFPSState(tgt)
    end
    impl.DoClickFPS = function(self, level)
        if not slua.isValid(self.UIRoot) then return end
        if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab)==2 then
            GraphicSettingDB:UpdateUIData(GraphicSettingDB.LobbyFPS, level)
        else
            GraphicSettingDB:UpdateSelectedFPS(level)
        end
        self:UpdateSelectedFPSState(level)
        if self:GetParentUI() then self:GetParentUI():SaveQualityAndFPS(); self:GetParentUI():SetDirty(true) end
    end
    impl.Change120FPSConfirm = function(self,cb) if cb then cb() end end
    impl.ClickExpandFPSConfirm = function(self,cb) if cb then cb() end end
end

local GSC_FPSFT = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT"]
    or require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
if GSC_FPSFT and GSC_FPSFT.__inner_impl then
    local ft = GSC_FPSFT.__inner_impl
    local MN, MX, ST = 90, 165, 5
    local function clamp(v,l,h) if v<l then return l elseif v>h then return h else return v end end
    ft.ShowOrHide = function(s) s:SelfHitTestInvisible(); if s.InitFPSFTSwitch then s:InitFPSFTSwitch() end end
    ft.InitFPSFTSwitch = function(s)
        local on = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
        if s.UIRoot.Setting_Switch then s.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true) end
        if s.UIRoot.CanvasPanel_8 then s:SetWidgetVisible(s.UIRoot.CanvasPanel_8, on) end
        if s.UIRoot.WidgetSwitcher_0 then s.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
        if s.InitFPSFTValue165 then s:InitFPSFTValue165() end
    end
    ft.InitFPSFTValue165 = function(s)
        local r = s.UIRoot
        local on = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
        local v = (on and GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165)
        r.Slider_screen3:SetLocked(not on)
        r.ProgressBar_screen3:SetFillColorAndOpacity(on and FLinearColor(1,1,1,1) or FLinearColor(1,0.625,0.6,1))
        r.Veihclescreen3:SetText(LocUtil.LocalizeResFormat(10567, v))
        local n = (v-MN)/(MX-MN)
        r.Slider_screen3:SetValue(n); r.ProgressBar_screen3:SetPercent(n)
    end
    ft.OnFPSFTValueChange3 = function(s, v)
        v = clamp(v, MN, MX)
        GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, v)
        s:InitFPSFTValue165()
        if s:GetParentUI() then s:GetParentUI():SetDirty(true) end
        local gi = GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
        if gi then gi:ExecuteCMD("t.MaxFPS", tostring(v)); gi:ExecuteCMD("r.FrameRateLimit", tostring(v)) end
    end
    ft.OnFPSFTSliderValueChange3 = function(s, nv)
        if not GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) then return end
        s:OnFPSFTValueChange3(clamp(math.floor((MN + nv*(MX-MN))/ST+0.5)*ST, MN, MX))
    end
    ft.OnFPSFTAdd3 = function(s)
        local c = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 90
        s:OnFPSFTValueChange3(math.min(MX, c+ST))
    end
    ft.OnFPSFTMinus3 = function(s)
        local c = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 90
        s:OnFPSFTValueChange3(math.max(MN, c-ST))
    end
    ft.OnFPSFTAdd = ft.OnFPSFTAdd3; ft.OnFPSFTMinus = ft.OnFPSFTMinus3
    ft.OnFPSFTSliderValueChange = ft.OnFPSFTSliderValueChange3
end

local GameplayData=require("GameLua.GameCore.Data.GameplayData")
local EAvatarDamagePosition = import("EAvatarDamagePosition")
function M.GetHitBodyType(ImpactResult, InImpactVec)
    return EAvatarDamagePosition.BigHead
end

_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
    local uPlayerController = player:GetPlayerControllerSafety()
    if not slua.isValid(uPlayerController) then return result end
    local ASTExtraPlayerCharacter = import("STExtraPlayerCharacter")
    if not ASTExtraPlayerCharacter then return result end
    local Actors = Game:GetActorsByClass(ASTExtraPlayerCharacter)
    if not Actors then return result end
    local count = Actors:Num() or 0
    local myTeam = player:GetTeamID()
    for i=0,count-1 do
        local actor = Actors:Get(i)
        if slua.isValid(actor) and actor~=player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local dist = player:GetDistanceTo(actor)
                if dist <= radius then table.insert(result, actor) end
            end
        end
    end
    return result
end

-- BANGDE CONFIG
_G.LexusConfig = _G.LexusConfig or {
    EnableFOV = false, FOVValue = 80,
    EnableWeaponMod = false,
    EnableMagic = false, MagicLevel = 70,
    EnableAutoAim = false, AutoAimBone = "Head",
    EnableAiming = false, AimingLevel = "LOW",
    EnableNoRecoil = false, EnableNoShake = false, RecoilLevel = "LESS",
    DisableGrass = false, BlackSky = false,
    WeaponMod = {
        [101001] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
        [101002] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
        [101003] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
        [101004] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
        [101005] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
        [101006] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
        [101007] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
        [101008] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
        [101009] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
        [101010] = {FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false}
    }
}
_G.LexusState = _G.LexusState or {}

-- FOV
function _G.SetFOV(value)
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local camera = player.ThirdPersonCameraComponent
    if camera then camera:SetFieldOfView(value) end
end

-- Weapon Mod
_G.otherWeapon = function()
    if not _G.LexusConfig.EnableWeaponMod then return end
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        local wm = player.WeaponManagerComponent
        if not slua.isValid(wm) then return end
        local cur = wm.CurrentWeaponReplicated
        if not slua.isValid(cur) then return end
        local shoot = cur.ShootWeaponEntityComp
        if not slua.isValid(shoot) then return end
        local wid = shoot.WeaponID
        local cfg = _G.LexusConfig.WeaponMod[wid]
        if not cfg then return end
        if cfg.FireSpeed then shoot.ShootInterval = 0.07 end
        if cfg.InstanHit then
            local speeds = {[101001]=120000,[101002]=110000,[101003]=130000,[101004]=130000,[101005]=130000,[101006]=130000,[101007]=130000,[101008]=130000,[101009]=130000,[101010]=130000}
            shoot.BulletFireSpeed = speeds[wid] or 130000
        end
        if cfg.FastSwitch then
            shoot.SwitchFromIdleToBackpackTime = 0
            shoot.SwitchFromBackpackToIdleTime = 0
        end
        if cfg.FastScope then shoot.WeaponAimInTime = 7 end
    end)
end

-- Magic Bullet
_G.ResetHitbox = function()
    pcall(function()
        local all = Game:GetAllPlayerPawns()
        if all then
            for _,e in pairs(all) do
                if slua.isValid(e) and slua.isValid(e.Mesh) then
                    e.Mesh:RecreatePhysicsState()
                    e.Mesh:UpdateBounds()
                end
            end
        end
        _G._MBones = {}
    end)
end
_G.Magic = function()
    if not _G.LexusConfig.EnableMagic then
        if _G._MBones and next(_G._MBones)~=nil then _G.ResetHitbox() end
        return
    end
    pcall(function()
        local char = GameplayData.GetPlayerCharacter()
        if not slua.isValid(char) then return end
        local all = Game:GetAllPlayerPawns()
        if not all then return end
        _G._MBones = _G._MBones or {}
        local scale = _G.LexusConfig.MagicLevel or 70
        for _,e in pairs(all) do
            pcall(function()
                if not slua.isValid(e) or e==char or e.TeamID==char.TeamID then return end
                local mesh = e.Mesh
                if not slua.isValid(mesh) then return end
                local phys = mesh.PhysicsAssetOverride
                if not slua.isValid(phys) and slua.isValid(mesh.SkeletalMesh) then phys = mesh.SkeletalMesh.PhysicsAsset end
                if not slua.isValid(phys) then return end
                local assetName = tostring((phys.GetName and phys:GetName()) or phys)
                if _G._MBones[assetName] then return end
                local setups = phys.SkeletalBodySetups
                if not setups then return end
                for i=0,60 do
                    pcall(function()
                        local bs = (type(setups.Get)=="function" and setups:Get(i)) or setups[i]
                        if not bs or not slua.isValid(bs) then return end
                        local bone = tostring(bs.BoneName):lower()
                        if bone:find("head") then
                            local ag = bs.AggGeom
                            if ag and ag.BoxElems then
                                local elem = (type(ag.BoxElems.Get)=="function" and ag.BoxElems:Get(0)) or ag.BoxElems[1]
                                if elem then elem.X, elem.Y, elem.Z = scale, scale, scale; if ag.BoxElems.Set then ag.BoxElems:Set(0,elem) else ag.BoxElems[1]=elem end end
                            end
                            if ag and ag.SphylElems then
                                local elem = (type(ag.SphylElems.Get)=="function" and ag.SphylElems:Get(0)) or ag.SphylElems[1]
                                if elem then if elem.Radius then elem.Radius=scale end; if elem.Length then elem.Length=scale end; if ag.SphylElems.Set then ag.SphylElems:Set(0,elem) else ag.SphylElems[1]=elem end end
                            end
                            if ag and ag.SphereElems then
                                local elem = (type(ag.SphereElems.Get)=="function" and ag.SphereElems:Get(0)) or ag.SphereElems[1]
                                if elem and elem.Radius then elem.Radius=scale; if ag.SphereElems.Set then ag.SphereElems:Set(0,elem) else ag.SphereElems[1]=elem end end
                            end
                        end
                    end)
                end
                mesh:RecreatePhysicsState()
                mesh:WakeAllRigidBodies()
                mesh:UpdateBounds()
                _G._MBones[assetName] = true
            end)
        end
    end)
end

-- Auto Aim
_G.ApplyAutoAim = function()
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local auto = player.AutoAimComp
    if not auto then return end
    if _G.LexusConfig.EnableAutoAim then
        local bone = _G.LexusConfig.AutoAimBone or "Head"
        auto.Bones = {bone, bone, bone}
    else
        auto.Bones = nil
    end
end

-- Aimbot config
_G.ApplyAimingConfig = function()
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local wm = player.WeaponManagerComponent
    if not slua.isValid(wm) then return end
    local cur = wm.CurrentWeaponReplicated
    if not slua.isValid(cur) then return end
    local shoot = cur.ShootWeaponEntityComp
    if not shoot then return end
    local aa = shoot.AutoAimingConfig
    if not aa then return end
    if not _G.LexusConfig.EnableAiming then
        if aa.OuterRange.Speed ~= 3.5 then
            local d = {S=3.5,SR=1,RR=1,RRS=1,SRS=1,CSR=1,CR=0.5,PR=0.10,DR=1,GDF=0}
            aa.OuterRange.Speed = d.S; aa.InnerRange.Speed = d.S
            aa.OuterRange.SpeedRate = d.SR; aa.InnerRange.SpeedRate = d.SR
            aa.OuterRange.RangeRate = d.RR; aa.InnerRange.RangeRate = d.RR
            aa.OuterRange.RangeRateSight = d.RRS; aa.InnerRange.RangeRateSight = d.RRS
            aa.OuterRange.SpeedRateSight = d.SRS; aa.InnerRange.SpeedRateSight = d.SRS
            aa.OuterRange.CenterSpeedRate = d.CSR; aa.InnerRange.CenterSpeedRate = d.CSR
            aa.OuterRange.CrouchRate = d.CR; aa.InnerRange.CrouchRate = d.CR
            aa.OuterRange.ProneRate = d.PR; aa.InnerRange.ProneRate = d.PR
            aa.OuterRange.DyingRate = d.DR; aa.InnerRange.DyingRate = d.DR
            shoot.GameDeviationFactor = d.GDF
        end
        return
    end
    local level = _G.LexusConfig.AimingLevel or "LOW"
    local cfg = {LOW={S=5,SR=5,RR=1,RRS=1,SRS=5,CSR=3,CR=1,PR=1,DR=0,GDF=0},
                 MEDIUM={S=7,SR=7,RR=2,RRS=2,SRS=7,CSR=5,CR=2,PR=2,DR=0,GDF=0},
                 HARD={S=10,SR=10,RR=10,RRS=10,SRS=10,CSR=7,CR=2,PR=2,DR=0,GDF=0},
                 EXTREME={S=50,SR=20,RR=20,RRS=20,SRS=20,CSR=15,CR=5,PR=5,DR=0,GDF=0}}
    local c = cfg[level] or cfg.LOW
    aa.OuterRange.Speed = c.S; aa.InnerRange.Speed = c.S
    aa.OuterRange.SpeedRate = c.SR; aa.InnerRange.SpeedRate = c.SR
    aa.OuterRange.RangeRate = c.RR; aa.InnerRange.RangeRate = c.RR
    aa.OuterRange.RangeRateSight = c.RRS; aa.InnerRange.RangeRateSight = c.RRS
    aa.OuterRange.SpeedRateSight = c.SRS; aa.InnerRange.SpeedRateSight = c.SRS
    aa.OuterRange.CenterSpeedRate = c.CSR; aa.InnerRange.CenterSpeedRate = c.CSR
    aa.OuterRange.CrouchRate = c.CR; aa.InnerRange.CrouchRate = c.CR
    aa.OuterRange.ProneRate = c.PR; aa.InnerRange.ProneRate = c.PR
    aa.OuterRange.DyingRate = c.DR; aa.InnerRange.DyingRate = c.DR
    shoot.GameDeviationFactor = c.GDF
end

-- No Recoil / No Shake
_G.ApplyNoRecoil = function()
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local wm = player.WeaponManagerComponent
    if not slua.isValid(wm) then return end
    local cur = wm.CurrentWeaponReplicated
    if not slua.isValid(cur) then return end
    local shoot = cur.ShootWeaponEntityComp
    if not shoot then return end
    local level = (_G.LexusConfig.EnableNoRecoil and _G.LexusConfig.RecoilLevel) or "DEFAULT"
    local r = shoot.RecoilInfo
    if level == "DEFAULT" then
        shoot.RecoilKickADS = 0.2
        shoot.AccessoriesHRecoilFactor = 0.5
        shoot.AccessoriesRecoveryFactor = 0.6
        shoot.AccessoriesVRecoilFactor = 0.5
        if r then
            r.VerticalRecoilMin = 0; r.VerticalRecoilMax = 7; r.VerticalRecoveryMax = 5
            r.RecoilValueClimb = 0.75; r.RecoilValueFail = 2.2; r.VerticalRecoveryModifier = 0.5
            r.RecovertySpeedVertical = 9; r.VerticalRecoveryClamp = 10
            r.LeftMax = -0.8; r.RightMax = 0.8; r.HorizontalTendency = 0.1
            r.RecoilHorizontalMinScalar = 0.1; r.RecoilSpeedHorizontal = 11; r.RecoilSpeedVertical = 11
        end
    elseif level == "LESS" then
        shoot.RecoilKickADS = 0
        shoot.AccessoriesHRecoilFactor = 0.2
        shoot.AccessoriesRecoveryFactor = 0.2
        shoot.AccessoriesVRecoilFactor = 0.2
        if r then
            r.VerticalRecoilMin = 0; r.VerticalRecoilMax = 2; r.VerticalRecoveryMax = 2
            r.RecoilValueClimb = 0.2; r.RecoilValueFail = 2; r.VerticalRecoveryModifier = 0.2
            r.RecovertySpeedVertical = 2; r.VerticalRecoveryClamp = 2
            r.LeftMax = -0.2; r.RightMax = 0.2; r.HorizontalTendency = 0.1
            r.RecoilHorizontalMinScalar = 0.1; r.RecoilSpeedHorizontal = 2; r.RecoilSpeedVertical = 2
        end
    elseif level == "NO" then
        shoot.RecoilKickADS = 0
        shoot.AccessoriesHRecoilFactor = 0
        shoot.AccessoriesRecoveryFactor = 0
        shoot.AccessoriesVRecoilFactor = 0
        if r then
            r.VerticalRecoilMin = 0; r.VerticalRecoilMax = 0; r.VerticalRecoveryMax = 0
            r.RecoilValueClimb = 0; r.RecoilValueFail = 0; r.VerticalRecoveryModifier = 0
            r.RecovertySpeedVertical = 0; r.VerticalRecoveryClamp = 0
            r.LeftMax = 0; r.RightMax = 0; r.HorizontalTendency = 0
            r.RecoilHorizontalMinScalar = 0; r.RecoilSpeedHorizontal = 0; r.RecoilSpeedVertical = 0
        end
    end
    if _G.LexusConfig.EnableNoShake then
        shoot.AnimationKick = 0
    end
end

-- No Grass
_G.DisableGrass = function()
    local gfx = require("client.slua.logic.setting.logic_setting_graphics")
    local gi = gfx.GetGameInstance()
    if gi then
        gi:ExecuteCMD("grass.heightScale", _G.LexusConfig.DisableGrass and "0" or "1")
    end
end

-- Black Sky
_G.BlackSky = function()
    local gfx = require("client.slua.logic.setting.logic_setting_graphics")
    local gi = gfx.GetGameInstance()
    if gi then
        gi:ExecuteCMD("r.CylinderMaxDrawHeight", _G.LexusConfig.BlackSky and "9999" or "0")
    end
end

-- BANGDE MOD MENU
function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true
    local LocUtil = _G.LocUtil or (package.loaded["client.common.LocUtil"] and require("client.common.LocUtil"))
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id) if type(id)=="string" and not tonumber(id) then return id end return old(id) end
        LocUtil._IsModMenuHooked = true
    end
    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
        local CombinedStack = {
            {Key="ModMenu_FOV_Ex", UI=AliasMap.TitleSwitcher, Text="BANGDE IPAD VIEW", ExpandIndex=0,
             GetFunc=function() return _G.LexusConfig.EnableFOV end,
             SetFunc=function(c,v) _G.LexusConfig.EnableFOV=v; if not v then _G.SetFOV(90) else _G.SetFOV(_G.LexusConfig.FOVValue) end; return true end},
            {Key="ModMenu_FOV_Slider", UI=AliasMap.Slider, Text="   FOV Value (80-140)", ExpandHandle="ModMenu_FOV_Ex", MinValue=0, MaxValue=60,
             GetFunc=function() return (_G.LexusConfig.FOVValue or 110)-80 end,
             SetFunc=function(c,v) local f=v+80; _G.LexusConfig.FOVValue=f; if _G.LexusConfig.EnableFOV then _G.SetFOV(f) end; return true end},
            {Key="ModMenu_Magic_Ex", UI=AliasMap.TitleSwitcher, Text="BANGDE MAGIC BULLET", ExpandIndex=0,
             GetFunc=function() return _G.LexusConfig.EnableMagic end,
             SetFunc=function(c,v) _G.LexusConfig.EnableMagic=v; _G.ResetHitbox(); return true end},
            {Key="ModMenu_Magic_Low", UI=AliasMap.Switcher, Text="   [ LEVEL: LOW ]", ExpandHandle="ModMenu_Magic_Ex",
             GetFunc=function() return _G.LexusConfig.MagicLevel==90 end,
             SetFunc=function(c,v) if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel=90 end; return true end},
            {Key="ModMenu_Magic_Med", UI=AliasMap.Switcher, Text="   [ LEVEL: MEDIUM ]", ExpandHandle="ModMenu_Magic_Ex",
             GetFunc=function() return _G.LexusConfig.MagicLevel==120 end,
             SetFunc=function(c,v) if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel=120 end; return true end},
            {Key="ModMenu_Magic_High", UI=AliasMap.Switcher, Text="   [ LEVEL: HARD ]", ExpandHandle="ModMenu_Magic_Ex",
             GetFunc=function() return _G.LexusConfig.MagicLevel==180 end,
             SetFunc=function(c,v) if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel=180 end; return true end},
            {Key="ModMenu_AutoAim_Ex", UI=AliasMap.TitleSwitcher, Text="BANGDE AUTO AIM", ExpandIndex=0,
             GetFunc=function() return _G.LexusConfig.EnableAutoAim end,
             SetFunc=function(c,v) _G.LexusConfig.EnableAutoAim=v; _G.ApplyAutoAim(); return true end},
            {Key="ModMenu_Bones_Title", UI=AliasMap.Title, Text="TARGET BONES", ExpandHandle="ModMenu_AutoAim_Ex"},
            {Key="ModMenu_Aim_Head", UI=AliasMap.Switcher, Text="   [ BONE: HEAD ]", ExpandHandle="ModMenu_AutoAim_Ex",
             GetFunc=function() return _G.LexusConfig.AutoAimBone=="Head" end,
             SetFunc=function(c,v) if v then _G.LexusConfig.AutoAimBone="Head"; _G.ApplyAutoAim() end; return true end},
            {Key="ModMenu_Aim_Neck", UI=AliasMap.Switcher, Text="   [ BONE: NECK ]", ExpandHandle="ModMenu_AutoAim_Ex",
             GetFunc=function() return _G.LexusConfig.AutoAimBone=="neck_01" end,
             SetFunc=function(c,v) if v then _G.LexusConfig.AutoAimBone="neck_01"; _G.ApplyAutoAim() end; return true end},
            {Key="ModMenu_Aim_Pelvis", UI=AliasMap.Switcher, Text="   [ BONE: PELVIS ]", ExpandHandle="ModMenu_AutoAim_Ex",
             GetFunc=function() return _G.LexusConfig.AutoAimBone=="pelvis" end,
             SetFunc=function(c,v) if v then _G.LexusConfig.AutoAimBone="pelvis"; _G.ApplyAutoAim() end; return true end},
            {Key="ModMenu_Grass_Ex", UI=AliasMap.TitleSwitcher, Text="BANGDE NO GRASS",
             GetFunc=function() return _G.LexusConfig.DisableGrass end,
             SetFunc=function(c,v) _G.LexusConfig.DisableGrass=v; _G.DisableGrass(); return true end},
            {Key="ModMenu_BlackSky", UI=AliasMap.TitleSwitcher, Text="BANGDE BLACKSKY",
             GetFunc=function() return _G.LexusConfig.BlackSky end,
             SetFunc=function(c,v) _G.LexusConfig.BlackSky=v; _G.BlackSky(); return true end}
        }
        local AimRecoilStack = {
            {Key="ModMenu_AimConfig_Title", UI=AliasMap.Title, Text="--- AIMBOT SETTINGS ---"},
            {Key="ModMenu_AimConfig_Ex", UI=AliasMap.TitleSwitcher, Text="BANGDE AIMBOT", ExpandIndex=0,
             GetFunc=function() return _G.LexusConfig.EnableAiming end,
             SetFunc=function(c,v) _G.LexusConfig.EnableAiming=v; _G.ApplyAimingConfig(); return true end},
            {Key="ModMenu_Aim_Level_Title", UI=AliasMap.Title, Text="SPEED LEVEL", ExpandHandle="ModMenu_AimConfig_Ex"},
            {Key="ModMenu_Aim_Low", UI=AliasMap.Switcher, Text="   [ LEVEL: LOW ]", ExpandHandle="ModMenu_AimConfig_Ex",
             GetFunc=function() return _G.LexusConfig.AimingLevel=="LOW" end,
             SetFunc=function(c,v) if v then _G.LexusConfig.AimingLevel="LOW"; _G.LexusConfig.EnableAiming=true; _G.ApplyAimingConfig() end; return true end},
            {Key="ModMenu_Aim_Med", UI=AliasMap.Switcher, Text="   [ LEVEL: MEDIUM ]", ExpandHandle="ModMenu_AimConfig_Ex",
             GetFunc=function() return _G.LexusConfig.AimingLevel=="MEDIUM" end,
             SetFunc=function(c,v) if v then _G.LexusConfig.AimingLevel="MEDIUM"; _G.LexusConfig.EnableAiming=true; _G.ApplyAimingConfig() end; return true end},
            {Key="ModMenu_Aim_Hard", UI=AliasMap.Switcher, Text="   [ LEVEL: HARD ]", ExpandHandle="ModMenu_AimConfig_Ex",
             GetFunc=function() return _G.LexusConfig.AimingLevel=="HARD" end,
             SetFunc=function(c,v) if v then _G.LexusConfig.AimingLevel="HARD"; _G.LexusConfig.EnableAiming=true; _G.ApplyAimingConfig() end; return true end},
            {Key="ModMenu_Aim_Ext", UI=AliasMap.Switcher, Text="   [ LEVEL: EXTREME ]", ExpandHandle="ModMenu_AimConfig_Ex",
             GetFunc=function() return _G.LexusConfig.AimingLevel=="EXTREME" end,
             SetFunc=function(c,v) if v then _G.LexusConfig.AimingLevel="EXTREME"; _G.LexusConfig.EnableAiming=true; _G.ApplyAimingConfig() end; return true end},
            {Key="ModMenu_Recoil_Title", UI=AliasMap.Title, Text="--- RECOIL SETTINGS ---"},
            {Key="ModMenu_Recoil_Ex", UI=AliasMap.TitleSwitcher, Text="BANGDE NO RECOIL", ExpandIndex=0,
             GetFunc=function() return _G.LexusConfig.EnableNoRecoil end,
             SetFunc=function(c,v) _G.LexusConfig.EnableNoRecoil=v; _G.ApplyNoRecoil(); return true end},
            {Key="ModMenu_NoShake", UI=AliasMap.Switcher, Text="   [ NO SHAKE ]", ExpandHandle="ModMenu_Recoil_Ex",
             GetFunc=function() return _G.LexusConfig.EnableNoShake end,
             SetFunc=function(c,v) _G.LexusConfig.EnableNoShake=v; _G.ApplyNoRecoil(); return true end},
            {Key="ModMenu_Recoil_Less", UI=AliasMap.Switcher, Text="   [ LESS RECOIL ]", ExpandHandle="ModMenu_Recoil_Ex",
             GetFunc=function() return _G.LexusConfig.RecoilLevel=="LESS" end,
             SetFunc=function(c,v) if v then _G.LexusConfig.RecoilLevel="LESS"; _G.LexusConfig.EnableNoRecoil=true; _G.ApplyNoRecoil() end; return true end}
        }
        local WeaponStack = {
            {Key="ModMenu_Weapon_Ex", UI=AliasMap.TitleSwitcher, Text="BANGDE WEAPON MOD", ExpandIndex=0,
             GetFunc=function() return _G.LexusConfig.EnableWeaponMod end,
             SetFunc=function(c,v) _G.LexusConfig.EnableWeaponMod=v; return true end},
        }
        for _,wid in ipairs({101001,101002,101003,101004,101005,101006,101007,101008,101009,101010}) do
            local name = ({[101001]="AKM",[101002]="M16A4",[101003]="SCAR-L",[101004]="M416",[101005]="Groza",[101006]="AUG",[101007]="QBZ",[101008]="M762",[101009]="Mk47 Mutant",[101010]="G36C"})[wid]
            table.insert(WeaponStack, {Key="ModMenu_W"..wid.."_Title", UI=AliasMap.Title, Text=name, ExpandHandle="ModMenu_Weapon_Ex"})
            table.insert(WeaponStack, {Key="ModMenu_W"..wid.."_F", UI=AliasMap.Switcher, Text="   FIRESPEED", ExpandHandle="ModMenu_Weapon_Ex", GetFunc=function() return _G.LexusConfig.WeaponMod[wid].FireSpeed end, SetFunc=function(c,v) _G.LexusConfig.WeaponMod[wid].FireSpeed=v; return true end})
            table.insert(WeaponStack, {Key="ModMenu_W"..wid.."_I", UI=AliasMap.Switcher, Text="   INSTAN HIT", ExpandHandle="ModMenu_Weapon_Ex", GetFunc=function() return _G.LexusConfig.WeaponMod[wid].InstanHit end, SetFunc=function(c,v) _G.LexusConfig.WeaponMod[wid].InstanHit=v; return true end})
            table.insert(WeaponStack, {Key="ModMenu_W"..wid.."_S", UI=AliasMap.Switcher, Text="   FAST SWITCH", ExpandHandle="ModMenu_Weapon_Ex", GetFunc=function() return _G.LexusConfig.WeaponMod[wid].FastSwitch end, SetFunc=function(c,v) _G.LexusConfig.WeaponMod[wid].FastSwitch=v; return true end})
            table.insert(WeaponStack, {Key="ModMenu_W"..wid.."_O", UI=AliasMap.Switcher, Text="   FAST OPEN SCOPE", ExpandHandle="ModMenu_Weapon_Ex", GetFunc=function() return _G.LexusConfig.WeaponMod[wid].FastScope end, SetFunc=function(c,v) _G.LexusConfig.WeaponMod[wid].FastScope=v; return true end})
        end
        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            loc = "BANGDE MENU",
            UIKey = "Setting_Page_Privacy",
            Category = {
                {Key="Cat_General", loc="BASIC MOD", Stack=CombinedStack},
                {Key="Cat_Weapon", loc="WEAPON MOD", Stack=WeaponStack},
                {Key="Cat_Aimbot", loc="AIMBOT & RECOIL MOD", Stack=AimRecoilStack}
            }
        }
        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
    end
    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            if config and config.keyName and (string.find(string.lower(config.keyName),"setting_main") or string.find(string.lower(config.keyName),"setting")) then
                local catalog = args[1]
                if type(catalog)=="table" then
                    local has = false
                    for _,p in ipairs(catalog) do if type(p)=="table" and p.Key=="ModMenu" then has=true; break end end
                    if not has then table.insert(catalog, SettingPageDefine.ModMenu) end
                end
            end
            local unpack = table.unpack or unpack
            return old(config, unpack(args,1,select('#',...)))
        end
        UIManager._IsModMenuHooked = true
    end
end

function M.OnCtor(self) end
function M.OnPost(self) self:OnAdvance() self:OnTick(DeltaTime) end

function M.OnTick(self, DeltaTime)
    if _G.LexusConfig.EnableWeaponMod then _G.otherWeapon() end
    if _G.LexusConfig.EnableAiming then _G.ApplyAimingConfig() end
    if _G.LexusConfig.EnableNoRecoil then _G.ApplyNoRecoil() end
    if _G.LexusConfig.EnableMagic then _G.Magic() else if _G._MBones then _G._MBones = {} end end
end

function M.OnAdvance(self)
    if not Client then return end
    if self.HitMarkTimer then _G.KillTimer(self.HitMarkTimer); self.HitMarkTimer=nil end
    self.HitMarkTimer = self:AddGameTimer(0.6, true, function()
        if not slua.isValid(self.Object) then return end
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
    end)
end

function M.OnBeginPlay(self)
    _G.InitModMenuTab()
    _G.TryShowLegalCredit()
    _G.TryBypassMD5()
    _G.BypassCacheMD5()
    _G.BypassSecurityUtils()
    _G.BypassHiggsComponent()
end

return M