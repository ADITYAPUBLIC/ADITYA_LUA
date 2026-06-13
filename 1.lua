--[[
    ADITYA_ORG MOD - Self-Injecting Edition
    Refactored to work with the same injection style as the first script.
]]

-- Per-match guard: allow re-init when the player controller changes
do
    local hud = slua_GameFrontendHUD
    if not hud then return end
    local pc = hud:GetPlayerController()
    if not pc then return end
    local pawn = pc:GetCurPawn()
    if not pawn then return end
    if _G._ADITYA_MOD_LOADED and _G._ADITYA_MOD_PAWN == pawn then return end
    _G._ADITYA_MOD_LOADED = true
    _G._ADITYA_MOD_PAWN = pawn
end

-- ==================== GLOBAL CONFIG ====================
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

-- ==================== BYPASS FUNCTIONS (from second script) ====================
function _G.TryBypassMD5()
    if _G.MD5Bypassed then return end
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

function _G.BypassSecurityUtils()
    pcall(function()
        local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")        
        if SecurityCommonUtils then
            if SecurityCommonUtils.EStrategyTypeInReplay then
                for k, v in pairs(SecurityCommonUtils.EStrategyTypeInReplay) do
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

function _G.BypassHiggsComponent()
    pcall(function()
        local HiggsComponentClass = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")        
        if HiggsComponentClass then
            local CHiggsBosonComponent = HiggsComponentClass
            if type(HiggsComponentClass) == "table" and HiggsComponentClass.__index then
                CHiggsBosonComponent = HiggsComponentClass.__index
            end
            CHiggsBosonComponent.StaticShowSecurityAlertInDev = function() end
            CHiggsBosonComponent._ClientShowSecurityAlertWindow = function() end
            CHiggsBosonComponent._ReportChatRobot = function() end
            CHiggsBosonComponent._ProcessReportChatRobotQueue = function() end
            CHiggsBosonComponent.RecordStrategyTimestampInReplay = function() end
            CHiggsBosonComponent.SendAntiDataFlow = function() end
            CHiggsBosonComponent.SendHitFireBtnFlow = function() end
            CHiggsBosonComponent.OnBattleResult = function() end
            CHiggsBosonComponent.SendHisarData = function() end
            if CHiggsBosonComponent.ClientRPC then
                CHiggsBosonComponent.ClientRPC.RPC_Client_ShowSecurityAlertWindow = function() end
                CHiggsBosonComponent.ClientRPC.RPC_Client_ServerNameAck = function() end
            end
            if CHiggsBosonComponent.ServerRPC then
                CHiggsBosonComponent.ServerRPC.RPC_Server_TellServerName = function() end
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

-- ==================== FEATURE IMPLEMENTATIONS ====================
function _G.SetFOV(value)
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local camera = player.ThirdPersonCameraComponent
    if not camera then return end
    camera:SetFieldOfView(value)
end

function _G.otherWeapon()
    if not _G.LexusConfig.EnableWeaponMod then return end
    pcall(function()
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
        if cfg.FireSpeed then shootComp.ShootInterval = 0.07 end
        if cfg.InstanHit then
            local bulletSpeeds = {
                [101001]=120000,[101002]=110000,[101003]=130000,[101004]=130000,
                [101005]=130000,[101006]=130000,[101007]=130000,[101008]=130000,
                [101009]=130000,[101010]=130000
            }
            shootComp.BulletFireSpeed = bulletSpeeds[wid] or 130000
        end
        if cfg.FastSwitch then
            shootComp.SwitchFromIdleToBackpackTime = 0
            shootComp.SwitchFromBackpackToIdleTime = 0
        end
        if cfg.FastScope then shootComp.WeaponAimInTime = 7 end
    end)
end

function _G.ResetHitbox()
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

function _G.Magic()
    if not _G.LexusConfig.EnableMagic then
        if _G._MBones and next(_G._MBones) ~= nil then _G.ResetHitbox() end
        return
    end
    pcall(function()
        local char = GameplayData.GetPlayerCharacter()
        if not slua.isValid(char) then return end
        local allChars = Game:GetAllPlayerPawns()
        if not allChars then return end
        _G._MBones = _G._MBones or {}
        local currentMagicScale = _G.LexusConfig.MagicLevel or 70
        for _, enemy in pairs(allChars) do
            pcall(function()
                if not slua.isValid(enemy) or enemy == char or enemy.TeamID == char.TeamID then return end
                local mesh = enemy.Mesh
                if not slua.isValid(mesh) then return end
                local physAsset = mesh.PhysicsAssetOverride
                if not slua.isValid(physAsset) and slua.isValid(mesh.SkeletalMesh) then
                    physAsset = mesh.SkeletalMesh.PhysicsAsset
                end
                if not slua.isValid(physAsset) then return end
                local assetName = tostring((physAsset.GetName and physAsset:GetName()) or physAsset)
                if _G._MBones[assetName] then return end
                local setups = physAsset.SkeletalBodySetups
                if not setups then return end
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

function _G.ApplyAutoAim()
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

function _G.ApplyAimingConfig()
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
        local d = { S=3.5, SR=1, RR=1, RRS=1, SRS=1, CSR=1, CR=0.5, PR=0.10, DR=1, GDF=0 }
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
        LOW = {S=5, SR=5, RR=1, RRS=1, SRS=5, CSR=3, CR=1, PR=1, DR=0, GDF=0},
        MEDIUM = {S=7, SR=7, RR=2, RRS=2, SRS=7, CSR=5, CR=2, PR=2, DR=0, GDF=0},
        HARD = {S=10, SR=10, RR=10, RRS=10, SRS=10, CSR=7, CR=2, PR=2, DR=0, GDF=0},
        EXTREME = {S=50, SR=20, RR=20, RRS=20, SRS=20, CSR=15, CR=5, PR=5, DR=0, GDF=0}
    }
    local c = configs[level] or configs.LOW
    aa.OuterRange.Speed = c.S; aa.InnerRange.Speed = c.S
    aa.OuterRange.SpeedRate = c.SR; aa.InnerRange.SpeedRate = c.SR
    aa.OuterRange.RangeRate = c.RR; aa.InnerRange.RangeRate = c.RR
    aa.OuterRange.RangeRateSight = c.RRS; aa.InnerRange.RangeRateSight = c.RRS
    aa.OuterRange.SpeedRateSight = c.SRS; aa.InnerRange.SpeedRateSight = c.SRS
    aa.OuterRange.CenterSpeedRate = c.CSR; aa.InnerRange.CenterSpeedRate = c.CSR
    aa.OuterRange.CrouchRate = c.CR; aa.InnerRange.CrouchRate = c.CR
    aa.OuterRange.ProneRate = c.PR; aa.InnerRange.ProneRate = c.PR
    aa.OuterRange.DyingRate = c.DR; aa.InnerRange.DyingRate = c.DR
    shootComp.GameDeviationFactor = c.GDF
end

function _G.ApplyNoRecoil()
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
            r.VerticalRecoilMin=0; r.VerticalRecoilMax=7; r.VerticalRecoveryMax=5
            r.RecoilValueClimb=0.75; r.RecoilValueFail=2.2; r.VerticalRecoveryModifier=0.5
            r.RecovertySpeedVertical=9; r.VerticalRecoveryClamp=10
            r.LeftMax=-0.8; r.RightMax=0.8; r.HorizontalTendency=0.1
            r.RecoilHorizontalMinScalar=0.1; r.RecoilSpeedHorizontal=11; r.RecoilSpeedVertical=11
        end
    elseif level == "LESS" then
        shootComp.RecoilKickADS = 0
        shootComp.AccessoriesHRecoilFactor = 0.2
        shootComp.AccessoriesRecoveryFactor = 0.2
        shootComp.AccessoriesVRecoilFactor = 0.2
        if r then
            r.VerticalRecoilMin=0; r.VerticalRecoilMax=2; r.VerticalRecoveryMax=2
            r.RecoilValueClimb=0.2; r.RecoilValueFail=2; r.VerticalRecoveryModifier=0.2
            r.RecovertySpeedVertical=2; r.VerticalRecoveryClamp=2
            r.LeftMax=-0.2; r.RightMax=0.2; r.HorizontalTendency=0.1
            r.RecoilHorizontalMinScalar=0.1; r.RecoilSpeedHorizontal=2; r.RecoilSpeedVertical=2
        end
    elseif level == "NO" then
        shootComp.RecoilKickADS = 0
        shootComp.AccessoriesHRecoilFactor = 0
        shootComp.AccessoriesRecoveryFactor = 0
        shootComp.AccessoriesVRecoilFactor = 0
        if r then
            r.VerticalRecoilMin=0; r.VerticalRecoilMax=0; r.VerticalRecoveryMax=0
            r.RecoilValueClimb=0; r.RecoilValueFail=0; r.VerticalRecoveryModifier=0
            r.RecovertySpeedVertical=0; r.VerticalRecoveryClamp=0
            r.LeftMax=0; r.RightMax=0; r.HorizontalTendency=0
            r.RecoilHorizontalMinScalar=0; r.RecoilSpeedHorizontal=0; r.RecoilSpeedVertical=0
        end
    end
    if _G.LexusConfig.EnableNoShake then shootComp.AnimationKick = 0 end
end

function _G.DisableGrass()
    local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
    local gi = logic_setting_graphics.GetGameInstance()
    if not gi then return end
    if _G.LexusConfig.DisableGrass then
        gi:ExecuteCMD("grass.heightScale", "0")
    else
        gi:ExecuteCMD("grass.heightScale", "1")
    end
end

function _G.BlackSky()
    local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
    local gi = logic_setting_graphics.GetGameInstance()
    if not gi then return end
    if _G.LexusConfig.BlackSky then
        gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
    else
        gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0")
    end
end

-- ==================== MOD MENU INTEGRATION (same as original) ====================
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
            { Key = "ModMenu_FOV_Ex", UI = AliasMap.TitleSwitcher, Text = "ADITYA_ORG IPAD VIEW", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableFOV end,
              SetFunc = function(c, v) _G.LexusConfig.EnableFOV = v; if not v then _G.SetFOV(90) else _G.SetFOV(_G.LexusConfig.FOVValue) end; return true end },
            { Key = "ModMenu_FOV_Slider", UI = AliasMap.Slider, Text = "   FOV Value (80-140)", ExpandHandle = "ModMenu_FOV_Ex", MinValue = 0, MaxValue = 60, min = 0, max = 60,
              GetFunc = function() return (_G.LexusConfig.FOVValue or 110) - 80 end,
              SetFunc = function(c, v) local finalFOV = v + 80; _G.LexusConfig.FOVValue = finalFOV; if _G.LexusConfig.EnableFOV then _G.SetFOV(finalFOV) end; return true end },
            { Key = "ModMenu_Magic_Ex", UI = AliasMap.TitleSwitcher, Text = "ADITYA_ORG MAGIC BULLET", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableMagic end,
              SetFunc = function(c, v) _G.LexusConfig.EnableMagic = v; _G.ResetHitbox(); return true end },
            { Key = "ModMenu_Magic_Low", UI = AliasMap.Switcher, Text = "   [ LEVEL: LOW ]", ExpandHandle = "ModMenu_Magic_Ex",
              GetFunc = function() return _G.LexusConfig.MagicLevel == 90 end,
              SetFunc = function(c, v) if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel = 90 end; return true end },
            { Key = "ModMenu_Magic_Med", UI = AliasMap.Switcher, Text = "   [ LEVEL: MEDIUM ]", ExpandHandle = "ModMenu_Magic_Ex",
              GetFunc = function() return _G.LexusConfig.MagicLevel == 120 end,
              SetFunc = function(c, v) if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel = 120 end; return true end },
            { Key = "ModMenu_Magic_High", UI = AliasMap.Switcher, Text = "   [ LEVEL: HARD ]", ExpandHandle = "ModMenu_Magic_Ex",
              GetFunc = function() return _G.LexusConfig.MagicLevel == 180 end,
              SetFunc = function(c, v) if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel = 180 end; return true end },
            { Key = "ModMenu_AutoAim_Ex", UI = AliasMap.TitleSwitcher, Text = "ADITYA_ORG AUTO AIM", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableAutoAim end,
              SetFunc = function(c, v) _G.LexusConfig.EnableAutoAim = v; _G.ApplyAutoAim(); return true end },
            { Key = "ModMenu_Bones_Title", UI = AliasMap.Title, Text = "TARGET BONES", ExpandHandle = "ModMenu_AutoAim_Ex" },
            { Key = "ModMenu_Aim_Head", UI = AliasMap.Switcher, Text = "   [ BONE: HEAD ]", ExpandHandle = "ModMenu_AutoAim_Ex",
              GetFunc = function() return _G.LexusConfig.AutoAimBone == "Head" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AutoAimBone = "Head"; _G.ApplyAutoAim() end; return true end },
            { Key = "ModMenu_Aim_Neck", UI = AliasMap.Switcher, Text = "   [ BONE: NECK ]", ExpandHandle = "ModMenu_AutoAim_Ex",
              GetFunc = function() return _G.LexusConfig.AutoAimBone == "neck_01" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AutoAimBone = "neck_01"; _G.ApplyAutoAim() end; return true end },
            { Key = "ModMenu_Aim_Pelvis", UI = AliasMap.Switcher, Text = "   [ BONE: PELVIS ]", ExpandHandle = "ModMenu_AutoAim_Ex",
              GetFunc = function() return _G.LexusConfig.AutoAimBone == "pelvis" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AutoAimBone = "pelvis"; _G.ApplyAutoAim() end; return true end },
            { Key = "ModMenu_Grass_Ex", UI = AliasMap.TitleSwitcher, Text = "ADITYA_ORG NO GRASS",
              GetFunc = function() return _G.LexusConfig.DisableGrass end,
              SetFunc = function(c, v) _G.LexusConfig.DisableGrass = v; _G.DisableGrass(); return true end },
            { Key = "ModMenu_BlackSky", UI = AliasMap.TitleSwitcher, Text = "ADITYA_ORG BLACKSKY",
              GetFunc = function() return _G.LexusConfig.BlackSky end,
              SetFunc = function(c, v) _G.LexusConfig.BlackSky = v; _G.BlackSky(); return true end }
        }

        local AimRecoilStack = {
            { Key = "ModMenu_AimConfig_Title", UI = AliasMap.Title, Text = "--- AIMBOT SETTINGS ---" },
            { Key = "ModMenu_AimConfig_Ex", UI = AliasMap.TitleSwitcher, Text = "ADITYA_ORG AIMBOT", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableAiming end,
              SetFunc = function(c, v) _G.LexusConfig.EnableAiming = v; _G.ApplyAimingConfig(); return true end },
            { Key = "ModMenu_Aim_Level_Title", UI = AliasMap.Title, Text = "SPEED LEVEL", ExpandHandle = "ModMenu_AimConfig_Ex" },
            { Key = "ModMenu_Aim_Low", UI = AliasMap.Switcher, Text = "   [ LEVEL: LOW ]", ExpandHandle = "ModMenu_AimConfig_Ex",
              GetFunc = function() return _G.LexusConfig.AimingLevel == "LOW" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AimingLevel = "LOW"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end; return true end },
            { Key = "ModMenu_Aim_Med", UI = AliasMap.Switcher, Text = "   [ LEVEL: MEDIUM ]", ExpandHandle = "ModMenu_AimConfig_Ex",
              GetFunc = function() return _G.LexusConfig.AimingLevel == "MEDIUM" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AimingLevel = "MEDIUM"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end; return true end },
            { Key = "ModMenu_Aim_Hard", UI = AliasMap.Switcher, Text = "   [ LEVEL: HARD ]", ExpandHandle = "ModMenu_AimConfig_Ex",
              GetFunc = function() return _G.LexusConfig.AimingLevel == "HARD" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AimingLevel = "HARD"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end; return true end },
            { Key = "ModMenu_Aim_Ext", UI = AliasMap.Switcher, Text = "   [ LEVEL: EXTREME ]", ExpandHandle = "ModMenu_AimConfig_Ex",
              GetFunc = function() return _G.LexusConfig.AimingLevel == "EXTREME" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AimingLevel = "EXTREME"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end; return true end },
            { Key = "ModMenu_Recoil_Title", UI = AliasMap.Title, Text = "--- RECOIL SETTINGS ---" },
            { Key = "ModMenu_Recoil_Ex", UI = AliasMap.TitleSwitcher, Text = "ADITYA_ORG NO RECOIL", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableNoRecoil end,
              SetFunc = function(c, v) _G.LexusConfig.EnableNoRecoil = v; _G.ApplyNoRecoil(); return true end },
            { Key = "ModMenu_NoShake", UI = AliasMap.Switcher, Text = "   [ NO SHAKE ]", ExpandHandle = "ModMenu_Recoil_Ex",
              GetFunc = function() return _G.LexusConfig.EnableNoShake end,
              SetFunc = function(c, v) _G.LexusConfig.EnableNoShake = v; _G.ApplyNoRecoil(); return true end },
            { Key = "ModMenu_Recoil_Less", UI = AliasMap.Switcher, Text = "   [ LESS RECOIL ]", ExpandHandle = "ModMenu_Recoil_Ex",
              GetFunc = function() return _G.LexusConfig.RecoilLevel == "LESS" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.RecoilLevel = "LESS"; _G.LexusConfig.EnableNoRecoil = true; _G.ApplyNoRecoil() end; return true end }
        }

        local WeaponStack = {
            { Key = "ModMenu_Weapon_Ex", UI = AliasMap.TitleSwitcher, Text = "ADITYA_ORG WEAPON MOD", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableWeaponMod end,
              SetFunc = function(c, v) _G.LexusConfig.EnableWeaponMod = v; return true end },
            -- AKM
            { Key = "ModMenu_W101001_Title", UI = AliasMap.Title, Text = "AKM", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101001_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101001].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].FireSpeed = v; return true end },
            { Key = "ModMenu_W101001_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101001].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].InstanHit = v; return true end },
            { Key = "ModMenu_W101001_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101001].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].FastSwitch = v; return true end },
            { Key = "ModMenu_W101001_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101001].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].FastScope = v; return true end },
            -- M16A4
            { Key = "ModMenu_W101002_Title", UI = AliasMap.Title, Text = "M16A4", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101002_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101002].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101002].FireSpeed = v; return true end },
            { Key = "ModMenu_W101002_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101002].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101002].InstanHit = v; return true end },
            { Key = "ModMenu_W101002_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101002].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101002].FastSwitch = v; return true end },
            { Key = "ModMenu_W101002_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101002].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101002].FastScope = v; return true end },
            -- SCAR-L
            { Key = "ModMenu_W101003_Title", UI = AliasMap.Title, Text = "SCAR-L", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101003_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101003].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].FireSpeed = v; return true end },
            { Key = "ModMenu_W101003_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101003].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].InstanHit = v; return true end },
            { Key = "ModMenu_W101003_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101003].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].FastSwitch = v; return true end },
            { Key = "ModMenu_W101003_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101003].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].FastScope = v; return true end },
            -- M416
            { Key = "ModMenu_W101004_Title", UI = AliasMap.Title, Text = "M416", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101004_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101004].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].FireSpeed = v; return true end },
            { Key = "ModMenu_W101004_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101004].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].InstanHit = v; return true end },
            { Key = "ModMenu_W101004_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101004].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].FastSwitch = v; return true end },
            { Key = "ModMenu_W101004_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101004].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].FastScope = v; return true end },
            -- Groza
            { Key = "ModMenu_W101005_Title", UI = AliasMap.Title, Text = "Groza", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101005_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101005].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101005].FireSpeed = v; return true end },
            { Key = "ModMenu_W101005_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101005].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101005].InstanHit = v; return true end },
            { Key = "ModMenu_W101005_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101005].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101005].FastSwitch = v; return true end },
            { Key = "ModMenu_W101005_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101005].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101005].FastScope = v; return true end },
            -- AUG
            { Key = "ModMenu_W101006_Title", UI = AliasMap.Title, Text = "AUG", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101006_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101006].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101006].FireSpeed = v; return true end },
            { Key = "ModMenu_W101006_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101006].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101006].InstanHit = v; return true end },
            { Key = "ModMenu_W101006_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101006].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101006].FastSwitch = v; return true end },
            { Key = "ModMenu_W101006_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101006].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101006].FastScope = v; return true end },
            -- QBZ
            { Key = "ModMenu_W101007_Title", UI = AliasMap.Title, Text = "QBZ", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101007_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101007].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101007].FireSpeed = v; return true end },
            { Key = "ModMenu_W101007_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101007].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101007].InstanHit = v; return true end },
            { Key = "ModMenu_W101007_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101007].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101007].FastSwitch = v; return true end },
            { Key = "ModMenu_W101007_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101007].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101007].FastScope = v; return true end },
            -- M762
            { Key = "ModMenu_W101008_Title", UI = AliasMap.Title, Text = "M762", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101008_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101008].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101008].FireSpeed = v; return true end },
            { Key = "ModMenu_W101008_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101008].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101008].InstanHit = v; return true end },
            { Key = "ModMenu_W101008_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101008].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101008].FastSwitch = v; return true end },
            { Key = "ModMenu_W101008_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101008].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101008].FastScope = v; return true end },
            -- Mk47 Mutant
            { Key = "ModMenu_W101009_Title", UI = AliasMap.Title, Text = "Mk47 Mutant", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101009_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101009].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101009].FireSpeed = v; return true end },
            { Key = "ModMenu_W101009_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101009].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101009].InstanHit = v; return true end },
            { Key = "ModMenu_W101009_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101009].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101009].FastSwitch = v; return true end },
            { Key = "ModMenu_W101009_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101009].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101009].FastScope = v; return true end },
            -- G36C
            { Key = "ModMenu_W101010_Title", UI = AliasMap.Title, Text = "G36C", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101010_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101010].FireSpeed end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101010].FireSpeed = v; return true end },
            { Key = "ModMenu_W101010_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101010].InstanHit end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101010].InstanHit = v; return true end },
            { Key = "ModMenu_W101010_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101010].FastSwitch end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101010].FastSwitch = v; return true end },
            { Key = "ModMenu_W101010_O", UI = AliasMap.Switcher, Text = "   FAST OPEN SCOPE", ExpandHandle = "ModMenu_Weapon_Ex",
              GetFunc = function() return _G.LexusConfig.WeaponMod[101010].FastScope end,
              SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101010].FastScope = v; return true end }
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
            local args = {...}
            local n = select('#', ...)
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if type(catalog) == "table" then
                    local hasModMenu = false
                    for _, page in ipairs(catalog) do
                        if type(page) == "table" and page.Key == "ModMenu" then hasModMenu = true; break end
                    end
                    if not hasModMenu then
                        table.insert(catalog, SettingPageDefine.ModMenu)
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

-- ==================== MAIN TICK LOOP (replaces OnTick) ====================
local function AdityaMainTick()
    pcall(function()
        if not _G.CheatsEnabled then return end

        -- Apply weapon mods
        if _G.LexusConfig.EnableWeaponMod then
            _G.otherWeapon()
        end

        -- Apply aimbot & recoil
        if _G.LexusConfig.EnableAiming then
            _G.ApplyAimingConfig()
        end
        if _G.LexusConfig.EnableNoRecoil then
            _G.ApplyNoRecoil()
        end

        -- Magic bullet
        if _G.LexusConfig.EnableMagic then
            _G.Magic()
        elseif _G._MBones then
            _G._MBones = {}
        end

        -- Grass & sky
        _G.DisableGrass()
        _G.BlackSky()

        -- FOV / iPad view
        if _G.LexusConfig.EnableFOV then
            _G.SetFOV(_G.LexusConfig.FOVValue)
        end
    end)
end

-- ==================== AUTO-START TIMER (like first script) ====================
local function StartAdityaMod()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not (pc and slua.isValid(pc)) then
        -- retry after 1 second
        if slua_GameFrontendHUD and slua_GameFrontendHUD.AddGameTimer then
            slua_GameFrontendHUD:AddGameTimer(1.0, false, StartAdityaMod)
        end
        return
    end
    if _G._ADITYA_TIMER then
        -- already running
        return
    end
    _G._ADITYA_TIMER = pc:AddGameTimer(0.2, true, AdityaMainTick)
end

-- Run bypasses and menu init once
pcall(function()
    _G.TryBypassMD5()
    _G.BypassCacheMD5()
    _G.BypassSecurityUtils()
    _G.BypassHiggsComponent()
    _G.InitModMenuTab()
    _G.TryShowLegalCredit()
end)

-- Start the main tick timer
StartAdityaMod()