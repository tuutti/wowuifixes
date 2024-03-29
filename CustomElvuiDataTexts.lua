local E, L, V, P, G = unpack(ElvUI); 
local CustomElvuiDataTexts = E:NewModule('CustomElvuiDataTexts', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0'); 
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local addonName, addonTable = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2

local DT = E:GetModule('DataTexts')

--Lua functions
local format, strjoin = format, strjoin
--WoW API / Variables
local GetLootSpecialization = GetLootSpecialization
local GetNumSpecializations = GetNumSpecializations
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpecializationInfoByID = GetSpecializationInfoByID
local HideUIPanel = HideUIPanel
local IsShiftKeyDown = IsShiftKeyDown
local SetLootSpecialization = SetLootSpecialization
local SetSpecialization = SetSpecialization
local ShowUIPanel = ShowUIPanel
local LOOT = LOOT
local LOOT_SPECIALIZATION_DEFAULT = LOOT_SPECIALIZATION_DEFAULT
local SELECT_LOOT_SPECIALIZATION = SELECT_LOOT_SPECIALIZATION

--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: PlayerTalentFrame, LoadAddOn

local lastPanel, active
local displayString = '';
local activeString = strjoin("", "|cff00FF00" , ACTIVE_PETS, "|r")
local inactiveString = strjoin("", "|cffFF0000", FACTION_INACTIVE, "|r")
local menuFrame = CreateFrame("Frame", "LootSpecializationDatatextClickMenu", E.UIParent, "UIDropDownMenuTemplate")
local menuList = {
	{ text = SELECT_LOOT_SPECIALIZATION, isTitle = true, notCheckable = true },
	{ notCheckable = true, func = function() SetLootSpecialization(0) end },
	{ notCheckable = true },
	{ notCheckable = true },
	{ notCheckable = true },
	{ notCheckable = true }
}
local specList = {
	{ text = SPECIALIZATION, isTitle = true, notCheckable = true },
	{ notCheckable = true },
	{ notCheckable = true },
	{ notCheckable = true },
	{ notCheckable = true }
}

local function OnEvent(self)
	lastPanel = self

	local specIndex = GetSpecialization();
	if not specIndex then
		self.text:SetText('N/A')
		return
	end

	active = specIndex

	local spec, loot, text = '', 'N/A', LOOT
	local specialization = GetLootSpecialization()

	local _, _, _, specTex = GetSpecializationInfo(specIndex)
	if specTex then
		spec = format('|T%s:14:14:0:0:64:64:4:60:4:60|t', specTex)
	end

	if specialization == 0 then
		loot, text = spec, '|cFF54FF00'..text..'|r'
	else
		local _, _, _, texture = GetSpecializationInfoByID(specialization);
		if texture then
			loot = format('|T%s:14:14:0:0:64:64:4:60:4:60|t', texture)
		end
	end

	self.text:SetFormattedText('%s  %s', L["Loot"], loot)
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	for i = 1, GetNumSpecializations() do
		local _, name = GetSpecializationInfo(i);
		if name then
			DT.tooltip:AddLine(strjoin(" ", format(displayString, name), (i == active and activeString or inactiveString)),1,1,1)
		end
	end

	DT.tooltip:AddLine(' ')

	local specialization = GetLootSpecialization()
	if specialization == 0 then
		local specIndex = GetSpecialization()
		if specIndex then
			local _, name = GetSpecializationInfo(specIndex);
			DT.tooltip:AddLine(format('|cffFFFFFF%s:|r %s', SELECT_LOOT_SPECIALIZATION, format(LOOT_SPECIALIZATION_DEFAULT, name)))
		end
	else
		local specID, name = GetSpecializationInfoByID(specialization);
		if specID then
			DT.tooltip:AddLine(format('|cffFFFFFF%s:|r %s', SELECT_LOOT_SPECIALIZATION, name))
		end
	end

	DT.tooltip:AddLine(' ')
	DT.tooltip:AddLine(L["|cffFFFFFFLeft Click:|r Change Talent Specialization"])
	DT.tooltip:AddLine(L["|cffFFFFFFShift + Left Click:|r Show Talent Specialization UI"])
	DT.tooltip:AddLine(L["|cffFFFFFFRight Click:|r Change Loot Specialization"])

	DT.tooltip:Show()
end

local function OnClick(self, button)
	local specIndex = GetSpecialization();
	if not specIndex then return end

	if button == "LeftButton" then
		DT.tooltip:Hide()
		if not PlayerTalentFrame then
			LoadAddOn("Blizzard_TalentUI")
		end
		if IsShiftKeyDown() then
			if not PlayerTalentFrame:IsShown() then
				ShowUIPanel(PlayerTalentFrame)
			else
				HideUIPanel(PlayerTalentFrame)
			end
		else
			for index = 1, 4 do
				local id, name, _, texture = GetSpecializationInfo(index);
				if ( id ) then
					specList[index + 1].text = format('|T%s:14:14:0:0:64:64:4:60:4:60|t  %s', texture, name)
					specList[index + 1].func = function() SetSpecialization(index) end
				else
					specList[index + 1] = nil
				end
			end
			_G.EasyMenu(specList, menuFrame, "cursor", -15, -7, "MENU", 2)
		end
	else
		DT.tooltip:Hide()
		local _, specName = GetSpecializationInfo(specIndex);
		menuList[2].text = format(LOOT_SPECIALIZATION_DEFAULT, specName);

		for index = 1, 4 do
			local id, name = GetSpecializationInfo(index);
			if ( id ) then
				menuList[index + 2].text = name
				menuList[index + 2].func = function() SetLootSpecialization(id) end
			else
				menuList[index + 2] = nil
			end
		end

		_G.EasyMenu(menuList, menuFrame, "cursor", -15, -7, "MENU", 2)
	end
end

local function ValueColorUpdate()
	displayString = strjoin("", "|cffFFFFFF%s:|r ")

	if lastPanel ~= nil then
		OnEvent(lastPanel)
	end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext('LootSpec',{"PLAYER_ENTERING_WORLD", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", 'PLAYER_LOOT_SPEC_UPDATED'}, OnEvent, nil, OnClick, OnEnter, nil, L["LootSpec"])

function CustomElvuiDataTexts:Initialize()
	EP:RegisterPlugin(addonName, CustomElvuiDataTexts.InsertOptions)
end

E:RegisterModule(CustomElvuiDataTexts:GetName()) 
