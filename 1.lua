-- Per-match guard: allow re-init when the player controller changes (new match)
do
    local hud = slua_GameFrontendHUD
    if not hud then return end
    local pc = hud:GetPlayerController()
    if not pc then return end
    local pawn = pc:GetCurPawn()
    if not pawn then return end
    if _G._MOD_LOADED and _G._MOD_PAWN == pawn then return end
    _G._MOD_LOADED = true
    _G._MOD_PAWN = pawn
end

-- ADITYA_ORG SRC DUMPED
local M = {}

function _G.TryBypassMD5()
    if _G.MD5Bypassed then
        return
    end
    pcall(function()
        require("client.client_entry")
        if _G.NetUtil then
            _G.NetUtil.check_dh_packet_key = function(packet_key, svr_packet_key_md5, from, dh_ext_info, bReportDSInfo)
                if type(dh_ext_info) == "table" then
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
                for k, v in pairs(SecurityCommonUtils.EStrategyTypeInReplay) do
                    SecurityCommonUtils.EStrategyTypeInReplay[k] = 0
                end
            end
            SecurityCommonUtils.LogIf = function(Condition, sFormat, ...)
                return false
            end
            SecurityCommonUtils.IsFunctionCheckPass = function(FunctionOuter, sFuncName, ...)
                return true
            end
            SecurityCommonUtils.IsHealthStatusHealthy = function(nHealthStatus)
                return true
            end
            SecurityCommonUtils.IsHealthStatusAlive = function(nHealthStatus)
                return true
            end
            SecurityCommonUtils.IsTrue = function(Value)
                return true
            end            
            _G.SecurityCommonUtils = SecurityCommonUtils
        end
    end)
end

_G.BypassHiggsComponent = function()
    pcall(function()
        local HiggsComponentClass = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")        
        if HiggsComponentClass then
            local CHiggsBosonComponent = HiggsComponentClass
            if type(HiggsComponentClass) == "table" and HiggsComponentClass.__index then
                CHiggsBosonComponent = HiggsComponentClass.__index
            end
            CHiggsBosonComponent.StaticShowSecurityAlertInDev = function(uPlayerController, sMessage, bIsClientShowWindow, bSkipServer)
                return
            end
            CHiggsBosonComponent._ClientShowSecurityAlertWindow = function(sMessage)
                return
            end
            CHiggsBosonComponent._ReportChatRobot = function(sMessage, uHiggsBosonComponent)
                return
            end
            CHiggsBosonComponent._ProcessReportChatRobotQueue = function()
                return
            end
            CHiggsBosonComponent.RecordStrategyTimestampInReplay = function(nStrategyTypeInReplay, nValue, uController, nTimeInSecondsOffSet)
                return
            end
            CHiggsBosonComponent.SendAntiDataFlow = function(self)
                return
            end
            CHiggsBosonComponent.SendHitFireBtnFlow = function(self)
                return
            end
            CHiggsBosonComponent.OnBattleResult = function(self)
                return
            end
            CHiggsBosonComponent.SendHisarData = function()
                return
            end
            if CHiggsBosonComponent.ClientRPC then
                CHiggsBosonComponent.ClientRPC.RPC_Client_ShowSecurityAlertWindow = function(self, sMessage)
                    return
                end
                CHiggsBosonComponent.ClientRPC.RPC_Client_ServerNameAck = function(self)
                    return
                end
            end
            if CHiggsBosonComponent.ServerRPC then
                CHiggsBosonComponent.ServerRPC.RPC_Server_TellServerName = function(self, sServerName)
                    return
                end
            end
        end
    end)
end

function _G.TryShowLegalCredit()
    if _G.LegalShown then return end
    pcall(function()
        local Legal = require("client.slua.logic.common.logic_common_legal_msg")
        local content = table.concat({
            "FILE BY: @ADITYA_ORG_REALONE",
            "WARNING: Only use from ADITYA_ORG team!",
            "STAY SAFE FROM SCAMMERS!",
            "━━━━━━━━━━━━━━━━",
            ":@ADITYA_ORG_REALONE",
            "━━━━━━━━━━━━━━━━",
            "JOIN VIP FOR BEST FEATURES!",
            "✓ High Quality & Safe Mods",
            "✓ Daily Updates & 24/7 Support",
            "✓ Next Level Gaming Experience",
            "━━━━━━━━━━━━━━━━",
            "Har Har Mahadev",
            "Enjoy & Keep Safe!"
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

    -- Constructor
    local origCtor = impl.ctor
    impl.ctor = function(self)
        if origCtor then origCtor(self) end
        self.FPSButtons = {}
        for i = 1, 8 do
            self.FPSButtons[i] = { false, false }
        end
    end

    -- Register events
    local origRegistEvents = impl.RegistEvents
    impl.RegistEvents = function(self)
        if origRegistEvents then origRegistEvents(self) end
        if self.UIRoot and self.UIRoot.Btn_fpslv8 then
            self.UIRoot:AddControlEventByControl("Btn_fpslv8", "OnClicked", self.ClickFPS, self)
        end
        self:AddCommonEvent(EVENTTYPE_SETTING, EVENTID_SETTING_FPS_LIMIT_CONFIRM, self.OnFPSPopConfirm, self)
    end

    impl.GetMaxFPSLevel = function() return 8, 8 end

    impl.CanChangeQualityAndFPSPreCheck = function() return true end

    impl.InitRealSupportFPS = function(self)
        local tbl = {}
        for i = 1, 8 do tbl[i] = { true, true } end
        GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, tbl, false)
        return tbl
    end

    impl.SetFPSAndQualityEnable = function(self, enable)
        if self.UIRoot and self.UIRoot.Image_Mask then
            self:SetWidgetVisible(self.UIRoot.Image_Mask, false)
        end
    end

    impl.UpdateSelectedFPSState = function(self, level)
        local names = {
            [2]="NodeFps20", [3]="NodeFps25", [4]="NodeFps30",
            [5]="NodeFps40", [6]="NodeFps60", [7]="NodeFps90", [8]="NodeFps120"
        }
        if not names[level] then return end
        for k, v in pairs(names) do
            if self.UIRoot[v] then
                self:WidgetSelfHit(self.UIRoot[v])
                self.UIRoot[v]:SetIsEnabled(true)
                local sw = self.UIRoot["WidgetSwitcher_" .. k]
                if sw then sw:SetActiveWidgetIndex(k == level and 0 or 1) end
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
            if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab) == 2 then
                tgt = GraphicSettingDB:GetUIData(GraphicSettingDB.LobbyFPS) or 8
            else
                tgt = GraphicSettingDB:GetUIData(GraphicSettingDB.SelectedFPS) or 8
            end
        end
        self:UpdateSelectedFPSState(tgt)
    end

    impl.DoClickFPS = function(self, level)
        if not slua.isValid(self.UIRoot) then return end
        if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab) == 2 then
            GraphicSettingDB:UpdateUIData(GraphicSettingDB.LobbyFPS, level)
        else
            GraphicSettingDB:UpdateSelectedFPS(level)
        end
        self:UpdateSelectedFPSState(level)
        if self:GetParentUI() then self:GetParentUI():SaveQualityAndFPS(); self:GetParentUI():SetDirty(true) end
    end
    impl.Change120FPSConfirm = function(self, cb) if cb then cb() end end
    impl.ClickExpandFPSConfirm = function(self, cb) if cb then cb() end end
end


local GSC_FPSFT = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT"]
    or require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")

if GSC_FPSFT and GSC_FPSFT.__inner_impl then
    local ft = GSC_FPSFT.__inner_impl
    local MN, MX, ST = 90, 165, 5

    local function clamp(v, l, h)
        if v < l then return l elseif v > h then return h else return v end
    end

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
        local n = (v - MN) / (MX - MN)
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
        s:OnFPSFTValueChange3(math.min(MX, c + ST))
    end

    ft.OnFPSFTMinus3 = function(s)
        local c = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 90
        s:OnFPSFTValueChange3(math.max(MN, c - ST))
    end

    ft.OnFPSFTAdd = ft.OnFPSFTAdd3; ft.OnFPSFTMinus = ft.OnFPSFTMinus3
    ft.OnFPSFTSliderValueChange = ft.OnFPSFTSliderValueChange3
end

local GameplayStatics=import("GameplayStatics")
local GameplayData=require("GameLua.GameCore.Data.GameplayData")

local EAvatarDamagePosition = import("EAvatarDamagePosition")

function M.GetHitBodyType(ImpactResult, InImpactVec)
    return EAvatarDamagePosition.BigHead
end

_G.GetEnemyTargetsFromActors = function(radius)

    local result = {}

    local player = GameplayData.GetPlayerCharacter()

    if not slua.isValid(player) then
        return result
    end

    local uPlayerController = player:GetPlayerControllerSafety()

    if not slua.isValid(uPlayerController) then
        return result
    end

    local ASTExtraPlayerCharacter = import("STExtraPlayerCharacter")

    if not ASTExtraPlayerCharacter then
        return result
    end

    local Actors = Game:GetActorsByClass(ASTExtraPlayerCharacter)

    if not Actors then
        return result
    end

    local count = Actors:Num() or 0
    local myTeam = player:GetTeamID()

    for i = 0, count - 1 do

        local actor = Actors:Get(i)

        if slua.isValid(actor)
            and actor ~= player
            and actor.GetTeamID
            and actor:IsAlive() then

            if actor:GetTeamID() ~= myTeam then

                local dist = player:GetDistanceTo(actor)

                if dist <= radius then
                    table.insert(result, actor)
                end

            end

        end

    end

    return result

end

-- ADITYA_ORG MOD MENU V7

_G.LexusConfig = _G.LexusConfig or {
    EnableFOV = false,
    FOVValue = 80,
    EnableWeaponMod = false,
    EnableMagic = false,
    MagicLevel = 70,
    EnableAutoAim = false,
    AutoAimBone = "Head",
    EnableAiming = false,
    AimingLevel = "LOW",
    EnableNoRecoil = false,
    EnableNoShake = false,
    RecoilLevel = "LESS",
    DisableGrass = false,
    BlackSky = false,
    WeaponMod = {
        [101001] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101002] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101003] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101004] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101005] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101006] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101007] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101008] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101009] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101010] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false}
    }
}

_G.LexusState = _G.LexusState or {}

--- IPAD VIEW MENU

function _G.SetFOV(value)
    local current_time = os.time()
    local expire_time = os.time({year = 2026, month = 6, day = 14, hour = 17, min = 0, sec = 0})
    if current_time >= expire_time then
        return
    end
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local camera = player.ThirdPersonCameraComponent
    if not camera then return end
    camera:SetFieldOfView(value)
end

-- LOGIC WEAPON MOD

_G.otherWeapon = function()
    local current_time = os.time()
    local expire_time = os.time({year = 2026, month = 6, day = 14, hour = 17, min = 0, sec = 0})
    if current_time >= expire_time then
        return
    end
    if not _G.LexusConfig.EnableWeaponMod then 
        return 
    end

    local ok, err = pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        
        local weaponManager = player.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end

        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end

        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end

        local wid = shootComp.WeaponID
        if type(wid) ~= "number" then return end

        local cfg = _G.LexusConfig.WeaponMod[wid]
        if not cfg then return end

        if cfg.FireSpeed then
            shootComp.ShootInterval = 0.07
        end

        if cfg.InstanHit then
            local bulletSpeeds = {
                [101001] = 120000, [101002] = 110000, [101003] = 130000,
                [101004] = 130000, [101005] = 130000, [101006] = 130000,
                [101007] = 130000, [101008] = 130000, [101009] = 130000, [101010] = 130000
            }
            shootComp.BulletFireSpeed = bulletSpeeds[wid] or 130000
        end

        if cfg.FastSwitch then
            shootComp.SwitchFromIdleToBackpackTime = 0
            shootComp.SwitchFromBackpackToIdleTime = 0
        end

        if cfg.FastScope then
            shootComp.WeaponAimInTime = 7
        end
    end)
end

-- LOGIC MAGICBULLET

_G.ResetHitbox = function()
    local current_time = os.time()
    local expire_time = os.time({year = 2026, month = 6, day = 14, hour = 17, min = 0, sec = 0})
    if current_time >= expire_time then
        return
    end
    pcall(function()
        local allChars = Game:GetAllPlayerPawns()
        if allChars then
            for _, enemy in pairs(allChars) do
                if slua.isValid(enemy) and slua.isValid(enemy.Mesh) then
                    enemy.Mesh:RecreatePhysicsState()
                    enemy.Mesh:UpdateBounds()
                end
            end
        end
        _G._MBones = {}
    end)
end

_G.Magic = function()
    local current_time = os.time()
    local expire_time = os.time({year = 2026, month = 6, day = 14, hour = 17, min = 0, sec = 0})
    if current_time >= expire_time then
        return
    end
    if not _G.LexusConfig.EnableMagic then 
        if _G._MBones and next(_G._MBones) ~= nil then
            _G.ResetHitbox()
        end
        return 
    end

    pcall(function()
        local char = GameplayData.GetPlayerCharacter()
        if not slua.isValid(char) then
            return
        end
        local allChars = Game:GetAllPlayerPawns()
        if not allChars then
            return
        end
        
        _G._MBones = _G._MBones or {}
        local currentMagicScale = _G.LexusConfig.MagicLevel or 70

        for _, enemy in pairs(allChars) do
            pcall(function()
                if not slua.isValid(enemy)
                    or enemy == char
                    or enemy.TeamID == char.TeamID then
                    return
                end
                
                local mesh = enemy.Mesh
                if not slua.isValid(mesh) then
                    return
                end
                
                local physAsset = mesh.PhysicsAssetOverride
                if not slua.isValid(physAsset) and slua.isValid(mesh.SkeletalMesh) then
                    physAsset = mesh.SkeletalMesh.PhysicsAsset
                end
                if not slua.isValid(physAsset) then
                    return
                end
                
                local assetName = tostring((physAsset.GetName and physAsset:GetName()) or physAsset)
                if _G._MBones[assetName] then
                    return
                end
                
                local setups = physAsset.SkeletalBodySetups
                if not setups then
                    return
                end
                
                local scaleMap = { head = currentMagicScale }
                
                for i = 0, 60 do
                    pcall(function()
                        local bs = (type(setups.Get) == "function" and setups:Get(i)) or setups[i]
                        if not bs or not slua.isValid(bs) then return end
                        
                        local boneName = tostring(bs.BoneName):lower()
                        local scale = nil
                        for pattern, value in pairs(scaleMap) do
                            if string.find(boneName, pattern:lower()) then
                                scale = value
                                break
                            end
                        end
                        if not scale then return end
                        
                        local ag = bs.AggGeom
                        if not ag then return end
                        
                        pcall(function()
                            local box = ag.BoxElems
                            if box then
                                local elem = (type(box.Get) == "function" and box:Get(0)) or box[1]
                                if elem then
                                    elem.X, elem.Y, elem.Z = scale, scale, scale
                                    if type(box.Set) == "function" then box:Set(0, elem) else box[1] = elem end
                                end
                            end
                        end)
                        pcall(function()
                            local sphyl = ag.SphylElems
                            if sphyl then
                                local elem = (type(sphyl.Get) == "function" and sphyl:Get(0)) or sphyl[1]
                                if elem then
                                    if elem.Radius then elem.Radius = scale end
                                    if elem.Length then elem.Length = scale end
                                    if type(sphyl.Set) == "function" then sphyl:Set(0, elem) else sphyl[1] = elem end
                                end
                            end
                        end)
                        pcall(function()
                            local sphere = ag.SphereElems
                            if sphere then
                                local elem = (type(sphere.Get) == "function" and sphere:Get(0)) or sphere[1]
                                if elem and elem.Radius then
                                    elem.Radius = scale
                                    if type(sphere.Set) == "function" then sphere:Set(0, elem) else sphere[1] = elem end
                                end
                            end
                        end)
                    end)
                end
                
                pcall(function()
                    mesh:RecreatePhysicsState()
                    mesh:WakeAllRigidBodies()
                    mesh:UpdateBounds()
                end)
                
                _G._MBones[assetName] = true
            end)
        end
    end)
end

-- LOGIC AIMLOCK

_G.ApplyAutoAim = function()
    local current_time = os.time()
    local expire_time = os.time({year = 2026, month = 6, day = 14, hour = 17, min = 0, sec = 0})
    if current_time >= expire_time then
        return
    end
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    
    local autoComp = player.AutoAimComp
    if not autoComp then return end

    if _G.LexusConfig.EnableAutoAim then
        local targetBone = _G.LexusConfig.AutoAimBone or "Head"
        autoComp.Bones = { targetBone, targetBone, targetBone }
    else
        autoComp.Bones = nil 
    end
end 

--- LOGIC AIMBOT V1

_G.ApplyAimingConfig = function()
    local current_time = os.time()
    local expire_time = os.time({year = 2026, month = 6, day = 14, hour = 17, min = 0, sec = 0})
    if current_time >= expire_time then
        return
    end
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    
    local weaponManager = player.WeaponManagerComponent
    if not slua.isValid(weaponManager) then return end
    
    local currentWeapon = weaponManager.CurrentWeaponReplicated
    if not slua.isValid(currentWeapon) then return end
    
    local shootComp = currentWeapon.ShootWeaponEntityComp
    if not shootComp then return end
    
    local aa = shootComp.AutoAimingConfig
    if not aa then return end

    if not _G.LexusConfig.EnableAiming then
        if aa.OuterRange.Speed == 3.5 then return end 
        
        local d = { S = 3.5, SR = 1, RR = 1, RRS = 1, SRS = 1, CSR = 1, CR = 0.5, PR = 0.10, DR = 1, GDF = 0 }
        
        aa.OuterRange.Speed = d.S; aa.InnerRange.Speed = d.S
        aa.OuterRange.SpeedRate = d.SR; aa.InnerRange.SpeedRate = d.SR
        aa.OuterRange.RangeRate = d.RR; aa.InnerRange.RangeRate = d.RR
        aa.OuterRange.RangeRateSight = d.RRS; aa.InnerRange.RangeRateSight = d.RRS
        aa.OuterRange.SpeedRateSight = d.SRS; aa.InnerRange.SpeedRateSight = d.SRS
        aa.OuterRange.CenterSpeedRate = d.CSR; aa.InnerRange.CenterSpeedRate = d.CSR
        aa.OuterRange.CrouchRate = d.CR; aa.InnerRange.CrouchRate = d.CR
        aa.OuterRange.ProneRate = d.PR; aa.InnerRange.ProneRate = d.PR
        aa.OuterRange.DyingRate = d.DR; aa.InnerRange.DyingRate = d.DR
        shootComp.GameDeviationFactor = d.GDF
        return
    end

    local level = _G.LexusConfig.AimingLevel or "LOW"
    local configs = {
        LOW     = { S = 5,  SR = 5,  RR = 1,  RRS = 1,  SRS = 5,  CSR = 3,  CR = 1,   PR = 1,   DR = 0, GDF = 0 },
        MEDIUM  = { S = 7,  SR = 7,  RR = 2,  RRS = 2,  SRS = 7,  CSR = 5,  CR = 2,   PR = 2,   DR = 0, GDF = 0 },
        HARD    = { S = 10, SR = 10, RR = 10, RRS = 10, SRS = 10, CSR = 7,  CR = 2,   PR = 2,   DR = 0, GDF = 0 },
        EXTREME = { S = 50, SR = 20, RR = 20, RRS = 20, SRS = 20, CSR = 15, CR = 5,   PR = 5,   DR = 0, GDF = 0 }
    }

    local c = configs[level] or configs.LOW
    
    aa.OuterRange.Speed = c.S;              aa.InnerRange.Speed = c.S
    aa.OuterRange.SpeedRate = c.SR;         aa.InnerRange.SpeedRate = c.SR
    aa.OuterRange.RangeRate = c.RR;         aa.InnerRange.RangeRate = c.RR
    aa.OuterRange.RangeRateSight = c.RRS;   aa.InnerRange.RangeRateSight = c.RRS
    aa.OuterRange.SpeedRateSight = c.SRS;   aa.InnerRange.SpeedRateSight = c.SRS
    aa.OuterRange.CenterSpeedRate = c.CSR;  aa.InnerRange.CenterSpeedRate = c.CSR
    aa.OuterRange.CrouchRate = c.CR;        aa.InnerRange.CrouchRate = c.CR
    aa.OuterRange.ProneRate = c.PR;         aa.InnerRange.ProneRate = c.PR
    aa.OuterRange.DyingRate = c.DR;         aa.InnerRange.DyingRate = c.DR
    
    shootComp.GameDeviationFactor = c.GDF
end

-- LOGIC RECOIL

_G.ApplyNoRecoil = function()
    local current_time = os.time()
    local expire_time = os.time({year = 2026, month = 6, day = 14, hour = 17, min = 0, sec = 0})
    if current_time >= expire_time then
        return
    end
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local weaponManager = player.WeaponManagerComponent
    if not slua.isValid(weaponManager) then return end
    local currentWeapon = weaponManager.CurrentWeaponReplicated
    if not slua.isValid(currentWeapon) then return end
    local shootComp = currentWeapon.ShootWeaponEntityComp
    if not shootComp then return end

    local level = (_G.LexusConfig.EnableNoRecoil and _G.LexusConfig.RecoilLevel) or "DEFAULT"
    local r = shootComp.RecoilInfo

    if level == "DEFAULT" then
        shootComp.RecoilKickADS = 0.2
        shootComp.AccessoriesHRecoilFactor = 0.5
        shootComp.AccessoriesRecoveryFactor = 0.6
        shootComp.AccessoriesVRecoilFactor = 0.5
        if r then
            r.VerticalRecoilMin = 0; r.VerticalRecoilMax = 7; r.VerticalRecoveryMax = 5
            r.RecoilValueClimb = 0.75; r.RecoilValueFail = 2.2; r.VerticalRecoveryModifier = 0.5
            r.RecovertySpeedVertical = 9; r.VerticalRecoveryClamp = 10
            r.LeftMax = -0.8; r.RightMax = 0.8; r.HorizontalTendency = 0.1
            r.RecoilHorizontalMinScalar = 0.1; r.RecoilSpeedHorizontal = 11; r.RecoilSpeedVertical = 11
        end
    elseif level == "LESS" then
        shootComp.RecoilKickADS = 0
        shootComp.AccessoriesHRecoilFactor = 0.2
        shootComp.AccessoriesRecoveryFactor = 0.2
        shootComp.AccessoriesVRecoilFactor = 0.2
        if r then
            r.VerticalRecoilMin = 0; r.VerticalRecoilMax = 2; r.VerticalRecoveryMax = 2
            r.RecoilValueClimb = 0.2; r.RecoilValueFail = 2; r.VerticalRecoveryModifier = 0.2
            r.RecovertySpeedVertical = 2; r.VerticalRecoveryClamp = 2
            r.LeftMax = -0.2; r.RightMax = 0.2; r.HorizontalTendency = 0.1
            r.RecoilHorizontalMinScalar = 0.1; r.RecoilSpeedHorizontal = 2; r.RecoilSpeedVertical = 2
        end
    elseif level == "NO" then
        shootComp.RecoilKickADS = 0
        shootComp.AccessoriesHRecoilFactor = 0
        shootComp.AccessoriesRecoveryFactor = 0
        shootComp.AccessoriesVRecoilFactor = 0
        if r then
            r.VerticalRecoilMin = 0; r.VerticalRecoilMax = 0; r.VerticalRecoveryMax = 0
            r.RecoilValueClimb = 0; r.RecoilValueFail = 0; r.VerticalRecoveryModifier = 0
            r.RecovertySpeedVertical = 0; r.VerticalRecoveryClamp = 0
            r.LeftMax = 0; r.RightMax = 0; r.HorizontalTendency = 0
            r.RecoilHorizontalMinScalar = 0; r.RecoilSpeedHorizontal = 0; r.RecoilSpeedVertical = 0
        end
    end
    
    if _G.LexusConfig.EnableNoShake then
        shootComp.AnimationKick = 0
    end
end

-- LOGIC NO GRASS

_G.DisableGrass = function()
    local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
    local gi = logic_setting_graphics.GetGameInstance()
    if not gi then return end

    if _G.LexusConfig.DisableGrass then
        gi:ExecuteCMD("grass.heightScale", "0")
    else
        gi:ExecuteCMD("grass.heightScale", "1")
    end
end

-- LOGIC BLACK SKY 

_G.BlackSky = function()
    local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
    local gi = logic_setting_graphics.GetGameInstance()
    if not gi then return end

    if _G.LexusConfig.BlackSky then
        gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
    else
        gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0")
    end
end



function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end

    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then return id end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")

    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

local CombinedStack = {

    -- FITUR IPAD VIEW
    {
        Key = "ModMenu_FOV_Ex",
        UI = AliasMap.TitleSwitcher,
        Text = "ADITYA_ORG IPAD VIEW",
        ExpandIndex = 0,
        GetFunc = function() return _G.LexusConfig.EnableFOV end,
        SetFunc = function(c, v)
            _G.LexusConfig.EnableFOV = v
            if not v then _G.SetFOV(90) else _G.SetFOV(_G.LexusConfig.FOVValue) end
            return true
        end
    },
    {
        Key = "ModMenu_FOV_Slider",
        UI = AliasMap.Slider,
        Text = "   FOV Value (80-140)",
        ExpandHandle = "ModMenu_FOV_Ex",
        MinValue = 0, MaxValue = 60, min = 0, max = 60,
        GetFunc = function() return (_G.LexusConfig.FOVValue or 110) - 80 end,
        SetFunc = function(c, v)
            local finalFOV = v + 80
            _G.LexusConfig.FOVValue = finalFOV
            if _G.LexusConfig.EnableFOV then _G.SetFOV(finalFOV) end
            return true
        end
    },

    -- FITUR MAGIC BULLET
    {
        Key = "ModMenu_Magic_Ex",
        UI = AliasMap.TitleSwitcher,
        Text = "ADITYA_ORG MAGIC BULLET",
        ExpandIndex = 0,
        GetFunc = function() return _G.LexusConfig.EnableMagic end,
        SetFunc = function(c, v) 
            _G.LexusConfig.EnableMagic = v
            _G.ResetHitbox()
            return true 
        end
    },
    {
        Key = "ModMenu_Magic_Low",
        UI = AliasMap.Switcher,
        Text = "   [ LEVEL: LOW ]",
        ExpandHandle = "ModMenu_Magic_Ex",
        GetFunc = function() return _G.LexusConfig.MagicLevel == 90 end,
        SetFunc = function(c, v) 
            if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel = 90 end
            return true 
        end
    },
    {
        Key = "ModMenu_Magic_Med",
        UI = AliasMap.Switcher,
        Text = "   [ LEVEL: MEDIUM ]",
        ExpandHandle = "ModMenu_Magic_Ex",
        GetFunc = function() return _G.LexusConfig.MagicLevel == 120 end,
        SetFunc = function(c, v) 
            if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel = 120 end
            return true 
        end
    },
    {
        Key = "ModMenu_Magic_High",
        UI = AliasMap.Switcher,
        Text = "   [ LEVEL: HARD ]",
        ExpandHandle = "ModMenu_Magic_Ex",
        GetFunc = function() return _G.LexusConfig.MagicLevel == 180 end,
        SetFunc = function(c, v) 
            if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel = 180 end
            return true 
        end
    },

    -- FITUR AUTO AIM
    {
        Key = "ModMenu_AutoAim_Ex",
        UI = AliasMap.TitleSwitcher,
        Text = "ADITYA_ORG AUTO AIM",
        ExpandIndex = 0,
        GetFunc = function() return _G.LexusConfig.EnableAutoAim end,
        SetFunc = function(c, v) 
            _G.LexusConfig.EnableAutoAim = v
            _G.ApplyAutoAim()
            return true 
        end
    },
    { 
        Key = "ModMenu_Bones_Title", 
        UI = AliasMap.Title, 
        Text = "TARGET BONES", 
        ExpandHandle = "ModMenu_AutoAim_Ex" 
    },
    {
        Key = "ModMenu_Aim_Head",
        UI = AliasMap.Switcher,
        Text = "   [ BONE: HEAD ]",
        ExpandHandle = "ModMenu_AutoAim_Ex",
        GetFunc = function() return _G.LexusConfig.AutoAimBone == "Head" end,
        SetFunc = function(c, v) 
            if v then _G.LexusConfig.AutoAimBone = "Head"; _G.ApplyAutoAim() end
            return true 
        end
    },
    {
        Key = "ModMenu_Aim_Neck",
        UI = AliasMap.Switcher,
        Text = "   [ BONE: NECK ]",
        ExpandHandle = "ModMenu_AutoAim_Ex",
        GetFunc = function() return _G.LexusConfig.AutoAimBone == "neck_01" end,
        SetFunc = function(c, v) 
            if v then _G.LexusConfig.AutoAimBone = "neck_01"; _G.ApplyAutoAim() end
            return true 
        end
    },
    {
        Key = "ModMenu_Aim_Pelvis",
        UI = AliasMap.Switcher,
        Text = "   [ BONE: PELVIS ]",
        ExpandHandle = "ModMenu_AutoAim_Ex",
        GetFunc = function() return _G.LexusConfig.AutoAimBone == "pelvis" end,
        SetFunc = function(c, v) 
            if v then _G.LexusConfig.AutoAimBone = "pelvis"; _G.ApplyAutoAim() end
            return true 
        end
    },

    -- MENU NOGRASS
    
    { 
    Key = "ModMenu_Grass_Ex", 
    UI = AliasMap.TitleSwitcher, 
    Text = "ADITYA_ORG NO GRASS", 
    GetFunc = function() return _G.LexusConfig.DisableGrass end, 
    SetFunc = function(c, v) 
        _G.LexusConfig.DisableGrass = v
        _G.DisableGrass()
        return true 
    end 
},

   -- MENU BLACKSKY
   { 
    Key = "ModMenu_BlackSky", 
    UI = AliasMap.TitleSwitcher, 
    Text = "ADITYA_ORG BLACKSKY", 
    GetFunc = function() return _G.LexusConfig.BlackSky end, 
    SetFunc = function(c, v) 
        _G.LexusConfig.BlackSky = v
        _G.BlackSky() 
        return true 
    end 
}
}

local AimRecoilStack = {
    -- AIMBOT SECTION
    {
        Key = "ModMenu_AimConfig_Title",
        UI = AliasMap.Title,
        Text = "--- AIMBOT SETTINGS ---"
    },
    {
        Key = "ModMenu_AimConfig_Ex",
        UI = AliasMap.TitleSwitcher,
        Text = "ADITYA_ORG AIMBOT",
        ExpandIndex = 0,
        GetFunc = function() return _G.LexusConfig.EnableAiming end,
        SetFunc = function(c, v) 
            _G.LexusConfig.EnableAiming = v
            _G.ApplyAimingConfig()
            return true 
        end
    },
    { 
        Key = "ModMenu_Aim_Level_Title", 
        UI = AliasMap.Title, 
        Text = "SPEED LEVEL", 
        ExpandHandle = "ModMenu_AimConfig_Ex" 
    },
    {
        Key = "ModMenu_Aim_Low",
        UI = AliasMap.Switcher,
        Text = "   [ LEVEL: LOW ]",
        ExpandHandle = "ModMenu_AimConfig_Ex",
        GetFunc = function() return _G.LexusConfig.AimingLevel == "LOW" end,
        SetFunc = function(c, v) 
            if v then _G.LexusConfig.AimingLevel = "LOW"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end 
            return true 
        end
    },
    {
        Key = "ModMenu_Aim_Med",
        UI = AliasMap.Switcher,
        Text = "   [ LEVEL: MEDIUM ]",
        ExpandHandle = "ModMenu_AimConfig_Ex",
        GetFunc = function() return _G.LexusConfig.AimingLevel == "MEDIUM" end,
        SetFunc = function(c, v) 
            if v then _G.LexusConfig.AimingLevel = "MEDIUM"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end 
            return true 
        end
    },
    {
        Key = "ModMenu_Aim_Hard",
        UI = AliasMap.Switcher,
        Text = "   [ LEVEL: HARD ]",
        ExpandHandle = "ModMenu_AimConfig_Ex",
        GetFunc = function() return _G.LexusConfig.AimingLevel == "HARD" end,
        SetFunc = function(c, v) 
            if v then _G.LexusConfig.AimingLevel = "HARD"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end 
            return true 
        end
    },
    {
        Key = "ModMenu_Aim_Ext",
        UI = AliasMap.Switcher,
        Text = "   [ LEVEL: EXTREME ]",
        ExpandHandle = "ModMenu_AimConfig_Ex",
        GetFunc = function() return _G.LexusConfig.AimingLevel == "EXTREME" end,
        SetFunc = function(c, v) 
            if v then _G.LexusConfig.AimingLevel = "EXTREME"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end 
            return true 
        end
    },

    -- RECOIL SECTION
    {
        Key = "ModMenu_Recoil_Title",
        UI = AliasMap.Title,
        Text = "--- RECOIL SETTINGS ---"
    },
    {
        Key = "ModMenu_Recoil_Ex",
        UI = AliasMap.TitleSwitcher,
        Text = "ADITYA_ORG NO RECOIL",
        ExpandIndex = 0,
        GetFunc = function() return _G.LexusConfig.EnableNoRecoil end,
        SetFunc = function(c, v) 
            _G.LexusConfig.EnableNoRecoil = v
            _G.ApplyNoRecoil()
            return true 
        end
    },
    {
        Key = "ModMenu_NoShake",
        UI = AliasMap.Switcher,
        Text = "   [ NO SHAKE ]",
        ExpandHandle = "ModMenu_Recoil_Ex",
        GetFunc = function() return _G.LexusConfig.EnableNoShake end,
        SetFunc = function(c, v) _G.LexusConfig.EnableNoShake = v; _G.ApplyNoRecoil(); return true end
    },
    {
        Key = "ModMenu_Recoil_Less",
        UI = AliasMap.Switcher,
        Text = "   [ LESS RECOIL ]",
        ExpandHandle = "ModMenu_Recoil_Ex",
        GetFunc = function() return _G.LexusConfig.RecoilLevel == "LESS" end,
        SetFunc = function(c, v) 
            if v then _G.LexusConfig.RecoilLevel = "LESS"; _G.LexusConfig.EnableNoRecoil = true; _G.ApplyNoRecoil() end 
            return true 
        end
    }

}






local WeaponStack = {
    { 
        Key = "ModMenu_Weapon_Ex", 
        UI = AliasMap.TitleSwitcher, 
        Text = "ADITYA_ORG WEAPON MOD", 
        ExpandIndex = 0,
        GetFunc = function() return _G.LexusConfig.EnableWeaponMod end, 
        SetFunc = function(c, v) _G.LexusConfig.EnableWeaponMod = v; return true end 
    },

    -- ID 101001 (AKM)
    { Key = "ModMenu_W101001_Title", UI = AliasMap.Title, Text = "AKM", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101001_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101001].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].FireSpeed = v; return true end },
    { Key = "ModMenu_W101001_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101001].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].InstanHit = v; return true end },
    { Key = "ModMenu_W101001_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101001].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].FastSwitch = v; return true end },
    { Key = "ModMenu_W101001_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101001].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].FastScope = v; return true end },

    -- ID 101002 (M16A4)
    { Key = "ModMenu_W101002_Title", UI = AliasMap.Title, Text = "M16A4", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101002_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101002].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101002].FireSpeed = v; return true end },
    { Key = "ModMenu_W101002_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101002].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101002].InstanHit = v; return true end },
    { Key = "ModMenu_W101002_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101002].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101002].FastSwitch = v; return true end },
    { Key = "ModMenu_W101002_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101002].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101002].FastScope = v; return true end },

    -- ID 101003 (SCAR-L)
    { Key = "ModMenu_W101003_Title", UI = AliasMap.Title, Text = "SCAR-L", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101003_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101003].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].FireSpeed = v; return true end },
    { Key = "ModMenu_W101003_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101003].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].InstanHit = v; return true end },
    { Key = "ModMenu_W101003_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101003].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].FastSwitch = v; return true end },
    { Key = "ModMenu_W101003_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101003].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].FastScope = v; return true end },

    -- ID 101004 (M416)
    { Key = "ModMenu_W101004_Title", UI = AliasMap.Title, Text = "M416", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101004_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101004].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].FireSpeed = v; return true end },
    { Key = "ModMenu_W101004_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101004].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].InstanHit = v; return true end },
    { Key = "ModMenu_W101004_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101004].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].FastSwitch = v; return true end },
    { Key = "ModMenu_W101004_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101004].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].FastScope = v; return true end },

    -- ID 101005 (Groza)
    { Key = "ModMenu_W101005_Title", UI = AliasMap.Title, Text = "Groza", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101005_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101005].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101005].FireSpeed = v; return true end },
    { Key = "ModMenu_W101005_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101005].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101005].InstanHit = v; return true end },
    { Key = "ModMenu_W101005_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101005].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101005].FastSwitch = v; return true end },
    { Key = "ModMenu_W101005_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101005].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101005].FastScope = v; return true end },

    -- ID 101006 (AUG)
    { Key = "ModMenu_W101006_Title", UI = AliasMap.Title, Text = "AUG", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101006_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101006].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101006].FireSpeed = v; return true end },
    { Key = "ModMenu_W101006_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101006].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101006].InstanHit = v; return true end },
    { Key = "ModMenu_W101006_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101006].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101006].FastSwitch = v; return true end },
    { Key = "ModMenu_W101006_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101006].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101006].FastScope = v; return true end },

    -- ID 101007 (QBZ)
    { Key = "ModMenu_W101007_Title", UI = AliasMap.Title, Text = "QBZ", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101007_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101007].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101007].FireSpeed = v; return true end },
    { Key = "ModMenu_W101007_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101007].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101007].InstanHit = v; return true end },
    { Key = "ModMenu_W101007_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101007].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101007].FastSwitch = v; return true end },
    { Key = "ModMenu_W101007_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101007].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101007].FastScope = v; return true end },

    -- ID 101008 (M762)
    { Key = "ModMenu_W101008_Title", UI = AliasMap.Title, Text = "M762", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101008_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101008].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101008].FireSpeed = v; return true end },
    { Key = "ModMenu_W101008_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101008].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101008].InstanHit = v; return true end },
    { Key = "ModMenu_W101008_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101008].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101008].FastSwitch = v; return true end },
    { Key = "ModMenu_W101008_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101008].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101008].FastScope = v; return true end },

    -- ID 101009 (Mk47 Mutant)
    { Key = "ModMenu_W101009_Title", UI = AliasMap.Title, Text = "Mk47 Mutant", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101009_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101009].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101009].FireSpeed = v; return true end },
    { Key = "ModMenu_W101009_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101009].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101009].InstanHit = v; return true end },
    { Key = "ModMenu_W101009_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101009].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101009].FastSwitch = v; return true end },
    { Key = "ModMenu_W101009_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101009].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101009].FastScope = v; return true end },

    -- ID 101010 (G36C)
    { Key = "ModMenu_W101010_Title", UI = AliasMap.Title, Text = "G36C", ExpandHandle = "ModMenu_Weapon_Ex" },
    { Key = "ModMenu_W101010_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101010].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101010].FireSpeed = v; return true end },
    { Key = "ModMenu_W101010_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101010].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101010].InstanHit = v; return true end },
    { Key = "ModMenu_W101010_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101010].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101010].FastSwitch = v; return true end },
    { Key = "ModMenu_W101010_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101010].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101010].FastScope = v; return true end }
}


        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            loc = "ADITYA_ORG MENU",
            UIKey = "Setting_Page_Privacy",
            Category = {
                { Key = "Cat_General", loc = "BASIC MOD", Stack = CombinedStack },
                { Key = "Cat_Weapon", loc = "WEAPON MOD", Stack = WeaponStack },
                { Key = "Cat_Aimbot", loc = "AIMBOT & RECOIL MOD", Stack = AimRecoilStack }
            }
        }


        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}; local n = select('#', ...)
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if type(catalog) == "table" then
                    local hasModMenu = false
                    for _, page in ipairs(catalog) do if type(page) == "table" and page.Key == "ModMenu" then hasModMenu = true; break end end
                    if not hasModMenu then table.insert(catalog, SettingPageDefine.ModMenu) end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end






function M.OnCtor(self)
end

function M.OnPost(self)
    self:OnAdvance()
    self:OnTick(DeltaTime)
end

function M.OnTick(self, DeltaTime)

    -- WEAPON MOD
    if _G.LexusConfig.EnableWeaponMod then
        _G.otherWeapon()
    end
    
    -- AIM + RECOIL MOD
    if _G.LexusConfig.EnableAiming then
        _G.ApplyAimingConfig()
    end    
    if _G.LexusConfig.EnableNoRecoil then
        _G.ApplyNoRecoil()
    end        
    
    -- MAGIC BULLET
    if _G.LexusConfig.EnableMagic then
        _G.Magic()
    else
        if _G._MBones then
            _G._MBones = {} 
        end
    end
    
end
 

function M.OnAdvance(self)
    if not Client then return end 

    if self.HitMarkTimer then 
        _G.KillTimer(self.HitMarkTimer) 
        self.HitMarkTimer = nil 
    end 

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