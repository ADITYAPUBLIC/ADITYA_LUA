

local NetworkRPC = {
    ServerRPC = {},
    ClientRPC = {},
    MulticastRPC = {}
}

NetworkRPC.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
NetworkRPC.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
NetworkRPC.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
NetworkRPC.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
NetworkRPC.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }
NetworkRPC.ClientRPC.ClientRPC_TriggerHighlightMoment = { Reliable = true, Params = { UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32 } }

local ENetRole = import("ENetRole")
local EPawnStateRef = import("EPawnState")
local GameplayDataRef3 = require("GameLua.GameCore.Data.GameplayData")
local GamePlayToolsRef = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local KismetMathLibraryRef = import("KismetMathLibrary")
local GameplayStaticsRef = import("GameplayStatics")
local InGameMarkToolsRef = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")

local timestampRef = os.time(os.date("!*t"))
local timestamp = os.time({ year = 2028, month = 5, day = 15, hour = 6, min = 45, sec = 0 })





if timestampRef <= timestamp then
    local logic_setting_graphics_1 = package.loaded["client.slua.logic.setting.logic_setting_graphics"] or require("client.slua.logic.setting.logic_setting_graphics")
    local GSC_FPS_1 = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS"] or require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    local GSC_FPSFT_1 = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT"] or require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    local GraphicSettingDBRef = package.loaded["client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"] or require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")

    if logic_setting_graphics_1 then
        local setFPS = logic_setting_graphics_1.SetFPS
        function logic_setting_graphics_1.SetFPS(gameInstance, FPSLevel)
            if FPSLevel == 8 and GraphicSettingDBRef then
                local uIDataRef = GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.FPSFineTuneSwitch)
                if not uIDataRef then 
                    GraphicSettingDBRef:UpdateUIData(GraphicSettingDBRef.FPSFineTuneSwitch, true) 
                end
            end
            if setFPS then 
                setFPS(gameInstance, FPSLevel) 
            end
            if FPSLevel == 8 and GraphicSettingDBRef then
                GraphicSettingDBRef:UpdateUIData(GraphicSettingDBRef.FPSFineTuneNum, 165)
                gameInstance:ExecuteCMD("t.MaxFPS", "165")
                gameInstance:ExecuteCMD("r.FrameRateLimit", "165")
            end
        end
    end

    if GSC_FPS_1 and GSC_FPS_1.__inner_impl then
        local inner_impl_1 = GSC_FPS_1.__inner_impl
        function inner_impl_1:GetMaxFPSLevel() return 8, 8 end
        function inner_impl_1:CanChangeQualityAndFPSPreCheck() return true end
        function inner_impl_1:InitRealSupportFPS()
            local configTable1 = {}
            for i = 1, 8 do configTable1[i] = {true, true} end
            if GraphicSettingDBRef then GraphicSettingDBRef:UpdateUIData(GraphicSettingDBRef.RealSupportFPS, configTable1, false) end
            return configTable1
        end
        function inner_impl_1:SetFPSAndQualityEnable(bEnable)
            if self.UIRoot and self.UIRoot.Image_Mask then self:SetWidgetVisible(self.UIRoot.Image_Mask, false) end
        end
        function inner_impl_1:UpdateSelectedFPSState(selectedLevel)
            local configTable3 = { [2]="NodeFps20", [3]="NodeFps25", [4]="NodeFps30", [5]="NodeFps40", [6]="NodeFps60", [7]="NodeFps90", [8]="NodeFps120" }
            if not self.UIRoot then return end
            for level, name in pairs(configTable3) do
                if self.UIRoot[name] then
                    self:WidgetSelfHit(self.UIRoot[name])
                    self.UIRoot[name]:SetIsEnabled(true)
                    local uiDataProgress = self.UIRoot["WidgetSwitcher_" .. level]
                    if uiDataProgress then uiDataProgress:SetActiveWidgetIndex(level == selectedLevel and 0 or 1) end
                end
            end
        end
        local updateUI = inner_impl_1.UpdateUI
        function inner_impl_1:UpdateUI()
            if updateUI then pcall(updateUI, self) end
            self:SelfHitTestInvisible()
            self:InitRealSupportFPS()
            self:SetFPSAndQualityEnable(true)
            local defaultFps = 8
            if GraphicSettingDBRef then
                if GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.CustomTab) == 2 then
                    defaultFps = GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.LobbyFPS) or 8
                else
                    defaultFps = GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.SelectedFPS) or 8
                end
            end
            self:UpdateSelectedFPSState(defaultFps)
        end
        function inner_impl_1:DoClickFPS(FPSLevel)
            if slua.isValid(self.UIRoot) then
                if GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.CustomTab) == 2 then
                    GraphicSettingDBRef:UpdateUIData(GraphicSettingDBRef.LobbyFPS, FPSLevel)
                else
                    GraphicSettingDBRef:UpdateSelectedFPS(FPSLevel)
                end
                self:UpdateSelectedFPSState(FPSLevel)
                if self:GetParentUI() then 
                    self:GetParentUI():SaveQualityAndFPS()
                    self:GetParentUI():SetDirty(true) 
                end
            end
        end
    end

    if GSC_FPSFT_1 and GSC_FPSFT_1.__inner_impl then
        local inner_impl = GSC_FPSFT_1.__inner_impl
        local contextData17, fpsTuneStep = 90, 5
        local function localMethod6(val, min, max) return val < min and min or (val > max and max or val) end
        function inner_impl:ShowOrHide() 
            self:SelfHitTestInvisible() 
            if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end 
        end
        function inner_impl:InitFPSFTSwitch()
            local sw = GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.FPSFineTuneSwitch)
            if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(sw, true) end
            if self.UIRoot.canvasPanelComp8 then self:SetWidgetVisible(self.UIRoot.canvasPanelComp8, sw) end
            if self.UIRoot.widgetSwitcherComp0 then self.UIRoot.widgetSwitcherComp0:SetActiveWidgetIndex(2) end
            if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
        end
        function inner_impl:InitFPSFTValue165()
            local uIRoot = self.UIRoot
            local sw = GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.FPSFineTuneSwitch)
            local uIData = sw and GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.FPSFineTuneNum) or 165
            uIRoot.Slider_screen3:SetLocked(not sw)
            uIRoot.ProgressBar_screen3:SetFillColorAndOpacity(sw and FLinearColor(1,1,1,1) or FLinearColor(1,0.625,0.6,1))
            local sliderProgress = (uIData - contextData17) / (165 - contextData17)
            uIRoot.Veihclescreen3:SetText(LocUtil.LocalizeResFormat(10567, uIData))
            uIRoot.Slider_screen3:SetValue(sliderProgress)
            uIRoot.ProgressBar_screen3:SetPercent(sliderProgress)
        end
        function inner_impl:OnFPSFTValueChange3(uIData)
            GraphicSettingDBRef:UpdateUIData(GraphicSettingDBRef.FPSFineTuneNum, uIData)
            self:InitFPSFTValue165()
            if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
            local gameInst = GraphicSettingDBRef.GetGameInstance and GraphicSettingDBRef.GetGameInstance()
            if gameInst then 
                gameInst:ExecuteCMD("t.MaxFPS", tostring(uIData))
                gameInst:ExecuteCMD("r.FrameRateLimit", tostring(uIData)) 
            end
        end
        function inner_impl:OnFPSFTSliderValueChange3(configIntValue)
            if GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.FPSFineTuneSwitch) then
                local uIData = KismetMathLibraryRef.FCeil(configIntValue * (165 - contextData17) / fpsTuneStep) * fpsTuneStep + contextData17
                self:OnFPSFTValueChange3(localMethod6(uIData, contextData17, 165))
            end
        end
        function inner_impl:OnFPSFTAdd3()
            local uIData = GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.FPSFineTuneNum)
            if uIData then self:OnFPSFTValueChange3(math.min(165, uIData + fpsTuneStep)) end
        end
        function inner_impl:OnFPSFTMinus3()
            local uIData = GraphicSettingDBRef:GetUIData(GraphicSettingDBRef.FPSFineTuneNum)
            if uIData then self:OnFPSFTValueChange3(math.max(contextData17, uIData - fpsTuneStep)) end
        end
        inner_impl.OnFPSFTAdd = inner_impl.OnFPSFTAdd3 
        inner_impl.OnFPSFTMinus = inner_impl.OnFPSFTMinus3
        inner_impl.OnFPSFTSliderValueChange = inner_impl.OnFPSFTSliderValueChange3
    end
end




_G.ConfigFilePath = '/storage/emulated/0/Android/data/com.vng.pubgmobile/files/ADITYA_MENU.ini'

_G.BaseSkinIDs = {
    Weapons = { 101004, 101001, 101003, 103001, 102002, 103002, 103003, 101008, 102003, 105010, 102004, 105002, 105001, 101006, 104004 },
    Outfits = { Suit = 403003, Bag = 501001, Helmet = 502001, Parachut = 703001, Pet = 50000 }
}
_G.OutfitSkins = { 
    Suit = {_G.BaseSkinIDs.Outfits.Suit}, 
    Bag = {_G.BaseSkinIDs.Outfits.Bag}, 
    Helmet = {_G.BaseSkinIDs.Outfits.Helmet}, 
    Parachut = {_G.BaseSkinIDs.Outfits.Parachut}, 
    Pet = {_G.BaseSkinIDs.Outfits.Pet} 
}

_G.skinIdMappings = {}
for _, id in ipairs(_G.BaseSkinIDs.Weapons) do 
    _G.skinIdMappings[id] = {id} 
end


_G.VehicleMapDict = {
    UAZ = 1908001,
    Dacia = 1903001,
    Buggy = 1907001,
    Motor = 1901001,
    CoupeRB = 1961001
}

_G.VehicleSkinsList = {}
_G.VehicleSkinIndex = {}

_G.CustSlotType = { ClothesEquipemtSlot=5, BackpackEquipemtSlot=8, HelmetEquipemtSlot=9, ParachuteEquipemtSlot=11, GlideEquipemtSlot=15 }
_G.WeaponSkinIndex = _G.WeaponSkinIndex or {}
_G.SuitSkin, _G.BagSkin, _G.HelmetSkin, _G.ParachuteSkin, _G.GliderSkin, _G.PetSkin = 0, 0, 0, 0, 0, 0
_G.LastBackApplyValue, _G.LastHelmetApplyValue = 0, 0
_G.skinIdCache, _G.skinIdCache2 = {}, {}
local configTable3 = {}

local function localMethod1(id)
    local puffer_manager_1 = require('client.slua.logic.download.puffer.puffer_manager')
    local puffer_const_1 = require('client.slua.logic.download.puffer_const')
    if puffer_manager_1 and puffer_const_1 and puffer_manager_1.GetState(puffer_const_1.ENUM_DownloadType.ODPAK, {id}) ~= puffer_const_1.ENUM_DownloadState.Done then
        puffer_manager_1.Download(puffer_const_1.ENUM_DownloadType.ODPAK, {id})
    end
end
_G.download_item = localMethod1

_G.get_skin_id = function(weaponID)
    if not weaponID then return nil end
    local weaponSkinIndex = (_G.WeaponSkinIndex[weaponID]) or 1
    local skinIdMappingsRef = _G.skinIdMappings[weaponID]
    if not skinIdMappingsRef or not skinIdMappingsRef[weaponSkinIndex] then return weaponID end
    
    local skinIdMappings_1Item = skinIdMappingsRef[weaponSkinIndex]
    if not _G.skinIdCache2[skinIdMappings_1Item] then 
        pcall(_G.download_item, skinIdMappings_1Item)
        _G.skinIdCache2[skinIdMappings_1Item] = true 
    end
    return skinIdMappings_1Item
end

_G.get_vehicle_skin_id = function(vehicleID)
    if not vehicleID or vehicleID == 0 then return vehicleID end
    
    local vehicleIdStr = tostring(vehicleID)
    local localVal_8_sub = string.sub(vehicleIdStr, 1, 4)
    local numVal = tonumber(localVal_8_sub .. "001")
    
    local vehicleSkinsList = _G.VehicleSkinsList[numVal]
    if vehicleSkinsList then
        local vehicleSkinIndex = _G.VehicleSkinIndex[numVal] or 1
        if vehicleSkinIndex < 1 then vehicleSkinIndex = 1 end
        if vehicleSkinIndex > #vehicleSkinsList then vehicleSkinIndex = #vehicleSkinsList end
        
        local vehicleSkinsListItem = vehicleSkinsList[vehicleSkinIndex]
        if vehicleSkinsListItem and vehicleSkinsListItem > 0 then
            if not _G.skinIdCache2[vehicleSkinsListItem] then 
                if _G.download_item then pcall(_G.download_item, vehicleSkinsListItem) end
                _G.skinIdCache2[vehicleSkinsListItem] = true 
            end
            return vehicleSkinsListItem
        end
    end
    return vehicleID
end

_G.LoadSkinDataFromINI = function()
    local configFilePath = io.open(_G.ConfigFilePath, 'r')
    if not configFilePath then return end
    
    local bIsDisabled4 = false
    for line in configFilePath:lines() do
        if line:match('%[SKIN_LIST%]') then 
            bIsDisabled4 = true 
        elseif line:match('%[SELECTED%]') then 
            bIsDisabled4 = false 
        end
        
        if bIsDisabled4 and not line:match('^%s*%[') and not line:match('^%s*[#]') then
            local configKey, configValue = line:match('([^=]+)=(.+)')
            if configKey and configValue then
                configKey = configKey:match("^%s*(.-)%s*$")
                local configTable4 = {}
                for val in configValue:gmatch('([^,]+)') do
                    local numericVal1 = tonumber(val:match("^%s*(.-)%s*$"))
                    if numericVal1 then table.insert(configTable4, numericVal1) end
                end
                
                if #configTable4 > 0 then
                    if _G.OutfitSkins[configKey] ~= nil then 
                        _G.OutfitSkins[configKey] = configTable4
                    elseif _G.VehicleMapDict[configKey] ~= nil then 
                        local vehicleMapDict = _G.VehicleMapDict[configKey]
                        _G.VehicleSkinsList[vehicleMapDict] = configTable4
                    elseif tonumber(configKey) then 
                        _G.skinIdMappings[tonumber(configKey)] = configTable4 
                    end
                end
            end
        end
    end
    configFilePath:close()
    
    _G.SuitSkinsMap = _G.OutfitSkins.Suit
    _G.BagSkinsMap = _G.OutfitSkins.Bag
    _G.HelmetSkinsMap = _G.OutfitSkins.Helmet
    _G.ParachutSkinsMap = _G.OutfitSkins.Parachut
    _G.PetSkinsMap = _G.OutfitSkins.Pet
end
pcall(_G.LoadSkinDataFromINI)

_G.ReadConfigFile = function()
    local configFilePath = io.open(_G.ConfigFilePath, 'r')
    if not configFilePath then return end
    
    local configTable5 = {}
    for line in configFilePath:lines() do
        if line:match('%[SKIN_LIST%]') then break end 
        if not line:match('^%s*%[') and not line:match('^%s*[#]') then
            local configKey, configIntValue = line:match('([%w_]+)%s*=%s*(%d+)')
            if configKey and configIntValue and not line:match(',') then 
                configTable5[configKey] = tonumber(configIntValue) 
            end
        end
    end
    configFilePath:close()
    
    local function localMethod12(configKey, map, globalVarName)
        if configTable5[configKey] and configTable5[configKey] ~= configTable3[configKey] then 
            _G[globalVarName] = map and map[configTable5[configKey] + 1] or 0
            configTable3[configKey] = configTable5[configKey] 
        end
    end
    
    localMethod12('Suit', _G.SuitSkinsMap, 'SuitSkin')
    localMethod12('Bag', _G.BagSkinsMap, 'BagSkin')
    localMethod12('Helmet', _G.HelmetSkinsMap, 'HelmetSkin')
    localMethod12('Parachute', _G.ParachutSkinsMap, 'ParachuteSkin')
    localMethod12('Pet', _G.PetSkinsMap, 'PetSkin')
    
    local function localMethod10(configKey, id)
        if configTable5[configKey] and configTable5[configKey] ~= configTable3[configKey] then 
            _G.WeaponSkinIndex[id] = configTable5[configKey] + 1
            configTable3[configKey] = configTable5[configKey] 
        end
    end
    
    localMethod10('M416', 101004)
    localMethod10('AKM', 101001)
    localMethod10('UMP', 102002)
    localMethod10('SCAR', 101003)
    localMethod10('M762', 101008)
    localMethod10('AUG', 101006)
    localMethod10('Vector', 102003)
    localMethod10('UZI', 102004)
    localMethod10('Kar98k', 103001)
    localMethod10('M24', 103002)
    localMethod10('AWM', 103003)
    localMethod10('DP28', 105002)
    localMethod10('M249', 105001)
    localMethod10('MG3', 105010)
    localMethod10('Shotgun', 104004)

    local function localMethod11(configKey)
        local vehicleMapDict = _G.VehicleMapDict[configKey]
        if vehicleMapDict and configTable5[configKey] and configTable5[configKey] ~= configTable3[configKey] then 
            _G.VehicleSkinIndex[vehicleMapDict] = configTable5[configKey] + 1
            configTable3[configKey] = configTable5[configKey] 
        end
    end
    
    localMethod11('UAZ')
    localMethod11('Dacia')
    localMethod11('Buggy')
    localMethod11('Motor')
    localMethod11('CoupeRB')
end

_G.BaseAttachToIndex = {
    [201010]=1, [201005]=1, [201004]=1, 
    [201009]=2, [201003]=2, [201002]=2, 
    [201011]=3, [201007]=3, [201006]=3, 
    [204012]=4, [204005]=4, [204008]=4, 
    [204011]=5, [204004]=5, [204007]=5, 
    [204013]=6, [204006]=6, [204009]=6, 
    [203001]=7, [203002]=8, [203003]=9, [203014]=10, [203004]=11, [203015]=12, [203005]=13, 
    [202002]=14, [202001]=15, [202004]=16, [202005]=17, [202007]=18, [202006]=19, 
    [205002]=20, [205003]=20, [205001]=20, 
    [203018]=21, [204014]=22 
}

_G.VIP_Attachments = {}
_G.VipAttachToIndex = {} 

_G.LoadAttachmentsFromINI = function()
    local configFilePath = io.open(_G.ConfigFilePath, 'r')
    if not configFilePath then return end
    
    _G.VIP_Attachments = {}
    _G.VipAttachToIndex = {}
    
    local bIsDisabled2 = false
    for line in configFilePath:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line == '[ATTACHMENTS]' then 
            bIsDisabled2 = true 
        elseif line:match('^%[') then 
            bIsDisabled2 = false 
        end
        
        if bIsDisabled2 and not line:match('^%[') and line ~= '' and not line:match('^#') then
            local contextData31, configValue = line:match('^(%d+)=(.+)$')
            if contextData31 and configValue then
                local skinIdMappings_1Item = tonumber(contextData31)
                local dictData = {}
                local weaponSkinIndex = 1
                for val in configValue:gmatch('([^,]+)') do
                    local uIData = tonumber(val) or 0
                    table.insert(dictData, uIData)
                    if uIData > 0 then _G.VipAttachToIndex[uIData] = weaponSkinIndex end
                    weaponSkinIndex = weaponSkinIndex + 1
                end
                _G.VIP_Attachments[skinIdMappings_1Item] = dictData
            end
        end
    end
    configFilePath:close()
end
pcall(_G.LoadAttachmentsFromINI)

_G.equip_character_avatar = function(playerCharacterSafety)
    if not playerCharacterSafety or not slua.isValid(playerCharacterSafety) or not playerCharacterSafety.AvatarComponent2 then return end
    local BackpackUtilsRef = import("BackpackUtils")
    local slotSyncData = playerCharacterSafety.AvatarComponent2.NetAvatarData and playerCharacterSafety.AvatarComponent2.NetAvatarData.SlotSyncData
    if not slotSyncData or not slua.isValid(slotSyncData) or not BackpackUtilsRef then return end
    
    local function localMethod7(ApplyDataIdx, itemId, ApplyEquipSlot, isLevelDependent, levelFunc, globalCacheVal)
        if itemId == 0 then return end
        local slotData = slotSyncData:Get(ApplyDataIdx)
        if slotData and slotData.SlotID == ApplyEquipSlot then
            local itemIdRef = itemId
            if isLevelDependent then
                local levelVal = levelFunc(slotData.AdditionalItemID) or 1
                itemIdRef = itemId + (levelVal - 1) * 1000
                if itemIdRef == slotData.ItemId and _G[globalCacheVal] == itemId then return end
                _G[globalCacheVal] = itemId
            elseif slotData.ItemId == itemId then 
                return 
            end

            if not _G.skinIdCache[itemIdRef] then 
                _G.download_item(itemIdRef)
                _G.skinIdCache[itemIdRef] = true 
            end
            
            slotData.ItemId = itemIdRef
            slotSyncData:Set(ApplyDataIdx, slotData)
            playerCharacterSafety.AvatarComponent2:OnRep_BodySlotStateChanged()
        end
    end

    local bIsDisabled1 = false
    for i = 0, slotSyncData:Num() - 1 do
        local slotData = slotSyncData:Get(i)
        if slotData and slotData.SlotID == _G.CustSlotType.GlideEquipemtSlot then 
            bIsDisabled1 = true
            break 
        end
    end
    if not bIsDisabled1 then 
        slotSyncData:Add({ SlotID = _G.CustSlotType.GlideEquipemtSlot, ItemId = 0 }) 
    end

    for i = 0, slotSyncData:Num() - 1 do
        localMethod7(i, _G.SuitSkin, _G.CustSlotType.ClothesEquipemtSlot, false)
        localMethod7(i, _G.BagSkin, _G.CustSlotType.BackpackEquipemtSlot, true, BackpackUtilsRef.GetEquipmentBagLevel, 'LastBackApplyValue')
        localMethod7(i, _G.HelmetSkin, _G.CustSlotType.HelmetEquipemtSlot, true, BackpackUtilsRef.GetEquipmentHelmetLevel, 'LastHelmetApplyValue')
        localMethod7(i, _G.GliderSkin, _G.CustSlotType.GlideEquipemtSlot, false)
        localMethod7(i, _G.ParachuteSkin, _G.CustSlotType.ParachuteEquipemtSlot, false)
    end
end

_G.ApplyWeaponSkins = function(GameplayDataRef)
    pcall(function()
        local weaponManager = GameplayDataRef:GetWeaponManager()
        if not slua.isValid(weaponManager) then return end
        
        for slot = 1, 3 do
            local inventoryWeaponByPropSlot = weaponManager:GetInventoryWeaponByPropSlot(slot)
            if slua.isValid(inventoryWeaponByPropSlot) and slua.isValid(inventoryWeaponByPropSlot.synData) then
                local weaponIDRef2 = inventoryWeaponByPropSlot:GetWeaponID()
                local get_skin_id_2 = _G.get_skin_id(weaponIDRef2) or weaponIDRef2
                local bIsDisabled6 = false
                
                local synData7 = inventoryWeaponByPropSlot.synData:Get(7) 
                if synData7 and synData7.defineID and synData7.defineID.TypeSpecificID ~= get_skin_id_2 then
                    synData7.defineID.TypeSpecificID = get_skin_id_2
                    inventoryWeaponByPropSlot.synData:Set(7, synData7)
                    if inventoryWeaponByPropSlot.SetWeaponAvatarID then pcall(function() inventoryWeaponByPropSlot:SetWeaponAvatarID(get_skin_id_2) end) end
                    if not _G.skinIdCache[get_skin_id_2] then 
                        _G.download_item(get_skin_id_2)
                        _G.skinIdCache[get_skin_id_2] = true 
                    end
                    bIsDisabled6 = true
                end
                
                if get_skin_id_2 >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[get_skin_id_2] then
                    for AttachIdx = 0, 5 do 
                        local attachData = inventoryWeaponByPropSlot.synData:Get(AttachIdx)
                        if attachData then
                            local attachDefineID = slua.IndexReference(attachData, "defineID")
                            if attachDefineID then
                                local typeSpecificID = attachDefineID.TypeSpecificID
                                if typeSpecificID and typeSpecificID > 0 then
                                    local weaponSkinIndex = _G.BaseAttachToIndex[typeSpecificID] or _G.VipAttachToIndex[typeSpecificID]
                                    if weaponSkinIndex and _G.VIP_Attachments[get_skin_id_2][weaponSkinIndex] and _G.VIP_Attachments[get_skin_id_2][weaponSkinIndex] > 0 then
                                        local vIP_Attachments = _G.VIP_Attachments[get_skin_id_2][weaponSkinIndex]
                                        if vIP_Attachments ~= typeSpecificID then
                                            attachData.defineID.TypeSpecificID = vIP_Attachments
                                            inventoryWeaponByPropSlot.synData:Set(AttachIdx, attachData)
                                            if not _G.skinIdCache2[vIP_Attachments] then 
                                                if _G.download_item then pcall(_G.download_item, vIP_Attachments) end
                                                _G.skinIdCache2[vIP_Attachments] = true 
                                            end
                                            bIsDisabled6 = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                if bIsDisabled6 then
                    if inventoryWeaponByPropSlot.DelayHandleAvatarMeshChanged then pcall(function() inventoryWeaponByPropSlot:DelayHandleAvatarMeshChanged() end) end
                    if inventoryWeaponByPropSlot.OnRep_synData then pcall(function() inventoryWeaponByPropSlot:OnRep_synData() end) end
                end
            end
        end
    end)
end




_G.ApplyVehicleSkins = function(GameplayDataRef)
    pcall(function()
        local currentVehicleRef = GameplayDataRef:GetCurrentVehicle()
        if not slua.isValid(currentVehicleRef) then 
            _G.LastVehicleEntity = nil
            return 
        end
        
        
        if not Game:IsDriver(GameplayDataRef.Object) then return end

        local avatarComponent = currentVehicleRef.VehicleAvatarComponent_BP or currentVehicleRef:GetAvatarComponent()
        if not slua.isValid(avatarComponent) then return end

        
        local zeroData1 = 0
        if currentVehicleRef.AvatarDefaultCfg then
            zeroData1 = currentVehicleRef.AvatarDefaultCfg.TypeSpecificID
        end
        if zeroData1 == 0 and avatarComponent.VehicleNetAvatarData and avatarComponent.VehicleNetAvatarData.ItemDefineID then
            zeroData1 = avatarComponent.VehicleNetAvatarData.ItemDefineID.TypeSpecificID
        end
        if zeroData1 == 0 then return end

        local get_vehicle_skin_id_1 = _G.get_vehicle_skin_id(zeroData1)
        local curItemAvatarID = avatarComponent:GetCurItemAvatarID()

        
        if get_vehicle_skin_id_1 and get_vehicle_skin_id_1 ~= 0 and curItemAvatarID ~= get_vehicle_skin_id_1 then
            if not _G.skinIdCache[get_vehicle_skin_id_1] then 
                if _G.download_item then pcall(_G.download_item, get_vehicle_skin_id_1) end
                _G.skinIdCache[get_vehicle_skin_id_1] = true 
            end

            
            if avatarComponent.VehicleNetAvatarData and avatarComponent.VehicleNetAvatarData.ItemDefineID then
                avatarComponent.VehicleNetAvatarData.ItemDefineID.TypeSpecificID = get_vehicle_skin_id_1
                avatarComponent.VehicleNetAvatarData.SkinOwnerUID = GameplayDataRef.PlayerUID
            end
            
            
            if _G.LastVehicleEntity ~= currentVehicleRef or _G.CurrentEquipVehicleID ~= get_vehicle_skin_id_1 then
                _G.LastVehicleEntity = currentVehicleRef
                _G.CurrentEquipVehicleID = get_vehicle_skin_id_1

                pcall(function()
                    
                    avatarComponent.lastEquipedAvatarId = curItemAvatarID
                    
                    
                    if avatarComponent.ShowVehicleSwitchEffect then 
                        avatarComponent:ShowVehicleSwitchEffect() 
                    end
                    
                    
                    avatarComponent.ClientUsedAvatarID = get_vehicle_skin_id_1
                    currentVehicleRef.ClientUsedAvatarID = get_vehicle_skin_id_1
                    if avatarComponent.ChangeItemAvatar then 
                        avatarComponent:ChangeItemAvatar(get_vehicle_skin_id_1, false) 
                    end
                end)
            else
                
                if avatarComponent.ChangeItemAvatar then avatarComponent:ChangeItemAvatar(get_vehicle_skin_id_1, false) end
            end

            
            if avatarComponent.EnableHighTireLight then
                avatarComponent:EnableHighTireLight(true, get_vehicle_skin_id_1)
            end
            
            
            if currentVehicleRef.UpdateParticle then pcall(function() currentVehicleRef:UpdateParticle(get_vehicle_skin_id_1) end) end
            if currentVehicleRef.ChangeParticles then pcall(function() currentVehicleRef:ChangeParticles(get_vehicle_skin_id_1) end) end
            if currentVehicleRef.ReActivateExhaustParticle then pcall(function() currentVehicleRef:ReActivateExhaustParticle() end) end
            
            
            local VehicleLicenseNumberComponentRef = import("VehicleLicenseNumberComponent")
            local componentByClass = currentVehicleRef:GetComponentByClass(VehicleLicenseNumberComponentRef)
            if slua.isValid(componentByClass) then
                if componentByClass.LicensePlate then
                    componentByClass.LicensePlate.ItemID = get_vehicle_skin_id_1
                    componentByClass.LicensePlate.ChassisLightId = get_vehicle_skin_id_1 + 1000
                end
                if componentByClass.PreChangeEffect then componentByClass:PreChangeEffect() end
                if componentByClass.PreChangeChassisLight then componentByClass:PreChangeChassisLight() end
            end
            
            
            if currentVehicleRef.SetVehicleMusicPlayState then currentVehicleRef:SetVehicleMusicPlayState(true) end
        end
    end)
end

_G.HandlePetLogic = function()
    pcall(function()
        if not _G.PetSkin or _G.PetSkin == 0 or _G.PetSkin == 50000 or _G.PetSkin == _G.LastAppliedPet then return end
        if not _G.skinIdCache[_G.PetSkin] then _G.download_item(_G.PetSkin); _G.skinIdCache[_G.PetSkin] = true end
        
        local ModuleManagerRef = require("client.module_framework.ModuleManager")
        if ModuleManagerRef then
            local petModule = ModuleManagerRef.GetModule(ModuleManagerRef.CommonModuleConfig.logic_pet)
            if petModule then
                if petModule.SetCurPetID then petModule:SetCurPetID(_G.PetSkin) end
                if petModule.EquipPet then petModule:EquipPet(_G.PetSkin) end
            end
        end
        _G.LastAppliedPet = _G.PetSkin
    end)
end

_G.DeadBoxSkins = _G.DeadBoxSkins or {}
_G.AlreadyChangedSet = _G.AlreadyChangedSet or {}

local function localMethod13(t, element)
    if not t then return false end
    for _, configIntValue in ipairs(t) do
        if configIntValue == element then return true end
    end
    return false
end

local function localMethod5(loc1, loc2, tolerance)
    local dx = loc1.X - loc2.X
    local dy = loc1.Y - loc2.Y
    local dz = loc1.Z - loc2.Z
    return dx * dx + dy * dy + dz * dz < tolerance * tolerance
end

_G.DeadBox_TemperRequest = function(playerController)
    local playerCharacterSafety = playerController:GetPlayerCharacterSafety()
    if not playerCharacterSafety then return end
    
    local GameplayStaticsRef = import("GameplayStatics")
    if GameplayStaticsRef then
        local ActorRef = import("Actor")
        local ui_util_1 = require("client.common.ui_util")
        if ui_util_1 then
            local gameInstance = ui_util_1.GetGameInstance()
            if gameInstance then
                local PlayerTombBoxRef = import("PlayerTombBox")
                local actorsArray = GameplayStaticsRef.GetAllActorsOfClass(gameInstance, PlayerTombBoxRef, slua.Array(UEnums.EPropertyClass.Object, ActorRef))
                
                for _, actorRef1 in pairs(actorsArray) do
                    if slua.isValid(actorRef1) then
                        local damageCauser = actorRef1.DamageCauser
                        if damageCauser and damageCauser.Playerkey == playerController.Playerkey then
                            local deadBoxAvatarComponent_BP = actorRef1.DeadBoxAvatarComponent_BP
                            if deadBoxAvatarComponent_BP and not localMethod13(_G.AlreadyChangedSet, actorRef1) then
                                local actorLocation = actorRef1:K2_GetActorLocation()
                                local bFalse = false
                                
                                for _, entry in pairs(_G.DeadBoxSkins) do
                                    if localMethod5(entry.location, actorLocation, 1.0) then
                                        deadBoxAvatarComponent_BP:ResetItemAvatar()
                                        deadBoxAvatarComponent_BP:PreChangeItemAvatar(entry.SkinID)
                                        deadBoxAvatarComponent_BP:SyncChangeItemAvatar(entry.SkinID)
                                        table.insert(_G.AlreadyChangedSet, actorRef1)
                                        bFalse = true
                                        break
                                    end
                                end
                                
                                if not bFalse then
                                    local zeroVal = 0
                                    local currentVehicle = playerCharacterSafety.CurrentVehicle
                                    if currentVehicle and _G.CurrentEquipVehicleID and _G.CurrentEquipVehicleID ~= 0 then
                                        zeroVal = tonumber(tostring(_G.CurrentEquipVehicleID) .. "1") or 0
                                    else
                                        local currentWeaponRef3 = playerCharacterSafety:GetCurrentWeapon()
                                        if currentWeaponRef3 then
                                            local synData7 = currentWeaponRef3.synData and currentWeaponRef3.synData:Get(7)
                                            if synData7 and synData7.defineID then
                                                zeroVal = synData7.defineID.TypeSpecificID
                                            end
                                        end
                                    end
                                    
                                    if zeroVal ~= 0 then
                                        deadBoxAvatarComponent_BP:ResetItemAvatar()
                                        deadBoxAvatarComponent_BP:PreChangeItemAvatar(zeroVal)
                                        deadBoxAvatarComponent_BP:SyncChangeItemAvatar(zeroVal)
                                        table.insert(_G.DeadBoxSkins, { location = actorLocation, SkinID = zeroVal })
                                        table.insert(_G.AlreadyChangedSet, actorRef1)
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

_G.AKFakeKillCounts = _G.AKFakeKillCounts or {}

_G.ForceEnableKillCounterUI = function()
    pcall(function()
        local KillCounterUISubsystemRef = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"] or require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if KillCounterUISubsystemRef and KillCounterUISubsystemRef.__inner_impl and not _G.KCUISystemHacked2 then
            local inner_impl_2 = KillCounterUISubsystemRef.__inner_impl
            inner_impl_2.CheckSupportKCUI = function() return true end
            
            inner_impl_2.CheckNeedMainKillCounterUI = function(self, weaponBySlot, PlayerID)
                if slua.isValid(weaponBySlot) then
                    local weaponIDRef2 = weaponBySlot:GetWeaponID()
                    self:UpdateMainKillCounterUI(true, weaponIDRef2, _G.get_skin_id(weaponIDRef2) or weaponIDRef2)
                else 
                    self:UpdateMainKillCounterUI(false) 
                end
            end
            
            local updateMainKillCounterUI = inner_impl_2.UpdateMainKillCounterUI
            inner_impl_2.UpdateMainKillCounterUI = function(self, bShow, weaponIDRef3, AvatarID)
                if bShow then AvatarID = _G.get_skin_id(weaponIDRef3) or AvatarID end
                if updateMainKillCounterUI then updateMainKillCounterUI(self, bShow, weaponIDRef3, AvatarID) end
            end
            _G.KCUISystemHacked2 = true
        end

        local ModuleManagerRef = require("client.module_framework.ModuleManager")
        if ModuleManagerRef then
            local logicKillCounterModuleRef = ModuleManagerRef.GetModule(ModuleManagerRef.CommonModuleConfig.LogicKillCounter)
            if logicKillCounterModuleRef and not _G.KCLogicHacked2 then
                logicKillCounterModuleRef.CheckSupportKC = function() return true end
                logicKillCounterModuleRef.CheckSupportKillCounterAvatar = function() return true end
                logicKillCounterModuleRef.CheckHasWeaponKillCounter = function() return true end
                logicKillCounterModuleRef.GetBaseKillCounterIdByWeaponId = function() return 2100004 end
                logicKillCounterModuleRef.GetEquipedKillCounterId = function() return 2100004 end
                logicKillCounterModuleRef.GetMyEquipedKillCounterId = function() return 2100004 end
                logicKillCounterModuleRef.GetOneWeaponKillCountInBattle = function(self, uid, weaponId) return _G.AKFakeKillCounts[weaponId] or 0 end
                logicKillCounterModuleRef.GetWeaponKillCountByUid = function(self, uid, weaponId) return _G.AKFakeKillCounts[weaponId] or 0 end
                _G.KCLogicHacked2 = true
            end
        end

        local killInfoPath = "GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"
        local cachedVal_12_1 = package.loaded[killInfoPath] or require(killInfoPath)
        if cachedVal_12_1 and cachedVal_12_1.__inner_impl and not _G.KillInfoCounterHacked then
            local fileItem = cachedVal_12_1.__inner_impl.FileItem
            cachedVal_12_1.__inner_impl.FileItem = function(self, DamageRecordData)
                pcall(function()
                    local GameplayDataRef2 = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()
                    if slua.isValid(GameplayDataRef2) and DamageRecordData.Causer == GameplayDataRef2:GetPlayerNameSafety() then 
                        local currentWeaponRef = GameplayDataRef2:GetCurrentWeapon()
                        if slua.isValid(currentWeaponRef) then
                            local weaponIDRef = currentWeaponRef:GetWeaponID()
                            local get_skin_id_3 = _G.get_skin_id(weaponIDRef)
                            if get_skin_id_3 then DamageRecordData.CauserWeaponAvatarID = get_skin_id_3 end
                            if _G.SuitSkin ~= 0 then DamageRecordData.CauserClothAvatarID = _G.SuitSkin end
                            
                            DamageRecordData.IsUseColor, DamageRecordData.UseColor = true, import("LinearColor")(1.0, 0.8, 0.0, 1.0) 
                            
                            if DamageRecordData.ResultHealthStatus == 2 then
                                _G.AKFakeKillCounts[weaponIDRef] = (_G.AKFakeKillCounts[weaponIDRef] or 0) + 1
                                local managerRef = require("client.slua_ui_framework.manager")
                                local mainKillCounterUI = managerRef.GetUI(managerRef.UI_Config_InGame.MainKillCounter)
                                if mainKillCounterUI and mainKillCounterUI.UpdateWeaponID then
                                    local weaponMainAvatarID = get_skin_id_3 or currentWeaponRef:GetWeaponMainAvatarID()
                                    mainKillCounterUI:UpdateWeaponID(weaponIDRef, weaponMainAvatarID)
                                    local logicKillCounterModule = ModuleManagerRef.GetModule(ModuleManagerRef.CommonModuleConfig.LogicKillCounter)
                                    local equipedKillCounterId = logicKillCounterModule:GetEquipedKillCounterId(0, weaponMainAvatarID)
                                    mainKillCounterUI:SetKillCounterItemShowWithNum(equipedKillCounterId, _G.AKFakeKillCounts[weaponIDRef], weaponMainAvatarID)
                                end
                            end
                        end
                    end
                end)
                if fileItem then return fileItem(self, DamageRecordData) end
            end
            _G.KillInfoCounterHacked = true
        end

        local SwitchWeaponSlotMode2_1 = package.loaded["GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2"] or require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
        if SwitchWeaponSlotMode2_1 and SwitchWeaponSlotMode2_1.__inner_impl and not _G.SlotBaseHacked then
            SwitchWeaponSlotMode2_1.__inner_impl.CheckShowKCIcon = function(self)
                if self.KillCounterImg and slua.isValid(self.KillCounterImg) then 
                    self.KillCounterImg:SetVisibility(import("ESlateVisibility").SelfHitTestInvisible) 
                end
            end
            _G.SlotBaseHacked = true
        end
    end)
end

function _G.InitializeSkinModSystem()
    pcall(function()
        local LobbyAvatarRef = package.loaded["client.logic.avatar.LobbyAvatar"] or require("client.logic.avatar.LobbyAvatar")
        if LobbyAvatarRef and not _G.LobbyBypassHacked then
            local putonEquipment = LobbyAvatarRef.PutonEquipment
            LobbyAvatarRef.PutonEquipment = function(self, itemID, tAvatarCustom, tExtraData)
                local weaponSkinIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[itemID]
                if weaponSkinIndex then
                    local curHoldingWeaponSkinID = self.GetCurHoldingWeaponSkinID and self:GetCurHoldingWeaponSkinID()
                    if curHoldingWeaponSkinID and curHoldingWeaponSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[curHoldingWeaponSkinID] then
                        local vIP_Attachments_2 = _G.VIP_Attachments[curHoldingWeaponSkinID][weaponSkinIndex]
                        if vIP_Attachments_2 and vIP_Attachments_2 > 0 then
                            if self.HandleDownload then self:HandleDownload(vIP_Attachments_2, nil, nil, false) end
                            itemID = vIP_Attachments_2
                        end
                    end
                end
                if putonEquipment then
                    return putonEquipment(self, itemID, tAvatarCustom, tExtraData)
                end
            end

            local charEquipWeaponByResId = LobbyAvatarRef.CharEquipWeaponByResId
            LobbyAvatarRef.CharEquipWeaponByResId = function(self, resID, isUse, isAsync, SocketName)
                local equipWeaponResult
                if charEquipWeaponByResId then
                    equipWeaponResult = charEquipWeaponByResId(self, resID, isUse, isAsync, SocketName)
                end
                if isUse and self.GetEquipments then
                    local equipments = self:GetEquipments()
                    for _, equip in ipairs(equipments) do
                        if _G.BaseAttachToIndex and _G.BaseAttachToIndex[equip.itemID] then
                            self:PutonEquipment(equip.itemID, equip.CustomInfo, {bIsUse = false})
                        end
                    end
                end
                return equipWeaponResult
            end
            _G.LobbyBypassHacked = true
        end
    end)

    pcall(function()
        local Common_Items_UIBP_1 = package.loaded["client.slua.component.item.ItemChildren.Common_Items_UIBP"] or require("client.slua.component.item.ItemChildren.Common_Items_UIBP")
        if Common_Items_UIBP_1 and not _G.IconBaloHacked then
            local initView = Common_Items_UIBP_1.InitView
            Common_Items_UIBP_1.InitView = function(self, nItemId, nCount, nValidTime, tExtraData)
                tExtraData = tExtraData or {}
                local nullData6 = nil
                
                if _G.get_skin_id then
                    local get_skin_id_1 = _G.get_skin_id(nItemId)
                    if get_skin_id_1 and get_skin_id_1 ~= nItemId then
                        nullData6 = get_skin_id_1
                    end
                end
                
                local weaponSkinIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[nItemId]
                if not nullData6 and weaponSkinIndex then
                    local GameplayDataRef3 = require("GameLua.GameCore.Data.GameplayData")
                    if GameplayDataRef3 then
                        local GameplayDataRef = GameplayDataRef3.GetPlayerCharacter()
                        if GameplayDataRef and slua.isValid(GameplayDataRef) then
                            local currentWeaponRef2 = GameplayDataRef:GetCurrentWeapon()
                            if slua.isValid(currentWeaponRef2) then
                                local weaponIDRef2 = currentWeaponRef2:GetWeaponID()
                                local get_skin_id_4 = _G.get_skin_id(weaponIDRef2) or weaponIDRef2
                                if get_skin_id_4 >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[get_skin_id_4] then
                                    local vIP_Attachments_1 = _G.VIP_Attachments[get_skin_id_4][weaponSkinIndex]
                                    if vIP_Attachments_1 and vIP_Attachments_1 > 0 then
                                        nullData6 = vIP_Attachments_1
                                    end
                                end
                            end
                        end
                    end
                end
                
                if nullData6 then
                    tExtraData.displayResId = nullData6
                    if not _G.skinIdCache2[nullData6] then
                        if _G.download_item then pcall(_G.download_item, nullData6) end
                        _G.skinIdCache2[nullData6] = true
                    end
                end
                
                if initView then
                    return initView(self, nItemId, nCount, nValidTime, tExtraData)
                end
            end
            _G.IconBaloHacked = true
        end
    end)

    pcall(function()
        local vehiclePlateLicenseUtilPath = "GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil"
        local cachedVal_33_1 = package.loaded[vehiclePlateLicenseUtilPath] or require(vehiclePlateLicenseUtilPath)
        
        if cachedVal_33_1 and not _G.VehicleEffectHacked then
            cachedVal_33_1.CheckIsBetterVehicle = function() return true end
            cachedVal_33_1.CheckHasUnLockFeature = function() return true end
            cachedVal_33_1.NeedOpenHighTire = function() return true end
            
            local getUpgradeEffectList = cachedVal_33_1.GetUpgradeEffectList
            cachedVal_33_1.GetUpgradeEffectList = function(UID)
                local GameplayDataRef = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()
                if slua.isValid(GameplayDataRef) and GameplayDataRef:GetCurrentVehicle() then
                    local currentVehicleRef = GameplayDataRef:GetCurrentVehicle()
                    local avatarComponent = currentVehicleRef.VehicleAvatarComponent_BP or currentVehicleRef:GetAvatarComponent()
                    if slua.isValid(avatarComponent) then
                        local vehicleSkinsListItem = avatarComponent.VehicleNetAvatarData and avatarComponent.VehicleNetAvatarData.ItemDefineID.TypeSpecificID or avatarComponent:GetCurItemAvatarID()
                        local betterVehicleEffect = CDataTable.GetTableData("BetterVehicleEffect", vehicleSkinsListItem)
                        if betterVehicleEffect and betterVehicleEffect.EffectIDList then
                            local propInt = slua.Array(UEnums.EPropertyClass.Int)
                            for i=0, betterVehicleEffect.EffectIDList:Num()-1 do
                                propInt:Add(betterVehicleEffect.EffectIDList:Get(i))
                            end
                            return propInt
                        end
                    end
                end
                if getUpgradeEffectList then return getUpgradeEffectList(UID) end
                return nil
            end
            _G.VehicleEffectHacked = true
        end

        local VehicleAvatarComponentRef = package.loaded["GameLua.GameCore.Module.Vehicle.Component.VehicleAvatarComponent"] or require("GameLua.GameCore.Module.Vehicle.Component.VehicleAvatarComponent")
        if VehicleAvatarComponentRef and VehicleAvatarComponentRef.__inner_impl and not _G.VehicleAvatarSwitchHacked then
            
            VehicleAvatarComponentRef.__inner_impl.CheckCanPlaySkinSwitchEffect = function(self, curVehicleId, lastVehicleId)
                return true
            end
            
            VehicleAvatarComponentRef.__inner_impl.ShowVehicleSwitchEffect = function(self)
                if not self.curSwitchEffectId or self.curSwitchEffectId <= 0 then
                    self.curSwitchEffectId = 7303001
                end
                
                local ownerRef = self:GetOwner()
                if not slua.isValid(ownerRef) then return false end
                
                if self.uSwitchEffectActor then
                    self:StopSkinSwitchEffect()
                    self.uSwitchEffectActor:K2_DestroyActor()
                    self.uSwitchEffectActor = nil
                end
                
                if not self.lastEquipedAvatarId or self.lastEquipedAvatarId <= 0 then
                    self.lastEquipedAvatarId = ownerRef.ClientUsedAvatarID or ownerRef:GetDefaultAvatarID() or 0
                end
                
                local clientUsedAvatarID = ownerRef.ClientUsedAvatarID or self.lastEquipedAvatarId or 0
                local bIsLobbyActor = self:IsLobbyActor()
                local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
                if not world then return false end
                
                local VehiclePlateLicenseUtilRef = require("GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil")
                local switchEffectActorPath = VehiclePlateLicenseUtilRef.GetSwitchEffectActorPath()
                local switchEffectActorClass = import(switchEffectActorPath)

                self.uSwitchEffectActor = world:SpawnActor(switchEffectActorClass, nil, nil, nil)
                if not slua.isValid(self.uSwitchEffectActor) then
                    self.uSwitchEffectActor = nil
                    return false
                end
                
                self.uSwitchEffectActor:K2_AttachToActor(ownerRef, "None", 1, 1, 1, false)
                self.uSwitchEffectActor:K2_SetActorRelativeLocation(FVector(0, 0, 0), false, nil, false)
                self.uSwitchEffectActor:K2_SetActorRelativeRotation(FRotator(0, 0, 0), false, nil, false)
                
                self:ChangeFakeSwitchVehicleAvatar(self.uSwitchEffectActor.Mesh, self.lastEquipedAvatarId)
                self.uSwitchEffectActor:SetAnimInsAndAnimState(self.uOldVehicleMeshAnimClass, ownerRef)
                self.uSwitchEffectActor:StartVehicleSwitchEffect(ownerRef, self.curSwitchEffectId, self.lastEquipedAvatarId, clientUsedAvatarID, bIsLobbyActor)
                
                self.uOldVehicleMeshAnimClass = nil
                return true
            end
            
            VehicleAvatarComponentRef.__inner_impl.ResetAnimationState = function(self)
                if self.uSwitchEffectActor then
                    self:StopSkinSwitchEffect()
                    self.uSwitchEffectActor:K2_DestroyActor()
                    self.uSwitchEffectActor = nil
                end
                self.lastEquipedAvatarId = 0
                self.curSwitchEffectId = 7303001
            end
            
            local receiveBeginPlay = VehicleAvatarComponentRef.__inner_impl.ReceiveBeginPlay
            VehicleAvatarComponentRef.__inner_impl.ReceiveBeginPlay = function(self)
                if receiveBeginPlay then receiveBeginPlay(self) end
                self:ResetAnimationState()
            end
            
            _G.VehicleAvatarSwitchHacked = true
        end

        local LobbyVehicleRef = package.loaded["client.lobby_ue_object.Actor.LobbyVehicle"] or require("client.lobby_ue_object.Actor.LobbyVehicle")
        if LobbyVehicleRef and not _G.LobbyVehicleHacked then
            local preChangeVehicleAvatar = LobbyVehicleRef.PreChangeVehicleAvatar
            LobbyVehicleRef.PreChangeVehicleAvatar = function(self, InAvatarID, InAdvanceAvatarID)
                local vehicleSkinsListItem = _G.get_vehicle_skin_id(InAvatarID)
                if vehicleSkinsListItem and vehicleSkinsListItem ~= InAvatarID and vehicleSkinsListItem ~= 0 then
                    if not _G.skinIdCache[vehicleSkinsListItem] then 
                        if _G.download_item then pcall(_G.download_item, vehicleSkinsListItem) end
                        _G.skinIdCache[vehicleSkinsListItem] = true 
                    end
                    InAvatarID = vehicleSkinsListItem
                end
                
                local bIsDisabled7 = false
                if preChangeVehicleAvatar then
                    bIsDisabled7 = preChangeVehicleAvatar(self, InAvatarID, InAdvanceAvatarID)
                end
                
                pcall(function()
                    self.ClientUsedAvatarID = InAvatarID
                    if self.PlayStartUpEffect then self:PlayStartUpEffect() end
                    if self.PlayAccelerateEffect then self:PlayAccelerateEffect() end
                end)
                
                return bIsDisabled7
            end
            _G.LobbyVehicleHacked = true
        end
    end)

    if not _G.AKSkinLoopStarted then
        _G.AKSkinLoopStarted = true
        local time_ticker_1 = require("common.time_ticker")
        
        local function localMethod2()
            pcall(function()
                local GameplayDataRef3 = require("GameLua.GameCore.Data.GameplayData")
                if GameplayDataRef3 then
                    local GameplayDataRef2 = GameplayDataRef3.GetPlayerCharacter()
                    if slua.isValid(GameplayDataRef2) then
                        _G.ForceEnableKillCounterUI()
                        _G.ReadConfigFile()
                        _G.LoadAttachmentsFromINI()
                        _G.equip_character_avatar(GameplayDataRef2)   
                        _G.ApplyWeaponSkins(GameplayDataRef2)  
                        _G.ApplyVehicleSkins(GameplayDataRef2)       
                        _G.HandlePetLogic()
                        local PC = GameplayDataRef3.GetPlayerController()
                        if slua.isValid(PC) then _G.DeadBox_TemperRequest(PC) end
                    end
                end
            end)
            if time_ticker_1 and time_ticker_1.AddTimerOnce then
                time_ticker_1.AddTimerOnce(0.1, localMethod2)
            end
        end
        localMethod2() 
    end
end

local configTable1 = {
    '/storage/emulated/0/Android/data/com.tencent.ig/files/ADITYA_MENU.ini',
    '/storage/emulated/0/Android/data/com.pubg.krmobile/files/ADITYA_MENU.ini',
    '/storage/emulated/0/Android/data/com.vng.pubgmobile/files/ADITYA_MENU.ini',
    '/storage/emulated/0/Android/data/com.rekoo.pubgm/files/ADITYA_MENU.ini'
}

function _G.AK_SaveINI()
    for _, path in ipairs(configTable1) do
        local configFilePath = io.open(path, "w")
        if configFilePath then
            local blankText3 = ""
            for _, f in ipairs(_G.AK_Features) do
                blankText3 = blankText3 .. f.id .. "=" .. tostring(f.val) .. "\n"
            end
            configFilePath:write(blankText3)
            configFilePath:close()
        end
    end
    _G.EnvRequiresUpdate = true
    _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
end

function _G.AK_LoadINI()
    local configFilePath = nil
    for _, path in ipairs(configTable1) do
        configFilePath = io.open(path, "r")
        if configFilePath then break end
    end
    if configFilePath then
        local blankText3 = configFilePath:read("*all")
        configFilePath:close()
        for _, f in ipairs(_G.AK_Features) do
            local featureMatch = string.match(blankText3, f.id .. "=(%d+)")
            if featureMatch then f.val = tonumber(featureMatch) end
        end
    end
end

function _G.AK_GetVal(id)
    if not _G.AK_Features then return 0 end
    for _, f in ipairs(_G.AK_Features) do
        if f.id == id then return f.val end
    end
    return 0
end

function _G.ShowAKMenu()
    if not _G.AK_Features then return end

    local akFeatures = _G.AK_Features[_G.AK_MenuIndex]
    local akmodpubgString = "ADITYA_ORG"
    local modVersionString = "MOD LUA PAK VIP CUSTOM ANDROID V11\n[MOD SKIN VIP - BYPASS V7 - ANTI REPORT]\n"
    local blankText2 = ""
    
    if akFeatures.type == "ACTIVED" then
        blankText2 = (akFeatures.val == 1) and "ON" or "OFF"
    elseif akFeatures.type == "percentVal100" then
        local localVal_8_sub = akFeatures.action_prefix or "INCREASE"
        blankText2 = localVal_8_sub .. " " .. tostring(akFeatures.val / 10) .. "%"
    elseif akFeatures.type == "percentVal10" then
        local localVal_8_sub = akFeatures.action_prefix or "INCREASE"
        blankText2 = localVal_8_sub .. " " .. tostring(akFeatures.val) .. "%"
    elseif akFeatures.type == "value_range" then
        blankText2 = tostring(akFeatures.val)
    end
    
    modVersionString = modVersionString .. "SELECTED FUNCTION \n[" .. akFeatures.name .. "]\nSTATUS [" .. blankText2 .. "]\n\n"
    
    for i, f in ipairs(_G.AK_Features) do
        local akMenuIndex = (i == _G.AK_MenuIndex) and "▶ " or "   "
        local blankText1 = ""
        if f.type == "ACTIVED" then
            blankText1 = (f.val == 1) and "[ON]" or "[OFF]"
        elseif f.type == "percentVal100" then
            blankText1 = "[" .. tostring(f.val / 10) .. "%]"
        elseif f.type == "percentVal10" then
            blankText1 = "[" .. tostring(f.val) .. "%]"
        elseif f.type == "value_range" then
            blankText1 = "[" .. tostring(f.val) .. "]"
        end
        modVersionString = modVersionString .. akMenuIndex .. f.name .. " " .. blankText1 .. "\n"
    end
    
    local chnString = "SELECT"
    if akFeatures.type == "ACTIVED" then
        chnString = "ON / OFF"
    elseif akFeatures.type == "percentVal100" or akFeatures.type == "percentVal10" then
        local localVal_8_sub = akFeatures.action_prefix or "INCREASE"
        chnString = localVal_8_sub .. " 10%"
    elseif akFeatures.type == "value_range" then
        chnString = "INCREASE MORE " .. tostring(akFeatures.step)
    end

    local logic_common_msg_box_1 = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
    if logic_common_msg_box_1 and logic_common_msg_box_1.Show then
        logic_common_msg_box_1.Show(4, akmodpubgString, modVersionString, 
        function() 
            if akFeatures.type == "ACTIVED" then
                akFeatures.val = 1 - akFeatures.val
            elseif akFeatures.type == "percentVal100" then
                akFeatures.val = akFeatures.val + 100
                if akFeatures.val > 1000 then akFeatures.val = 0 end 
            elseif akFeatures.type == "percentVal10" then
                akFeatures.val = akFeatures.val + 10
                if akFeatures.val > 100 then akFeatures.val = 0 end 
            elseif akFeatures.type == "value_range" then
                akFeatures.val = akFeatures.val + akFeatures.step
                if akFeatures.val > akFeatures.max then akFeatures.val = akFeatures.min end
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
        chnString, "NEXT FEATURE")
    end
end





function NetworkRPC:ctor()
    self.bHasShownDevNotice = false 
    self.bHasShownExpiredNotice = false 
    self.AK_NativeESP_Ready = false
end

function NetworkRPC:_PostConstruct()
    NetworkRPC.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
    print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
    self:StartAdvancedSystems()
end

function NetworkRPC:ReceiveBeginPlay()
    NetworkRPC.__super.ReceiveBeginPlay(self)
    
    
    self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
    if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
        local CheckFallingDistanceComponentRef = import("CheckFallingDistanceComponent")
        if slua.isValid(CheckFallingDistanceComponentRef) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponentRef)) then
            print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
            Game:AddComponent(CheckFallingDistanceComponentRef, self, "CheckFallingDistanceComponent")
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
        GameplayDataRef3.AddCharacter(self.Object)
        self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
        self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
    else
        self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
            [1] = "FinishedState"
        }, self.HandleFinishedState, self)
    end

    
    EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
end

function NetworkRPC:ReceiveEndPlay(EndPlayReason)
    NetworkRPC.__super.ReceiveEndPlay(self, EndPlayReason)
    if Client and GameplayDataRef3.RemoveCharacter ~= nil then
        GameplayDataRef3.RemoveCharacter(self.Object)
    end
end

function NetworkRPC:StartAdvancedSystems()
    if not Client then return end
    
    self:AddGameTimer(0.1, true, function()
        if not slua.isValid(self.Object) then return end
        
        local GameplayDataRef2 = GameplayDataRef3.GetPlayerCharacter()
        if not slua.isValid(GameplayDataRef2) then return end

        if timestampRef > timestamp then
            if self.Object == GameplayDataRef2 and not self.bHasShownExpiredNotice then
                if self.Object.IsAlive and self.Object:IsAlive() then
                    self.bHasShownExpiredNotice = true
                    pcall(function()
                        local logic_common_msg_box_1 = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
                        if logic_common_msg_box_1 and logic_common_msg_box_1.Show then
                            logic_common_msg_box_1.Show(4, "MESSAGE FROM ADMIN ADITYA_ORG", "YOUR MOD VERSION HAS EXPIRED\nPLEASE CONTACT TELEGRAM @ADITYA_ORG TO PURCHASE", function() 
                                local KismetSystemLibraryRef2 = import("KismetSystemLibrary")
                                if KismetSystemLibraryRef2 then KismetSystemLibraryRef2.LaunchURL("https://t.me/nanamod96") end
                            end, function() end, "CONTACT ADMIN", "CANCEL")
                        end
                    end)
                end
            end
            return 
        end

        if self.Object == GameplayDataRef2 and not self.bHasShownDevNotice then
            if self.Object.IsAlive and self.Object:IsAlive() then
                self.bHasShownDevNotice = true
                
                if not _G.AK_Features then
                    _G.AK_Features = {
                        { id="ESP_HP", name="ESP HEALTH BAR", val=0, type="ACTIVED" },
                        { id="ESP_BOX", name="ESP BOX", val=0, type="ACTIVED" },
                        { id="IPAD_VIEW_TPP", name="IPAD VIEW TPP", val=90, type="value_range", min=90, max=150, step=5 },
                        { id="IPAD_VIEW_FPP", name="IPAD VIEW FPP", val=103, type="value_range", min=103, max=150, step=5 },
                        { id="AIMBOT", name="AIMBOT", val=0, type="ACTIVED" },
                        { id="SPEED_AIMBOT", name="AIMBOT SPEED", val=0, type="percentVal10", action_prefix="INCREASE" },
                        { id="FOV_AIMBOT", name="FOV AIMBOT", val=0, type="percentVal10", action_prefix="INCREASE" },
                        { id="THU_TAM", name="SMALL CROSSHAIR", val=0, type="percentVal10", action_prefix="THU" },
                        { id="GIAM_GIAT_NGANG", name="REDUCE HORIZONTAL RECOIL", val=0, type="percentVal10", action_prefix="DECREASE" },
                        { id="GIAM_GIAT_DOC", name="REDUCE VERTICAL RECOIL", val=0, type="percentVal10", action_prefix="DECREASE" },
                        { id="GIAM_RUNG_SCOPE", name="REDUCE SCOPE SHAKE", val=0, type="percentVal10", action_prefix="DECREASE" },
                        { id="MAGIC_HEAD", name="MAGIC HEAD", val=0, type="percentVal100", action_prefix="INCREASE" },
                        { id="MAGIC_BODY", name="MAGIC BODY", val=0, type="percentVal100", action_prefix="INCREASE" },
                        { id="MAGIC_LEGS", name="MAGIC LEGS", val=0, type="percentVal100", action_prefix="INCREASE" },
                        { id="NOGRASS", name="REMOVE GRASS", val=0, type="ACTIVED" },
                        { id="NOTREES", name="REMOVE TREES", val=0, type="ACTIVED" },
                        { id="NOWATER", name="REMOVE WATER", val=0, type="ACTIVED" },
                        { id="NOFOG", name="REMOVE FOG", val=0, type="ACTIVED" },
                        { id="WHITE_BODY", name="COLORED BODY", val=0, type="ACTIVED" },
                    }
                    _G.AK_MenuIndex = 1
                end

                pcall(function()
                    _G.AK_LoadINI()
                    _G.ShowAKMenu()
                end)
            end
        end

        local akGetVal_4 = _G.AK_GetVal("IPAD_VIEW_TPP")
        if akGetVal_4 == 0 or akGetVal_4 < 90 then akGetVal_4 = 90 end
        
        local akGetVal_7 = _G.AK_GetVal("IPAD_VIEW_FPP")
        if akGetVal_7 == 0 or akGetVal_7 < 103 then akGetVal_7 = 103 end
        
        local thirdPersonCameraComponent = self.Object.ThirdPersonCameraComponent
        local firstPersonCameraComponent = self.Object.FirstPersonCameraComponent
        local bIsWeaponAimingRef = self.Object.bIsWeaponAiming or false
        
        if not bIsWeaponAimingRef then
            if slua.isValid(thirdPersonCameraComponent) and akGetVal_4 > 90 then 
                thirdPersonCameraComponent:SetFieldOfView(akGetVal_4)
                thirdPersonCameraComponent.FieldOfView = akGetVal_4 
            end
            if slua.isValid(firstPersonCameraComponent) and akGetVal_7 > 103 then 
                firstPersonCameraComponent:SetFieldOfView(akGetVal_7)
                firstPersonCameraComponent.FieldOfView = akGetVal_7 
            end
        end

        if self.Object.GetCurrentWeapon then
            local currentWeapon = self.Object:GetCurrentWeapon()
            if slua.isValid(currentWeapon) then
                local clockVal = os.clock()
                if self.LastWeaponEntity ~= currentWeapon then
                    self.LastWeaponEntity = currentWeapon
                    self.bForceWeaponMod = true
                end
                
                if not self.LastWeaponModTime or clockVal > self.LastWeaponModTime + 2.0 then
                    self.bForceWeaponMod = true
                    self.LastWeaponModTime = clockVal
                end
                
                if self.bForceWeaponMod or not currentWeapon.bIsAKModded then
                    pcall(function()
                        local shootWeaponEntity_GEN_VARIABLE = currentWeapon.ShootWeaponEntity_GEN_VARIABLE or currentWeapon.ShootWeaponEntity
                        if slua.isValid(shootWeaponEntity_GEN_VARIABLE) then
                            local thu_tam = _G.AK_GetVal("THU_TAM") / 100.0
                            local giam_giat_ngang = _G.AK_GetVal("GIAM_GIAT_NGANG") / 100.0
                            local giam_giat_doc = _G.AK_GetVal("GIAM_GIAT_DOC") / 100.0
                            local giam_rung_scope = _G.AK_GetVal("GIAM_RUNG_SCOPE") / 100.0
                            
                            shootWeaponEntity_GEN_VARIABLE.GameDeviationFactor = 3.36 - (3.36 * thu_tam)
                            shootWeaponEntity_GEN_VARIABLE.AccessoriesHRecoilFactor = 0.80 - (0.80 * giam_giat_ngang)
                            shootWeaponEntity_GEN_VARIABLE.AccessoriesVRecoilFactor = 0.50 - (0.50 * giam_giat_doc)
                            shootWeaponEntity_GEN_VARIABLE.RecoilKickADS = 0.20 - (0.20 * giam_rung_scope)

                            if _G.AK_GetVal("AIMBOT") == 1 then
                                if shootWeaponEntity_GEN_VARIABLE.AutoAimingConfig then
                                    local autoAimingConfig = shootWeaponEntity_GEN_VARIABLE.AutoAimingConfig
                                    local speed_aimbot = _G.AK_GetVal("SPEED_AIMBOT") / 100.0
                                    local fov_aimbot = _G.AK_GetVal("FOV_AIMBOT") / 100.0
                                    
                                    local speedScale = 3.0 + (3.0 * speed_aimbot)
                                    local fovScale = 1.5 + (1.5 * fov_aimbot)
                                    
                                    if autoAimingConfig.OuterRange then
                                        autoAimingConfig.OuterRange.Speed = speedScale
                                        autoAimingConfig.OuterRange.SpeedRate = speedScale
                                        autoAimingConfig.OuterRange.RangeRate = fovScale
                                        autoAimingConfig.OuterRange.RangeRateSight = fovScale
                                        autoAimingConfig.OuterRange.SpeedRateSight = speedScale
                                        autoAimingConfig.OuterRange.CrouchRate = 1.0
                                        autoAimingConfig.OuterRange.ProneRate = 1.0
                                    end
                                    if autoAimingConfig.InnerRange then
                                        autoAimingConfig.InnerRange.Speed = speedScale
                                        autoAimingConfig.InnerRange.SpeedRate = speedScale
                                        autoAimingConfig.InnerRange.RangeRate = fovScale
                                        autoAimingConfig.InnerRange.RangeRateSight = fovScale
                                        autoAimingConfig.InnerRange.SpeedRateSight = speedScale
                                        autoAimingConfig.InnerRange.CrouchRate = 1.0
                                        autoAimingConfig.InnerRange.ProneRate = 1.0
                                    end
                                    shootWeaponEntity_GEN_VARIABLE.AutoAimingConfig = autoAimingConfig
                                end
                            end
                        end
                    end)
                    currentWeapon.bIsAKModded = true
                    self.bForceWeaponMod = false
                end
            end
        end

        if self.Object == GameplayDataRef2 then
            if not _G.AKModTickCount then _G.AKModTickCount = 0 end
            if not _G.MagicUpdateVersion then _G.MagicUpdateVersion = 1 end
            if _G.EnvRequiresUpdate == nil then _G.EnvRequiresUpdate = true end

            _G.AKModTickCount = _G.AKModTickCount + 1

            if _G.AKModTickCount % 50 == 0 then
                pcall(function()
                    local contextData23, contextData6, akGetVal_6 = _G.AK_GetVal("MAGIC_HEAD"), _G.AK_GetVal("MAGIC_BODY"), _G.AK_GetVal("MAGIC_LEGS")
                    local contextData22, contextData39, contextData24, akGetVal_1 = _G.AK_GetVal("NOGRASS"), _G.AK_GetVal("NOTREES"), _G.AK_GetVal("NOWATER"), _G.AK_GetVal("NOFOG")
                    local akGetVal = _G.AK_GetVal("WHITE_BODY")
                    
                    _G.AK_LoadINI() 
                    
                    if contextData23 ~= _G.AK_GetVal("MAGIC_HEAD") or contextData6 ~= _G.AK_GetVal("MAGIC_BODY") or akGetVal_6 ~= _G.AK_GetVal("MAGIC_LEGS") then
                        _G.MagicUpdateVersion = _G.MagicUpdateVersion + 1
                    end
                    if contextData22 ~= _G.AK_GetVal("NOGRASS") or contextData39 ~= _G.AK_GetVal("NOTREES") or contextData24 ~= _G.AK_GetVal("NOWATER") or akGetVal_1 ~= _G.AK_GetVal("NOFOG") or akGetVal ~= _G.AK_GetVal("WHITE_BODY") then
                        _G.EnvRequiresUpdate = true
                    end
                end)
            end

            if not self.AK_NativeESP_Ready then
                pcall(function()
                    local GamePlayToolsRef = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
                    local screenMarkConfig = GamePlayToolsRef.GetCurrentConfig("ScreenMarkConfig")
                    
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
                            local InGameMarkToolsRef = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                            if InGameMarkToolsRef and InGameMarkToolsRef.ScreenMarkManager and InGameMarkToolsRef.ScreenMarkManager.OnInitMarkGroupData then
                                pcall(function() InGameMarkToolsRef.ScreenMarkManager:OnInitMarkGroupData(9999) end)
                            end
                        end
                    end

                    for k, autoAimingConfig in pairs(package.loaded) do
                        if type(k) == "string" and string.find(k, "ScreenMarkConfig") then
                            if type(autoAimingConfig) == "table" then
                                if autoAimingConfig[1006] then
                                    autoAimingConfig[1006].bBindBlocked = true     
                                    autoAimingConfig[1006].bBindOutScreen = true   
                                    autoAimingConfig[1006].MaxWidgetNum = 99
                                    autoAimingConfig[1006].MaxShowDistance = 6000000
                                    autoAimingConfig[1006].bScaleByDistance = false
                                    autoAimingConfig[1006].BindSocketName = "root"
                                    autoAimingConfig[1006].bUseLuaWorldSocketName = true
                                    autoAimingConfig[1006].WorldPositionOffset = FVector(0, 0, -30)
                                end
                                autoAimingConfig[9999] = {
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

                    local SubsystemMgrRef = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                    local clientHPBarSubSystemSubsystem = SubsystemMgrRef:Get("ClientHPBarSubSystem")
                    if clientHPBarSubSystemSubsystem then
                        if clientHPBarSubSystemSubsystem.SetPauseCheck then clientHPBarSubSystemSubsystem:SetPauseCheck(true) end
                        if clientHPBarSubSystemSubsystem.FocusActorCheckParam then
                            clientHPBarSubSystemSubsystem.FocusActorCheckParam.CheckBlock = false 
                            clientHPBarSubSystemSubsystem.FocusActorCheckParam.CheckDistance = 1000000
                        end
                    end
                    
                    if managerRef and managerRef.GetUI then
                        local enemyHpWidgetsMain = managerRef.GetUI(managerRef.UI_Config_InGame.EnemyHpWidgetsMain)
                        if slua.isValid(enemyHpWidgetsMain) then
                            if enemyHpWidgetsMain.SetCheckBlock then enemyHpWidgetsMain:SetCheckBlock(false) end
                            if enemyHpWidgetsMain.UIRoot and enemyHpWidgetsMain.UIRoot.CanvasPanel_HPBarWidgets then
                                if enemyHpWidgetsMain.UIRoot.CanvasPanel_HPBarWidgets.SetRenderScale then
                                    enemyHpWidgetsMain.UIRoot.CanvasPanel_HPBarWidgets:SetRenderScale(FVector2D(1.5, 1.5))
                                end
                            end
                        end
                    end
                end)
                self.AK_NativeESP_Ready = true
            end
            
            if _G.EnvRequiresUpdate then
                _G.EnvRequiresUpdate = false 
                pcall(function()
                    local KismetSystemLibraryRef2 = import("KismetSystemLibrary")
                    local playerControllerSafety = GameplayDataRef3.GetPlayerController()
                    
                    local function localMethod4(cmdKey, cmdValue)
                        if slua.isValid(KismetSystemLibraryRef2) and slua.isValid(playerControllerSafety) then
                            KismetSystemLibraryRef2.ExecuteConsoleCommand(playerControllerSafety, cmdKey .. " " .. cmdValue)
                        end
                        local gameInst = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
                        if slua.isValid(gameInst) and gameInst.ExecuteCMD then gameInst:ExecuteCMD(cmdKey, cmdValue) end
                    end

                    if slua.isValid(playerControllerSafety) then
                        if _G.AK_GetVal("NOGRASS") == 1 then localMethod4("r.DisableGrassRender", "1") else localMethod4("r.DisableGrassRender", "0") end
                        if _G.AK_GetVal("NOTREES") == 1 then
                            localMethod4("foliage.DensityScale", "0"); localMethod4("r.Foliage.DensityScale", "0")
                            localMethod4("foliage.MinimumScreenSize", "10000"); localMethod4("r.DisableTreeRender", "1")
                        else
                            localMethod4("foliage.DensityScale", "1"); localMethod4("r.Foliage.DensityScale", "1")
                            localMethod4("foliage.MinimumScreenSize", "0.0001"); localMethod4("r.DisableTreeRender", "0")
                        end
                        if _G.AK_GetVal("NOWATER") == 1 then
                            localMethod4("r.Water.SingleLayer.Enable", "0"); localMethod4("r.Show.Water", "0")
                            localMethod4("r.Show.Translucency", "0"); localMethod4("r.DisableWaterRender", "1")
                        else
                            localMethod4("r.Water.SingleLayer.Enable", "1"); localMethod4("r.Show.Water", "1")
                            localMethod4("r.Show.Translucency", "1"); localMethod4("r.DisableWaterRender", "0")
                        end
                        if _G.AK_GetVal("NOFOG") == 1 then
                            localMethod4("r.SkyAtmosphere", "0"); localMethod4("r.Atmosphere", "0")
                            localMethod4("r.Fog", "0"); localMethod4("r.VolumetricFog", "0"); localMethod4("r.DisableSkyRender", "1")
                        else
                            localMethod4("r.SkyAtmosphere", "1"); localMethod4("r.Atmosphere", "1")
                            localMethod4("r.Fog", "1"); localMethod4("r.VolumetricFog", "1"); localMethod4("r.DisableSkyRender", "0")
                        end
                        if _G.AK_GetVal("WHITE_BODY") == 1 then
                            localMethod4("r.CharacterDiffuseOffset", "2")
                            localMethod4("r.CharacterDiffusePower", "5")
                            localMethod4("r.CharacterMinShadowFactor", "100")
                        else
                            localMethod4("r.CharacterDiffuseOffset", "0")
                            localMethod4("r.CharacterDiffusePower", "1")
                            localMethod4("r.CharacterMinShadowFactor", "0")
                        end
                    end
                end)
            end

            local configTable2 = {}
            if GameplayDataRef3.GetAllPlayerCharacters then
                configTable2 = GameplayDataRef3.GetAllPlayerCharacters()
            elseif GameplayDataRef3.GameCharacters then
                for _, char in pairs(GameplayDataRef3.GameCharacters) do table.insert(configTable2, char) end
            end

            
            if not _G.AK_Active_Marks_Cache then _G.AK_Active_Marks_Cache = {} end

            for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
                local bIsDisabled3 = false
                if not slua.isValid(cacheData.actor) then 
                    bIsDisabled3 = true 
                else
                    pcall(function()
                        local actorRef1 = cacheData.actor
                        if actorRef1.bHidden or (actorRef1.Mesh and actorRef1.Mesh.bHidden) then bIsDisabled3 = true end
                        if type(actorRef1.IsDead) == "function" and actorRef1:IsDead() then bIsDisabled3 = true
                        elseif actorRef1.bIsDead == true or actorRef1.bIsDeadFlag == true then bIsDisabled3 = true end
                    end)
                end

                if bIsDisabled3 then
                    pcall(function()
                        if InGameMarkToolsRef and InGameMarkToolsRef.ClientRemoveMapMark then
                            InGameMarkToolsRef.ClientRemoveMapMark(cacheData.hpMark)
                            if cacheData.distMark then InGameMarkToolsRef.ClientRemoveMapMark(cacheData.distMark) end
                        end
                    end)
                    _G.AK_Active_Marks_Cache[cacheKey] = nil
                end
            end

            for _, enemy in pairs(configTable2) do
                if slua.isValid(enemy) and enemy ~= GameplayDataRef2 and enemy.TeamID ~= GameplayDataRef2.TeamID then
                    local bIsDisabled5 = false
                    local bIsDisabled8 = false

                    pcall(function()
                        if type(enemy.IsNearDeath) == "function" then bIsDisabled8 = enemy:IsNearDeath()
                        elseif enemy.bIsNearDeath ~= nil then bIsDisabled8 = enemy.bIsNearDeath end

                        if type(enemy.IsDead) == "function" then bIsDisabled5 = enemy:IsDead()
                        elseif enemy.bIsDead ~= nil then bIsDisabled5 = enemy.bIsDead
                        elseif enemy.bIsDeadFlag ~= nil then bIsDisabled5 = enemy.bIsDeadFlag end

                        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then bIsDisabled5 = true end

                        if not bIsDisabled8 then
                            local valRef = 100
                            if type(enemy.GetHealth) == "function" then valRef = enemy:GetHealth()
                            elseif enemy.Health ~= nil then valRef = enemy.Health end
                            if valRef <= 0 then bIsDisabled5 = true end
                        end
                    end)

                    if not bIsDisabled5 then
                        if enemy.bHasAKNativeHPBar and enemy.AK_LastKnockState ~= nil and enemy.AK_LastKnockState ~= bIsDisabled8 then
                            pcall(function()
                                if InGameMarkToolsRef and InGameMarkToolsRef.ClientRemoveMapMark then 
                                    InGameMarkToolsRef.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                    InGameMarkToolsRef.ClientRemoveMapMark(enemy.NativeDistMark)
                                end
                            end)
                            enemy.bHasAKNativeHPBar = false
                            _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
                        end
                        enemy.AK_LastKnockState = bIsDisabled8

                        if _G.AK_GetVal("ESP_HP") == 1 then
                            if not enemy.bHasAKNativeHPBar then
                                pcall(function()
                                    if InGameMarkToolsRef and InGameMarkToolsRef.ClientAddMapMark then
                                        enemy.NativeHPBarMark = InGameMarkToolsRef.ClientAddMapMark(1006, FVector(0,0,0), 0, "", 4, enemy)
                                        enemy.NativeDistMark = InGameMarkToolsRef.ClientAddMapMark(9999, FVector(0,0,0), 0, "", 4, enemy)
                                        enemy.bHasAKNativeHPBar = true

                                        _G.AK_Active_Marks_Cache[tostring(enemy)] = {
                                            actorRef1 = enemy,
                                            hpMark = enemy.NativeHPBarMark,
                                            distMark = enemy.NativeDistMark
                                        }
                                    end
                                end)
                            end
                        else
                            if enemy.bHasAKNativeHPBar and InGameMarkToolsRef then
                                pcall(function()
                                    if InGameMarkToolsRef.ClientRemoveMapMark then 
                                        InGameMarkToolsRef.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                        if enemy.NativeDistMark then InGameMarkToolsRef.ClientRemoveMapMark(enemy.NativeDistMark) end
                                    else 
                                        InGameMarkToolsRef.HideMapMark(enemy.NativeHPBarMark) 
                                        if enemy.NativeDistMark then InGameMarkToolsRef.HideMapMark(enemy.NativeDistMark) end
                                    end
                                end)
                                enemy.NativeHPBarMark = nil
                                enemy.NativeDistMark = nil
                                enemy.bHasAKNativeHPBar = false
                                _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
                            end
                        end
                        
                        if _G.AK_GetVal("ESP_BOX") == 1 then
                            pcall(function()
                                if enemy.Replay_IsEnemyFrameUIExisted then
                                    if not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
                                    if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                end
                            end)
                        else
                            pcall(function() if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end end)
                        end
                        
                        local mesh = enemy.Mesh or (enemy.getAvatarComponent2 and enemy:getAvatarComponent2())
                        if slua.isValid(mesh) then
                            if not mesh.LastHitboxUpdateVersion or mesh.LastHitboxUpdateVersion ~= _G.MagicUpdateVersion then
                                mesh.bIsAKHitboxModded = false
                            end
                            if not mesh.bIsAKHitboxModded then
                                pcall(function()
                                    local physicsAssetOverride = mesh.PhysicsAssetOverride
                                    if not slua.isValid(physicsAssetOverride) and mesh.SkeletalMesh then physicsAssetOverride = mesh.SkeletalMesh.PhysicsAsset end

                                    if slua.isValid(physicsAssetOverride) and physicsAssetOverride.SkeletalBodySetups then
                                        if not _G.AK_OrigHitboxes then _G.AK_OrigHitboxes = {} end
                                        local emptyStr = ""
                                        pcall(function() emptyStr = physicsAssetOverride:GetName() end)
                                        if emptyStr == "" then emptyStr = "DefaultPhys" end
                                        
                                        if not _G.AK_OrigHitboxes[emptyStr] then 
                                            _G.AK_OrigHitboxes[emptyStr] = {} 
                                        end
                                        local akOrigHitboxes = _G.AK_OrigHitboxes[emptyStr]

                                        local akGetVal_3 = 1.0 + (_G.AK_GetVal("MAGIC_HEAD") / 100.0)
                                        local akGetVal_2 = 1.0 + (_G.AK_GetVal("MAGIC_BODY") / 100.0)
                                        local akGetVal_5 = 1.0 + (_G.AK_GetVal("MAGIC_LEGS") / 100.0)

                                        local tableData = {
                                            ["head"] = akGetVal_3,
                                            ["pelvis"] = akGetVal_2,
                                            ["spineBone03"] = akGetVal_2,
                                            ["thigh_l"] = akGetVal_5, ["thigh_r"] = akGetVal_5,
                                            ["calf_l"] = akGetVal_5, ["calf_r"] = akGetVal_5,   
                                            ["foot_l"] = akGetVal_5, ["foot_r"] = akGetVal_5    
                                        }

                                        local skeletalBodySetups = physicsAssetOverride.SkeletalBodySetups
                                        for i = 1, 50 do 
                                            local nullData3 = nil
                                            pcall(function() nullData3 = type(skeletalBodySetups.Get) == "function" and skeletalBodySetups:Get(i-1) or skeletalBodySetups[i] end)
                                            if not nullData3 then break end
                                            
                                            if slua.isValid(nullData3) then
                                                local lowerStr = string.lower(tostring(nullData3.BoneName))
                                                local nullData1 = nil
                                                for k, _ in pairs(tableData) do
                                                    if string.find(lowerStr, k) then nullData1 = k break end
                                                end

                                                if nullData1 then
                                                    local localVal_24Item = tableData[nullData1]
                                                    local aggGeom = nullData3.AggGeom
                                                    
                                                    local boxElems = aggGeom and aggGeom.BoxElems or nullData3.BoxElems
                                                    local sphereElems = aggGeom and aggGeom.SphereElems or nullData3.SphereElems
                                                    local sphylElems = aggGeom and aggGeom.SphylElems or nullData3.SphylElems

                                                    local nilVal = nil
                                                    if boxElems then pcall(function() nilVal = type(boxElems.Get) == "function" and boxElems:Get(0) or boxElems[1] end) end
                                                    local nullData5 = nil
                                                    if sphereElems then pcall(function() nullData5 = type(sphereElems.Get) == "function" and sphereElems:Get(0) or sphereElems[1] end) end
                                                    local nullData7 = nil
                                                    if sphylElems then pcall(function() nullData7 = type(sphylElems.Get) == "function" and sphylElems:Get(0) or sphylElems[1] end) end

                                                    if not akOrigHitboxes[nullData1] then
                                                        akOrigHitboxes[nullData1] = { Box = nil, Sphere = nil, Sphyl = nil }
                                                        if nilVal then akOrigHitboxes[nullData1].Box = { X = nilVal.X, Y = nilVal.Y, Z = nilVal.Z } end
                                                        if nullData5 then akOrigHitboxes[nullData1].Sphere = { Radius = nullData5.Radius } end
                                                        if nullData7 then akOrigHitboxes[nullData1].Sphyl = { Radius = nullData7.Radius, Length = nullData7.Length } end
                                                    end

                                                    local akOrigHitboxesItem = akOrigHitboxes[nullData1]

                                                    if akOrigHitboxesItem.Box and nilVal then
                                                        nilVal.X = akOrigHitboxesItem.Box.X * localVal_24Item
                                                        nilVal.Y = akOrigHitboxesItem.Box.Y * localVal_24Item
                                                        nilVal.Z = akOrigHitboxesItem.Box.Z * localVal_24Item
                                                        pcall(function() if type(boxElems.Set) == "function" then boxElems:Set(0, nilVal) else boxElems[1] = nilVal end end)
                                                        if aggGeom then aggGeom.BoxElems = boxElems; nullData3.AggGeom = aggGeom else nullData3.BoxElems = boxElems end
                                                    end

                                                    if akOrigHitboxesItem.Sphere and nullData5 then
                                                        nullData5.Radius = akOrigHitboxesItem.Sphere.Radius * localVal_24Item
                                                        pcall(function() if type(sphereElems.Set) == "function" then sphereElems:Set(0, nullData5) else sphereElems[1] = nullData5 end end)
                                                        if aggGeom then aggGeom.SphereElems = sphereElems; nullData3.AggGeom = aggGeom else nullData3.SphereElems = sphereElems end
                                                    end

                                                    if akOrigHitboxesItem.Sphyl and nullData7 then
                                                        nullData7.Radius = akOrigHitboxesItem.Sphyl.Radius * localVal_24Item
                                                        nullData7.Length = akOrigHitboxesItem.Sphyl.Length * localVal_24Item
                                                        pcall(function() if type(sphylElems.Set) == "function" then sphylElems:Set(0, nullData7) else sphylElems[1] = nullData7 end end)
                                                        if aggGeom then aggGeom.SphylElems = sphylElems; nullData3.AggGeom = aggGeom else nullData3.SphylElems = sphylElems end
                                                    end

                                                end
                                            end
                                        end
                                        pcall(function() 
                                            if mesh.SetPhysicsAsset then mesh:SetPhysicsAsset(physicsAssetOverride) end
                                            mesh.PhysicsAssetOverride = physicsAssetOverride
                                            if mesh.RecreatePhysicsState then mesh:RecreatePhysicsState() end 
                                            if mesh.WakeAllRigidBodies then mesh:WakeAllRigidBodies() end
                                            if mesh.ForceUpdateBones then mesh:ForceUpdateBones() end
                                            if mesh.UpdateBounds then mesh:UpdateBounds() end
                                            mesh.bEnableUpdateRateOptimizations = false
                                        end)

                                    end
                                end)
                                mesh.bIsAKHitboxModded = true
                                mesh.LastHitboxUpdateVersion = _G.MagicUpdateVersion

                            end
                        end
                    else
                        if enemy.bHasAKNativeHPBar and InGameMarkToolsRef then
                            pcall(function()
                                if InGameMarkToolsRef.ClientRemoveMapMark then 
                                    InGameMarkToolsRef.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                    if enemy.NativeDistMark then InGameMarkToolsRef.ClientRemoveMapMark(enemy.NativeDistMark) end
                                else 
                                    InGameMarkToolsRef.HideMapMark(enemy.NativeHPBarMark) 
                                    if enemy.NativeDistMark then InGameMarkToolsRef.HideMapMark(enemy.NativeDistMark) end
                                end
                            end)
                            enemy.NativeHPBarMark = nil
                            enemy.NativeDistMark = nil
                            enemy.bHasAKNativeHPBar = false
                        end
                        pcall(function() if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end end)
                    end
                end
            end
        end
    end)
end




function _G.InitializeSkinBypass()
    pcall(function()
        
        local puffer_tlog_1 = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if puffer_tlog_1 then
            puffer_tlog_1.ReportEvent = function() end
            puffer_tlog_1.ReportDownloadResult = function() end
            puffer_tlog_1.ReportODPAKError = function() end
        end

        
        local AvatarUtilsRef2 = package.loaded["AvatarUtils"]
        if AvatarUtilsRef2 then
            AvatarUtilsRef2.CheckIsWeaponInBlackList = function() return false end
            AvatarUtilsRef2.IsValidAvatar = function() return true end
        end

        
        local SubsystemMgrRef2 = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
        if SubsystemMgrRef2 then
            SubsystemMgrRef2.StartCheck = function() end
            SubsystemMgrRef2.ReportAbnormalFile = function() end
        end
        
        
        local EquipmentExceptionReportRef = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if EquipmentExceptionReportRef then
            EquipmentExceptionReportRef.Report = function() end
        end
    end)
    print('[SkinBypass] Resource & Skin Scanners Bypassed!')
end




function _G.InitializeLogBlocker()
    print('[LogBlocker] Initializing Ultimate Log/Crash/Screenshot Blocker V11...')
    pcall(function()
        local ScreenshotMakerRef = import("ScreenshotMaker")
        if ScreenshotMakerRef then
            ScreenshotMakerRef.MakePicture = function() return "" end
            ScreenshotMakerRef.ReMakePicture = function() return "" end
            ScreenshotMakerRef.HasCaptured = function() return true end
        end

        local TLogRef = package.loaded["TLog"] or _G.TLog
        if TLogRef then
            TLogRef.Info = function() end; TLogRef.Warning = function() end
            TLogRef.Error = function() end; TLogRef.Debug = function() end; TLogRef.Report = function() end
        end

        local CrashSightRef = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSightRef then
            CrashSightRef.ReportException = function() end
            CrashSightRef.SetCustomData = function() end; CrashSightRef.Log = function() end
        end
        
        local GameReportUtilsRef = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GameReportUtilsRef then
            GameReportUtilsRef.BugglyPostExceptionFull = function() return false end
            GameReportUtilsRef.CheckCanBugglyPostException = function() return false end
            GameReportUtilsRef.ReplayReportData = function() end
            GameReportUtilsRef.ReportGameException = function() end
        end

        local ClientToolsReportRef = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if ClientToolsReportRef then
            ClientToolsReportRef.SendReport = function() end; ClientToolsReportRef.SendException = function() end
        end

        local tlog_report_utils_1 = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if tlog_report_utils_1 then
            tlog_report_utils_1.ReportTLogEvent = function() end
        end

        local UGCNewTLogReportRef = package.loaded["client.slua.logic.ugc.UGCNewTLogReport"] or package.loaded["client.slua.data.BasicData.BasicDataTLogReport"]
        if UGCNewTLogReportRef then
            UGCNewTLogReportRef.SendExposeReq = function() end
            UGCNewTLogReportRef.SendInteractionReq = function() end
            UGCNewTLogReportRef.TLogReport = function() end
        end
        
        local logic_ugc_tlog_1 = package.loaded["client.slua.logic.ugc.logic_ugc_tlog"]
        if logic_ugc_tlog_1 then
            logic_ugc_tlog_1.SendModTLog = function() end
            logic_ugc_tlog_1.ReportStay = function() end
        end

        local ClientTLogUtilRef = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"]
        if ClientTLogUtilRef then
            ClientTLogUtilRef.ReportGeneralCountByBRPhase = function() end
            ClientTLogUtilRef.ReportCommonTLogDataByBRPhase = function() end
        end

        local GameplayDataRef3 = require("GameLua.GameCore.Data.GameplayData")
        if GameplayDataRef3 then
            local playerControllerSafety = GameplayDataRef3.GetPlayerControllerSafety and GameplayDataRef3.GetPlayerControllerSafety() or GameplayDataRef3.GetPlayerController()
            if slua.isValid(playerControllerSafety) and playerControllerSafety.ReportCrashKitFeature then
                playerControllerSafety.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException = function() end
            end
        end
    end)
    print('[LogBlocker] Log/Crash/Buggly & Silent Screenshots Bypassed!')
end

function _G.InitializeScannerBlocker()
    print('[ScannerBlocker] Initializing Scanner Blocker V11...')
    pcall(function()
        local SubsystemMgrRef = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        
        if SubsystemMgrRef then
            local aFKReportorSubsystem = SubsystemMgrRef:Get("AFKReportorSubsystem")
            if aFKReportorSubsystem then 
                aFKReportorSubsystem.PlayerHaveAction = function() end; aFKReportorSubsystem.ReportAFK = function() end
            end

            local clientDataStatistcsSubsystem = SubsystemMgrRef:Get("ClientDataStatistcsSubsystem")
            if clientDataStatistcsSubsystem then
                clientDataStatistcsSubsystem.StartToCheck = function() end
                clientDataStatistcsSubsystem.DelayCount = 0
                if clientDataStatistcsSubsystem.ReportPingDelayTimer then
                    clientDataStatistcsSubsystem:RemoveGameTimer(clientDataStatistcsSubsystem.ReportPingDelayTimer)
                    clientDataStatistcsSubsystem.ReportPingDelayTimer = nil
                end
            end

            local avatarExceptionSubsystem = SubsystemMgrRef:Get("AvatarExceptionSubsystem")
            if avatarExceptionSubsystem then
                avatarExceptionSubsystem.ReportException = function() end
                avatarExceptionSubsystem.BindPlayerCharacter = function() end
                avatarExceptionSubsystem.CheckAvatarValid = function() return true end
            end
            
            local shootVerifySubSystemClientSubsystem = SubsystemMgrRef:Get("ShootVerifySubSystemClient")
            if shootVerifySubSystemClientSubsystem then
                shootVerifySubSystemClientSubsystem.ReportVerifyFail = function() end
                shootVerifySubSystemClientSubsystem.OnVerifyFailed = function() end
            end
        end

        local CreativeModeBlueprintLibraryRef = import("CreativeModeBlueprintLibrary")
        if CreativeModeBlueprintLibraryRef then
            CreativeModeBlueprintLibraryRef.MD5HashByteArray = function() return "BYPASSED_MD5_HASH" end
            CreativeModeBlueprintLibraryRef.GetContentDiffData = function() return true, "BYPASSED" end
        end

        local AvatarExceptionPlayerInstRef = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvatarExceptionPlayerInstRef then
            AvatarExceptionPlayerInstRef.CheckAvatarException = function() end
            AvatarExceptionPlayerInstRef.CheckAvatarExceptionOnce = function() end
            AvatarExceptionPlayerInstRef.ReportAvatarException = function() end
            AvatarExceptionPlayerInstRef.CheckSlotMeshVisible = function() return false end
            AvatarExceptionPlayerInstRef.CheckPawnVisible = function() return false end
            AvatarExceptionPlayerInstRef.CheckCanBugglyPostException = function() return false end
        end

        local AvatarCheckerModuleRef = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
        if AvatarCheckerModuleRef then
            AvatarCheckerModuleRef.CheckAvatar = function() return true end
            AvatarCheckerModuleRef.ReportException = function() end
        end

        local logic_memory_warning_1 = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
        if logic_memory_warning_1 then
            logic_memory_warning_1.OnMemoryWarning = function() end
            logic_memory_warning_1.ReportMemoryWarning = function() end
        end

        local logic_store_game_interface_1 = package.loaded["client.slua.logic.store.logic_store_game_interface"]
        if logic_store_game_interface_1 then
            logic_store_game_interface_1.IsStoreGameSupported = function() return true end 
            logic_store_game_interface_1.NotifyGetPGSLoginInfo = function() end 
        end

        local VoiceChatSubsystemRef = package.loaded["GameLua.Mod.BaseMod.Client.Voice.VoiceChatSubsystem"]
        if VoiceChatSubsystemRef then
            VoiceChatSubsystemRef.OnPlayerSubmitComplaint = function() end
        end

        
        local TssSdkRef = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdkRef then
            local onRecvData = TssSdkRef.OnRecvData
            TssSdkRef.OnRecvData = function(data)
                
                if type(data) == "string" and (string.find(data, "report") or string.find(data, "exception")) then
                    return
                end
                if onRecvData then onRecvData(data) end
            end
            
            TssSdkRef.SendReportInfo = function() end
            TssSdkRef.ScanMemory = function() return true end
            TssSdkRef.IsEmulator = function() return false end
            TssSdkRef.GetTssSdkReportInfo = function() return "" end
        end
    end)
    print('[ScannerBlocker] Magic Bullet/MD5 Checks/TSS/OS Scans Bypassed!')
end

function _G.InitializeReplayTelemetryBlocker()
    print('[ReplayBlocker] Initializing Replay Telemetry Blocker V11...')
    pcall(function()
        local SubsystemMgrRef = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        
        local rescueBtnReplayTraceSubsystem = SubsystemMgrRef and SubsystemMgrRef:Get("RescueBtnReplayTraceSubsystem")
        if rescueBtnReplayTraceSubsystem then
            rescueBtnReplayTraceSubsystem.ReportTrace = function() end; rescueBtnReplayTraceSubsystem.StartTickMonitor = function() end
            rescueBtnReplayTraceSubsystem.TickMonitorCheck = function() end; rescueBtnReplayTraceSubsystem.ReportTickMonitorHeartbeat = function() end
        end

        local gameReportSubsystem = SubsystemMgrRef and SubsystemMgrRef:Get("GameReportSubsystem")
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

        local logic_report_replay_1 = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logic_report_replay_1 then
            logic_report_replay_1.ReportReplay = function() end
            logic_report_replay_1.SendReportReq = function() end
        end

        local logic_home_report_1 = package.loaded["client.slua.logic.home.logic_home_report"]
        if logic_home_report_1 then
            logic_home_report_1.ShowInGameReportUI = function() end
            logic_home_report_1.SendReport = function() end
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
        local HiggsBosonComponentRef = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponentRef and HiggsBosonComponentRef.StaticShowSecurityAlertInDev then
            HiggsBosonComponentRef.StaticShowSecurityAlertInDev = function() end
        end
    end)

    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = function(HiggsBosonComponentRef) end
        _G.AvatarCheckCallback.OnReportItemID = function(HiggsBosonComponentRef) end
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(playerController)
            if slua.isValid(playerController) and playerController.HiggsBosonComponent then
                playerController.HiggsBosonComponent:ControlMHActive(0)
                playerController.HiggsBosonComponent.bMHActive = false
            end
        end
    end

    pcall(function()
        local HiggsBosonComponentRef2 = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponentRef2 and HiggsBosonComponentRef2.BlackList then
            for k in pairs(HiggsBosonComponentRef2.BlackList) do HiggsBosonComponentRef2.BlackList[k] = nil end
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
        local STExtraBlueprintFunctionLibraryRef = import("STExtraBlueprintFunctionLibrary")
        if STExtraBlueprintFunctionLibraryRef then
            STExtraBlueprintFunctionLibraryRef.IsDevelopment = function() return false end
        end
    end)
    print('[AntiCheat] Bypass system activated!')
end

function _G.InitializeAntiReport()
    print('[AntiReport] Initializing System...')
    pcall(function()
        local configTable5 = { "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem" }
        local nullData4 = nil
        for _, path in ipairs(configTable5) do
            if package.loaded[path] then nullData4 = package.loaded[path] break end
            local contextData14, bIsLoaded = pcall(require, path)
            if contextData14 and bIsLoaded then nullData4 = bIsLoaded break end
        end
        if nullData4 then
            nullData4.OnInit = function(self) return end
            nullData4._OnPlayerKilledOtherPlayer = function() return end
            nullData4._RecordFatalDamager = function() return end
            nullData4._OnDeathReplayDataWhenFatalDamaged = function() return end
            nullData4._RecordMurdererFromDeathReplayData = function() return end
            nullData4._RecordTeammatePlayerInfo = function() return end
            nullData4._OnBattleResult = function() return end
            nullData4._OnShowQuickReportMutualExclusiveUI = function() return end
            nullData4.GetFatalDamagerMap = function() return {} end
            nullData4.GetCachedTeammateName2InfoMap = function() return {} end
            nullData4.GetTeammateName2InfoMapDuringBattle = function() return {} end
            nullData4.GetCurrentNotInTeamHistoricalTeammateMap = function() return {} end
            nullData4.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
        end
    end)

    pcall(function()
        local configTable5 = { "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem", "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem" }
        local nullData2 = nil
        for _, path in ipairs(configTable5) do
            if package.loaded[path] then nullData2 = package.loaded[path] break end
            local contextData14, bIsLoaded = pcall(require, path)
            if contextData14 and bIsLoaded then nullData2 = bIsLoaded break end
        end
        if nullData2 then
            nullData2.OnInit = function(self) return end
            nullData2._OnNearDeathOrRescued = function() return end
            nullData2._OnCharacterDied = function() return end
            nullData2._OnTeammateDamage = function() return end
            nullData2._OnPlayerSettlementStart = function() return end
            nullData2._AddKnockDownerToBattleResult = function() return end
            nullData2._AddKillerToBattleResult = function() return end
            nullData2._AddTeammateMurderToBattleResult = function() return end
            nullData2._AddFatalDamagerMapToBattleResult = function() return end
            nullData2._AddMLKillerUIDToBattleResult = function() return end
            nullData2._SaveHistoricalTeammateInfo = function() return end
            nullData2._RecordFatalDamager = function() return end
            nullData2._RecordTeammateMurderer = function() return end
        end
    end)

    pcall(function()
        local ReportPlayerUtilsRef = require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
        if ReportPlayerUtilsRef then
            ReportPlayerUtilsRef.RecordFatalDamager = function() return end
            ReportPlayerUtilsRef.IsUsingHistoricalTeammateInfo = function() return false end
            ReportPlayerUtilsRef.IsCharacterDeliverAI = function() return false end
        end
    end)

    pcall(function()
        local SecurityCommonUtilsRef = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if SecurityCommonUtilsRef then
            SecurityCommonUtilsRef.ExtractPlayerBasicInfo = function() return {} end
            SecurityCommonUtilsRef.LogIf = function() return false end
        end
    end)

    pcall(function()
        local ClientQuickReportMaliciousTeammateRef = require("GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate")
        if ClientQuickReportMaliciousTeammateRef then
            ClientQuickReportMaliciousTeammateRef.OnShowMutualExclusiveUI = function() return end
            ClientQuickReportMaliciousTeammateRef.OnHideMutualExclusiveUI = function() return end
        end
    end)
    print('[AntiReport] System Fully Active!')
end

function _G.InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end
        
        local GC = _G.GameplayCallbacks
        print('[GameplayBypass] Hooking GameplayCallbacks...')
        
        local onDSPlayerStateChanged = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            if InPlayerState and string.lower(tostring(InPlayerState)) == "cheatdetected" then return end
            if onDSPlayerStateChanged then return onDSPlayerStateChanged(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
        end

        local function func() return end
        local function localMethod9() return {} end
        local function localMethod3() return nil end
        
        GC.ReportAttackFlow = func
        GC.ReportSecAttackFlow = func
        GC.ReportHurtFlow = func
        GC.ReportFireArms = func
        GC.ReportVerifyInfoFlow = func
        GC.ReportMrpcsFlow = func
        GC.ReportPlayerBehavior = func
        GC.ReportTeammatHurt = func
        GC.ReportMisKillByTeammate = func
        GC.ReportForbitPick = func
        GC.ReportPlayerMoveRoute = func
        GC.ReportPlayerPosition = func
        GC.ReportVehicleMoveFlow = func
        GC.ReportSecTgameMovingFlow = func
        GC.ReportParachuteData = func
        GC.SendTssSdkAntiDataToLobby = func
        GC.SendDSErrorLogToLobby = func
        GC.SendDSErrorLogToLobbyOnece = func
        GC.SendDSHawkEyePatrolLogToLobby = func
        GC.ReportEquipmentFlow = func
        GC.ReportAimFlow = func
        GC.GetWeaponReport = localMethod9
        GC.GetOneWeaponReport = localMethod9
        GC.ReportHeavyWeaponBoxSpawnFlow = func
        GC.ReportHeavyWeaponBoxActivationFlow = func
        GC.ReportHeavyWeaponBoxOpenPlayerFlow = func
        GC.ReportHeavyWeaponBoxItemFlow = func
        GC.ReportPlayersPing = func
        GC.ReportPlayerIP = func
        GC.ReportPlayerFramePingRecord = func
        GC.OnDSConnectionSaturated = func
        GC.ReportDSNetSaturation = func
        GC.ReportNetContinuousSaturate = func
        GC.ReportDSNetRate = func
        GC.SendClientStats = func
        GC.SendServerAvgTickDelta = func
        GC.ReportCircleFlow = func
        GC.ReportDSCircleFlow = func
        GC.ReportJumpFlow = func
        GC.ReportAIStrategyInfo = func
        GC.SendAIDeliveryInfo = func
        GC.ReportDailyTaskInfo = func
        GC.ReportMatchRoomData = func
        GC.SendPlayerSpectatingLog = func
        GC.ReportIDCardProduceFlow = func
        GC.ReportIDCardPickUpFlow = func
        GC.ReportIDCardDestroyFlow = func
        GC.ReportRevivalFlow = func
        GC.ReportGameSetting = func
        GC.ReportGameSettingNew = func
        GC.ReportAntsVoiceTeamCreate = func
        GC.ReportAntsVoiceTeamQuit = func
        GC.ReportCommonInfo = func
        GC.ReportLightweightStat = func
        GC.SendSecTLog = func
        GC.SendDataMiningTLog = func
        GC.SendActivityTLog = func
        GC.GetGeneralTLogData = localMethod3
        
        GC.IsBypassed = true
    end)

    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
            local sendPacket = NetUtil.SendPacket
            local configTable4 = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1,
                ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportTeammateKillConfirmFlow"]=1,
                ["ReportForbiddenPickupFlow"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1,
                ["ReportSecVehicleMoveFlow"]=1, ["ReportSecTgameMovingFlow"]=1, ["report_parachute_data"]=1,
                ["report_character_all_drag"]=1, ["report_parachute_all_drag"]=1, ["report_vehicle_move_drag"]=1,
                ["on_tss_sdk_anti_data"]=1, ["report_unrealnet_exception"]=1, ["ReportPlayerEquipmentInfo"]=1,
                ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["log_shooting_miss"]=1, ["report_heavy_weapon_box_activation_flow"]=1,
                ["report_heavy_weapon_box_item_flow"]=1, ["ReportCircleFlow"]=1, ["report_ds_player_circle_flow"]=1,
                ["ReportJumpFlow"]=1, ["ReportGameStartFlow"]=1, ["ReportGameEndFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_player_frame_ping_record"]=1, ["report_net_saturate"]=1,
                ["report_ds_netsaturate"]=1, ["report_ds_net_continuous_saturate"]=1, ["report_ds_netrate"]=1,
                ["report_unrealnet_clientstats"]=1, ["report_serverstat_avgtickdelta"]=1, ["report_all_players_address"]=1,
                ["report_ai_strategyinfo"]=1, ["ReportAIActionFlow"]=1, ["ReportGenerateMonsterFlow"]=1,
                ["report_ds_match_room_data"]=1, ["SendSpectatingLog"]=1, ["ReportIDCardProduceFlow"]=1,
                ["ReportIDCardPickUpFlow"]=1, ["ReportIDCardDestroyFlow"]=1, ["ReportRevivalFlow"]=1,
                ["ReportGameSetting"]=1, ["ReportGameSettingNew"]=1, ["ReportAntsVoiceTeamCreate"]=1,
                ["ReportAntsVoiceTeamQuit"]=1, ["report_common_info"]=1, ["report_common_battle_info"]=1,
                ["report_client_scan_result"]=1, ["tss_sdk_report"]=1, ["report_memory_exception"]=1,
                ["report_avatar_exception"]=1, ["report_ui_state"]=1, ["report_hit_reg_fail"]=1,
                ["report_character_state"]=1, ["report_vehicle_exception"]=1, ["report_camera_exception"]=1,
                ["ReportPlayerControllerStateChanged"]=1, ["ReportAvatarFlow"]=1,
                
                
                ["send_ugc_report_uni_mod_expose_req"]=1, 
                ["send_ugc_report_uni_mod_interactive_req"]=1,
            }
            
            NetUtil.SendPacket = function(packetName, ...)
                if configTable4[packetName] then return end
                return sendPacket(packetName, ...)
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
        local onDSPlayerStateChanged = GC.OnDSPlayerStateChanged

        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            local lowerStrRef = InPlayerState and string.lower(tostring(InPlayerState)) or ""
            local configTable2 = {
                ["cheatdetected"] = true, ["connectionlost"] = true,
                ["connectiontimeout"] = true, ["connectionexception"] = true,
                ["netdrivererror"] = true
            }
            if configTable2[lowerStrRef] then return end
            if onDSPlayerStateChanged then
                pcall(onDSPlayerStateChanged, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
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





function NetworkRPC:HandleOnMovementModeChangedNew()
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
    local EMovementModeRef = import("EMovementMode")
    if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementModeRef.MOVE_Swimming and self:CheckBaseIsMoveable() then
        print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
        self.CharacterMovement:SetBase(nil, "", true)
    end
    if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementModeRef.MOVE_Walking and managerRef.UI_Config_InGame.ParachuteOpenUI then
        print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
        managerRef.CloseUI(managerRef.UI_Config_InGame.ParachuteOpenUI)
    end
end

function NetworkRPC:HandleOnAttachedToVehicle(currentVehicleRef)
    if not slua.isValid(currentVehicleRef) then
        return
    end
    print(bWriteLog and string.format("BRPlayerCharacterBase:HandleOnAttachedToVehicle", Game:GetObjName(currentVehicleRef)))
    if self.Role == ENetRole.ROLE_SimulatedProxy then
        self:ClearAttachToVehicleTimer()
        self.nUpdatePlayerAttachToVehicleCount = 0
        self.nUpdatePlayerAttachToVehicleTimer = self:AddGameTimer(5, true, function()
            if slua.isValid(self.Object) and slua.isValid(currentVehicleRef) then
                self:UpdatePlayerAttachToVehicle(currentVehicleRef)
            end
        end)
        self.nFixMeshContainerTimer = self:AddGameTimer(3, true, function()
            if slua.isValid(self.Object) and slua.isValid(currentVehicleRef) then
                self:FixMeshContainerOffsetIfNeeded(currentVehicleRef)
            end
        end)
    end
end

function NetworkRPC:HandleOnDetachedFromVehicle(uLastVehicle)
    if not slua.isValid(uLastVehicle) then
        return
    end
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnDetachedFromVehicle", uLastVehicle)
    if self.Role == ENetRole.ROLE_SimulatedProxy then
        self:ClearAttachToVehicleTimer()
        self.nUpdatePlayerAttachToVehicleCount = 0
    end
end

function NetworkRPC:UpdatePlayerAttachToVehicle(currentVehicleRef)
    if not slua.isValid(self.Object) or not slua.isValid(currentVehicleRef) then return end
    if not (slua.isValid(self.CapsuleComponent) and slua.isValid(self.Mesh)) or not slua.isValid(self.MeshContainer) then return end
    if not slua.isValid(self:GetCurrentVehicle()) then return end
    if Game:IsDriver(self.Object) then return end
    if not self.nUpdatePlayerAttachToVehicleCount then self.nUpdatePlayerAttachToVehicleCount = 0 end
    
    local ESTEPoseStateRef = import("ESTEPoseState")
    local stand = self.PoseState == ESTEPoseStateRef.Stand
    local relativeTransform = self.CapsuleComponent:GetRelativeTransform():GetLocation()
    local relativeTransformRef2 = self.Mesh:GetRelativeTransform():GetLocation()
    local relativeTransformRef = self.MeshContainer:GetRelativeTransform():GetLocation().Z
    local scaledCapsuleRadius = self.CapsuleComponent:GetScaledCapsuleRadius()
    local scaledCapsuleHalfHeight = self.CapsuleComponent:GetScaledCapsuleHalfHeight()
    local standHalfHeight = -1 * self.StandHalfHeight
    local standRadius = self.StandRadius
    local standHalfHeightRef = self.StandHalfHeight
    local vector = FVector(0, 0, 0)
    local vectorData2 = FVector(0, 0, self.StandHalfHeight)
    local tolerance = 1.0
    local isLocValid = relativeTransform:Equals(vectorData2, tolerance)
    local isRelativeLocValid = relativeTransformRef2:Equals(vector, tolerance)
    local absVal = tolerance > math.abs(relativeTransformRef - standHalfHeight)
    local absValRef2 = tolerance > math.abs(scaledCapsuleRadius - standRadius)
    local absValRef = tolerance > math.abs(scaledCapsuleHalfHeight - standHalfHeightRef)
    local isValidPosition = stand and isLocValid and isRelativeLocValid and absVal and absValRef2 and absValRef
    
    if not isValidPosition then self.nUpdatePlayerAttachToVehicleCount = self.nUpdatePlayerAttachToVehicleCount + 1 else self.nUpdatePlayerAttachToVehicleCount = 0 end
    
    if self.nUpdatePlayerAttachToVehicleCount >= 3 and not isValidPosition then
        local playerControllerSafety = GameplayDataRef3.GetPlayerController()
        if playerControllerSafety.ReportCrashKitFeature and playerControllerSafety.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException then
            local crashReportMsg = string.format("VehicleShapeType:%s PlayerKey:%s. Check Result:%d %d %d %d %d %d. Capsule.RelativeLoc:%s Capsule.Radius:%s Capsule.HalfHeight:%s Mesh.RelativeLoc:%s MeshContainer.RelativeLocZ:%s", tostring(currentVehicleRef.VehicleShapeType), tostring(self.PlayerKey), stand and 1 or 0, isLocValid and 1 or 0, isRelativeLocValid and 1 or 0, absVal and 1 or 0, absValRef2 and 1 or 0, absValRef and 1 or 0, relativeTransform:ToString(), tostring(scaledCapsuleRadius), tostring(scaledCapsuleHalfHeight), relativeTransformRef2:ToString(), tostring(relativeTransformRef))
            playerControllerSafety.ReportCrashKitFeature:ReportCharacterAttachedOnVehicleException(crashReportMsg)
        end
        self.nUpdatePlayerAttachToVehicleCount = 0
    end
end

function NetworkRPC:FixMeshContainerOffsetIfNeeded(currentVehicleRef)
    if not slua.isValid(self.Object) or not slua.isValid(currentVehicleRef) then return end
    if not slua.isValid(self.MeshContainer) then return end
    if not slua.isValid(self:GetCurrentVehicle()) then return end
    if Game:IsDriver(self.Object) then return end
    local tolerance = 1.0
    local standHalfHeight = -1 * self.StandHalfHeight
    local relativeTransformRef = self.MeshContainer:GetRelativeTransform():GetLocation().Z
    if tolerance <= math.abs(relativeTransformRef - standHalfHeight) then
        self:SetMeshContainerOffsetZ(standHalfHeight)
    end
end

function NetworkRPC:ClearAttachToVehicleTimer()
    if self.nUpdatePlayerAttachToVehicleTimer then
        self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
        self.nUpdatePlayerAttachToVehicleTimer = nil
    end
    if self.nFixMeshContainerTimer then
        self:RemoveGameTimer(self.nFixMeshContainerTimer)
        self.nFixMeshContainerTimer = nil
    end
end

function NetworkRPC:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
    NetworkRPC.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
    if self.Object ~= uPawn then return end
    if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
        local playerControllerSafety = self:GetPlayerControllerSafety()
        if slua.isValid(playerControllerSafety) then
            playerControllerSafety:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
        end
    end
end

function NetworkRPC:OnPawnStateChange(PawnState)
    local EPawnStateRef = import("EPawnState")
    if PawnState == EPawnStateRef.SwitchPP then
        local playerControllerSafety = self:GetPlayerControllerSafety()
        if slua.isValid(playerControllerSafety) then
            playerControllerSafety:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
        end
    end
end

function NetworkRPC:HandleFinishedState()
    if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
        self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
    end
end

function NetworkRPC:CheckAddCheckFallingDistanceComponent()
    if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
        local EGameModeTypeRef = import("EGameModeType")
        local MatchModeIdsConfigRef = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")
        local gameModeType = CGameMode.GameModeType
        local numericVal2 = tonumber(CGameState.GameModeID)
        local eTypicalGameMode = gameModeType == EGameModeTypeRef.ETypicalGameMode or gameModeType == EGameModeTypeRef.EFourInOneGameMode or gameModeType == EGameModeTypeRef.EHeavyWeaponGameMode
        local notMatchMode = not MatchModeIdsConfigRef[numericVal2]
        return eTypicalGameMode and notMatchMode
    end
    return false
end

function NetworkRPC:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
    NetworkRPC.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
    local EParachuteStateRef = import("EParachuteState")
    if not Client then
        local playerControllerSafetyRef = self:GetPlayerControllerSafety()
        if slua.isValid(playerControllerSafetyRef) and playerControllerSafetyRef.CheckParachuteOpenFeature then
            if NewParachuteState == EParachuteStateRef.PS_Opening then
                if playerControllerSafetyRef.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
                    playerControllerSafetyRef.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
                end
            elseif NewParachuteState == EParachuteStateRef.PS_None then
                if playerControllerSafetyRef.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
                    playerControllerSafetyRef.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
                end
                if playerControllerSafetyRef.CheckParachuteOpenFeature.ClearTimerAndState then
                    playerControllerSafetyRef.CheckParachuteOpenFeature:ClearTimerAndState()
                end
            end
        end
    end
end

function NetworkRPC:OnLanded()
    if self.HandleOnLanded then self:HandleOnLanded(-1) end
    if not Client then
        local playerControllerSafetyRef = self:GetPlayerControllerSafety()
        if slua.isValid(playerControllerSafetyRef) and playerControllerSafetyRef.CheckParachuteOpenFeature then
            if playerControllerSafetyRef.CheckParachuteOpenFeature.ClearTimerAndState then
                playerControllerSafetyRef.CheckParachuteOpenFeature:ClearTimerAndState()
            end
            if playerControllerSafetyRef.CheckParachuteOpenFeature.ResetCheckShowUI then
                playerControllerSafetyRef.CheckParachuteOpenFeature:ResetCheckShowUI()
            end
        end
    end
end

function NetworkRPC:IsWarGameMode()
    local GameplayDataRef3 = require("GameLua.GameCore.Data.GameplayData")
    local gameState = GameplayDataRef3:GetGameState()
    local STExtraGameStateBaseRef = import("STExtraGameStateBase")
    if slua.isValid(gameState) and Game:IsClassOf(gameState, STExtraGameStateBaseRef) then
        local EGameModeTypeRef = import("EGameModeType")
        return gameState.GameModeType == EGameModeTypeRef.EWarGameMode
    else
        return false
    end
end

function NetworkRPC:BPOnRecycled()
    if Client then self:ResetMeshRelativeLocationAndRotation() end
end

function NetworkRPC:BPOnRespawned()
    if Client then self:ResetMeshRelativeLocationAndRotation() end
end

function NetworkRPC:ReceiveOnRecycle()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        GameplayDataRef3.RemoveCharacter(self.Object)
    end
end

function NetworkRPC:ReceiveOnSpawn()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        GameplayDataRef3.AddCharacter(self.Object)
    end
end

function NetworkRPC:ResetMeshRelativeLocationAndRotation()
    if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
        local rotator = FRotator(0, -90, 0)
        local vectorData1 = FVector(0, 0, 0)
        if self.Mesh.K2_SetRelativeRotation then
            self.Mesh:K2_SetRelativeRotation(rotator, false, nil, false)
        end
        self:CacheInitialMeshOffset(vectorData1, rotator)
    end
end

function NetworkRPC:BPOnMissPlayerDamageRecord()
end

function NetworkRPC:PreAttachedToVehicle()
    local KismetSystemLibraryRef = import("KismetSystemLibrary")
    local bIsDedicatedServer = KismetSystemLibraryRef.IsDedicatedServer(self)
    if not bIsDedicatedServer then return end
    local playerControllerSafety = self:GetPlayerControllerSafety()
    if not slua.isValid(playerControllerSafety) then return end
    local characterAvatarComp2_BP = self.CharacterAvatarComp2_BP
    if not slua.isValid(characterAvatarComp2_BP) then return end
    local CommerAvatarDataUtilRef = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
    local commerAvatarData = CommerAvatarDataUtilRef:ChangeVehicleSkinByClothes(playerControllerSafety, characterAvatarComp2_BP)
    local ESTExtraVehicleShapeTypeRef = import("ESTExtraVehicleShapeType")
    if commerAvatarData then
        local AvatarUtilsRef = import("AvatarUtils")
        if AvatarUtilsRef.GetVehicleShapeBySkinID(commerAvatarData) == ESTExtraVehicleShapeTypeRef.VST_Horse then
            local playerStateSafetyRef = self:GetPlayerStateSafety()
            if slua.isValid(playerStateSafetyRef) then
                playerStateSafetyRef:AddGeneralCount(468, 1, false)
            end
        end
    end
end

function NetworkRPC:ClientRPC_TriggerHighlightMoment(Type, Param)
    EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
end

function NetworkRPC:ParachuteJump()
    local playerControllerSafety = self:GetControllerSafety()
    if slua.isValid(playerControllerSafety) then
        if not self:GetEnsure() then
            local EStateTypeRef = import("EStateType")
            if playerControllerSafety:GetCurrentStateType() ~= EStateTypeRef.State_ParachuteJump and playerControllerSafety:GetCurrentStateType() ~= EStateTypeRef.State_ParachuteOpen then
                local ESTEPoseStateRef = import("ESTEPoseState")
                self:SwitchPoseState(ESTEPoseStateRef.Stand, true, true, true, false)
                playerControllerSafety:ReInitParachuteItem()
                playerControllerSafety:ServerChangeStatePC(EStateTypeRef.State_ParachuteJump)
            end
        else
            EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
        end
    end
end

function NetworkRPC:OnMovementBaseChangedEvent(playerCharacterSafety, uNewMovementBase, uOldMovementBase)
    if playerCharacterSafety ~= self.Object then return end
    local medievalCraneFromBase = self:GetMedievalCraneFromBase(uNewMovementBase)
    if medievalCraneFromBase and medievalCraneFromBase.AddCharacter then
        medievalCraneFromBase:AddCharacter(self.Object)
    else
        medievalCraneFromBase = self:GetMedievalCraneFromBase(uOldMovementBase)
        if medievalCraneFromBase and medievalCraneFromBase.RemoveCharacter then
            medievalCraneFromBase:RemoveCharacter(self.Object)
        end
    end
end

function NetworkRPC:GetMedievalCraneFromBase(Base)
    if not slua.isValid(Base) or not Base.GetOwner then return end
    local owner = Base:GetOwner()
    if not slua.isValid(owner) then return end
    if not owner.AddCharacter then return end
    return owner
end

function NetworkRPC:CheckForbidFlaregun()
    local playerStateSafety = self:GetPlayerStateSafety()
    if not slua.isValid(playerStateSafety) then return false end
    if playerStateSafety.CanUseFlaregun == false and self:IsLocallyControlled() then
        local playerControllerSafety = self:GetPlayerControllerSafety()
        if slua.isValid(playerControllerSafety) then
            playerControllerSafety:DisplayGameTipWithMsgID(48532)
        end
    end
    return not playerStateSafety.CanUseFlaregun
end

function NetworkRPC:ServerRPC_NearDeathGiveupRescue()
    self:HandleNearDeathGiveupRescue()
end

function NetworkRPC:HandleNearDeathGiveupRescue()
    local nearDeatchComponent = self.NearDeatchComponent
    if self:IsNearDeath() and slua.isValid(nearDeatchComponent) and self.bCanNearDeathGiveup == true then
        local playerStateSafety = self:GetPlayerStateSafety()
        if slua.isValid(playerStateSafety) then playerStateSafety:AddGeneralCount(1613, 1, false) end
        nearDeatchComponent:TriggerGotoDieExplictly(self.Object)
    end
end

function NetworkRPC:RPC_Server_GmPlayAction(actionId)
    local STExtraBlueprintFunctionLibraryRef = import("STExtraBlueprintFunctionLibrary")
    if STExtraBlueprintFunctionLibraryRef.IsDevelopment() then
        self:MulticastRPC_GmPlayAction(actionId)
    end
end

function NetworkRPC:MulticastRPC_GmPlayAction(actionId)
    if not Client then return end
    local playEmoteComponent = self:GetPlayEmoteComponent()
    if not slua.isValid(playEmoteComponent) then return end
    local log_filter_1 = require("common.log_filter")
    log_filter_1.SetLogTreeEnable(true)
    local emoteData = CDataTable.GetTableData("EmoteBPTable", actionId)
    if not emoteData then return end
    local pathRef = emoteData.Path
    local loadedObject = slua.loadObject(pathRef)
    local softObjectPath = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
    local loadedEmoteObj = loadedObject()
    playEmoteComponent:OnLoadEmoteAssetBegin(loadedEmoteObj, actionId, softObjectPath, "")
    local tb = FuncUtil.LuaArrayToTable(softObjectPath)
    local asset_util_1 = require("common.asset_util")
    local callback = function() playEmoteComponent:OnLoadEmoteAssetEnd(loadedEmoteObj, actionId, 0) end
    asset_util_1.GetAssetsArrayAsyncParallel(tb, callback)
end

function NetworkRPC:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
    if slua.isValid(self.ParachuteComponent) then
        self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
    end
end

function NetworkRPC:OnPlayerEnterCarryBoxState()
    self.Super:OnPlayerEnterCarryBoxState()
    if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState() end
end

function NetworkRPC:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt) end
end

function NetworkRPC:ServerRPC_CarryDeadBox(uInDeadBox)
    if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
    end
end

function NetworkRPC:SetAreaID(AreaID)
    self:SetAttrValue("AreaID", AreaID, -1)
end

function NetworkRPC:GetAreaID()
    return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function NetworkRPC:CannotChangeIntoPetSpectator()
    return self.bCannotChangeIntoPetSpectator
end

function NetworkRPC:DoModChangeToBT()
    if self:HasState(EPawnStateRef.SpecialSuit) then
        self:TriggerEntrySkillWithID(4301101, true)
    end
end

function NetworkRPC:SwitchCameraToParachuteOpening()
    self.Super:SwitchCameraToParachuteOpening()
    if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
        self.ParachuteFormation:OverlayFormationCameraParams()
    end
end

function NetworkRPC:SwitchCameraToParachuteFalling()
    self.Super:SwitchCameraToParachuteFalling()
    if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
        self.ParachuteFormation:OverlayFormationCameraParams()
    end
end

function NetworkRPC:SwitchCameraToNormal()
    self.Super:SwitchCameraToNormal()
    if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
        self.ParachuteFormation:OnLandingClearFormationCamera()
    end
end

function NetworkRPC:SwitchWeaponCheck(Slot, IgnoreState)
    if self:HasState(EPawnStateRef.AttachToOther) then
        local weaponBySlot = self:GetWeaponBySlot(Slot)
        if slua.isValid(weaponBySlot) then
            local weaponIDRef3 = weaponBySlot:GetWeaponID()
            local attachToOtherConfig = GamePlayToolsRef.GetCurrentConfig("AttachToOtherConfig")
            if attachToOtherConfig and attachToOtherConfig.CheckIsWeaponInBlackList and attachToOtherConfig.CheckIsWeaponInBlackList(weaponIDRef3) then
                local playerControllerSafety = self:GetPlayerControllerSafety()
                if Client and slua.isValid(playerControllerSafety) and playerControllerSafety.Role == ENetRole.ROLE_AutonomousProxy then
                    playerControllerSafety:DisplayGameTipWithMsgID(47306)
                end
                return false
            end
        end
    end
    return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

local function localMethod8()
    pcall(function()
        
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

    
    local GameplayDataRef3 = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
    if not GameplayDataRef3 then return end

    pcall(function()
        local GameplayDataRef = GameplayDataRef3.GetPlayerCharacter and GameplayDataRef3.GetPlayerCharacter()
        if slua.isValid(GameplayDataRef) then
            if NetworkRPC.StartAdvancedSystems then
                GameplayDataRef.StartAdvancedSystems = NetworkRPC.StartAdvancedSystems
            end
            
            if GameplayDataRef.bHasShownDevNotice == nil then
                GameplayDataRef.bHasShownDevNotice = false 
                GameplayDataRef.bHasShownExpiredNotice = false 
                GameplayDataRef.bIsDeadFlag = false
                GameplayDataRef.bForceWeaponMod = true
                GameplayDataRef.AK_NativeESP_Ready = false
            end
            
            if type(GameplayDataRef.StartAdvancedSystems) == "function" then
                pcall(function() 
                    GameplayDataRef:StartAdvancedSystems() 
                end)
            end
        end
    end)
end


pcall(function() 
    require("common.time_ticker").AddTimerOnce(0.5, localMethod8) 
end)

local classRef1 = require("class")
local CharacterBaseRef = require("GameLua.GameCore.Framework.CharacterBase")
local characterBase_1Class = classRef1(CharacterBaseRef, nil, NetworkRPC)

return require("combine_class").DeclareFeature(characterBase_1Class, {
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