
-- ============================================================================

local RPCConfig = {
    ServerRPC = {},
    ClientRPC = {},
    MulticastRPC = {}
}

RPCConfig.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
RPCConfig.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
RPCConfig.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
RPCConfig.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
RPCConfig.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }
RPCConfig.ClientRPC.ClientRPC_TriggerHighlightMoment = { Reliable = true, Params = { UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32 } }

-- ============================================================================
-- SECTION 2: IMPORTS & DEPENDENCIES
-- ============================================================================

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local KismetMathLibrary = import("KismetMathLibrary")
local GameplayStatics = import("GameplayStatics")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")

local currentTime = os.time(os.date("!*t"))
local expirationDate = os.time({ year = 2028, month = 5, day = 15, hour = 6, min = 45, sec = 0 })

-- ============================================================================
-- SECTION 3: FPS UNLOCK SYSTEM (Time-Limited Feature)
-- ============================================================================

if currentTime <= expirationDate then
    -- Dynamically load required UI modules
    local graphicsSettingLogic = package.loaded["client.slua.logic.setting.logic_setting_graphics"] 
        or require("client.slua.logic.setting.logic_setting_graphics")
    local fpsComponent = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS"] 
        or require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    local fpsFineTuneComponent = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT"] 
        or require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    local graphicSettingDB = package.loaded["client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"] 
        or require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")

    --------------------------------------------------------------------------
    -- 3.1 Override SetFPS to unlock 165 FPS and force FineTune switch
    --------------------------------------------------------------------------
    if graphicsSettingLogic then
        local originalSetFPS = graphicsSettingLogic.SetFPS
        function graphicsSettingLogic.SetFPS(gameInstance, fpsLevel)
            if fpsLevel == 8 and graphicSettingDB then
                local isFineTuneEnabled = graphicSettingDB:GetUIData(graphicSettingDB.FPSFineTuneSwitch)
                if not isFineTuneEnabled then
                    graphicSettingDB:UpdateUIData(graphicSettingDB.FPSFineTuneSwitch, true)
                end
            end
            if originalSetFPS then
                originalSetFPS(gameInstance, fpsLevel)
            end
            if fpsLevel == 8 and graphicSettingDB then
                graphicSettingDB:UpdateUIData(graphicSettingDB.FPSFineTuneNum, 165)
                gameInstance:ExecuteCMD("t.MaxFPS", "165")
                gameInstance:ExecuteCMD("r.FrameRateLimit", "165")
            end
        end
    end

    --------------------------------------------------------------------------
    -- 3.2 Override FPS Component (GSC_FPS) to unlock max FPS levels
    --------------------------------------------------------------------------
    if fpsComponent and fpsComponent.__inner_impl then
        local fpsImpl = fpsComponent.__inner_impl

        function fpsImpl:GetMaxFPSLevel() 
            return 8, 8 
        end

        function fpsImpl:CanChangeQualityAndFPSPreCheck() 
            return true 
        end

        function fpsImpl:InitRealSupportFPS()
            local supportedFPSList = {}
            for i = 1, 8 do 
                supportedFPSList[i] = { true, true } 
            end
            if graphicSettingDB then
                graphicSettingDB:UpdateUIData(graphicSettingDB.RealSupportFPS, supportedFPSList, false)
            end
            return supportedFPSList
        end

        function fpsImpl:SetFPSAndQualityEnable(bEnable)
            if self.UIRoot and self.UIRoot.Image_Mask then
                self:SetWidgetVisible(self.UIRoot.Image_Mask, false)
            end
        end

        function fpsImpl:UpdateSelectedFPSState(selectedLevel)
            local levelNodeNames = {
                [2] = "NodeFps20", [3] = "NodeFps25", [4] = "NodeFps30",
                [5] = "NodeFps40", [6] = "NodeFps60", [7] = "NodeFps90", [8] = "NodeFps120"
            }
            if not self.UIRoot then return end

            for level, nodeName in pairs(levelNodeNames) do
                if self.UIRoot[nodeName] then
                    self:WidgetSelfHit(self.UIRoot[nodeName])
                    self.UIRoot[nodeName]:SetIsEnabled(true)
                    local switcher = self.UIRoot["WidgetSwitcher_" .. level]
                    if switcher then
                        switcher:SetActiveWidgetIndex(level == selectedLevel and 0 or 1)
                    end
                end
            end
        end

        local originalUpdateUI = fpsImpl.UpdateUI
        function fpsImpl:UpdateUI()
            if originalUpdateUI then 
                pcall(originalUpdateUI, self) 
            end

            self:SelfHitTestInvisible()
            self:InitRealSupportFPS()
            self:SetFPSAndQualityEnable(true)

            local selectedFPS = 8
            if graphicSettingDB then
                if graphicSettingDB:GetUIData(graphicSettingDB.CustomTab) == 2 then
                    selectedFPS = graphicSettingDB:GetUIData(graphicSettingDB.LobbyFPS) or 8
                else
                    selectedFPS = graphicSettingDB:GetUIData(graphicSettingDB.SelectedFPS) or 8
                end
            end
            self:UpdateSelectedFPSState(selectedFPS)
        end

        function fpsImpl:DoClickFPS(fpsLevel)
            if slua.isValid(self.UIRoot) then
                if graphicSettingDB:GetUIData(graphicSettingDB.CustomTab) == 2 then
                    graphicSettingDB:UpdateUIData(graphicSettingDB.LobbyFPS, fpsLevel)
                else
                    graphicSettingDB:UpdateSelectedFPS(fpsLevel)
                end
                self:UpdateSelectedFPSState(fpsLevel)
                if self:GetParentUI() then
                    self:GetParentUI():SaveQualityAndFPS()
                    self:GetParentUI():SetDirty(true)
                end
            end
        end
    end

    --------------------------------------------------------------------------
    -- 3.3 Override FPS FineTune Component (GSC_FPSFT) for 165 FPS slider
    --------------------------------------------------------------------------
    if fpsFineTuneComponent and fpsFineTuneComponent.__inner_impl then
        local fpsFineTuneImpl = fpsFineTuneComponent.__inner_impl
        local FPS_MIN, FPS_STEP = 90, 5

        local function clampValue(val, min, max)
            if val < min then return min
            elseif val > max then return max
            else return val end
        end

        function fpsFineTuneImpl:ShowOrHide()
            self:SelfHitTestInvisible()
            if self.InitFPSFTSwitch then 
                self:InitFPSFTSwitch() 
            end
        end

        function fpsFineTuneImpl:InitFPSFTSwitch()
            local isSwitchEnabled = graphicSettingDB:GetUIData(graphicSettingDB.FPSFineTuneSwitch)
            if self.UIRoot.Setting_Switch then
                self.UIRoot.Setting_Switch:SetSwitcherEnable2(isSwitchEnabled, true)
            end
            if self.UIRoot.CanvasPanel_8 then
                self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, isSwitchEnabled)
            end
            if self.UIRoot.WidgetSwitcher_0 then
                self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2)
            end
            if self.InitFPSFTValue165 then
                self:InitFPSFTValue165()
            end
        end

        function fpsFineTuneImpl:InitFPSFTValue165()
            local uiRoot = self.UIRoot
            local isSwitchEnabled = graphicSettingDB:GetUIData(graphicSettingDB.FPSFineTuneSwitch)
            local currentFPS = isSwitchEnabled and graphicSettingDB:GetUIData(graphicSettingDB.FPSFineTuneNum) or 165

            uiRoot.Slider_screen3:SetLocked(not isSwitchEnabled)
            uiRoot.ProgressBar_screen3:SetFillColorAndOpacity(
                isSwitchEnabled and FLinearColor(1, 1, 1, 1) or FLinearColor(1, 0.625, 0.6, 1)
            )

            local sliderPercent = (currentFPS - FPS_MIN) / (165 - FPS_MIN)
            uiRoot.Veihclescreen3:SetText(LocUtil.LocalizeResFormat(10567, currentFPS))
            uiRoot.Slider_screen3:SetValue(sliderPercent)
            uiRoot.ProgressBar_screen3:SetPercent(sliderPercent)
        end

        function fpsFineTuneImpl:OnFPSFTValueChange3(newFPS)
            graphicSettingDB:UpdateUIData(graphicSettingDB.FPSFineTuneNum, newFPS)
            self:InitFPSFTValue165()
            if self:GetParentUI() then 
                self:GetParentUI():SetDirty(true) 
            end

            local gameInstance = graphicSettingDB.GetGameInstance and graphicSettingDB.GetGameInstance()
            if gameInstance then
                gameInstance:ExecuteCMD("t.MaxFPS", tostring(newFPS))
                gameInstance:ExecuteCMD("r.FrameRateLimit", tostring(newFPS))
            end
        end

        function fpsFineTuneImpl:OnFPSFTSliderValueChange3(sliderValue)
            if graphicSettingDB:GetUIData(graphicSettingDB.FPSFineTuneSwitch) then
                local newFPS = KismetMathLibrary.FCeil(sliderValue * (165 - FPS_MIN) / FPS_STEP) * FPS_STEP + FPS_MIN
                self:OnFPSFTValueChange3(clampValue(newFPS, FPS_MIN, 165))
            end
        end

        function fpsFineTuneImpl:OnFPSFTAdd3()
            local currentFPS = graphicSettingDB:GetUIData(graphicSettingDB.FPSFineTuneNum)
            if currentFPS then 
                self:OnFPSFTValueChange3(math.min(165, currentFPS + FPS_STEP)) 
            end
        end

        function fpsFineTuneImpl:OnFPSFTMinus3()
            local currentFPS = graphicSettingDB:GetUIData(graphicSettingDB.FPSFineTuneNum)
            if currentFPS then 
                self:OnFPSFTValueChange3(math.max(FPS_MIN, currentFPS - FPS_STEP)) 
            end
        end

        fpsFineTuneImpl.OnFPSFTAdd = fpsFineTuneImpl.OnFPSFTAdd3
        fpsFineTuneImpl.OnFPSFTMinus = fpsFineTuneImpl.OnFPSFTMinus3
        fpsFineTuneImpl.OnFPSFTSliderValueChange = fpsFineTuneImpl.OnFPSFTSliderValueChange3
    end
end

-- ============================================================================
-- SECTION 4: SKIN CONFIGURATION & PERSISTENCE
-- ============================================================================

_G.ConfigFilePath = '/storage/emulated/0/Android/data/com.vng.pubgmobile/files/ADITYA_MENU.ini'

-- Base skin IDs for weapons and outfit slots
_G.BaseSkinIDs = {
    Weapons = { 101004, 101001, 101003, 103001, 102002, 103002, 103003, 101008, 102003, 105010, 102004, 105002, 105001, 101006, 104004 },
    Outfits = { Suit = 403003, Bag = 501001, Helmet = 502001, Parachut = 703001, Pet = 50000 }
}

-- Outfit skin collections (initialized with base IDs)
_G.OutfitSkins = {
    Suit = { _G.BaseSkinIDs.Outfits.Suit },
    Bag = { _G.BaseSkinIDs.Outfits.Bag },
    Helmet = { _G.BaseSkinIDs.Outfits.Helmet },
    Parachut = { _G.BaseSkinIDs.Outfits.Parachut },
    Pet = { _G.BaseSkinIDs.Outfits.Pet }
}

-- Initialize weapon skin mappings
_G.skinIdMappings = {}
for _, id in ipairs(_G.BaseSkinIDs.Weapons) do
    _G.skinIdMappings[id] = { id }
end

-- Vehicle type to base ID mapping
_G.VehicleMapDict = {
    UAZ = 1908001,
    Dacia = 1903001,
    Buggy = 1907001,
    Motor = 1901001,
    CoupeRB = 1961001
}

_G.VehicleSkinsList = {}
_G.VehicleSkinIndex = {}

-- Equipment slot type constants
_G.CustSlotType = {
    ClothesEquipemtSlot = 5,
    BackpackEquipemtSlot = 8,
    HelmetEquipemtSlot = 9,
    ParachuteEquipemtSlot = 11,
    GlideEquipemtSlot = 15
}

-- Current skin indices
_G.WeaponSkinIndex = _G.WeaponSkinIndex or {}
_G.SuitSkin, _G.BagSkin, _G.HelmetSkin, _G.ParachuteSkin, _G.GliderSkin, _G.PetSkin = 0, 0, 0, 0, 0, 0
_G.LastBackApplyValue, _G.LastHelmetApplyValue = 0, 0
_G.skinIdCache, _G.skinIdCache2 = {}, {}
local skinConfigCache = {}

--- Downloads a skin resource if not already cached
local function downloadSkinResource(skinId)
    local pufferManager = require('client.slua.logic.download.puffer.puffer_manager')
    local pufferConst = require('client.slua.logic.download.puffer_const')
    if pufferManager and pufferConst and pufferManager.GetState(pufferConst.ENUM_DownloadType.ODPAK, { skinId }) ~= pufferConst.ENUM_DownloadState.Done then
        pufferManager.Download(pufferConst.ENUM_DownloadType.ODPAK, { skinId })
    end
end
_G.download_item = downloadSkinResource

--- Gets the active skin ID for a weapon
_G.get_skin_id = function(weaponID)
    if not weaponID then return nil end
    local skinIndex = (_G.WeaponSkinIndex[weaponID]) or 1
    local skinList = _G.skinIdMappings[weaponID]
    if not skinList or not skinList[skinIndex] then return weaponID end

    local targetSkinId = skinList[skinIndex]
    if not _G.skinIdCache2[targetSkinId] then
        pcall(_G.download_item, targetSkinId)
        _G.skinIdCache2[targetSkinId] = true
    end
    return targetSkinId
end

--- Gets the active skin ID for a vehicle
_G.get_vehicle_skin_id = function(vehicleID)
    if not vehicleID or vehicleID == 0 then return vehicleID end

    local vehicleIdStr = tostring(vehicleID)
    local prefix = string.sub(vehicleIdStr, 1, 4)
    local baseVehicleId = tonumber(prefix .. "001")

    local skinList = _G.VehicleSkinsList[baseVehicleId]
    if skinList then
        local skinIndex = _G.VehicleSkinIndex[baseVehicleId] or 1
        if skinIndex < 1 then skinIndex = 1 end
        if skinIndex > #skinList then skinIndex = #skinList end

        local targetSkinId = skinList[skinIndex]
        if targetSkinId and targetSkinId > 0 then
            if not _G.skinIdCache2[targetSkinId] then
                if _G.download_item then pcall(_G.download_item, targetSkinId) end
                _G.skinIdCache2[targetSkinId] = true
            end
            return targetSkinId
        end
    end
    return vehicleID
end

--- Loads skin lists from the INI configuration file
_G.LoadSkinDataFromINI = function()
    local fileHandle = io.open(_G.ConfigFilePath, 'r')
    if not fileHandle then return end

    local inSkinListSection = false
    for line in fileHandle:lines() do
        if line:match('%[SKIN_LIST%]') then
            inSkinListSection = true
        elseif line:match('%[SELECTED%]') then
            inSkinListSection = false
        end

        if inSkinListSection and not line:match('^%s*%[') and not line:match('^%s*[#]') then
            local key, value = line:match('([^=]+)=(.+)')
            if key and value then
                key = key:match("^%s*(.-)%s*$")
                local idList = {}
                for val in value:gmatch('([^,]+)') do
                    local numVal = tonumber(val:match("^%s*(.-)%s*$"))
                    if numVal then table.insert(idList, numVal) end
                end

                if #idList > 0 then
                    if _G.OutfitSkins[key] ~= nil then
                        _G.OutfitSkins[key] = idList
                    elseif _G.VehicleMapDict[key] ~= nil then
                        local baseVehicleId = _G.VehicleMapDict[key]
                        _G.VehicleSkinsList[baseVehicleId] = idList
                    elseif tonumber(key) then
                        _G.skinIdMappings[tonumber(key)] = idList
                    end
                end
            end
        end
    end
    fileHandle:close()

    -- Update convenience references
    _G.SuitSkinsMap = _G.OutfitSkins.Suit
    _G.BagSkinsMap = _G.OutfitSkins.Bag
    _G.HelmetSkinsMap = _G.OutfitSkins.Helmet
    _G.ParachutSkinsMap = _G.OutfitSkins.Parachut
    _G.PetSkinsMap = _G.OutfitSkins.Pet
end
pcall(_G.LoadSkinDataFromINI)

--- Reads the currently selected skin indices from the INI file
_G.ReadConfigFile = function()
    local fileHandle = io.open(_G.ConfigFilePath, 'r')
    if not fileHandle then return end

    local configValues = {}
    for line in fileHandle:lines() do
        if line:match('%[SKIN_LIST%]') then break end
        if not line:match('^%s*%[') and not line:match('^%s*[#]') then
            local key, value = line:match('([%w_]+)%s*=%s*(%d+)')
            if key and value and not line:match(',') then
                configValues[key] = tonumber(value)
            end
        end
    end
    fileHandle:close()

    --- Updates a global skin variable if the config value changed
    local function updateOutfitSkin(slotName, skinMap, globalVarName)
        if configValues[slotName] and configValues[slotName] ~= skinConfigCache[slotName] then
            _G[globalVarName] = skinMap and skinMap[configValues[slotName] + 1] or 0
            skinConfigCache[slotName] = configValues[slotName]
        end
    end

    updateOutfitSkin('Suit', _G.SuitSkinsMap, 'SuitSkin')
    updateOutfitSkin('Bag', _G.BagSkinsMap, 'BagSkin')
    updateOutfitSkin('Helmet', _G.HelmetSkinsMap, 'HelmetSkin')
    updateOutfitSkin('Parachute', _G.ParachutSkinsMap, 'ParachuteSkin')
    updateOutfitSkin('Pet', _G.PetSkinsMap, 'PetSkin')

    --- Updates a weapon skin index if the config value changed
    local function updateWeaponSkin(slotName, weaponId)
        if configValues[slotName] and configValues[slotName] ~= skinConfigCache[slotName] then
            _G.WeaponSkinIndex[weaponId] = configValues[slotName] + 1
            skinConfigCache[slotName] = configValues[slotName]
        end
    end

    updateWeaponSkin('M416', 101004)
    updateWeaponSkin('AKM', 101001)
    updateWeaponSkin('UMP', 102002)
    updateWeaponSkin('SCAR', 101003)
    updateWeaponSkin('M762', 101008)
    updateWeaponSkin('AUG', 101006)
    updateWeaponSkin('Vector', 102003)
    updateWeaponSkin('UZI', 102004)
    updateWeaponSkin('Kar98k', 103001)
    updateWeaponSkin('M24', 103002)
    updateWeaponSkin('AWM', 103003)
    updateWeaponSkin('DP28', 105002)
    updateWeaponSkin('M249', 105001)
    updateWeaponSkin('MG3', 105010)
    updateWeaponSkin('Shotgun', 104004)

    --- Updates a vehicle skin index if the config value changed
    local function updateVehicleSkin(slotName)
        local baseVehicleId = _G.VehicleMapDict[slotName]
        if baseVehicleId and configValues[slotName] and configValues[slotName] ~= skinConfigCache[slotName] then
            _G.VehicleSkinIndex[baseVehicleId] = configValues[slotName] + 1
            skinConfigCache[slotName] = configValues[slotName]
        end
    end

    updateVehicleSkin('UAZ')
    updateVehicleSkin('Dacia')
    updateVehicleSkin('Buggy')
    updateVehicleSkin('Motor')
    updateVehicleSkin('CoupeRB')
end

-- ============================================================================
-- SECTION 5: WEAPON ATTACHMENT MAPPING SYSTEM
-- ============================================================================

_G.BaseAttachToIndex = {
    [201010] = 1, [201005] = 1, [201004] = 1,
    [201009] = 2, [201003] = 2, [201002] = 2,
    [201011] = 3, [201007] = 3, [201006] = 3,
    [204012] = 4, [204005] = 4, [204008] = 4,
    [204011] = 5, [204004] = 5, [204007] = 5,
    [204013] = 6, [204006] = 6, [204009] = 6,
    [203001] = 7, [203002] = 8, [203003] = 9, [203014] = 10, [203004] = 11, [203015] = 12, [203005] = 13,
    [202002] = 14, [202001] = 15, [202004] = 16, [202005] = 17, [202007] = 18, [202006] = 19,
    [205002] = 20, [205003] = 20, [205001] = 20,
    [203018] = 21, [204014] = 22
}

_G.VIP_Attachments = {}
_G.VipAttachToIndex = {}

--- Loads custom attachment mappings from the INI file
_G.LoadAttachmentsFromINI = function()
    local fileHandle = io.open(_G.ConfigFilePath, 'r')
    if not fileHandle then return end

    _G.VIP_Attachments = {}
    _G.VipAttachToIndex = {}

    local inAttachmentsSection = false
    for line in fileHandle:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line == '[ATTACHMENTS]' then
            inAttachmentsSection = true
        elseif line:match('^%[') then
            inAttachmentsSection = false
        end

        if inAttachmentsSection and not line:match('^%[') and line ~= '' and not line:match('^#') then
            local weaponId, attachmentList = line:match('^(%d+)=(.+)$')
            if weaponId and attachmentList then
                local skinId = tonumber(weaponId)
                local attachments = {}
                local attachIndex = 1
                for val in attachmentList:gmatch('([^,]+)') do
                    local attachId = tonumber(val) or 0
                    table.insert(attachments, attachId)
                    if attachId > 0 then _G.VipAttachToIndex[attachId] = attachIndex end
                    attachIndex = attachIndex + 1
                end
                _G.VIP_Attachments[skinId] = attachments
            end
        end
    end
    fileHandle:close()
end
pcall(_G.LoadAttachmentsFromINI)

-- ============================================================================
-- SECTION 6: OUTFIT AVATAR SYSTEM
-- ============================================================================

--- Equips custom outfit skins on a character's avatar component
_G.equip_character_avatar = function(playerCharacter)
    if not playerCharacter or not slua.isValid(playerCharacter) or not playerCharacter.AvatarComponent2 then return end
    local BackpackUtils = import("BackpackUtils")
    local slotSyncData = playerCharacter.AvatarComponent2.NetAvatarData and playerCharacter.AvatarComponent2.NetAvatarData.SlotSyncData
    if not slotSyncData or not slua.isValid(slotSyncData) or not BackpackUtils then return end

    --- Applies a skin to a specific equipment slot
    local function applySkinToSlot(applyDataIdx, itemId, equipSlot, isLevelDependent, levelFunc, globalCacheVal)
        if itemId == 0 then return end
        local slotData = slotSyncData:Get(applyDataIdx)
        if slotData and slotData.SlotID == equipSlot then
            local finalItemId = itemId
            if isLevelDependent then
                local equipmentLevel = levelFunc(slotData.AdditionalItemID) or 1
                finalItemId = itemId + (equipmentLevel - 1) * 1000
                if finalItemId == slotData.ItemId and _G[globalCacheVal] == itemId then return end
                _G[globalCacheVal] = itemId
            elseif slotData.ItemId == itemId then
                return
            end

            if not _G.skinIdCache[finalItemId] then
                _G.download_item(finalItemId)
                _G.skinIdCache[finalItemId] = true
            end

            slotData.ItemId = finalItemId
            slotSyncData:Set(applyDataIdx, slotData)
            playerCharacter.AvatarComponent2:OnRep_BodySlotStateChanged()
        end
    end

    -- Ensure glider slot exists
    local hasGliderSlot = false
    for i = 0, slotSyncData:Num() - 1 do
        local slotData = slotSyncData:Get(i)
        if slotData and slotData.SlotID == _G.CustSlotType.GlideEquipemtSlot then
            hasGliderSlot = true
            break
        end
    end
    if not hasGliderSlot then
        slotSyncData:Add({ SlotID = _G.CustSlotType.GlideEquipemtSlot, ItemId = 0 })
    end

    -- Apply skins to all outfit slots
    for i = 0, slotSyncData:Num() - 1 do
        applySkinToSlot(i, _G.SuitSkin, _G.CustSlotType.ClothesEquipemtSlot, false)
        applySkinToSlot(i, _G.BagSkin, _G.CustSlotType.BackpackEquipemtSlot, true, BackpackUtils.GetEquipmentBagLevel, 'LastBackApplyValue')
        applySkinToSlot(i, _G.HelmetSkin, _G.CustSlotType.HelmetEquipemtSlot, true, BackpackUtils.GetEquipmentHelmetLevel, 'LastHelmetApplyValue')
        applySkinToSlot(i, _G.GliderSkin, _G.CustSlotType.GlideEquipemtSlot, false)
        applySkinToSlot(i, _G.ParachuteSkin, _G.CustSlotType.ParachuteEquipemtSlot, false)
    end
end

-- ============================================================================
-- SECTION 7: WEAPON SKIN SYSTEM
-- ============================================================================

--- Applies custom weapon skins and attachment overrides
_G.ApplyWeaponSkins = function(playerCharacter)
    pcall(function()
        local weaponManager = playerCharacter:GetWeaponManager()
        if not slua.isValid(weaponManager) then return end

        for slot = 1, 3 do
            local inventoryWeapon = weaponManager:GetInventoryWeaponByPropSlot(slot)
            if slua.isValid(inventoryWeapon) and slua.isValid(inventoryWeapon.synData) then
                local weaponId = inventoryWeapon:GetWeaponID()
                local targetSkinId = _G.get_skin_id(weaponId) or weaponId
                local hasChanges = false

                -- Apply weapon skin
                local weaponDefineData = inventoryWeapon.synData:Get(7)
                if weaponDefineData and weaponDefineData.defineID and weaponDefineData.defineID.TypeSpecificID ~= targetSkinId then
                    weaponDefineData.defineID.TypeSpecificID = targetSkinId
                    inventoryWeapon.synData:Set(7, weaponDefineData)
                    if inventoryWeapon.SetWeaponAvatarID then
                        pcall(function() inventoryWeapon:SetWeaponAvatarID(targetSkinId) end)
                    end
                    if not _G.skinIdCache[targetSkinId] then
                        _G.download_item(targetSkinId)
                        _G.skinIdCache[targetSkinId] = true
                    end
                    hasChanges = true
                end

                -- Apply VIP attachment overrides
                if targetSkinId >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[targetSkinId] then
                    for attachIdx = 0, 5 do
                        local attachData = inventoryWeapon.synData:Get(attachIdx)
                        if attachData then
                            local defineRef = slua.IndexReference(attachData, "defineID")
                            if defineRef then
                                local currentAttachId = defineRef.TypeSpecificID
                                if currentAttachId and currentAttachId > 0 then
                                    local attachIndex = _G.BaseAttachToIndex[currentAttachId] or _G.VipAttachToIndex[currentAttachId]
                                    if attachIndex and _G.VIP_Attachments[targetSkinId][attachIndex] and _G.VIP_Attachments[targetSkinId][attachIndex] > 0 then
                                        local newAttachId = _G.VIP_Attachments[targetSkinId][attachIndex]
                                        if newAttachId ~= currentAttachId then
                                            attachData.defineID.TypeSpecificID = newAttachId
                                            inventoryWeapon.synData:Set(attachIdx, attachData)
                                            if not _G.skinIdCache2[newAttachId] then
                                                if _G.download_item then pcall(_G.download_item, newAttachId) end
                                                _G.skinIdCache2[newAttachId] = true
                                            end
                                            hasChanges = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- Force mesh refresh if changes were made
                if hasChanges then
                    if inventoryWeapon.DelayHandleAvatarMeshChanged then
                        pcall(function() inventoryWeapon:DelayHandleAvatarMeshChanged() end)
                    end
                    if inventoryWeapon.OnRep_synData then
                        pcall(function() inventoryWeapon:OnRep_synData() end)
                    end
                end
            end
        end
    end)
end

-- ============================================================================
-- SECTION 8: VEHICLE SKIN SYSTEM
-- ============================================================================

_G.LastVehicleEntity = nil
_G.CurrentEquipVehicleID = nil

--- Applies custom vehicle skins with full effect support
_G.ApplyVehicleSkins = function(playerCharacter)
    pcall(function()
        local currentVehicle = playerCharacter:GetCurrentVehicle()
        if not slua.isValid(currentVehicle) then
            _G.LastVehicleEntity = nil
            return
        end

        -- Only apply skins when the player is the driver
        if not Game:IsDriver(playerCharacter.Object) then return end

        local avatarComponent = currentVehicle.VehicleAvatarComponent_BP or currentVehicle:GetAvatarComponent()
        if not slua.isValid(avatarComponent) then return end

        -- Determine the base vehicle ID
        local baseVehicleId = 0
        if currentVehicle.AvatarDefaultCfg then
            baseVehicleId = currentVehicle.AvatarDefaultCfg.TypeSpecificID
        end
        if baseVehicleId == 0 and avatarComponent.VehicleNetAvatarData and avatarComponent.VehicleNetAvatarData.ItemDefineID then
            baseVehicleId = avatarComponent.VehicleNetAvatarData.ItemDefineID.TypeSpecificID
        end
        if baseVehicleId == 0 then return end

        local targetSkinId = _G.get_vehicle_skin_id(baseVehicleId)
        local currentAvatarId = avatarComponent:GetCurItemAvatarID()

        -- Apply skin if different from current
        if targetSkinId and targetSkinId ~= 0 and currentAvatarId ~= targetSkinId then
            if not _G.skinIdCache[targetSkinId] then
                if _G.download_item then pcall(_G.download_item, targetSkinId) end
                _G.skinIdCache[targetSkinId] = true
            end

            -- Update network data
            if avatarComponent.VehicleNetAvatarData and avatarComponent.VehicleNetAvatarData.ItemDefineID then
                avatarComponent.VehicleNetAvatarData.ItemDefineID.TypeSpecificID = targetSkinId
                avatarComponent.VehicleNetAvatarData.SkinOwnerUID = playerCharacter.PlayerUID
            end

            -- Apply vehicle change with or without switch effect
            if _G.LastVehicleEntity ~= currentVehicle or _G.CurrentEquipVehicleID ~= targetSkinId then
                _G.LastVehicleEntity = currentVehicle
                _G.CurrentEquipVehicleID = targetSkinId

                pcall(function()
                    avatarComponent.lastEquipedAvatarId = currentAvatarId
                    if avatarComponent.ShowVehicleSwitchEffect then
                        avatarComponent:ShowVehicleSwitchEffect()
                    end
                    avatarComponent.ClientUsedAvatarID = targetSkinId
                    currentVehicle.ClientUsedAvatarID = targetSkinId
                    if avatarComponent.ChangeItemAvatar then
                        avatarComponent:ChangeItemAvatar(targetSkinId, false)
                    end
                end)
            else
                if avatarComponent.ChangeItemAvatar then
                    avatarComponent:ChangeItemAvatar(targetSkinId, false)
                end
            end

            -- Apply vehicle effects
            if avatarComponent.EnableHighTireLight then
                avatarComponent:EnableHighTireLight(true, targetSkinId)
            end

            if currentVehicle.UpdateParticle then pcall(function() currentVehicle:UpdateParticle(targetSkinId) end) end
            if currentVehicle.ChangeParticles then pcall(function() currentVehicle:ChangeParticles(targetSkinId) end) end
            if currentVehicle.ReActivateExhaustParticle then pcall(function() currentVehicle:ReActivateExhaustParticle() end) end

            -- Update license plate
            local LicenseNumberComponent = import("VehicleLicenseNumberComponent")
            local licenseComp = currentVehicle:GetComponentByClass(LicenseNumberComponent)
            if slua.isValid(licenseComp) then
                if licenseComp.LicensePlate then
                    licenseComp.LicensePlate.ItemID = targetSkinId
                    licenseComp.LicensePlate.ChassisLightId = targetSkinId + 1000
                end
                if licenseComp.PreChangeEffect then licenseComp:PreChangeEffect() end
                if licenseComp.PreChangeChassisLight then licenseComp:PreChangeChassisLight() end
            end

            -- Enable vehicle music
            if currentVehicle.SetVehicleMusicPlayState then
                currentVehicle:SetVehicleMusicPlayState(true)
            end
        end
    end)
end

-- ============================================================================
-- SECTION 9: PET SYSTEM
-- ============================================================================

_G.LastAppliedPet = nil

--- Handles pet skin equipping
_G.HandlePetLogic = function()
    pcall(function()
        if not _G.PetSkin or _G.PetSkin == 0 or _G.PetSkin == 50000 or _G.PetSkin == _G.LastAppliedPet then return end
        if not _G.skinIdCache[_G.PetSkin] then
            _G.download_item(_G.PetSkin)
            _G.skinIdCache[_G.PetSkin] = true
        end

        local moduleManager = require("client.module_framework.ModuleManager")
        if moduleManager then
            local petModule = moduleManager.GetModule(moduleManager.CommonModuleConfig.logic_pet)
            if petModule then
                if petModule.SetCurPetID then petModule:SetCurPetID(_G.PetSkin) end
                if petModule.EquipPet then petModule:EquipPet(_G.PetSkin) end
            end
        end
        _G.LastAppliedPet = _G.PetSkin
    end)
end

-- ============================================================================
-- SECTION 10: DEADBOX SKIN SYSTEM
-- ============================================================================

_G.DeadBoxSkins = _G.DeadBoxSkins or {}
_G.AlreadyChangedSet = _G.AlreadyChangedSet or {}

local function tableContains(t, element)
    if not t then return false end
    for _, val in ipairs(t) do
        if val == element then return true end
    end
    return false
end

local function isLocationNear(loc1, loc2, tolerance)
    local dx = loc1.X - loc2.X
    local dy = loc1.Y - loc2.Y
    local dz = loc1.Z - loc2.Z
    return dx * dx + dy * dy + dz * dz < tolerance * tolerance
end

--- Applies skin to dead boxes created by the player
_G.DeadBox_TemperRequest = function(playerController)
    local playerCharacter = playerController:GetPlayerCharacterSafety()
    if not playerCharacter then return end

    local GameplayStatics = import("GameplayStatics")
    if GameplayStatics then
        local ActorClass = import("Actor")
        local uiUtil = require("client.common.ui_util")
        if uiUtil then
            local gameInstance = uiUtil.GetGameInstance()
            if gameInstance then
                local TombBoxClass = import("PlayerTombBox")
                local allTombBoxes = GameplayStatics.GetAllActorsOfClass(gameInstance, TombBoxClass, slua.Array(UEnums.EPropertyClass.Object, ActorClass))

                for _, tombBox in pairs(allTombBoxes) do
                    if slua.isValid(tombBox) then
                        local damageCauser = tombBox.DamageCauser
                        if damageCauser and damageCauser.Playerkey == playerController.Playerkey then
                            local deadBoxAvatar = tombBox.DeadBoxAvatarComponent_BP
                            if deadBoxAvatar and not tableContains(_G.AlreadyChangedSet, tombBox) then
                                local tombLocation = tombBox:K2_GetActorLocation()
                                local foundExisting = false

                                -- Check if a skin was already applied at this location
                                for _, entry in pairs(_G.DeadBoxSkins) do
                                    if isLocationNear(entry.location, tombLocation, 1.0) then
                                        deadBoxAvatar:ResetItemAvatar()
                                        deadBoxAvatar:PreChangeItemAvatar(entry.SkinID)
                                        deadBoxAvatar:SyncChangeItemAvatar(entry.SkinID)
                                        table.insert(_G.AlreadyChangedSet, tombBox)
                                        foundExisting = true
                                        break
                                    end
                                end

                                -- Apply skin based on current vehicle or weapon
                                if not foundExisting then
                                    local skinIdToApply = 0
                                    local currentVehicle = playerCharacter.CurrentVehicle
                                    if currentVehicle and _G.CurrentEquipVehicleID and _G.CurrentEquipVehicleID ~= 0 then
                                        skinIdToApply = tonumber(tostring(_G.CurrentEquipVehicleID) .. "1") or 0
                                    else
                                        local currentWeapon = playerCharacter:GetCurrentWeapon()
                                        if currentWeapon then
                                            local weaponDefineData = currentWeapon.synData and currentWeapon.synData:Get(7)
                                            if weaponDefineData and weaponDefineData.defineID then
                                                skinIdToApply = weaponDefineData.defineID.TypeSpecificID
                                            end
                                        end
                                    end

                                    if skinIdToApply ~= 0 then
                                        deadBoxAvatar:ResetItemAvatar()
                                        deadBoxAvatar:PreChangeItemAvatar(skinIdToApply)
                                        deadBoxAvatar:SyncChangeItemAvatar(skinIdToApply)
                                        table.insert(_G.DeadBoxSkins, { location = tombLocation, SkinID = skinIdToApply })
                                        table.insert(_G.AlreadyChangedSet, tombBox)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- SECTION 11: KILL COUNTER SYSTEM
-- ============================================================================

_G.AKFakeKillCounts = _G.AKFakeKillCounts or {}
_G.KCUISystemHacked2 = nil
_G.KCLogicHacked2 = nil
_G.KillInfoCounterHacked = nil
_G.SlotBaseHacked = nil

--- Forces the kill counter UI and logic to always be active with custom skins
_G.ForceEnableKillCounterUI = function()
    pcall(function()
        -- Hook KillCounterUISubsystem
        local killCounterUISubsystem = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"]
            or require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if killCounterUISubsystem and killCounterUISubsystem.__inner_impl and not _G.KCUISystemHacked2 then
            local uiImpl = killCounterUISubsystem.__inner_impl
            uiImpl.CheckSupportKCUI = function() return true end

            uiImpl.CheckNeedMainKillCounterUI = function(self, weapon, playerId)
                if slua.isValid(weapon) then
                    local weaponId = weapon:GetWeaponID()
                    self:UpdateMainKillCounterUI(true, weaponId, _G.get_skin_id(weaponId) or weaponId)
                else
                    self:UpdateMainKillCounterUI(false)
                end
            end

            local originalUpdateUI = uiImpl.UpdateMainKillCounterUI
            uiImpl.UpdateMainKillCounterUI = function(self, bShow, weaponId, avatarId)
                if bShow then avatarId = _G.get_skin_id(weaponId) or avatarId end
                if originalUpdateUI then originalUpdateUI(self, bShow, weaponId, avatarId) end
            end
            _G.KCUISystemHacked2 = true
        end

        -- Hook LogicKillCounter module
        local moduleManager = require("client.module_framework.ModuleManager")
        if moduleManager then
            local killCounterModule = moduleManager.GetModule(moduleManager.CommonModuleConfig.LogicKillCounter)
            if killCounterModule and not _G.KCLogicHacked2 then
                killCounterModule.CheckSupportKC = function() return true end
                killCounterModule.CheckSupportKillCounterAvatar = function() return true end
                killCounterModule.CheckHasWeaponKillCounter = function() return true end
                killCounterModule.GetBaseKillCounterIdByWeaponId = function() return 2100004 end
                killCounterModule.GetEquipedKillCounterId = function() return 2100004 end
                killCounterModule.GetMyEquipedKillCounterId = function() return 2100004 end
                killCounterModule.GetOneWeaponKillCountInBattle = function(self, uid, weaponId)
                    return _G.AKFakeKillCounts[weaponId] or 0
                end
                killCounterModule.GetWeaponKillCountByUid = function(self, uid, weaponId)
                    return _G.AKFakeKillCounts[weaponId] or 0
                end
                _G.KCLogicHacked2 = true
            end
        end

        -- Hook KillInfo tips
        local killInfoPath = "GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"
        local killInfoModule = package.loaded[killInfoPath] or require(killInfoPath)
        if killInfoModule and killInfoModule.__inner_impl and not _G.KillInfoCounterHacked then
            local originalFileItem = killInfoModule.__inner_impl.FileItem
            killInfoModule.__inner_impl.FileItem = function(self, damageRecordData)
                pcall(function()
                    local localPlayer = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()
                    if slua.isValid(localPlayer) and damageRecordData.Causer == localPlayer:GetPlayerNameSafety() then
                        local currentWeapon = localPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponId = currentWeapon:GetWeaponID()
                            local targetSkinId = _G.get_skin_id(weaponId)
                            if targetSkinId then damageRecordData.CauserWeaponAvatarID = targetSkinId end
                            if _G.SuitSkin ~= 0 then damageRecordData.CauserClothAvatarID = _G.SuitSkin end

                            damageRecordData.IsUseColor, damageRecordData.UseColor = true, import("LinearColor")(1.0, 0.8, 0.0, 1.0)

                            -- Track kills and update kill counter UI
                            if damageRecordData.ResultHealthStatus == 2 then
                                _G.AKFakeKillCounts[weaponId] = (_G.AKFakeKillCounts[weaponId] or 0) + 1
                                local uiManager = require("client.slua_ui_framework.manager")
                                local killCounterUI = uiManager.GetUI(uiManager.UI_Config_InGame.MainKillCounter)
                                if killCounterUI and killCounterUI.UpdateWeaponID then
                                    local displayAvatarId = targetSkinId or currentWeapon:GetWeaponMainAvatarID()
                                    killCounterUI:UpdateWeaponID(weaponId, displayAvatarId)
                                    local equippedCounterId = killCounterModule:GetEquipedKillCounterId(0, displayAvatarId)
                                    killCounterUI:SetKillCounterItemShowWithNum(
                                        equippedCounterId,
                                        _G.AKFakeKillCounts[weaponId],
                                        displayAvatarId
                                    )
                                end
                            end
                        end
                    end
                end)
                if originalFileItem then return originalFileItem(self, damageRecordData) end
            end
            _G.KillInfoCounterHacked = true
        end

        -- Hook switch weapon slot to always show kill counter icon
        local switchWeaponSlot = package.loaded["GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2"]
            or require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
        if switchWeaponSlot and switchWeaponSlot.__inner_impl and not _G.SlotBaseHacked then
            switchWeaponSlot.__inner_impl.CheckShowKCIcon = function(self)
                if self.KillCounterImg and slua.isValid(self.KillCounterImg) then
                    self.KillCounterImg:SetVisibility(import("ESlateVisibility").SelfHitTestInvisible)
                end
            end
            _G.SlotBaseHacked = true
        end
    end)
end

-- ============================================================================
-- SECTION 12: VEHICLE FX OVERRIDES
-- ============================================================================

_G.VehicleEffectHacked = nil
_G.VehicleAvatarSwitchHacked = nil
_G.LobbyVehicleHacked = nil
_G.LobbyBypassHacked = nil
_G.IconBaloHacked = nil

--- Initializes all skin-related hooks (lobby, icons, vehicle effects)
function _G.InitializeSkinModSystem()
    -- Hook lobby avatar system for attachment remapping
    pcall(function()
        local lobbyAvatar = package.loaded["client.logic.avatar.LobbyAvatar"] or require("client.logic.avatar.LobbyAvatar")
        if lobbyAvatar and not _G.LobbyBypassHacked then
            local originalPutonEquipment = lobbyAvatar.PutonEquipment
            lobbyAvatar.PutonEquipment = function(self, itemId, avatarCustom, extraData)
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[itemId]
                if attachIndex then
                    local currentWeaponSkinId = self.GetCurHoldingWeaponSkinID and self:GetCurHoldingWeaponSkinID()
                    if currentWeaponSkinId and currentWeaponSkinId >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[currentWeaponSkinId] then
                        local replacementId = _G.VIP_Attachments[currentWeaponSkinId][attachIndex]
                        if replacementId and replacementId > 0 then
                            if self.HandleDownload then self:HandleDownload(replacementId, nil, nil, false) end
                            itemId = replacementId
                        end
                    end
                end
                if originalPutonEquipment then
                    return originalPutonEquipment(self, itemId, avatarCustom, extraData)
                end
            end

            local originalCharEquipWeapon = lobbyAvatar.CharEquipWeaponByResId
            lobbyAvatar.CharEquipWeaponByResId = function(self, resId, isUse, isAsync, socketName)
                local result
                if originalCharEquipWeapon then
                    result = originalCharEquipWeapon(self, resId, isUse, isAsync, socketName)
                end
                if isUse and self.GetEquipments then
                    local equipments = self:GetEquipments()
                    for _, equip in ipairs(equipments) do
                        if _G.BaseAttachToIndex and _G.BaseAttachToIndex[equip.itemID] then
                            self:PutonEquipment(equip.itemID, equip.CustomInfo, { bIsUse = false })
                        end
                    end
                end
                return result
            end
            _G.LobbyBypassHacked = true
        end
    end)

    -- Hook item icon display to show custom skins
    pcall(function()
        local commonItemsUIBP = package.loaded["client.slua.component.item.ItemChildren.Common_Items_UIBP"]
            or require("client.slua.component.item.ItemChildren.Common_Items_UIBP")
        if commonItemsUIBP and not _G.IconBaloHacked then
            local originalInitView = commonItemsUIBP.InitView
            commonItemsUIBP.InitView = function(self, itemId, count, validTime, extraData)
                extraData = extraData or {}
                local displayResId = nil

                -- Check for weapon skin override
                if _G.get_skin_id then
                    local skinId = _G.get_skin_id(itemId)
                    if skinId and skinId ~= itemId then
                        displayResId = skinId
                    end
                end

                -- Check for VIP attachment override
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[itemId]
                if not displayResId and attachIndex then
                    local gameplayData = require("GameLua.GameCore.Data.GameplayData")
                    if gameplayData then
                        local playerCharacter = gameplayData.GetPlayerCharacter()
                        if playerCharacter and slua.isValid(playerCharacter) then
                            local currentWeapon = playerCharacter:GetCurrentWeapon()
                            if slua.isValid(currentWeapon) then
                                local weaponId = currentWeapon:GetWeaponID()
                                local weaponSkinId = _G.get_skin_id(weaponId) or weaponId
                                if weaponSkinId >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[weaponSkinId] then
                                    local replacementId = _G.VIP_Attachments[weaponSkinId][attachIndex]
                                    if replacementId and replacementId > 0 then
                                        displayResId = replacementId
                                    end
                                end
                            end
                        end
                    end
                end

                if displayResId then
                    extraData.displayResId = displayResId
                    if not _G.skinIdCache2[displayResId] then
                        if _G.download_item then pcall(_G.download_item, displayResId) end
                        _G.skinIdCache2[displayResId] = true
                    end
                end

                if originalInitView then
                    return originalInitView(self, itemId, count, validTime, extraData)
                end
            end
            _G.IconBaloHacked = true
        end
    end)

    -- Hook vehicle plate license and effects
    pcall(function()
        local vehiclePlateUtilPath = "GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil"
        local vehiclePlateUtil = package.loaded[vehiclePlateUtilPath] or require(vehiclePlateUtilPath)

        if vehiclePlateUtil and not _G.VehicleEffectHacked then
            vehiclePlateUtil.CheckIsBetterVehicle = function() return true end
            vehiclePlateUtil.CheckHasUnLockFeature = function() return true end
            vehiclePlateUtil.NeedOpenHighTire = function() return true end

            local originalGetUpgradeEffectList = vehiclePlateUtil.GetUpgradeEffectList
            vehiclePlateUtil.GetUpgradeEffectList = function(uid)
                local playerCharacter = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()
                if slua.isValid(playerCharacter) and playerCharacter:GetCurrentVehicle() then
                    local currentVehicle = playerCharacter:GetCurrentVehicle()
                    local avatarComponent = currentVehicle.VehicleAvatarComponent_BP or currentVehicle:GetAvatarComponent()
                    if slua.isValid(avatarComponent) then
                        local currentSkinId = avatarComponent.VehicleNetAvatarData
                            and avatarComponent.VehicleNetAvatarData.ItemDefineID.TypeSpecificID
                            or avatarComponent:GetCurItemAvatarID()
                        local effectData = CDataTable.GetTableData("BetterVehicleEffect", currentSkinId)
                        if effectData and effectData.EffectIDList then
                            local effectList = slua.Array(UEnums.EPropertyClass.Int)
                            for i = 0, effectData.EffectIDList:Num() - 1 do
                                effectList:Add(effectData.EffectIDList:Get(i))
                            end
                            return effectList
                        end
                    end
                end
                if originalGetUpgradeEffectList then return originalGetUpgradeEffectList(uid) end
                return nil
            end
            _G.VehicleEffectHacked = true
        end

        -- Hook vehicle avatar component for switch effects
        local vehicleAvatarComponent = package.loaded["GameLua.GameCore.Module.Vehicle.Component.VehicleAvatarComponent"]
            or require("GameLua.GameCore.Module.Vehicle.Component.VehicleAvatarComponent")
        if vehicleAvatarComponent and vehicleAvatarComponent.__inner_impl and not _G.VehicleAvatarSwitchHacked then
            local avatarImpl = vehicleAvatarComponent.__inner_impl

            avatarImpl.CheckCanPlaySkinSwitchEffect = function(self, curVehicleId, lastVehicleId)
                return true
            end

            avatarImpl.ShowVehicleSwitchEffect = function(self)
                if not self.curSwitchEffectId or self.curSwitchEffectId <= 0 then
                    self.curSwitchEffectId = 7303001
                end

                local vehicleOwner = self:GetOwner()
                if not slua.isValid(vehicleOwner) then return false end

                -- Clean up any existing effect actor
                if self.uSwitchEffectActor then
                    self:StopSkinSwitchEffect()
                    self.uSwitchEffectActor:K2_DestroyActor()
                    self.uSwitchEffectActor = nil
                end

                if not self.lastEquipedAvatarId or self.lastEquipedAvatarId <= 0 then
                    self.lastEquipedAvatarId = vehicleOwner.ClientUsedAvatarID or vehicleOwner:GetDefaultAvatarID() or 0
                end

                local newAvatarId = vehicleOwner.ClientUsedAvatarID or self.lastEquipedAvatarId or 0
                local isLobbyActor = self:IsLobbyActor()
                local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
                if not world then return false end

                local vehiclePlateLicenseUtil = require("GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil")
                local effectActorPath = vehiclePlateLicenseUtil.GetSwitchEffectActorPath()
                local effectActorClass = import(effectActorPath)

                self.uSwitchEffectActor = world:SpawnActor(effectActorClass, nil, nil, nil)
                if not slua.isValid(self.uSwitchEffectActor) then
                    self.uSwitchEffectActor = nil
                    return false
                end

                self.uSwitchEffectActor:K2_AttachToActor(vehicleOwner, "None", 1, 1, 1, false)
                self.uSwitchEffectActor:K2_SetActorRelativeLocation(FVector(0, 0, 0), false, nil, false)
                self.uSwitchEffectActor:K2_SetActorRelativeRotation(FRotator(0, 0, 0), false, nil, false)

                self:ChangeFakeSwitchVehicleAvatar(self.uSwitchEffectActor.Mesh, self.lastEquipedAvatarId)
                self.uSwitchEffectActor:SetAnimInsAndAnimState(self.uOldVehicleMeshAnimClass, vehicleOwner)
                self.uSwitchEffectActor:StartVehicleSwitchEffect(
                    vehicleOwner, self.curSwitchEffectId, self.lastEquipedAvatarId, newAvatarId, isLobbyActor
                )

                self.uOldVehicleMeshAnimClass = nil
                return true
            end

            avatarImpl.ResetAnimationState = function(self)
                if self.uSwitchEffectActor then
                    self:StopSkinSwitchEffect()
                    self.uSwitchEffectActor:K2_DestroyActor()
                    self.uSwitchEffectActor = nil
                end
                self.lastEquipedAvatarId = 0
                self.curSwitchEffectId = 7303001
            end

            local originalReceiveBeginPlay = avatarImpl.ReceiveBeginPlay
            avatarImpl.ReceiveBeginPlay = function(self)
                if originalReceiveBeginPlay then originalReceiveBeginPlay(self) end
                self:ResetAnimationState()
            end

            _G.VehicleAvatarSwitchHacked = true
        end

        -- Hook lobby vehicle preview
        local lobbyVehicle = package.loaded["client.lobby_ue_object.Actor.LobbyVehicle"]
            or require("client.lobby_ue_object.Actor.LobbyVehicle")
        if lobbyVehicle and not _G.LobbyVehicleHacked then
            local originalPreChangeVehicleAvatar = lobbyVehicle.PreChangeVehicleAvatar
            lobbyVehicle.PreChangeVehicleAvatar = function(self, avatarId, advanceAvatarId)
                local targetSkinId = _G.get_vehicle_skin_id(avatarId)
                if targetSkinId and targetSkinId ~= avatarId and targetSkinId ~= 0 then
                    if not _G.skinIdCache[targetSkinId] then
                        if _G.download_item then pcall(_G.download_item, targetSkinId) end
                        _G.skinIdCache[targetSkinId] = true
                    end
                    avatarId = targetSkinId
                end

                local result = false
                if originalPreChangeVehicleAvatar then
                    result = originalPreChangeVehicleAvatar(self, avatarId, advanceAvatarId)
                end

                pcall(function()
                    self.ClientUsedAvatarID = avatarId
                    if self.PlayStartUpEffect then self:PlayStartUpEffect() end
                    if self.PlayAccelerateEffect then self:PlayAccelerateEffect() end
                end)

                return result
            end
            _G.LobbyVehicleHacked = true
        end
    end)
end

-- ============================================================================
-- SECTION 13: SKIN BYPASS SYSTEM
-- ============================================================================

--- Disables skin-related security checks and resource scanners
function _G.InitializeSkinBypass()
    pcall(function()
        -- Block puffer TLog reports
        local pufferTLog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if pufferTLog then
            pufferTLog.ReportEvent = function() end
            pufferTLog.ReportDownloadResult = function() end
            pufferTLog.ReportODPAKError = function() end
        end

        -- Bypass avatar validation
        local avatarUtils = package.loaded["AvatarUtils"]
        if avatarUtils then
            avatarUtils.CheckIsWeaponInBlackList = function() return false end
            avatarUtils.IsValidAvatar = function() return true end
        end

        -- Block file check subsystem
        local fileCheckSubsystem = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
        if fileCheckSubsystem then
            fileCheckSubsystem.StartCheck = function() end
            fileCheckSubsystem.ReportAbnormalFile = function() end
        end

        -- Block equipment exception reports
        local equipmentExceptionReport = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if equipmentExceptionReport then
            equipmentExceptionReport.Report = function() end
        end
    end)
    print('[SkinBypass] Resource & Skin Scanners Bypassed!')
end

-- ============================================================================
-- SECTION 14: RUNTIME SYNC LOOP
-- ============================================================================

_G.AKSkinLoopStarted = nil

--- Main runtime loop that continuously applies skins and updates systems
local function startSkinSyncLoop()
    if _G.AKSkinLoopStarted then return end
    _G.AKSkinLoopStarted = true

    local timeTicker = require("common.time_ticker")

    local function skinSyncTick()
        pcall(function()
            local gameplayData = require("GameLua.GameCore.Data.GameplayData")
            if gameplayData then
                local playerCharacter = gameplayData.GetPlayerCharacter()
                if slua.isValid(playerCharacter) then
                    _G.ForceEnableKillCounterUI()
                    _G.ReadConfigFile()
                    _G.LoadAttachmentsFromINI()
                    _G.equip_character_avatar(playerCharacter)
                    _G.ApplyWeaponSkins(playerCharacter)
                    _G.ApplyVehicleSkins(playerCharacter)
                    _G.HandlePetLogic()

                    local playerController = gameplayData.GetPlayerController()
                    if slua.isValid(playerController) then
                        _G.DeadBox_TemperRequest(playerController)
                    end
                end
            end
        end)
        if timeTicker and timeTicker.AddTimerOnce then
            timeTicker.AddTimerOnce(0.1, skinSyncTick)
        end
    end
    skinSyncTick()
end

-- ============================================================================
-- SECTION 15: FEATURE MENU SYSTEM (INI Save/Load)
-- ============================================================================

local configFilePaths = {
    '/storage/emulated/0/Android/data/com.tencent.ig/files/ADITYA_MENU.ini',
    '/storage/emulated/0/Android/data/com.pubg.krmobile/files/ADITYA_MENU.ini',
    '/storage/emulated/0/Android/data/com.vng.pubgmobile/files/ADITYA_MENU.ini',
    '/storage/emulated/0/Android/data/com.rekoo.pubgm/files/ADITYA_MENU.ini'
}

function _G.AK_SaveINI()
    for _, filePath in ipairs(configFilePaths) do
        local fileHandle = io.open(filePath, "w")
        if fileHandle then
            local fileContent = ""
            for _, feature in ipairs(_G.AK_Features) do
                fileContent = fileContent .. feature.id .. "=" .. tostring(feature.val) .. "\n"
            end
            fileHandle:write(fileContent)
            fileHandle:close()
        end
    end
    _G.EnvRequiresUpdate = true
    _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
end

function _G.AK_LoadINI()
    local fileHandle = nil
    for _, filePath in ipairs(configFilePaths) do
        fileHandle = io.open(filePath, "r")
        if fileHandle then break end
    end
    if fileHandle then
        local fileContent = fileHandle:read("*all")
        fileHandle:close()
        for _, feature in ipairs(_G.AK_Features) do
            local savedValue = string.match(fileContent, feature.id .. "=(%d+)")
            if savedValue then feature.val = tonumber(savedValue) end
        end
    end
end

function _G.AK_GetVal(featureId)
    if not _G.AK_Features then return 0 end
    for _, feature in ipairs(_G.AK_Features) do
        if feature.id == featureId then return feature.val end
    end
    return 0
end

--- Displays the interactive mod menu dialog
function _G.ShowAKMenu()
    if not _G.AK_Features then return end

    local selectedFeature = _G.AK_Features[_G.AK_MenuIndex]
    local menuTitle = "JOIN @ADITYA_ORG"
    local menuContent = "MOD LUA PAK VIP CUSTOM ANDROID V11\n[MOD SKIN VIP - BYPASS V7 - ANTI REPORT]\n"
    local statusText = ""

    -- Build status text for selected feature
    if selectedFeature.type == "toggle" then
        statusText = (selectedFeature.val == 1) and "ON" or "OFF"
    elseif selectedFeature.type == "percent_100" then
        local actionLabel = selectedFeature.action_prefix or "INCREASE"
        statusText = actionLabel .. " " .. tostring(selectedFeature.val / 10) .. "%"
    elseif selectedFeature.type == "percent_10" then
        local actionLabel = selectedFeature.action_prefix or "INCREASE"
        statusText = actionLabel .. " " .. tostring(selectedFeature.val) .. "%"
    elseif selectedFeature.type == "value_range" then
        statusText = tostring(selectedFeature.val)
    end

    menuContent = menuContent .. "SELECTED FEATURE\n[" .. selectedFeature.name .. "]\nSTATUS [" .. statusText .. "]\n\n"

    -- Build feature list
    for i, feature in ipairs(_G.AK_Features) do
        local cursorIndicator = (i == _G.AK_MenuIndex) and "▶ " or "   "
        local featureState = ""
        if feature.type == "toggle" then
            featureState = (feature.val == 1) and "[ON]" or "[OFF]"
        elseif feature.type == "percent_100" then
            featureState = "[" .. tostring(feature.val / 10) .. "%]"
        elseif feature.type == "percent_10" then
            featureState = "[" .. tostring(feature.val) .. "%]"
        elseif feature.type == "value_range" then
            featureState = "[" .. tostring(feature.val) .. "]"
        end
        menuContent = menuContent .. cursorIndicator .. feature.name .. " " .. featureState .. "\n"
    end

    -- Determine action button label
    local actionButtonLabel = "SELECT"
    if selectedFeature.type == "toggle" then
        actionButtonLabel = "TOGGLE"
    elseif selectedFeature.type == "percent_100" or selectedFeature.type == "percent_10" then
        local actionLabel = selectedFeature.action_prefix or "INCREASE"
        actionButtonLabel = actionLabel .. " 10%"
    elseif selectedFeature.type == "value_range" then
        actionButtonLabel = "INCREASE BY " .. tostring(selectedFeature.step)
    end

    local messageBoxLib = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        or require("client.slua.logic.common.logic_common_msg_box")
    if messageBoxLib and messageBoxLib.Show then
        messageBoxLib.Show(4, menuTitle, menuContent,
            function()
                if selectedFeature.type == "toggle" then
                    selectedFeature.val = 1 - selectedFeature.val
                elseif selectedFeature.type == "percent_100" then
                    selectedFeature.val = selectedFeature.val + 100
                    if selectedFeature.val > 1000 then selectedFeature.val = 0 end
                elseif selectedFeature.type == "percent_10" then
                    selectedFeature.val = selectedFeature.val + 10
                    if selectedFeature.val > 100 then selectedFeature.val = 0 end
                elseif selectedFeature.type == "value_range" then
                    selectedFeature.val = selectedFeature.val + selectedFeature.step
                    if selectedFeature.val > selectedFeature.max then
                        selectedFeature.val = selectedFeature.min
                    end
                end
                _G.AK_SaveINI()
                _G.ShowAKMenu()
            end,
            function()
                _G.AK_MenuIndex = _G.AK_MenuIndex + 1
                if _G.AK_MenuIndex > #_G.AK_Features then
                    _G.AK_MenuIndex = 1
                end
                _G.ShowAKMenu()
            end,
            actionButtonLabel,
            "NEXT FEATURE"
        )
    end
end

-- ============================================================================
-- SECTION 16: CORE CHARACTER FEATURE CLASS
-- ============================================================================

local BRPlayerCharacterBase = {}

function BRPlayerCharacterBase:ctor()
    self.bHasShownDevNotice = false
    self.bHasShownExpiredNotice = false
    self.AK_NativeESP_Ready = false
end

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
    print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
    self:StartAdvancedSystems()
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)

    self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
    if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
        local CheckFallingDistanceComponent = import("CheckFallingDistanceComponent")
        if slua.isValid(CheckFallingDistanceComponent) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent)) then
            print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
            Game:AddComponent(CheckFallingDistanceComponent, self, "CheckFallingDistanceComponent")
        end
    end
    if slua.isValid(self.STCharacterMovement) then
        self.STCharacterMovement.bPositiveBlowUp = true
    end
    if self.Role == ENetRole.ROLE_AutonomousProxy then
        self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
        self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
        self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
            AttrName = { "bCanSelfRescue" }
        }, self.CharacterAttrChangeEvent, self)
    end
    if Client then
        printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
        GameplayData.AddCharacter(self.Object)
        self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
        self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
    else
        self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
            [1] = "FinishedState"
        }, self.HandleFinishedState, self)
    end

    EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
end

function BRPlayerCharacterBase:ReceiveEndPlay(endPlayReason)
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, endPlayReason)
    if Client and GameplayData.RemoveCharacter ~= nil then
        GameplayData.RemoveCharacter(self.Object)
    end
end

-- ============================================================================
-- SECTION 17: ADVANCED GAMEPLAY SYSTEMS (ESP, Magic, Environment, Weapon Mods)
-- ============================================================================

function BRPlayerCharacterBase:StartAdvancedSystems()
    if not Client then return end

    self:AddGameTimer(0.1, true, function()
        if not slua.isValid(self.Object) then return end

        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end

        -----------------------------------------------------------------------
        -- 17.1 Expiration Check
        -----------------------------------------------------------------------
        if currentTime > expirationDate then
            if self.Object == localPlayer and not self.bHasShownExpiredNotice then
                if self.Object.IsAlive and self.Object:IsAlive() then
                    self.bHasShownExpiredNotice = true
                    pcall(function()
                        local messageBoxLib = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                            or require("client.slua.logic.common.logic_common_msg_box")
                        if messageBoxLib and messageBoxLib.Show then
                            messageBoxLib.Show(4, "NOTICE FROM ADMIN @ADITYA_ORG",
                                "YOUR MOD VERSION HAS EXPIRED\nPLEASE CONTACT TELEGRAM @ADITYA_ORG TO PURCHASE",
                                function()
                                    local KismetSystemLibrary = import("KismetSystemLibrary")
                                    if KismetSystemLibrary then
                                        KismetSystemLibrary.LaunchURL("https://t.me/ADITYA_ORG")
                                    end
                                end,
                                function() end,
                                "CONTACT ADMIN",
                                "CANCEL"
                            )
                        end
                    end)
                end
            end
            return
        end

        -----------------------------------------------------------------------
        -- 17.2 First-Time Initialization & Menu Display
        -----------------------------------------------------------------------
        if self.Object == localPlayer and not self.bHasShownDevNotice then
            if self.Object.IsAlive and self.Object:IsAlive() then
                self.bHasShownDevNotice = true

                if not _G.AK_Features then
                    _G.AK_Features = {
                        { id = "ESP_HP",          name = "HP ESP",              val = 0,  type = "toggle" },
                        { id = "ESP_BOX",         name = "BOX ESP",             val = 0,  type = "toggle" },
                        { id = "IPAD_VIEW_TPP",   name = "IPAD VIEW TPP",       val = 90, type = "value_range", min = 90,  max = 150, step = 5 },
                        { id = "IPAD_VIEW_FPP",   name = "IPAD VIEW FPP",       val = 103,type = "value_range", min = 103, max = 150, step = 5 },
                        { id = "AIMBOT",          name = "AIMBOT",              val = 0,  type = "toggle" },
                        { id = "SPEED_AIMBOT",    name = "AIMBOT SPEED",        val = 0,  type = "percent_10", action_prefix = "INCREASE" },
                        { id = "FOV_AIMBOT",      name = "AIMBOT FOV",          val = 0,  type = "percent_10", action_prefix = "INCREASE" },
                        { id = "THU_TAM",         name = "RECOIL REDUCTION",    val = 0,  type = "percent_10", action_prefix = "REDUCE" },
                        { id = "GIAM_GIAT_NGANG", name = "HORIZONTAL RECOIL",   val = 0,  type = "percent_10", action_prefix = "REDUCE" },
                        { id = "GIAM_GIAT_DOC",   name = "VERTICAL RECOIL",     val = 0,  type = "percent_10", action_prefix = "REDUCE" },
                        { id = "GIAM_RUNG_SCOPE", name = "SCOPE SWAY",          val = 0,  type = "percent_10", action_prefix = "REDUCE" },
                        { id = "MAGIC_HEAD",      name = "MAGIC HEAD",          val = 0,  type = "percent_100", action_prefix = "INCREASE" },
                        { id = "MAGIC_BODY",      name = "MAGIC BODY",          val = 0,  type = "percent_100", action_prefix = "INCREASE" },
                        { id = "MAGIC_LEGS",      name = "MAGIC LEGS",          val = 0,  type = "percent_100", action_prefix = "INCREASE" },
                        { id = "NOGRASS",         name = "NO GRASS",            val = 0,  type = "toggle" },
                        { id = "NOTREES",         name = "NO TREES",            val = 0,  type = "toggle" },
                        { id = "NOWATER",         name = "NO WATER",            val = 0,  type = "toggle" },
                        { id = "NOFOG",           name = "NO FOG",              val = 0,  type = "toggle" },
                        { id = "WHITE_BODY",      name = "WHITE BODY",          val = 0,  type = "toggle" },
                    }
                    _G.AK_MenuIndex = 1
                end

                pcall(function()
                    _G.AK_LoadINI()
                    _G.ShowAKMenu()
                end)
            end
        end

        -----------------------------------------------------------------------
        -- 17.3 FOV Modification (iPad View)
        -----------------------------------------------------------------------
        local tppFOV = _G.AK_GetVal("IPAD_VIEW_TPP")
        if tppFOV == 0 or tppFOV < 90 then tppFOV = 90 end

        local fppFOV = _G.AK_GetVal("IPAD_VIEW_FPP")
        if fppFOV == 0 or fppFOV < 103 then fppFOV = 103 end

        local tppCameraComponent = self.Object.ThirdPersonCameraComponent
        local fppCameraComponent = self.Object.FirstPersonCameraComponent
        local isAiming = self.Object.bIsWeaponAiming or false

        if not isAiming then
            if slua.isValid(tppCameraComponent) and tppFOV > 90 then
                tppCameraComponent:SetFieldOfView(tppFOV)
                tppCameraComponent.FieldOfView = tppFOV
            end
            if slua.isValid(fppCameraComponent) and fppFOV > 103 then
                fppCameraComponent:SetFieldOfView(fppFOV)
                fppCameraComponent.FieldOfView = fppFOV
            end
        end

        -----------------------------------------------------------------------
        -- 17.4 Weapon Modifications (Recoil, Aim Assist)
        -----------------------------------------------------------------------
        if self.Object.GetCurrentWeapon then
            local currentWeapon = self.Object:GetCurrentWeapon()
            if slua.isValid(currentWeapon) then
                local currentClock = os.clock()

                if self.LastWeaponEntity ~= currentWeapon then
                    self.LastWeaponEntity = currentWeapon
                    self.bForceWeaponMod = true
                end

                if not self.LastWeaponModTime or currentClock > self.LastWeaponModTime + 2.0 then
                    self.bForceWeaponMod = true
                    self.LastWeaponModTime = currentClock
                end

                if self.bForceWeaponMod or not currentWeapon.bIsAKModded then
                    pcall(function()
                        local shootWeapon = currentWeapon.ShootWeaponEntity_GEN_VARIABLE
                            or currentWeapon.ShootWeaponEntity
                        if slua.isValid(shootWeapon) then
                            local recoilRecoveryFactor = _G.AK_GetVal("THU_TAM") / 100.0
                            local horizontalRecoilReduction = _G.AK_GetVal("GIAM_GIAT_NGANG") / 100.0
                            local verticalRecoilReduction = _G.AK_GetVal("GIAM_GIAT_DOC") / 100.0
                            local scopeSwayReduction = _G.AK_GetVal("GIAM_RUNG_SCOPE") / 100.0

                            shootWeapon.GameDeviationFactor = 3.36 - (3.36 * recoilRecoveryFactor)
                            shootWeapon.AccessoriesHRecoilFactor = 0.80 - (0.80 * horizontalRecoilReduction)
                            shootWeapon.AccessoriesVRecoilFactor = 0.50 - (0.50 * verticalRecoilReduction)
                            shootWeapon.RecoilKickADS = 0.20 - (0.20 * scopeSwayReduction)

                            if _G.AK_GetVal("AIMBOT") == 1 then
                                if shootWeapon.AutoAimingConfig then
                                    local aimConfig = shootWeapon.AutoAimingConfig
                                    local speedMultiplier = _G.AK_GetVal("SPEED_AIMBOT") / 100.0
                                    local fovMultiplier = _G.AK_GetVal("FOV_AIMBOT") / 100.0

                                    local enhancedSpeed = 3.0 + (3.0 * speedMultiplier)
                                    local enhancedRange = 1.5 + (1.5 * fovMultiplier)

                                    if aimConfig.OuterRange then
                                        aimConfig.OuterRange.Speed = enhancedSpeed
                                        aimConfig.OuterRange.SpeedRate = enhancedSpeed
                                        aimConfig.OuterRange.RangeRate = enhancedRange
                                        aimConfig.OuterRange.RangeRateSight = enhancedRange
                                        aimConfig.OuterRange.SpeedRateSight = enhancedSpeed
                                        aimConfig.OuterRange.CrouchRate = 1.0
                                        aimConfig.OuterRange.ProneRate = 1.0
                                    end
                                    if aimConfig.InnerRange then
                                        aimConfig.InnerRange.Speed = enhancedSpeed
                                        aimConfig.InnerRange.SpeedRate = enhancedSpeed
                                        aimConfig.InnerRange.RangeRate = enhancedRange
                                        aimConfig.InnerRange.RangeRateSight = enhancedRange
                                        aimConfig.InnerRange.SpeedRateSight = enhancedSpeed
                                        aimConfig.InnerRange.CrouchRate = 1.0
                                        aimConfig.InnerRange.ProneRate = 1.0
                                    end
                                    shootWeapon.AutoAimingConfig = aimConfig
                                end
                            end
                        end
                    end)
                    currentWeapon.bIsAKModded = true
                    self.bForceWeaponMod = false
                end
            end
        end

        -----------------------------------------------------------------------
        -- 17.5 ESP, Magic Hitboxes, and Environment Mods (Local Player Only)
        -----------------------------------------------------------------------
        if self.Object == localPlayer then
            if not _G.AKModTickCount then _G.AKModTickCount = 0 end
            if not _G.MagicUpdateVersion then _G.MagicUpdateVersion = 1 end
            if _G.EnvRequiresUpdate == nil then _G.EnvRequiresUpdate = true end

            _G.AKModTickCount = _G.AKModTickCount + 1

            -- Periodic settings re-check (every 5 seconds)
            if _G.AKModTickCount % 50 == 0 then
                pcall(function()
                    local prevMagicHead = _G.AK_GetVal("MAGIC_HEAD")
                    local prevMagicBody = _G.AK_GetVal("MAGIC_BODY")
                    local prevMagicLegs = _G.AK_GetVal("MAGIC_LEGS")
                    local prevNoGrass = _G.AK_GetVal("NOGRASS")
                    local prevNoTrees = _G.AK_GetVal("NOTREES")
                    local prevNoWater = _G.AK_GetVal("NOWATER")
                    local prevNoFog = _G.AK_GetVal("NOFOG")
                    local prevWhiteBody = _G.AK_GetVal("WHITE_BODY")

                    _G.AK_LoadINI()

                    if prevMagicHead ~= _G.AK_GetVal("MAGIC_HEAD")
                        or prevMagicBody ~= _G.AK_GetVal("MAGIC_BODY")
                        or prevMagicLegs ~= _G.AK_GetVal("MAGIC_LEGS") then
                        _G.MagicUpdateVersion = _G.MagicUpdateVersion + 1
                    end
                    if prevNoGrass ~= _G.AK_GetVal("NOGRASS")
                        or prevNoTrees ~= _G.AK_GetVal("NOTREES")
                        or prevNoWater ~= _G.AK_GetVal("NOWATER")
                        or prevNoFog ~= _G.AK_GetVal("NOFOG")
                        or prevWhiteBody ~= _G.AK_GetVal("WHITE_BODY") then
                        _G.EnvRequiresUpdate = true
                    end
                end)
            end

            -------------------------------------------------------------------
            -- 17.5.1 ESP System Initialization
            -------------------------------------------------------------------
            if not self.AK_NativeESP_Ready then
                pcall(function()
                    local gameplayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
                    local screenMarkConfig = gameplayTools.GetCurrentConfig("ScreenMarkConfig")

                    if screenMarkConfig then
                        if screenMarkConfig[1006] then
                            screenMarkConfig[1006].bBindBlocked = true
                            screenMarkConfig[1006].bBindOutScreen = true
                            screenMarkConfig[1006].MaxWidgetNum = 99
                            screenMarkConfig[1006].MaxShowDistance = 6000000
                            screenMarkConfig[1006].bScaleByDistance = false
                            screenMarkConfig[1006].BindSocketName = "root"
                            screenMarkConfig[1006].bUseLuaWorldSocketName = true
                            screenMarkConfig[1006].WorldPositionOffset = FVector(0, 0, -30)
                        end

                        if not screenMarkConfig[9999] then
                            screenMarkConfig[9999] = {
                                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                                MaxWidgetNum = 99,
                                MaxShowDistance = 6000000,
                                bBindOutScreen = true,
                                bBindBlocked = true,
                                bIsBindingActor = true,
                                BindSocketName = "head",
                                bUseLuaWorldSocketName = true,
                                WorldPositionOffset = FVector(0, 0, 50),
                                bNeedPreLoad = true,
                                Priority = 2
                            }
                            if InGameMarkTools and InGameMarkTools.ScreenMarkManager and InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
                                pcall(function()
                                    InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999)
                                end)
                            end
                        end
                    end

                    -- Apply to all loaded package copies
                    for moduleName, moduleData in pairs(package.loaded) do
                        if type(moduleName) == "string" and string.find(moduleName, "ScreenMarkConfig") then
                            if type(moduleData) == "table" then
                                if moduleData[1006] then
                                    moduleData[1006].bBindBlocked = true
                                    moduleData[1006].bBindOutScreen = true
                                    moduleData[1006].MaxWidgetNum = 99
                                    moduleData[1006].MaxShowDistance = 6000000
                                    moduleData[1006].bScaleByDistance = false
                                    moduleData[1006].BindSocketName = "root"
                                    moduleData[1006].bUseLuaWorldSocketName = true
                                    moduleData[1006].WorldPositionOffset = FVector(0, 0, -30)
                                end
                                moduleData[9999] = {
                                    UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                                    MaxWidgetNum = 99,
                                    MaxShowDistance = 6000000,
                                    bBindOutScreen = true,
                                    bBindBlocked = true,
                                    bIsBindingActor = true,
                                    BindSocketName = "head",
                                    bUseLuaWorldSocketName = true,
                                    WorldPositionOffset = FVector(0, 0, 50),
                                    bNeedPreLoad = true,
                                    Priority = 2
                                }
                            end
                        end
                    end

                    -- Patch HP Bar Subsystem
                    local subsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                    local hpBarSubsystem = subsystemMgr:Get("ClientHPBarSubSystem")
                    if hpBarSubsystem then
                        if hpBarSubsystem.SetPauseCheck then hpBarSubsystem:SetPauseCheck(true) end
                        if hpBarSubsystem.FocusActorCheckParam then
                            hpBarSubsystem.FocusActorCheckParam.CheckBlock = false
                            hpBarSubsystem.FocusActorCheckParam.CheckDistance = 1000000
                        end
                    end

                    -- Patch HP Bar UI
                    if UIManager and UIManager.GetUI then
                        local hpBarUI = UIManager.GetUI(UIManager.UI_Config_InGame.EnemyHpWidgetsMain)
                        if slua.isValid(hpBarUI) then
                            if hpBarUI.SetCheckBlock then hpBarUI:SetCheckBlock(false) end
                            if hpBarUI.UIRoot and hpBarUI.UIRoot.CanvasPanel_HPBarWidgets then
                                if hpBarUI.UIRoot.CanvasPanel_HPBarWidgets.SetRenderScale then
                                    hpBarUI.UIRoot.CanvasPanel_HPBarWidgets:SetRenderScale(FVector2D(1.5, 1.5))
                                end
                            end
                        end
                    end
                end)
                self.AK_NativeESP_Ready = true
            end

            -------------------------------------------------------------------
            -- 17.5.2 Environment Modification
            -------------------------------------------------------------------
            if _G.EnvRequiresUpdate then
                _G.EnvRequiresUpdate = false
                pcall(function()
                    local KismetSystemLibrary = import("KismetSystemLibrary")
                    local playerController = GameplayData.GetPlayerController()

                    local function executeCommand(cmdKey, cmdValue)
                        if slua.isValid(KismetSystemLibrary) and slua.isValid(playerController) then
                            KismetSystemLibrary.ExecuteConsoleCommand(playerController, cmdKey .. " " .. cmdValue)
                        end
                        local gameInstance = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
                        if slua.isValid(gameInstance) and gameInstance.ExecuteCMD then
                            gameInstance:ExecuteCMD(cmdKey, cmdValue)
                        end
                    end

                    if slua.isValid(playerController) then
                        -- Grass
                        if _G.AK_GetVal("NOGRASS") == 1 then
                            executeCommand("r.DisableGrassRender", "1")
                        else
                            executeCommand("r.DisableGrassRender", "0")
                        end

                        -- Trees
                        if _G.AK_GetVal("NOTREES") == 1 then
                            executeCommand("foliage.DensityScale", "0")
                            executeCommand("r.Foliage.DensityScale", "0")
                            executeCommand("foliage.MinimumScreenSize", "10000")
                            executeCommand("r.DisableTreeRender", "1")
                        else
                            executeCommand("foliage.DensityScale", "1")
                            executeCommand("r.Foliage.DensityScale", "1")
                            executeCommand("foliage.MinimumScreenSize", "0.0001")
                            executeCommand("r.DisableTreeRender", "0")
                        end

                        -- Water
                        if _G.AK_GetVal("NOWATER") == 1 then
                            executeCommand("r.Water.SingleLayer.Enable", "0")
                            executeCommand("r.Show.Water", "0")
                            executeCommand("r.Show.Translucency", "0")
                            executeCommand("r.DisableWaterRender", "1")
                        else
                            executeCommand("r.Water.SingleLayer.Enable", "1")
                            executeCommand("r.Show.Water", "1")
                            executeCommand("r.Show.Translucency", "1")
                            executeCommand("r.DisableWaterRender", "0")
                        end

                        -- Fog
                        if _G.AK_GetVal("NOFOG") == 1 then
                            executeCommand("r.SkyAtmosphere", "0")
                            executeCommand("r.Atmosphere", "0")
                            executeCommand("r.Fog", "0")
                            executeCommand("r.VolumetricFog", "0")
                            executeCommand("r.DisableSkyRender", "1")
                        else
                            executeCommand("r.SkyAtmosphere", "1")
                            executeCommand("r.Atmosphere", "1")
                            executeCommand("r.Fog", "1")
                            executeCommand("r.VolumetricFog", "1")
                            executeCommand("r.DisableSkyRender", "0")
                        end

                        -- White Body
                        if _G.AK_GetVal("WHITE_BODY") == 1 then
                            executeCommand("r.CharacterDiffuseOffset", "2")
                            executeCommand("r.CharacterDiffusePower", "5")
                            executeCommand("r.CharacterMinShadowFactor", "100")
                        else
                            executeCommand("r.CharacterDiffuseOffset", "0")
                            executeCommand("r.CharacterDiffusePower", "1")
                            executeCommand("r.CharacterMinShadowFactor", "0")
                        end
                    end
                end)
            end

            -------------------------------------------------------------------
            -- 17.5.3 Enemy Iteration & ESP/Magic Application
            -------------------------------------------------------------------
            local enemyCharacters = {}
            if GameplayData.GetAllPlayerCharacters then
                enemyCharacters = GameplayData.GetAllPlayerCharacters()
            elseif GameplayData.GameCharacters then
                for _, char in pairs(GameplayData.GameCharacters) do
                    table.insert(enemyCharacters, char)
                end
            end

            if not _G.AK_Active_Marks_Cache then _G.AK_Active_Marks_Cache = {} end

            -- Cleanup invalid cached marks
            for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
                local shouldRemove = false
                if not slua.isValid(cacheData.actor) then
                    shouldRemove = true
                else
                    pcall(function()
                        local actor = cacheData.actor
                        if actor.bHidden or (actor.Mesh and actor.Mesh.bHidden) then shouldRemove = true end
                        if type(actor.IsDead) == "function" and actor:IsDead() then shouldRemove = true
                        elseif actor.bIsDead == true or actor.bIsDeadFlag == true then shouldRemove = true end
                    end)
                end

                if shouldRemove then
                    pcall(function()
                        if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                            InGameMarkTools.ClientRemoveMapMark(cacheData.hpMark)
                            if cacheData.distMark then InGameMarkTools.ClientRemoveMapMark(cacheData.distMark) end
                        end
                    end)
                    _G.AK_Active_Marks_Cache[cacheKey] = nil
                end
            end

            -- Process each enemy
            for _, enemy in pairs(enemyCharacters) do
                if slua.isValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                    local isDead = false
                    local isNearDeath = false

                    pcall(function()
                        if type(enemy.IsNearDeath) == "function" then isNearDeath = enemy:IsNearDeath()
                        elseif enemy.bIsNearDeath ~= nil then isNearDeath = enemy.bIsNearDeath end

                        if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
                        elseif enemy.bIsDead ~= nil then isDead = enemy.bIsDead
                        elseif enemy.bIsDeadFlag ~= nil then isDead = enemy.bIsDeadFlag end

                        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end

                        if not isNearDeath then
                            local health = 100
                            if type(enemy.GetHealth) == "function" then health = enemy:GetHealth()
                            elseif enemy.Health ~= nil then health = enemy.Health end
                            if health <= 0 then isDead = true end
                        end
                    end)

                    if not isDead then
                        -- Handle knock state change
                        if enemy.bHasAKNativeHPBar and enemy.AK_LastKnockState ~= nil
                            and enemy.AK_LastKnockState ~= isNearDeath then
                            pcall(function()
                                if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                                    InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                    InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark)
                                end
                            end)
                            enemy.bHasAKNativeHPBar = false
                            _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
                        end
                        enemy.AK_LastKnockState = isNearDeath

                        -- ESP HP Bars
                        if _G.AK_GetVal("ESP_HP") == 1 then
                            if not enemy.bHasAKNativeHPBar then
                                pcall(function()
                                    if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
                                        enemy.NativeHPBarMark = InGameMarkTools.ClientAddMapMark(
                                            1006, FVector(0, 0, 0), 0, "", 4, enemy
                                        )
                                        enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(
                                            9999, FVector(0, 0, 0), 0, "", 4, enemy
                                        )
                                        enemy.bHasAKNativeHPBar = true
                                        _G.AK_Active_Marks_Cache[tostring(enemy)] = {
                                            actor = enemy,
                                            hpMark = enemy.NativeHPBarMark,
                                            distMark = enemy.NativeDistMark
                                        }
                                    end
                                end)
                            end
                        else
                            if enemy.bHasAKNativeHPBar and InGameMarkTools then
                                pcall(function()
                                    if InGameMarkTools.ClientRemoveMapMark then
                                        InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                        if enemy.NativeDistMark then
                                            InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark)
                                        end
                                    else
                                        InGameMarkTools.HideMapMark(enemy.NativeHPBarMark)
                                        if enemy.NativeDistMark then
                                            InGameMarkTools.HideMapMark(enemy.NativeDistMark)
                                        end
                                    end
                                end)
                                enemy.NativeHPBarMark = nil
                                enemy.NativeDistMark = nil
                                enemy.bHasAKNativeHPBar = false
                                _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
                            end
                        end

                        -- ESP Box
                        if _G.AK_GetVal("ESP_BOX") == 1 then
                            pcall(function()
                                if enemy.Replay_IsEnemyFrameUIExisted then
                                    if not enemy:Replay_IsEnemyFrameUIExisted() then
                                        enemy:Replay_CreateEnemyFrameUI(true, true)
                                    end
                                    if enemy.Replay_SetVisiableOfFrameUI then
                                        enemy:Replay_SetVisiableOfFrameUI(true)
                                    end
                                end
                            end)
                        else
                            pcall(function()
                                if enemy.Replay_SetVisiableOfFrameUI then
                                    enemy:Replay_SetVisiableOfFrameUI(false)
                                end
                            end)
                        end

                        -- Magic Hitboxes
                        local enemyMesh = enemy.Mesh or (enemy.getAvatarComponent2 and enemy:getAvatarComponent2())
                        if slua.isValid(enemyMesh) then
                            if not enemyMesh.LastHitboxUpdateVersion
                                or enemyMesh.LastHitboxUpdateVersion ~= _G.MagicUpdateVersion then
                                enemyMesh.bIsAKHitboxModded = false
                            end

                            if not enemyMesh.bIsAKHitboxModded then
                                pcall(function()
                                    local physicsAsset = enemyMesh.PhysicsAssetOverride
                                    if not slua.isValid(physicsAsset) and enemyMesh.SkeletalMesh then
                                        physicsAsset = enemyMesh.SkeletalMesh.PhysicsAsset
                                    end

                                    if slua.isValid(physicsAsset) and physicsAsset.SkeletalBodySetups then
                                        if not _G.AK_OrigHitboxes then _G.AK_OrigHitboxes = {} end

                                        local assetName = ""
                                        pcall(function() assetName = physicsAsset:GetName() end)
                                        if assetName == "" then assetName = "DefaultPhys" end

                                        if not _G.AK_OrigHitboxes[assetName] then
                                            _G.AK_OrigHitboxes[assetName] = {}
                                        end
                                        local originalHitboxes = _G.AK_OrigHitboxes[assetName]

                                        local headScale = 1.0 + (_G.AK_GetVal("MAGIC_HEAD") / 100.0)
                                        local bodyScale = 1.0 + (_G.AK_GetVal("MAGIC_BODY") / 100.0)
                                        local legsScale = 1.0 + (_G.AK_GetVal("MAGIC_LEGS") / 100.0)

                                        local boneScaleMap = {
                                            ["head"] = headScale,
                                            ["pelvis"] = bodyScale,
                                            ["spine_03"] = bodyScale,
                                            ["thigh_l"] = legsScale, ["thigh_r"] = legsScale,
                                            ["calf_l"] = legsScale, ["calf_r"] = legsScale,
                                            ["foot_l"] = legsScale, ["foot_r"] = legsScale
                                        }

                                        local skeletalBodySetups = physicsAsset.SkeletalBodySetups
                                        for i = 1, 50 do
                                            local bodySetup = nil
                                            pcall(function()
                                                bodySetup = type(skeletalBodySetups.Get) == "function"
                                                    and skeletalBodySetups:Get(i - 1)
                                                    or skeletalBodySetups[i]
                                            end)
                                            if not bodySetup then break end

                                            if slua.isValid(bodySetup) then
                                                local boneName = string.lower(tostring(bodySetup.BoneName))
                                                local matchedBone = nil
                                                for boneKey, _ in pairs(boneScaleMap) do
                                                    if string.find(boneName, boneKey) then
                                                        matchedBone = boneKey
                                                        break
                                                    end
                                                end

                                                if matchedBone then
                                                    local scaleMultiplier = boneScaleMap[matchedBone]
                                                    local aggGeom = bodySetup.AggGeom

                                                    local boxElems = aggGeom and aggGeom.BoxElems or bodySetup.BoxElems
                                                    local sphereElems = aggGeom and aggGeom.SphereElems or bodySetup.SphereElems
                                                    local sphylElems = aggGeom and aggGeom.SphylElems or bodySetup.SphylElems

                                                    local boxElem, sphereElem, sphylElem = nil, nil, nil
                                                    if boxElems then
                                                        pcall(function()
                                                            boxElem = type(boxElems.Get) == "function"
                                                                and boxElems:Get(0) or boxElems[1]
                                                        end)
                                                    end
                                                    if sphereElems then
                                                        pcall(function()
                                                            sphereElem = type(sphereElems.Get) == "function"
                                                                and sphereElems:Get(0) or sphereElems[1]
                                                        end)
                                                    end
                                                    if sphylElems then
                                                        pcall(function()
                                                            sphylElem = type(sphylElems.Get) == "function"
                                                                and sphylElems:Get(0) or sphylElems[1]
                                                        end)
                                                    end

                                                    -- Save original dimensions
                                                    if not originalHitboxes[matchedBone] then
                                                        originalHitboxes[matchedBone] = {
                                                            Box = nil, Sphere = nil, Sphyl = nil
                                                        }
                                                        if boxElem then
                                                            originalHitboxes[matchedBone].Box = {
                                                                X = boxElem.X, Y = boxElem.Y, Z = boxElem.Z
                                                            }
                                                        end
                                                        if sphereElem then
                                                            originalHitboxes[matchedBone].Sphere = {
                                                                Radius = sphereElem.Radius
                                                            }
                                                        end
                                                        if sphylElem then
                                                            originalHitboxes[matchedBone].Sphyl = {
                                                                Radius = sphylElem.Radius,
                                                                Length = sphylElem.Length
                                                            }
                                                        end
                                                    end

                                                    local originalDims = originalHitboxes[matchedBone]

                                                    -- Apply scaled box
                                                    if originalDims.Box and boxElem then
                                                        boxElem.X = originalDims.Box.X * scaleMultiplier
                                                        boxElem.Y = originalDims.Box.Y * scaleMultiplier
                                                        boxElem.Z = originalDims.Box.Z * scaleMultiplier
                                                        pcall(function()
                                                            if type(boxElems.Set) == "function" then
                                                                boxElems:Set(0, boxElem)
                                                            else
                                                                boxElems[1] = boxElem
                                                            end
                                                        end)
                                                        if aggGeom then
                                                            aggGeom.BoxElems = boxElems
                                                            bodySetup.AggGeom = aggGeom
                                                        else
                                                            bodySetup.BoxElems = boxElems
                                                        end
                                                    end

                                                    -- Apply scaled sphere
                                                    if originalDims.Sphere and sphereElem then
                                                        sphereElem.Radius = originalDims.Sphere.Radius * scaleMultiplier
                                                        pcall(function()
                                                            if type(sphereElems.Set) == "function" then
                                                                sphereElems:Set(0, sphereElem)
                                                            else
                                                                sphereElems[1] = sphereElem
                                                            end
                                                        end)
                                                        if aggGeom then
                                                            aggGeom.SphereElems = sphereElems
                                                            bodySetup.AggGeom = aggGeom
                                                        else
                                                            bodySetup.SphereElems = sphereElems
                                                        end
                                                    end

                                                    -- Apply scaled sphyl
                                                    if originalDims.Sphyl and sphylElem then
                                                        sphylElem.Radius = originalDims.Sphyl.Radius * scaleMultiplier
                                                        sphylElem.Length = originalDims.Sphyl.Length * scaleMultiplier
                                                        pcall(function()
                                                            if type(sphylElems.Set) == "function" then
                                                                sphylElems:Set(0, sphylElem)
                                                            else
                                                                sphylElems[1] = sphylElem
                                                            end
                                                        end)
                                                        if aggGeom then
                                                            aggGeom.SphylElems = sphylElems
                                                            bodySetup.AggGeom = aggGeom
                                                        else
                                                            bodySetup.SphylElems = sphylElems
                                                        end
                                                    end
                                                end
                                            end
                                        end

                                        -- Refresh physics state
                                        pcall(function()
                                            if enemyMesh.SetPhysicsAsset then
                                                enemyMesh:SetPhysicsAsset(physicsAsset)
                                            end
                                            enemyMesh.PhysicsAssetOverride = physicsAsset
                                            if enemyMesh.RecreatePhysicsState then
                                                enemyMesh:RecreatePhysicsState()
                                            end
                                            if enemyMesh.WakeAllRigidBodies then
                                                enemyMesh:WakeAllRigidBodies()
                                            end
                                            if enemyMesh.ForceUpdateBones then
                                                enemyMesh:ForceUpdateBones()
                                            end
                                            if enemyMesh.UpdateBounds then
                                                enemyMesh:UpdateBounds()
                                            end
                                            enemyMesh.bEnableUpdateRateOptimizations = false
                                        end)
                                    end
                                end)
                                enemyMesh.bIsAKHitboxModded = true
                                enemyMesh.LastHitboxUpdateVersion = _G.MagicUpdateVersion
                            end
                        end
                    else
                        -- Remove marks for dead enemies
                        if enemy.bHasAKNativeHPBar and InGameMarkTools then
                            pcall(function()
                                if InGameMarkTools.ClientRemoveMapMark then
                                    InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                    if enemy.NativeDistMark then
                                        InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark)
                                    end
                                else
                                    InGameMarkTools.HideMapMark(enemy.NativeHPBarMark)
                                    if enemy.NativeDistMark then
                                        InGameMarkTools.HideMapMark(enemy.NativeDistMark)
                                    end
                                end
                            end)
                            enemy.NativeHPBarMark = nil
                            enemy.NativeDistMark = nil
                            enemy.bHasAKNativeHPBar = false
                        end
                        pcall(function()
                            if enemy.Replay_SetVisiableOfFrameUI then
                                enemy:Replay_SetVisiableOfFrameUI(false)
                            end
                        end)
                    end
                end
            end
        end
    end)
end

-- ============================================================================
-- SECTION 18: ANTI-DETECTION / SECURITY BYPASS SYSTEMS
-- ============================================================================

function _G.InitializeLogBlocker()
    print('[LogBlocker] Initializing Ultimate Log/Crash/Screenshot Blocker V11...')
    pcall(function()
        -- Block screenshot maker
        local ScreenshotMaker = import("ScreenshotMaker")
        if ScreenshotMaker then
            ScreenshotMaker.MakePicture = function() return "" end
            ScreenshotMaker.ReMakePicture = function() return "" end
            ScreenshotMaker.HasCaptured = function() return true end
        end

        -- Block TLog
        local tLog = package.loaded["TLog"] or _G.TLog
        if tLog then
            tLog.Info = function() end; tLog.Warning = function() end
            tLog.Error = function() end; tLog.Debug = function() end; tLog.Report = function() end
        end

        -- Block CrashSight
        local crashSight = package.loaded["CrashSight"] or _G.CrashSight
        if crashSight then
            crashSight.ReportException = function() end
            crashSight.SetCustomData = function() end; crashSight.Log = function() end
        end

        -- Block GameReportUtils
        local gameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if gameReportUtils then
            gameReportUtils.BugglyPostExceptionFull = function() return false end
            gameReportUtils.CheckCanBugglyPostException = function() return false end
            gameReportUtils.ReplayReportData = function() end
            gameReportUtils.ReportGameException = function() end
        end

        -- Block ClientToolsReport
        local clientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if clientToolsReport then
            clientToolsReport.SendReport = function() end; clientToolsReport.SendException = function() end
        end

        -- Block TLog Report Utils
        local tlogReportUtils = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if tlogReportUtils then
            tlogReportUtils.ReportTLogEvent = function() end
        end

        -- Block UGC TLog
        local ugcTLog = package.loaded["client.slua.logic.ugc.UGCNewTLogReport"]
            or package.loaded["client.slua.data.BasicData.BasicDataTLogReport"]
        if ugcTLog then
            ugcTLog.SendExposeReq = function() end
            ugcTLog.SendInteractionReq = function() end
            ugcTLog.TLogReport = function() end
        end

        local ugcTLogLogic = package.loaded["client.slua.logic.ugc.logic_ugc_tlog"]
        if ugcTLogLogic then
            ugcTLogLogic.SendModTLog = function() end
            ugcTLogLogic.ReportStay = function() end
        end

        -- Block ClientTLogUtil
        local clientTLogUtil = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"]
        if clientTLogUtil then
            clientTLogUtil.ReportGeneralCountByBRPhase = function() end
            clientTLogUtil.ReportCommonTLogDataByBRPhase = function() end
        end

        -- Block CrashKit
        local gameplayData = require("GameLua.GameCore.Data.GameplayData")
        if gameplayData then
            local playerController = gameplayData.GetPlayerControllerSafety and gameplayData.GetPlayerControllerSafety()
                or gameplayData.GetPlayerController()
            if slua.isValid(playerController) and playerController.ReportCrashKitFeature then
                playerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException = function() end
            end
        end
    end)
    print('[LogBlocker] Log/Crash/Buggly & Silent Screenshots Bypassed!')
end

function _G.InitializeScannerBlocker()
    print('[ScannerBlocker] Initializing Scanner Blocker V11...')
    pcall(function()
        local subsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")

        if subsystemMgr then
            -- Block AFK Reporter
            local afkReporter = subsystemMgr:Get("AFKReportorSubsystem")
            if afkReporter then
                afkReporter.PlayerHaveAction = function() end; afkReporter.ReportAFK = function() end
            end

            -- Block Client Data Statistics (ping delay reporting)
            local clientDataStats = subsystemMgr:Get("ClientDataStatistcsSubsystem")
            if clientDataStats then
                clientDataStats.StartToCheck = function() end
                clientDataStats.DelayCount = 0
                if clientDataStats.ReportPingDelayTimer then
                    clientDataStats:RemoveGameTimer(clientDataStats.ReportPingDelayTimer)
                    clientDataStats.ReportPingDelayTimer = nil
                end
            end

            -- Block Avatar Exception Subsystem
            local avatarException = subsystemMgr:Get("AvatarExceptionSubsystem")
            if avatarException then
                avatarException.ReportException = function() end
                avatarException.BindPlayerCharacter = function() end
                avatarException.CheckAvatarValid = function() return true end
            end

            -- Block Shoot Verify Subsystem
            local shootVerify = subsystemMgr:Get("ShootVerifySubSystemClient")
            if shootVerify then
                shootVerify.ReportVerifyFail = function() end
                shootVerify.OnVerifyFailed = function() end
            end
        end

        -- Block Creative Mode MD5 checks
        local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
        if CreativeModeBlueprintLibrary then
            CreativeModeBlueprintLibrary.MD5HashByteArray = function() return "BYPASSED_MD5_HASH" end
            CreativeModeBlueprintLibrary.GetContentDiffData = function() return true, "BYPASSED" end
        end

        -- Block Avatar Exception Player Instance
        local avatarExceptionPlayerInst = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if avatarExceptionPlayerInst then
            avatarExceptionPlayerInst.CheckAvatarException = function() end
            avatarExceptionPlayerInst.CheckAvatarExceptionOnce = function() end
            avatarExceptionPlayerInst.ReportAvatarException = function() end
            avatarExceptionPlayerInst.CheckSlotMeshVisible = function() return false end
            avatarExceptionPlayerInst.CheckPawnVisible = function() return false end
            avatarExceptionPlayerInst.CheckCanBugglyPostException = function() return false end
        end

        -- Block Avatar Checker Module
        local avatarChecker = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
        if avatarChecker then
            avatarChecker.CheckAvatar = function() return true end
            avatarChecker.ReportException = function() end
        end

        -- Block Memory Warning
        local memoryWarning = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
        if memoryWarning then
            memoryWarning.OnMemoryWarning = function() end
            memoryWarning.ReportMemoryWarning = function() end
        end

        -- Block Store Game Interface
        local storeGameInterface = package.loaded["client.slua.logic.store.logic_store_game_interface"]
        if storeGameInterface then
            storeGameInterface.IsStoreGameSupported = function() return true end
            storeGameInterface.NotifyGetPGSLoginInfo = function() end
        end

        -- Block Voice Chat Complaint
        local voiceChatSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Voice.VoiceChatSubsystem"]
        if voiceChatSubsystem then
            voiceChatSubsystem.OnPlayerSubmitComplaint = function() end
        end

        -- Block TssSdk
        local tssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if tssSdk then
            local originalOnRecvData = tssSdk.OnRecvData
            tssSdk.OnRecvData = function(data)
                if type(data) == "string" and (string.find(data, "report") or string.find(data, "exception")) then
                    return
                end
                if originalOnRecvData then originalOnRecvData(data) end
            end
            tssSdk.SendReportInfo = function() end
            tssSdk.ScanMemory = function() return true end
            tssSdk.IsEmulator = function() return false end
            tssSdk.GetTssSdkReportInfo = function() return "" end
        end
    end)
    print('[ScannerBlocker] Magic Bullet/MD5 Checks/TSS/OS Scans Bypassed!')
end

function _G.InitializeReplayTelemetryBlocker()
    print('[ReplayBlocker] Initializing Replay Telemetry Blocker V11...')
    pcall(function()
        local subsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")

        -- Block RescueBtnReplayTraceSubsystem
        local rescueReplayTrace = subsystemMgr and subsystemMgr:Get("RescueBtnReplayTraceSubsystem")
        if rescueReplayTrace then
            rescueReplayTrace.ReportTrace = function() end; rescueReplayTrace.StartTickMonitor = function() end
            rescueReplayTrace.TickMonitorCheck = function() end; rescueReplayTrace.ReportTickMonitorHeartbeat = function() end
        end

        -- Block GameReportSubsystem
        local gameReportSubsystem = subsystemMgr and subsystemMgr:Get("GameReportSubsystem")
        if gameReportSubsystem then
            gameReportSubsystem.ReplayReportData = function() return false end
            gameReportSubsystem.CheckCanBugglyPostException = function() return false end
            gameReportSubsystem.BugglyPostExceptionFull = function() return false end
            gameReportSubsystem.GetClientReplayDataReporter = function() return nil end

            if gameReportSubsystem.Reporter then
                gameReportSubsystem.Reporter.ReportIntArrayData = function() end
                gameReportSubsystem.Reporter.ReportUInt8ArrayData = function() end
                gameReportSubsystem.Reporter.ReportFloatArrayData = function() end
            end
        end

        -- Block Report Replay
        local reportReplay = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if reportReplay then
            reportReplay.ReportReplay = function() end
            reportReplay.SendReportReq = function() end
        end

        -- Block Home Report
        local homeReport = package.loaded["client.slua.logic.home.logic_home_report"]
        if homeReport then
            homeReport.ShowInGameReportUI = function() end
            homeReport.SendReport = function() end
        end
    end)
    print('[ReplayBlocker] Replay Evidence Collection Stopped!')
end

function _G.DisableHiggsBoson()
    local playerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not playerController or not slua.isValid(playerController) then return end
    if playerController.HiggsBoson then
        playerController.HiggsBoson.bMHActive = false
        playerController.HiggsBoson.bCallPreReplication = false
    end
    if playerController.HiggsBosonComponent then
        playerController.HiggsBosonComponent.bMHActive = false
        playerController.HiggsBosonComponent:ControlMHActive(0)
    end
end

function _G.InitializeAntiCheatHooks()
    print('[AntiCheat] Initializing bypass system...')
    pcall(function()
        local higgsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if higgsBosonComponent and higgsBosonComponent.StaticShowSecurityAlertInDev then
            higgsBosonComponent.StaticShowSecurityAlertInDev = function() end
        end
    end)

    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = function() end
        _G.AvatarCheckCallback.OnReportItemID = function() end
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(playerController)
            if slua.isValid(playerController) and playerController.HiggsBosonComponent then
                playerController.HiggsBosonComponent:ControlMHActive(0)
                playerController.HiggsBosonComponent.bMHActive = false
            end
        end
    end

    pcall(function()
        local higgsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if higgsBosonComponent and higgsBosonComponent.BlackList then
            for k in pairs(higgsBosonComponent.BlackList) do
                higgsBosonComponent.BlackList[k] = nil
            end
        end
    end)

    _G.BlackList = {}

    pcall(function()
        _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
        _G.GlobalPlayerCheatTimes = _G.GlobalPlayerCheatTimes or {}
        local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
        mt.__newindex = function(t, k, v) end
        setmetatable(_G.GlobalPlayerCoronaData, mt)
    end)

    pcall(function()
        if _G.GameSafeCallbacks and _G.GameSafeCallbacks.RecordStrategyTimestampInReplay then
            _G.GameSafeCallbacks.RecordStrategyTimestampInReplay = function(...) end
            _G.GameSafeCallbacks.DoAttackFlowStrategy = function() end
            _G.GameSafeCallbacks.GetScriptReportContent = function() return "" end
        end
    end)

    pcall(function()
        local blueprintLib = import("STExtraBlueprintFunctionLibrary")
        if blueprintLib then
            blueprintLib.IsDevelopment = function() return false end
        end
    end)
    print('[AntiCheat] Bypass system activated!')
end

function _G.InitializeAntiReport()
    print('[AntiReport] Initializing System...')
    pcall(function()
        local reportSubsystemPaths = {
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "Client.Security.ClientReportPlayerSubsystem"
        }
        local reportSubsystem = nil
        for _, path in ipairs(reportSubsystemPaths) do
            if package.loaded[path] then
                reportSubsystem = package.loaded[path]
                break
            end
            local success, module = pcall(require, path)
            if success and module then
                reportSubsystem = module
                break
            end
        end
        if reportSubsystem then
            reportSubsystem.OnInit = function() return end
            reportSubsystem._OnPlayerKilledOtherPlayer = function() return end
            reportSubsystem._RecordFatalDamager = function() return end
            reportSubsystem._OnDeathReplayDataWhenFatalDamaged = function() return end
            reportSubsystem._RecordMurdererFromDeathReplayData = function() return end
            reportSubsystem._RecordTeammatePlayerInfo = function() return end
            reportSubsystem._OnBattleResult = function() return end
            reportSubsystem._OnShowQuickReportMutualExclusiveUI = function() return end
            reportSubsystem.GetFatalDamagerMap = function() return {} end
            reportSubsystem.GetCachedTeammateName2InfoMap = function() return {} end
            reportSubsystem.GetTeammateName2InfoMapDuringBattle = function() return {} end
            reportSubsystem.GetCurrentNotInTeamHistoricalTeammateMap = function() return {} end
            reportSubsystem.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
        end
    end)

    pcall(function()
        local dsReportPaths = {
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem"
        }
        local dsReportSubsystem = nil
        for _, path in ipairs(dsReportPaths) do
            if package.loaded[path] then
                dsReportSubsystem = package.loaded[path]
                break
            end
            local success, module = pcall(require, path)
            if success and module then
                dsReportSubsystem = module
                break
            end
        end
        if dsReportSubsystem then
            dsReportSubsystem.OnInit = function() return end
            dsReportSubsystem._OnNearDeathOrRescued = function() return end
            dsReportSubsystem._OnCharacterDied = function() return end
            dsReportSubsystem._OnTeammateDamage = function() return end
            dsReportSubsystem._OnPlayerSettlementStart = function() return end
            dsReportSubsystem._AddKnockDownerToBattleResult = function() return end
            dsReportSubsystem._AddKillerToBattleResult = function() return end
            dsReportSubsystem._AddTeammateMurderToBattleResult = function() return end
            dsReportSubsystem._AddFatalDamagerMapToBattleResult = function() return end
            dsReportSubsystem._AddMLKillerUIDToBattleResult = function() return end
            dsReportSubsystem._SaveHistoricalTeammateInfo = function() return end
            dsReportSubsystem._RecordFatalDamager = function() return end
            dsReportSubsystem._RecordTeammateMurderer = function() return end
        end
    end)

    pcall(function()
        local reportUtils = require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
        if reportUtils then
            reportUtils.RecordFatalDamager = function() return end
            reportUtils.IsUsingHistoricalTeammateInfo = function() return false end
            reportUtils.IsCharacterDeliverAI = function() return false end
        end
    end)

    pcall(function()
        local securityUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if securityUtils then
            securityUtils.ExtractPlayerBasicInfo = function() return {} end
            securityUtils.LogIf = function() return false end
        end
    end)

    pcall(function()
        local quickReport = require("GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate")
        if quickReport then
            quickReport.OnShowMutualExclusiveUI = function() return end
            quickReport.OnHideMutualExclusiveUI = function() return end
        end
    end)
    print('[AntiReport] System Fully Active!')
end

function _G.InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end

        local GC = _G.GameplayCallbacks
        print('[GameplayBypass] Hooking GameplayCallbacks...')

        local originalStateChanged = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            if InPlayerState and string.lower(tostring(InPlayerState)) == "cheatdetected" then return end
            if originalStateChanged then
                return originalStateChanged(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            end
        end

        local noOpFunc = function() return end
        local emptyTableFunc = function() return {} end
        local nilReturnFunc = function() return nil end

        GC.ReportAttackFlow = noOpFunc
        GC.ReportSecAttackFlow = noOpFunc
        GC.ReportHurtFlow = noOpFunc
        GC.ReportFireArms = noOpFunc
        GC.ReportVerifyInfoFlow = noOpFunc
        GC.ReportMrpcsFlow = noOpFunc
        GC.ReportPlayerBehavior = noOpFunc
        GC.ReportTeammatHurt = noOpFunc
        GC.ReportMisKillByTeammate = noOpFunc
        GC.ReportForbitPick = noOpFunc
        GC.ReportPlayerMoveRoute = noOpFunc
        GC.ReportPlayerPosition = noOpFunc
        GC.ReportVehicleMoveFlow = noOpFunc
        GC.ReportSecTgameMovingFlow = noOpFunc
        GC.ReportParachuteData = noOpFunc
        GC.SendTssSdkAntiDataToLobby = noOpFunc
        GC.SendDSErrorLogToLobby = noOpFunc
        GC.SendDSErrorLogToLobbyOnece = noOpFunc
        GC.SendDSHawkEyePatrolLogToLobby = noOpFunc
        GC.ReportEquipmentFlow = noOpFunc
        GC.ReportAimFlow = noOpFunc
        GC.GetWeaponReport = emptyTableFunc
        GC.GetOneWeaponReport = emptyTableFunc
        GC.ReportHeavyWeaponBoxSpawnFlow = noOpFunc
        GC.ReportHeavyWeaponBoxActivationFlow = noOpFunc
        GC.ReportHeavyWeaponBoxOpenPlayerFlow = noOpFunc
        GC.ReportHeavyWeaponBoxItemFlow = noOpFunc
        GC.ReportPlayersPing = noOpFunc
        GC.ReportPlayerIP = noOpFunc
        GC.ReportPlayerFramePingRecord = noOpFunc
        GC.OnDSConnectionSaturated = noOpFunc
        GC.ReportDSNetSaturation = noOpFunc
        GC.ReportNetContinuousSaturate = noOpFunc
        GC.ReportDSNetRate = noOpFunc
        GC.SendClientStats = noOpFunc
        GC.SendServerAvgTickDelta = noOpFunc
        GC.ReportCircleFlow = noOpFunc
        GC.ReportDSCircleFlow = noOpFunc
        GC.ReportJumpFlow = noOpFunc
        GC.ReportAIStrategyInfo = noOpFunc
        GC.SendAIDeliveryInfo = noOpFunc
        GC.ReportDailyTaskInfo = noOpFunc
        GC.ReportMatchRoomData = noOpFunc
        GC.SendPlayerSpectatingLog = noOpFunc
        GC.ReportIDCardProduceFlow = noOpFunc
        GC.ReportIDCardPickUpFlow = noOpFunc
        GC.ReportIDCardDestroyFlow = noOpFunc
        GC.ReportRevivalFlow = noOpFunc
        GC.ReportGameSetting = noOpFunc
        GC.ReportGameSettingNew = noOpFunc
        GC.ReportAntsVoiceTeamCreate = noOpFunc
        GC.ReportAntsVoiceTeamQuit = noOpFunc
        GC.ReportCommonInfo = noOpFunc
        GC.ReportLightweightStat = noOpFunc
        GC.SendSecTLog = noOpFunc
        GC.SendDataMiningTLog = noOpFunc
        GC.SendActivityTLog = noOpFunc
        GC.GetGeneralTLogData = nilReturnFunc

        GC.IsBypassed = true
    end)

    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
            local originalSendPacket = NetUtil.SendPacket
            local blockedPackets = {
                ["ReportAttackFlow"] = 1, ["ReportSecAttackFlow"] = 1, ["ReportHurtFlow"] = 1,
                ["ReportFireArms"] = 1, ["ReportVerifyInfoFlow"] = 1, ["ReportMrpcsFlow"] = 1,
                ["ReportPlayerBehavior"] = 1, ["ReportTeammatHurt"] = 1, ["ReportTeammateKillConfirmFlow"] = 1,
                ["ReportForbiddenPickupFlow"] = 1, ["ReportPlayerMoveRoute"] = 1, ["ReportPlayerPosition"] = 1,
                ["ReportSecVehicleMoveFlow"] = 1, ["ReportSecTgameMovingFlow"] = 1, ["report_parachute_data"] = 1,
                ["report_character_all_drag"] = 1, ["report_parachute_all_drag"] = 1, ["report_vehicle_move_drag"] = 1,
                ["on_tss_sdk_anti_data"] = 1, ["report_unrealnet_exception"] = 1, ["ReportPlayerEquipmentInfo"] = 1,
                ["ReportAimFlow"] = 1, ["ReportHitFlow"] = 1, ["log_shooting_miss"] = 1,
                ["report_heavy_weapon_box_activation_flow"] = 1, ["report_heavy_weapon_box_item_flow"] = 1,
                ["ReportCircleFlow"] = 1, ["report_ds_player_circle_flow"] = 1, ["ReportJumpFlow"] = 1,
                ["ReportGameStartFlow"] = 1, ["ReportGameEndFlow"] = 1, ["report_players_ping"] = 1,
                ["report_player_ip"] = 1, ["report_player_frame_ping_record"] = 1, ["report_net_saturate"] = 1,
                ["report_ds_netsaturate"] = 1, ["report_ds_net_continuous_saturate"] = 1, ["report_ds_netrate"] = 1,
                ["report_unrealnet_clientstats"] = 1, ["report_serverstat_avgtickdelta"] = 1,
                ["report_all_players_address"] = 1, ["report_ai_strategyinfo"] = 1, ["ReportAIActionFlow"] = 1,
                ["ReportGenerateMonsterFlow"] = 1, ["report_ds_match_room_data"] = 1, ["SendSpectatingLog"] = 1,
                ["ReportIDCardProduceFlow"] = 1, ["ReportIDCardPickUpFlow"] = 1, ["ReportIDCardDestroyFlow"] = 1,
                ["ReportRevivalFlow"] = 1, ["ReportGameSetting"] = 1, ["ReportGameSettingNew"] = 1,
                ["ReportAntsVoiceTeamCreate"] = 1, ["ReportAntsVoiceTeamQuit"] = 1, ["report_common_info"] = 1,
                ["report_common_battle_info"] = 1, ["report_client_scan_result"] = 1, ["tss_sdk_report"] = 1,
                ["report_memory_exception"] = 1, ["report_avatar_exception"] = 1, ["report_ui_state"] = 1,
                ["report_hit_reg_fail"] = 1, ["report_character_state"] = 1, ["report_vehicle_exception"] = 1,
                ["report_camera_exception"] = 1, ["ReportPlayerControllerStateChanged"] = 1, ["ReportAvatarFlow"] = 1,
                ["send_ugc_report_uni_mod_expose_req"] = 1,
                ["send_ugc_report_uni_mod_interactive_req"] = 1,
            }

            NetUtil.SendPacket = function(packetName, ...)
                if blockedPackets[packetName] then return end
                return originalSendPacket(packetName, ...)
            end
            NetUtil.IsBypassed = true
        end
    end)
end

function _G.InitializeConnectionGuard()
    pcall(function()
        if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then return end
        print('[ConnectionGuard] Initializing Shield...')

        local GC = _G.GameplayCallbacks
        local originalStateChanged = GC.OnDSPlayerStateChanged

        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            local stateLower = InPlayerState and string.lower(tostring(InPlayerState)) or ""
            local blockedStates = {
                ["cheatdetected"] = true, ["connectionlost"] = true,
                ["connectiontimeout"] = true, ["connectionexception"] = true,
                ["netdrivererror"] = true
            }
            if blockedStates[stateLower] then return end
            if originalStateChanged then
                pcall(originalStateChanged, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            end
        end

        GC.OnPlayerNetConnectionClosed = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnPlayerActorChannelError = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnPlayerRPCValidateFailed = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnPlayerSpectateException = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnShutdownAfterError = function(GameID) end

        _G.ConnectionGuardInitialized = true
        print('[ConnectionGuard] Active & Protecting!')
    end)
end

-- ============================================================================
-- SECTION 19: GAMEPLAY EVENT HANDLERS
-- ============================================================================

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
    local EMovementMode = import("EMovementMode")
    if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming
        and self:CheckBaseIsMoveable() then
        print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
        self.CharacterMovement:SetBase(nil, "", true)
    end
    if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement)
        and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking
        and UIManager.UI_Config_InGame.ParachuteOpenUI then
        print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
        UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
    end
end

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(currentVehicle)
    if not slua.isValid(currentVehicle) then return end
    print(bWriteLog and string.format("BRPlayerCharacterBase:HandleOnAttachedToVehicle", Game:GetObjName(currentVehicle)))
    if self.Role == ENetRole.ROLE_SimulatedProxy then
        self:ClearAttachToVehicleTimer()
        self.nUpdatePlayerAttachToVehicleCount = 0
        self.nUpdatePlayerAttachToVehicleTimer = self:AddGameTimer(5, true, function()
            if slua.isValid(self.Object) and slua.isValid(currentVehicle) then
                self:UpdatePlayerAttachToVehicle(currentVehicle)
            end
        end)
        self.nFixMeshContainerTimer = self:AddGameTimer(3, true, function()
            if slua.isValid(self.Object) and slua.isValid(currentVehicle) then
                self:FixMeshContainerOffsetIfNeeded(currentVehicle)
            end
        end)
    end
end

function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(lastVehicle)
    if not slua.isValid(lastVehicle) then return end
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnDetachedFromVehicle", lastVehicle)
    if self.Role == ENetRole.ROLE_SimulatedProxy then
        self:ClearAttachToVehicleTimer()
        self.nUpdatePlayerAttachToVehicleCount = 0
    end
end

function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle(currentVehicle)
    if not slua.isValid(self.Object) or not slua.isValid(currentVehicle) then return end
    if not (slua.isValid(self.CapsuleComponent) and slua.isValid(self.Mesh)) or not slua.isValid(self.MeshContainer) then return end
    if not slua.isValid(self:GetCurrentVehicle()) then return end
    if Game:IsDriver(self.Object) then return end
    if not self.nUpdatePlayerAttachToVehicleCount then self.nUpdatePlayerAttachToVehicleCount = 0 end

    local ESTEPoseState = import("ESTEPoseState")
    local isStanding = self.PoseState == ESTEPoseState.Stand
    local capsuleRelativeLoc = self.CapsuleComponent:GetRelativeTransform():GetLocation()
    local meshRelativeLoc = self.Mesh:GetRelativeTransform():GetLocation()
    local meshContainerRelativeZ = self.MeshContainer:GetRelativeTransform():GetLocation().Z
    local capsuleRadius = self.CapsuleComponent:GetScaledCapsuleRadius()
    local capsuleHalfHeight = self.CapsuleComponent:GetScaledCapsuleHalfHeight()
    local standHalfHeightNeg = -1 * self.StandHalfHeight
    local standRadius = self.StandRadius
    local standHalfHeight = self.StandHalfHeight
    local zeroVector = FVector(0, 0, 0)
    local standVector = FVector(0, 0, self.StandHalfHeight)
    local tolerance = 1.0

    local capsuleLocCheck = capsuleRelativeLoc:Equals(standVector, tolerance)
    local meshLocCheck = meshRelativeLoc:Equals(zeroVector, tolerance)
    local meshContainerCheck = tolerance > math.abs(meshContainerRelativeZ - standHalfHeightNeg)
    local radiusCheck = tolerance > math.abs(capsuleRadius - standRadius)
    local halfHeightCheck = tolerance > math.abs(capsuleHalfHeight - standHalfHeight)
    local allChecksPassed = isStanding and capsuleLocCheck and meshLocCheck and meshContainerCheck and radiusCheck and halfHeightCheck

    if not allChecksPassed then
        self.nUpdatePlayerAttachToVehicleCount = self.nUpdatePlayerAttachToVehicleCount + 1
    else
        self.nUpdatePlayerAttachToVehicleCount = 0
    end

    if self.nUpdatePlayerAttachToVehicleCount >= 3 and not allChecksPassed then
        local playerController = GameplayData.GetPlayerController()
        if playerController.ReportCrashKitFeature and playerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException then
            local debugInfo = string.format(
                "VehicleShapeType:%s PlayerKey:%s. Check Result:%d %d %d %d %d %d. Capsule.RelativeLoc:%s Capsule.Radius:%s Capsule.HalfHeight:%s Mesh.RelativeLoc:%s MeshContainer.RelativeLocZ:%s",
                tostring(currentVehicle.VehicleShapeType), tostring(self.PlayerKey),
                isStanding and 1 or 0, capsuleLocCheck and 1 or 0, meshLocCheck and 1 or 0,
                meshContainerCheck and 1 or 0, radiusCheck and 1 or 0, halfHeightCheck and 1 or 0,
                capsuleRelativeLoc:ToString(), tostring(capsuleRadius), tostring(capsuleHalfHeight),
                meshRelativeLoc:ToString(), tostring(meshContainerRelativeZ)
            )
            playerController.ReportCrashKitFeature:ReportCharacterAttachedOnVehicleException(debugInfo)
        end
        self.nUpdatePlayerAttachToVehicleCount = 0
    end
end

function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded(currentVehicle)
    if not slua.isValid(self.Object) or not slua.isValid(currentVehicle) then return end
    if not slua.isValid(self.MeshContainer) then return end
    if not slua.isValid(self:GetCurrentVehicle()) then return end
    if Game:IsDriver(self.Object) then return end
    local tolerance = 1.0
    local standHalfHeightNeg = -1 * self.StandHalfHeight
    local meshContainerRelativeZ = self.MeshContainer:GetRelativeTransform():GetLocation().Z
    if tolerance <= math.abs(meshContainerRelativeZ - standHalfHeightNeg) then
        self:SetMeshContainerOffsetZ(standHalfHeightNeg)
    end
end

function BRPlayerCharacterBase:ClearAttachToVehicleTimer()
    if self.nUpdatePlayerAttachToVehicleTimer then
        self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
        self.nUpdatePlayerAttachToVehicleTimer = nil
    end
    if self.nFixMeshContainerTimer then
        self:RemoveGameTimer(self.nFixMeshContainerTimer)
        self.nFixMeshContainerTimer = nil
    end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, attrName, attrVal)
    BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, attrName, attrVal)
    if self.Object ~= uPawn then return end
    if self.Role == ENetRole.ROLE_AutonomousProxy and attrName == "bCanSelfRescue" then
        local playerController = self:GetPlayerControllerSafety()
        if slua.isValid(playerController) then
            playerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
        end
    end
end

function BRPlayerCharacterBase:OnPawnStateChange(pawnState)
    if pawnState == EPawnState.SwitchPP then
        local playerController = self:GetPlayerControllerSafety()
        if slua.isValid(playerController) then
            playerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
        end
    end
end

function BRPlayerCharacterBase:HandleFinishedState()
    if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
        self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
    end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
    if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
        local EGameModeType = import("EGameModeType")
        local matchModeIdsConfig = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")
        local gameModeType = CGameMode.GameModeType
        local gameModeId = tonumber(CGameState.GameModeID)
        local isTypicalMode = gameModeType == EGameModeType.ETypicalGameMode
            or gameModeType == EGameModeType.EFourInOneGameMode
            or gameModeType == EGameModeType.EHeavyWeaponGameMode
        local isNotInConfig = not matchModeIdsConfig[gameModeId]
        return isTypicalMode and isNotInConfig
    end
    return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(lastParachuteState, newParachuteState)
    BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, lastParachuteState, newParachuteState)
    local EParachuteState = import("EParachuteState")
    if not Client then
        local playerController = self:GetPlayerControllerSafety()
        if slua.isValid(playerController) and playerController.CheckParachuteOpenFeature then
            if newParachuteState == EParachuteState.PS_Opening then
                if playerController.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
                    playerController.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
                end
            elseif newParachuteState == EParachuteState.PS_None then
                if playerController.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
                    playerController.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
                end
                if playerController.CheckParachuteOpenFeature.ClearTimerAndState then
                    playerController.CheckParachuteOpenFeature:ClearTimerAndState()
                end
            end
        end
    end
end

function BRPlayerCharacterBase:OnLanded()
    if self.HandleOnLanded then self:HandleOnLanded(-1) end
    if not Client then
        local playerController = self:GetPlayerControllerSafety()
        if slua.isValid(playerController) and playerController.CheckParachuteOpenFeature then
            if playerController.CheckParachuteOpenFeature.ClearTimerAndState then
                playerController.CheckParachuteOpenFeature:ClearTimerAndState()
            end
            if playerController.CheckParachuteOpenFeature.ResetCheckShowUI then
                playerController.CheckParachuteOpenFeature:ResetCheckShowUI()
            end
        end
    end
end

function BRPlayerCharacterBase:IsWarGameMode()
    local gameState = GameplayData:GetGameState()
    local STExtraGameStateBase = import("STExtraGameStateBase")
    if slua.isValid(gameState) and Game:IsClassOf(gameState, STExtraGameStateBase) then
        local EGameModeType = import("EGameModeType")
        return gameState.GameModeType == EGameModeType.EWarGameMode
    else
        return false
    end
end

function BRPlayerCharacterBase:BPOnRecycled()
    if Client then self:ResetMeshRelativeLocationAndRotation() end
end

function BRPlayerCharacterBase:BPOnRespawned()
    if Client then self:ResetMeshRelativeLocationAndRotation() end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        GameplayData.RemoveCharacter(self.Object)
    end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        GameplayData.AddCharacter(self.Object)
    end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
    if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
        local targetRotation = FRotator(0, -90, 0)
        local targetLocation = FVector(0, 0, 0)
        if self.Mesh.K2_SetRelativeRotation then
            self.Mesh:K2_SetRelativeRotation(targetRotation, false, nil, false)
        end
        self:CacheInitialMeshOffset(targetLocation, targetRotation)
    end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
    local KismetSystemLibrary = import("KismetSystemLibrary")
    local isDedicatedServer = KismetSystemLibrary.IsDedicatedServer(self)
    if not isDedicatedServer then return end
    local playerController = self:GetPlayerControllerSafety()
    if not slua.isValid(playerController) then return end
    local avatarComponent = self.CharacterAvatarComp2_BP
    if not slua.isValid(avatarComponent) then return end
    local commerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
    local vehicleSkinId = commerAvatarDataUtil:ChangeVehicleSkinByClothes(playerController, avatarComponent)
    local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
    if vehicleSkinId then
        local AvatarUtils = import("AvatarUtils")
        if AvatarUtils.GetVehicleShapeBySkinID(vehicleSkinId) == ESTExtraVehicleShapeType.VST_Horse then
            local playerState = self:GetPlayerStateSafety()
            if slua.isValid(playerState) then
                playerState:AddGeneralCount(468, 1, false)
            end
        end
    end
end

function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(type, param)
    EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, type, param)
end

function BRPlayerCharacterBase:ParachuteJump()
    local playerController = self:GetControllerSafety()
    if slua.isValid(playerController) then
        if not self:GetEnsure() then
            local EStateType = import("EStateType")
            if playerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump
                and playerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
                local ESTEPoseState = import("ESTEPoseState")
                self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
                playerController:ReInitParachuteItem()
                playerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
            end
        else
            EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
        end
    end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(playerCharacter, newMovementBase, oldMovementBase)
    if playerCharacter ~= self.Object then return end
    local medievalCrane = self:GetMedievalCraneFromBase(newMovementBase)
    if medievalCrane and medievalCrane.AddCharacter then
        medievalCrane:AddCharacter(self.Object)
    else
        medievalCrane = self:GetMedievalCraneFromBase(oldMovementBase)
        if medievalCrane and medievalCrane.RemoveCharacter then
            medievalCrane:RemoveCharacter(self.Object)
        end
    end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(base)
    if not slua.isValid(base) or not base.GetOwner then return end
    local owner = base:GetOwner()
    if not slua.isValid(owner) then return end
    if not owner.AddCharacter then return end
    return owner
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
    local playerState = self:GetPlayerStateSafety()
    if not slua.isValid(playerState) then return false end
    if playerState.CanUseFlaregun == false and self:IsLocallyControlled() then
        local playerController = self:GetPlayerControllerSafety()
        if slua.isValid(playerController) then
            playerController:DisplayGameTipWithMsgID(48532)
        end
    end
    return not playerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
    self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
    local nearDeathComponent = self.NearDeatchComponent
    if self:IsNearDeath() and slua.isValid(nearDeathComponent) and self.bCanNearDeathGiveup == true then
        local playerState = self:GetPlayerStateSafety()
        if slua.isValid(playerState) then playerState:AddGeneralCount(1613, 1, false) end
        nearDeathComponent:TriggerGotoDieExplictly(self.Object)
    end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
    local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
    if STExtraBlueprintFunctionLibrary.IsDevelopment() then
        self:MulticastRPC_GmPlayAction(actionId)
    end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
    if not Client then return end
    local playEmoteComponent = self:GetPlayEmoteComponent()
    if not slua.isValid(playEmoteComponent) then return end
    local logFilter = require("common.log_filter")
    logFilter.SetLogTreeEnable(true)
    local emoteData = CDataTable.GetTableData("EmoteBPTable", actionId)
    if not emoteData then return end
    local emotePath = emoteData.Path
    local emoteClass = slua.loadObject(emotePath)
    local softObjectPaths = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
    local emoteInstance = emoteClass()
    playEmoteComponent:OnLoadEmoteAssetBegin(emoteInstance, actionId, softObjectPaths, "")
    local pathTable = FuncUtil.LuaArrayToTable(softObjectPaths)
    local assetUtil = require("common.asset_util")
    local onComplete = function() playEmoteComponent:OnLoadEmoteAssetEnd(emoteInstance, actionId, 0) end
    assetUtil.GetAssetsArrayAsyncParallel(pathTable, onComplete)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
    if slua.isValid(self.ParachuteComponent) then
        self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
    end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
    self.Super:OnPlayerEnterCarryBoxState()
    if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState() end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt) end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
    if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox"))
        and self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
    end
end

function BRPlayerCharacterBase:SetAreaID(areaId)
    self:SetAttrValue("AreaID", areaId, -1)
end

function BRPlayerCharacterBase:GetAreaID()
    return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
    return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
    if self:HasState(EPawnState.SpecialSuit) then
        self:TriggerEntrySkillWithID(4301101, true)
    end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
    self.Super:SwitchCameraToParachuteOpening()
    if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera
        and self.ParachuteFormation:ShouldApplyFormationCamera() then
        self.ParachuteFormation:OverlayFormationCameraParams()
    end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
    self.Super:SwitchCameraToParachuteFalling()
    if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera
        and self.ParachuteFormation:ShouldApplyFormationCamera() then
        self.ParachuteFormation:OverlayFormationCameraParams()
    end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
    self.Super:SwitchCameraToNormal()
    if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
        self.ParachuteFormation:OnLandingClearFormationCamera()
    end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(slot, ignoreState)
    if self:HasState(EPawnState.AttachToOther) then
        local weapon = self:GetWeaponBySlot(slot)
        if slua.isValid(weapon) then
            local weaponId = weapon:GetWeaponID()
            local attachConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
            if attachConfig and attachConfig.CheckIsWeaponInBlackList and attachConfig.CheckIsWeaponInBlackList(weaponId) then
                local playerController = self:GetPlayerControllerSafety()
                if Client and slua.isValid(playerController) and playerController.Role == ENetRole.ROLE_AutonomousProxy then
                    playerController:DisplayGameTipWithMsgID(47306)
                end
                return false
            end
        end
    end
    return self.Super:SwitchWeaponCheck(slot, ignoreState)
end

-- ============================================================================
-- SECTION 20: INITIALIZATION & HOOKING
-- ============================================================================

--- Master initialization function - hooks all systems into the game
local function initializeAllSystems()
    pcall(function()
        -- Initialize security bypass systems
        if _G.InitializeAntiReport then _G.InitializeAntiReport() end
        if _G.InitializeAntiCheatHooks then _G.InitializeAntiCheatHooks() end
        if _G.InitializeGameplayBypass then _G.InitializeGameplayBypass() end
        if _G.InitializeConnectionGuard then _G.InitializeConnectionGuard() end
        if _G.DisableHiggsBoson then _G.DisableHiggsBoson() end
        if _G.InitializeLogBlocker then _G.InitializeLogBlocker() end
        if _G.InitializeScannerBlocker then _G.InitializeScannerBlocker() end
        if _G.InitializeReplayTelemetryBlocker then _G.InitializeReplayTelemetryBlocker() end
        if _G.InitializeSkinModSystem then _G.InitializeSkinModSystem() end
        if _G.InitializeSkinBypass then _G.InitializeSkinBypass() end
    end)

    -- Start the skin sync loop
    pcall(function() startSkinSyncLoop() end)

    -- Hook StartAdvancedSystems into the local player character
    local gameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"]
        or require("GameLua.GameCore.Data.GameplayData")
    if not gameplayData then return end

    pcall(function()
        local playerCharacter = gameplayData.GetPlayerCharacter and gameplayData.GetPlayerCharacter()
        if slua.isValid(playerCharacter) then
            if BRPlayerCharacterBase.StartAdvancedSystems then
                playerCharacter.StartAdvancedSystems = BRPlayerCharacterBase.StartAdvancedSystems
            end

            if playerCharacter.bHasShownDevNotice == nil then
                playerCharacter.bHasShownDevNotice = false
                playerCharacter.bHasShownExpiredNotice = false
                playerCharacter.bIsDeadFlag = false
                playerCharacter.bForceWeaponMod = true
                playerCharacter.AK_NativeESP_Ready = false
            end

            if type(playerCharacter.StartAdvancedSystems) == "function" then
                pcall(function()
                    playerCharacter:StartAdvancedSystems()
                end)
            end
        end
    end)
end

-- Schedule initialization after a 0.5-second delay
pcall(function()
    require("common.time_ticker").AddTimerOnce(0.5, initializeAllSystems)
end)

-- ============================================================================
-- SECTION 21: CLASS REGISTRATION
-- ============================================================================

local class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local BRCharacterClass = class(CharacterBase, nil, BRPlayerCharacterBase)

return require("combine_class").DeclareFeature(BRCharacterClass, {
    { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
    { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" }
}, "BRPlayerCharacterBase")