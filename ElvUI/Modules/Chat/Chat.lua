local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local CH = E:GetModule("Chat")
local Skins = E:GetModule("Skins")
local LSM = E.Libs.LSM

--Lua functions
local _G = _G
local time, difftime = time, difftime
local pairs, ipairs, unpack, select, tostring, pcall, next, tonumber, type = pairs, ipairs, unpack, select, tostring, pcall, next, tonumber, type
local tinsert, tremove, tconcat, wipe = table.insert, table.remove, table.concat, table.wipe
local gsub, find, gmatch, format, strtrim = string.gsub, string.find, string.gmatch, string.format, string.trim
local strlower, strmatch, strsub, strlen, strupper = strlower, strmatch, strsub, strlen, strupper
--WoW API / Variables
local BetterDate = BetterDate
local ChatEdit_ActivateChat = ChatEdit_ActivateChat
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local ChatEdit_ParseText = ChatEdit_ParseText
local ChatEdit_SetLastTellTarget = ChatEdit_SetLastTellTarget
local ChatFrame_ConfigEventHandler = ChatFrame_ConfigEventHandler
local ChatFrame_SendTell = ChatFrame_SendTell
local ChatFrame_SystemEventHandler = ChatFrame_SystemEventHandler
local ChatHistory_GetAccessID = ChatHistory_GetAccessID
local Chat_GetChatCategory = Chat_GetChatCategory
local CreateFrame = CreateFrame
local FCFManager_ShouldSuppressMessage = FCFManager_ShouldSuppressMessage
local FCFTab_UpdateAlpha = FCFTab_UpdateAlpha
local FCF_GetChatWindowInfo = FCF_GetChatWindowInfo
local FCF_GetCurrentChatFrame = FCF_GetCurrentChatFrame
local FCF_SavePositionAndDimensions = FCF_SavePositionAndDimensions
local FCF_SetChatWindowFontSize = FCF_SetChatWindowFontSize
local FCF_StartAlertFlash = FCF_StartAlertFlash
local FloatingChatFrame_OnEvent = FloatingChatFrame_OnEvent
local GetChannelName = GetChannelName
local GetGuildRosterMOTD = GetGuildRosterMOTD
local GetMouseFocus = GetMouseFocus
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetTime = GetTime
local GMChatFrame_IsGM = GMChatFrame_IsGM
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local IsAltKeyDown = IsAltKeyDown
local IsInInstance = IsInInstance
local IsMouseButtonDown = IsMouseButtonDown
local IsShiftKeyDown = IsShiftKeyDown
local PlaySound = PlaySound
local PlaySoundFile = PlaySoundFile
local ScrollFrameTemplate_OnMouseWheel = ScrollFrameTemplate_OnMouseWheel
local ShowUIPanel, HideUIPanel = ShowUIPanel, HideUIPanel
local StaticPopup_Visible = StaticPopup_Visible
local ToggleFrame = ToggleFrame
local UnitName = UnitName
local AFK = AFK
local CHAT_BN_CONVERSATION_GET_LINK = CHAT_BN_CONVERSATION_GET_LINK
local CHAT_FILTERED = CHAT_FILTERED
local CHAT_FRAMES = CHAT_FRAMES
local CHAT_IGNORED = CHAT_IGNORED
local CHAT_OPTIONS = CHAT_OPTIONS
local CHAT_RESTRICTED = CHAT_RESTRICTED
local CHAT_TELL_ALERT_TIME = CHAT_TELL_ALERT_TIME
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local DND = DND
local ICON_LIST = ICON_LIST
local ICON_TAG_LIST = ICON_TAG_LIST
local MAX_WOW_CHAT_CHANNELS = MAX_WOW_CHAT_CHANNELS
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local RAID_WARNING = RAID_WARNING

local CreatedFrames = 0
local msgList, msgCount, msgTime = {}, {}, {}

local DEFAULT_STRINGS = {
	BATTLEGROUND = L["BG"],
	GUILD = L["G"],
	PARTY = L["P"],
	RAID = L["R"],
	OFFICER = L["O"],
	BATTLEGROUND_LEADER = L["BGL"],
	PARTY_LEADER = L["PL"],
	RAID_LEADER = L["RL"],
}

local hyperlinkTypes = {
	["item"] = true,
	["spell"] = true,
	["unit"] = true,
	["quest"] = true,
	["enchant"] = true,
	["achievement"] = true,
	["instancelock"] = true,
	["talent"] = true,
	["glyph"] = true,
}

local tabTexs = {
	"",
	"Selected",
	"Highlight"
}

CH.Smileys = {}
function CH:RemoveSmiley(key)
	if key and (type(key) == "string") then
		CH.Smileys[key] = nil
	end
end

function CH:AddSmiley(key, texture)
	if key and (type(key) == "string" and not find(key, ":%%", 1, true)) and texture then
		CH.Smileys[key] = texture
	end
end

local specialChatIcons
do --this can save some main file locals
	local y = ":13:25"
	--local ElvMelon		= E:TextureString(E.Media.ChatLogos.ElvMelon,y)
	--local ElvRainbow	= E:TextureString(E.Media.ChatLogos.ElvRainbow,y)
	--local ElvRed		= E:TextureString(E.Media.ChatLogos.ElvRed,y)
	--local ElvOrange		= E:TextureString(E.Media.ChatLogos.ElvOrange,y)
	--local ElvYellow		= E:TextureString(E.Media.ChatLogos.ElvYellow,y)
	--local ElvGreen		= E:TextureString(E.Media.ChatLogos.ElvGreen,y)
	--local ElvBlue		= E:TextureString(E.Media.ChatLogos.ElvBlue,y)
	--local ElvPurple		= E:TextureString(E.Media.ChatLogos.ElvPurple,y)
	local ElvPink		= E:TextureString(E.Media.ChatLogos.ElvPink,y)

	specialChatIcons = {
		["Крольчонак-x100"] = ElvPink,
	}
end

CH.Keywords = {}
CH.ClassNames = {}

local function ChatFrame_OnMouseScroll(frame, delta)
	local numScrollMessages = CH.db.numScrollMessages or 3
	if delta < 0 then
		if IsShiftKeyDown() then
			frame:ScrollToBottom()
		elseif IsAltKeyDown() then
			frame:ScrollDown()
		else
			for _ = 1, numScrollMessages do
				frame:ScrollDown()
			end
		end
	elseif delta > 0 then
		if IsShiftKeyDown() then
			frame:ScrollToTop()
		elseif IsAltKeyDown() then
			frame:ScrollUp()
		else
			for _ = 1, numScrollMessages do
				frame:ScrollUp()
			end
		end

		if CH.db.scrollDownInterval ~= 0 then
			if frame.ScrollTimer then
				CH:CancelTimer(frame.ScrollTimer, true)
			end

			frame.ScrollTimer = CH:ScheduleTimer("ScrollToBottom", CH.db.scrollDownInterval, frame)
		end
	end
end

function CH:GetGroupDistribution()
	local inInstance, kind = IsInInstance()
	if inInstance and (kind == "pvp") then
		return "/bg "
	end
	if GetNumRaidMembers() > 0 then
		return "/ra "
	end
	if GetNumPartyMembers() > 0 then
		return "/p "
	end
	return "/s "
end

function CH:InsertEmotions(msg)
	for word in gmatch(msg, "%s-%S+%s*") do
		word = strtrim(word)
		local pattern = gsub(word, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
		local emoji = CH.Smileys[pattern]
		if emoji and strmatch(msg, "[%s%p]-"..pattern.."[%s%p]*") then
			local base64 = E.Libs.Base64:Encode(word) -- btw keep `|h|cFFffffff|r|h` as it is
			msg = gsub(msg, "([%s%p]-)"..pattern.."([%s%p]*)", (base64 and ("%1|Helvmoji:%%"..base64.."|h|cFFffffff|r|h") or "%1")..emoji.."%2")
		end
	end

	return msg
end

function CH:GetSmileyReplacementText(msg)
	if not msg or not self.db.emotionIcons or find(msg, "/run") or find(msg, "/dump") or find(msg, "/script") then return msg end
	local outstr = ""
	local origlen = strlen(msg)
	local startpos = 1
	local endpos, _

	while(startpos <= origlen) do
		local pos = find(msg,"|H",startpos,true)
		endpos = pos or origlen
		outstr = outstr..CH:InsertEmotions(strsub(msg,startpos,endpos)) --run replacement on this bit
		startpos = endpos + 1
		if pos ~= nil then
			_, endpos = find(msg,"|h.-|h",startpos)
			endpos = endpos or origlen
			if startpos < endpos then
				outstr = outstr..strsub(msg,startpos,endpos) --don't run replacement on this bit
				startpos = endpos + 1
			end
		end
	end

	return outstr
end

function CH:StyleChat(frame)
	local name = frame:GetName()
	_G[name.."TabText"]:FontTemplate(LSM:Fetch("font", self.db.tabFont), self.db.tabFontSize, self.db.tabFontOutline)

	if frame.styled then return end

	frame:SetFrameLevel(4)

	local id = frame:GetID()

	local tab = _G[name.."Tab"]
	local editbox = _G[name.."EditBox"]
	local language = _G[name.."EditBoxLanguage"]

	--Character count
	editbox.characterCount = editbox:CreateFontString()
	editbox.characterCount:FontTemplate()
	editbox.characterCount:SetTextColor(190, 190, 190, 0.4)
	editbox.characterCount:Point("TOPRIGHT", editbox, "TOPRIGHT", -5, 0)
	editbox.characterCount:Point("BOTTOMRIGHT", editbox, "BOTTOMRIGHT", -5, 0)
	editbox.characterCount:SetJustifyH("CENTER")
	editbox.characterCount:Width(40)

	for _, texName in pairs(tabTexs) do
		_G[tab:GetName()..texName.."Left"]:SetTexture(nil)
		_G[tab:GetName()..texName.."Middle"]:SetTexture(nil)
		_G[tab:GetName()..texName.."Right"]:SetTexture(nil)
	end

	hooksecurefunc(tab, "SetAlpha", function(t, alpha)
		if alpha ~= 1 and (not t.isDocked or GeneralDockManager.selected:GetID() == t:GetID()) then
			t:SetAlpha(1)
		elseif alpha < 0.6 then
			t:SetAlpha(0.6)
		end
	end)

	tab.text = _G[name.."TabText"]
	tab.text:SetTextColor(unpack(E.media.rgbvaluecolor))
	hooksecurefunc(tab.text, "SetTextColor", function(tt, r, g, b)
		local rR, gG, bB = unpack(E.media.rgbvaluecolor)
		if r ~= rR or g ~= gG or b ~= bB then
			tt:SetTextColor(rR, gG, bB)
		end
	end)

	if tab.conversationIcon then
		tab.conversationIcon:ClearAllPoints()
		tab.conversationIcon:Point("RIGHT", tab.text, "LEFT", -1, 0)
	end

	frame:SetClampRectInsets(0,0,0,0)
	frame:SetClampedToScreen(false)
	frame:StripTextures(true)
	_G[name.."ButtonFrame"]:Kill()

	local function OnTextChanged(editBox)
		local text = editBox:GetText()

		if InCombatLockdown() then
			local MIN_REPEAT_CHARACTERS = E.db.chat.numAllowedCombatRepeat
			if (strlen(text) > MIN_REPEAT_CHARACTERS) then
			local repeatChar = true
			for i = 1, MIN_REPEAT_CHARACTERS, 1 do
				if strsub(text,(0-i), (0-i)) ~= strsub(text,(-1-i),(-1-i)) then
					repeatChar = false
					break
				end
			end
				if repeatChar then
					editBox:Hide()
					return
				end
			end
		end

		if strlen(text) < 5 then
			if strsub(text, 1, 4) == "/tt " then
				local unitname, realm = UnitName("target")
				if unitname and realm and not UnitIsSameServer("player", "target") then
					unitname = unitname.."-"..realm:gsub(" ", "")
				end
				ChatFrame_SendTell((unitname or L["Invalid Target"]), ChatFrame1)
			end

			if strsub(text, 1, 4) == "/gr " then
				editBox:SetText(CH:GetGroupDistribution()..strsub(text, 5))
				ChatEdit_ParseText(editBox, 0)
			end
		end
		editbox.characterCount:SetText((255 - strlen(text)))
	end

	local a, b, c = select(6, editbox:GetRegions()); a:Kill(); b:Kill(); c:Kill()
	_G[format(editbox:GetName().."FocusLeft", id)]:Kill()
	_G[format(editbox:GetName().."FocusMid", id)]:Kill()
	_G[format(editbox:GetName().."FocusRight", id)]:Kill()
	editbox:SetTemplate(nil, true)
	editbox:SetAltArrowKeyMode(CH.db.useAltKey)
	editbox:SetAllPoints(LeftChatDataPanel)
	self:SecureHook(editbox, "AddHistoryLine", "ChatEdit_AddHistory")
	editbox:HookScript("OnTextChanged", OnTextChanged)

	editbox:HookScript("OnEditFocusGained", function(editBox)
		editBox:Show()
		if not LeftChatPanel:IsShown() then
			LeftChatPanel.editboxforced = true
			LeftChatToggleButton:GetScript("OnEnter")(LeftChatToggleButton)
		end
	end)
	editbox:HookScript("OnEditFocusLost", function(editBox)
		if LeftChatPanel.editboxforced then
			LeftChatPanel.editboxforced = nil
			if LeftChatPanel:IsShown() then
				LeftChatToggleButton:GetScript("OnLeave")(LeftChatToggleButton)
			end
		end

		editBox.historyIndex = 0
		editBox:Hide()
	end)

	for _, text in pairs(ElvCharacterDB.ChatEditHistory) do
		editbox:AddHistoryLine(text)
	end

	language:Height(22)
	language:StripTextures()
	language:SetTemplate("Transparent")
	language:Point("LEFT", editbox, "RIGHT", -32, 0)

	if id ~= 2 then --Don't add timestamps to combat log, they don't work.
		--This usually taints, but LibChatAnims should make sure it doesn't.
		frame.OldAddMessage = frame.AddMessage
		frame.AddMessage = CH.AddMessage
	end

	--copy chat button
	frame.button = CreateFrame("Button", format("CopyChatButton%d", id), frame)
	frame.button:EnableMouse(true)
	frame.button:SetAlpha(0.35)
	frame.button:Size(20, 22)
	frame.button:Point("TOPRIGHT")
	frame.button:SetFrameLevel(frame:GetFrameLevel() + 5)

	frame.button.tex = frame.button:CreateTexture(nil, "OVERLAY")
	frame.button.tex:SetInside()
	frame.button.tex:SetTexture(E.Media.Textures.Copy)

	frame.button:SetScript("OnMouseUp", function(_, btn)
		if btn == "RightButton" and id == 1 then
			ToggleFrame(ChatMenu)
		else
			CH:CopyChat(frame)
		end
	end)

	frame.button:SetScript("OnEnter", function(button) button:SetAlpha(1) end)
	frame.button:SetScript("OnLeave", function(button)
		if _G[button:GetParent():GetName().."TabText"]:IsShown() then
			button:SetAlpha(0.35)
		else
			button:SetAlpha(0)
		end
	end)

	CreatedFrames = id
	frame.styled = true
end

function CH:AddMessage(msg, infoR, infoG, infoB, infoID, accessID, typeID, isHistory, historyTime)
	local historyTimestamp --we need to extend the arguments on AddMessage so we can properly handle times without overriding
	if isHistory == "ElvUI_ChatHistory" then historyTimestamp = historyTime end

	if (CH.db.timeStampFormat and CH.db.timeStampFormat ~= "NONE" ) then
		local timeStamp = BetterDate(CH.db.timeStampFormat, historyTimestamp or time())
		timeStamp = gsub(timeStamp, " ", "")
		timeStamp = gsub(timeStamp, "AM", " AM")
		timeStamp = gsub(timeStamp, "PM", " PM")
		if CH.db.useCustomTimeColor then
			local color = CH.db.customTimeColor
			local hexColor = E:RGBToHex(color.r, color.g, color.b)
			msg = format("%s[%s]|r %s", hexColor, timeStamp, msg)
		else
			msg = format("[%s] %s", timeStamp, msg)
		end
	end

	self.OldAddMessage(self, msg, infoR, infoG, infoB, infoID, accessID, typeID)
end

function CH:UpdateSettings()
	for i = 1, CreatedFrames do
		local chat = _G[format("ChatFrame%d", i)]
		local name = chat:GetName()
		local editbox = _G[name.."EditBox"]
		editbox:SetAltArrowKeyMode(CH.db.useAltKey)
	end
end

local removeIconFromLine
do
	local raidIconFunc = function(x) x = x ~= "" and _G["RAID_TARGET_"..x]; return x and ("{"..strlower(x).."}") or "" end
	local stripTextureFunc = function(w, x, y) if x=="" then return (w~="" and w) or (y~="" and y) or "" end end
	local hyperLinkFunc = function(w, x, y) if w~="" then return end
		local emoji = (x~="" and x) and strmatch(x, "elvmoji:%%(.+)")
		return (emoji and E.Libs.Base64:Decode(emoji)) or y
	end
	removeIconFromLine = function(text)
		text = gsub(text, "|TInterface\\TargetingFrame\\UI%-RaidTargetingIcon_(%d+):0|t", raidIconFunc) --converts raid icons into {star} etc, if possible.
		text = gsub(text, "(%s?)(|?)|T.-|t(%s?)", stripTextureFunc) --strip any other texture out but keep a single space from the side(s).
		text = gsub(text, "(|?)|H(.-)|h(.-)|h", hyperLinkFunc) --strip hyperlink data only keeping the actual text.
		return text
	end
end

local function colorizeLine(text, r, g, b)
	local hexCode = E:RGBToHex(r, g, b)
	local hexReplacement = format("|r%s", hexCode)

	text = gsub(text, "|r", hexReplacement) -- If the message contains color strings then we need to add message color hex code after every "|r"
	text = format("%s%s|r", hexCode, text) -- Add message color

	return text
end

local copyLines = {}
function CH:GetLines(...)
	local index = 1
	wipe(copyLines)
	for i = select("#", ...), 1, -1 do
		local region = select(i, ...)
		if region:GetObjectType() == "FontString" then
			local line = tostring(region:GetText())
			local r, g, b = region:GetTextColor()

			line = removeIconFromLine(line)

			line = colorizeLine(line, r, g, b)

			copyLines[index] = line
			index = index + 1
		end
	end
	return index - 1
end

function CH:CopyChat(frame)
	if not CopyChatFrame:IsShown() then
		local _, fontSize = FCF_GetChatWindowInfo(frame:GetID())
		if fontSize < 10 then fontSize = 12 end
		FCF_SetChatWindowFontSize(frame, frame, 0.01)
		CopyChatFrame:Show()
		local lineCt = self:GetLines(frame:GetRegions())
		local text = tconcat(copyLines, " \n", 1, lineCt)
		FCF_SetChatWindowFontSize(frame, frame, fontSize)
		CopyChatFrameEditBox:SetText(text)
	else
		CopyChatFrame:Hide()
	end
end

function CH:OnEnter(frame)
	_G[frame:GetName().."Text"]:Show()

	if frame.conversationIcon then
		frame.conversationIcon:Show()
	end
end

function CH:OnLeave(frame)
	_G[frame:GetName().."Text"]:Hide()

	if frame.conversationIcon then
		frame.conversationIcon:Hide()
	end
end

function CH:SetupChatTabs(frame, hook)
	if hook and (not self.hooks or not self.hooks[frame] or not self.hooks[frame].OnEnter) then
		self:HookScript(frame, "OnEnter")
		self:HookScript(frame, "OnLeave")
	elseif not hook and self.hooks and self.hooks[frame] and self.hooks[frame].OnEnter then
		self:Unhook(frame, "OnEnter")
		self:Unhook(frame, "OnLeave")
	end

	if not hook then
		_G[frame:GetName().."Text"]:Show()

		if frame.owner and frame.owner.button and GetMouseFocus() ~= frame.owner.button then
			frame.owner.button:SetAlpha(0.35)
		end
		if frame.conversationIcon then
			frame.conversationIcon:Show()
		end
	elseif GetMouseFocus() ~= frame then
		_G[frame:GetName().."Text"]:Hide()

		if frame.owner and frame.owner.button and GetMouseFocus() ~= frame.owner.button then
			frame.owner.button:SetAlpha(0)
		end

		if frame.conversationIcon then
			frame.conversationIcon:Hide()
		end
	end
end

function CH:UpdateAnchors()
	for _, frameName in pairs(CHAT_FRAMES) do
		local frame = _G[frameName.."EditBox"]
		if not frame then break end
		local noBackdrop = (self.db.panelBackdrop == "HIDEBOTH" or self.db.panelBackdrop == "RIGHT")
		frame:ClearAllPoints()
		if not E.db.datatexts.leftChatPanel and E.db.chat.editBoxPosition == "BELOW_CHAT" then
			frame:Point("TOPLEFT", ChatFrame1, "BOTTOMLEFT", noBackdrop and -1 or -4, noBackdrop and -1 or -4)
			frame:Point("BOTTOMRIGHT", ChatFrame1, "BOTTOMRIGHT", noBackdrop and 10 or 7, -LeftChatTab:GetHeight()-(noBackdrop and 1 or 4))
		elseif E.db.chat.editBoxPosition == "BELOW_CHAT" then
			frame:SetAllPoints(LeftChatDataPanel)
		else
			frame:Point("BOTTOMLEFT", ChatFrame1, "TOPLEFT", noBackdrop and -1 or -1, noBackdrop and 1 or 4)
			frame:Point("TOPRIGHT", ChatFrame1, "TOPRIGHT", noBackdrop and 10 or 4, LeftChatTab:GetHeight()+(noBackdrop and 1 or 4))
		end
	end

	CH:PositionChat(true)
end

local function FindRightChatID()
	local rightChatID

	for _, frameName in pairs(CHAT_FRAMES) do
		local chat = _G[frameName]
		local id = chat:GetID()

		if E:FramesOverlap(chat, RightChatPanel) and not E:FramesOverlap(chat, LeftChatPanel) then
			rightChatID = id
			break
		end
	end

	return rightChatID
end

function CH:UpdateChatTabs()
	local fadeUndockedTabs = E.db.chat.fadeUndockedTabs
	local fadeTabsNoBackdrop = E.db.chat.fadeTabsNoBackdrop

	for i = 1, CreatedFrames do
		local chat = _G[format("ChatFrame%d", i)]
		local tab = _G[format("ChatFrame%sTab", i)]
		local id = chat:GetID()
		local isDocked = chat.isDocked
		local chatbg = format("ChatFrame%dBackground", i)
		if id > NUM_CHAT_WINDOWS then
			if select(2, tab:GetPoint()):GetName() ~= chatbg then
				isDocked = true
			else
				isDocked = false
			end
		end

		if chat:IsShown() and not (id > NUM_CHAT_WINDOWS) and (id == self.RightChatWindowID) then
			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "LEFT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		elseif not isDocked and chat:IsShown() then
			tab:SetParent(RightChatPanel)
			chat:SetParent(RightChatPanel)
			CH:SetupChatTabs(tab, fadeUndockedTabs and true or false)
		else
			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "RIGHT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		end
	end
end

function CH:PositionChat(override)
	if (InCombatLockdown() and not override and self.initialMove) or (IsMouseButtonDown("LeftButton") and not override) then return end
	if not RightChatPanel or not LeftChatPanel then return end
	if not E.db.chat.lockPositions or E.private.chat.enable ~= true then return end

	RightChatPanel:Size(E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth, E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight)
	LeftChatPanel:Size(E.db.chat.panelWidth, E.db.chat.panelHeight)

	CombatLogQuickButtonFrame_Custom:Size(LeftChatTab:GetWidth(), LeftChatTab:GetHeight())

	self.RightChatWindowID = FindRightChatID()

	local fadeUndockedTabs = E.db.chat.fadeUndockedTabs
	local fadeTabsNoBackdrop = E.db.chat.fadeTabsNoBackdrop

	for i = 1, CreatedFrames do
		local BASE_OFFSET = 57 + E.Spacing*3

		local chat = _G[format("ChatFrame%d", i)]
		local chatbg = format("ChatFrame%dBackground", i)
		local id = chat:GetID()
		local tab = _G[format("ChatFrame%sTab", i)]
		local isDocked = chat.isDocked
		tab.isDocked = chat.isDocked
		tab.owner = chat

		if id > NUM_CHAT_WINDOWS then
			if select(2, tab:GetPoint()):GetName() ~= chatbg then
				isDocked = true
			else
				isDocked = false
			end
		end

		if chat:IsShown() and not (id > NUM_CHAT_WINDOWS) and id == self.RightChatWindowID then
			chat:ClearAllPoints()

			if E.db.datatexts.rightChatPanel then
				chat:Point("BOTTOMLEFT", RightChatDataPanel, "TOPLEFT", 1, 3)
			else
				BASE_OFFSET = BASE_OFFSET - 24
				chat:Point("BOTTOMLEFT", RightChatDataPanel, "BOTTOMLEFT", 1, 1)
			end
			if id ~= 2 then
				chat:Size((E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth) - 11, (E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight) - BASE_OFFSET)
			else
				chat:Size(E.db.chat.panelWidth - 11, (E.db.chat.panelHeight - BASE_OFFSET) - CombatLogQuickButtonFrame_Custom:GetHeight())
			end

			--Pass a 2nd argument which prevents an infinite loop in our ON_FCF_SavePositionAndDimensions function
			if chat:GetLeft() then
				FCF_SavePositionAndDimensions(chat, true)
			end

			tab:SetParent(RightChatPanel)
			chat:SetParent(RightChatPanel)

			if chat:IsMovable() then
				chat:SetUserPlaced(true)
			end
			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "LEFT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		elseif not isDocked and chat:IsShown() then
			tab:SetParent(UIParent)
			chat:SetParent(UIParent)
			CH:SetupChatTabs(tab, fadeUndockedTabs and true or false)
		else
			if id ~= 2 and not (id > NUM_CHAT_WINDOWS) then
				chat:ClearAllPoints()
				if E.db.datatexts.leftChatPanel then
					chat:Point("BOTTOMLEFT", LeftChatToggleButton, "TOPLEFT", 1, 3)
				else
					BASE_OFFSET = BASE_OFFSET - 24
					chat:Point("BOTTOMLEFT", LeftChatToggleButton, "BOTTOMLEFT", 1, 1)
				end
				chat:Size(E.db.chat.panelWidth - 11, (E.db.chat.panelHeight - BASE_OFFSET))

				--Pass a 2nd argument which prevents an infinite loop in our ON_FCF_SavePositionAndDimensions function
				if chat:GetLeft() then
					FCF_SavePositionAndDimensions(chat, true)
				end
			end
			chat:SetParent(LeftChatPanel)
			if i > 2 then
				tab:SetParent(GeneralDockManagerScrollFrameChild)
			else
				tab:SetParent(GeneralDockManager)
			end
			if chat:IsMovable() then
				chat:SetUserPlaced(true)
			end

			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "RIGHT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		end
	end

	E.Layout:RepositionChatDataPanels()

	self.initialMove = true
end

function CH:Panels_ColorUpdate()
	local panelColor = E.db.chat.panelColor
	LeftChatPanel.backdrop:SetBackdropColor(panelColor.r, panelColor.g, panelColor.b, panelColor.a)
	RightChatPanel.backdrop:SetBackdropColor(panelColor.r, panelColor.g, panelColor.b, panelColor.a)
end

local function UpdateChatTabColor(_, r, g, b)
	for i = 1, CreatedFrames do
		_G["ChatFrame"..i.."TabText"]:SetTextColor(r, g, b)
	end
end
E.valueColorUpdateFuncs[UpdateChatTabColor] = true

function CH:ScrollToBottom(frame)
	frame:ScrollToBottom()

	self:CancelTimer(frame.ScrollTimer, true)
end

function CH:PrintURL(url)
	return "|cFFFFFFFF[|Hurl:"..url.."|h"..url.."|h]|r "
end

function CH:FindURL(event, msg, author, ...)
	if (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_BN_WHISPER") and (CH.db.whisperSound ~= "None") and not CH.SoundTimer then
		if (CH.db.noAlertInCombat and not InCombatLockdown()) or not CH.db.noAlertInCombat then
			PlaySoundFile(LSM:Fetch("sound", CH.db.whisperSound), "Master")
		end

		CH.SoundTimer = E:Delay(1, CH.ThrottleSound)
	end

	if not CH.db.url then
		msg = CH:CheckKeyword(msg, author)
		msg = CH:GetSmileyReplacementText(msg)
		return false, msg, author, ...
	end

	local text, tag = msg, strmatch(msg, "{(.-)}")
	if tag and ICON_TAG_LIST[strlower(tag)] then
		text = gsub(gsub(text, "(%S)({.-})", "%1 %2"), "({.-})(%S)", "%1 %2")
	end

	text = gsub(gsub(text, "(%S)(|c.-|H.-|h.-|h|r)", "%1 %2"), "(|c.-|H.-|h.-|h|r)(%S)", "%1 %2")
	-- http://example.com
	local newMsg, found = gsub(text, "(%a+)://(%S+)%s?", CH:PrintURL("%1://%2"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end
	-- www.example.com
	newMsg, found = gsub(text, "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", CH:PrintURL("www.%1.%2"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end
	-- example@example.com
	newMsg, found = gsub(text, "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", CH:PrintURL("%1@%2%3%4"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end
	-- IP address with port 1.1.1.1:1
	newMsg, found = gsub(text, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)(:%d+)%s?", CH:PrintURL("%1.%2.%3.%4%5"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end
	-- IP address 1.1.1.1
	newMsg, found = gsub(text, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?", CH:PrintURL("%1.%2.%3.%4"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end

	msg = CH:CheckKeyword(msg, author)
	msg = CH:GetSmileyReplacementText(msg)

	return false, msg, author, ...
end

function CH:SetChatEditBoxMessage(message)
	local ChatFrameEditBox = ChatEdit_ChooseBoxForSend()
	local editBoxShown = ChatFrameEditBox:IsShown()
	local editBoxText = ChatFrameEditBox:GetText()
	if not editBoxShown then
		ChatEdit_ActivateChat(ChatFrameEditBox)
	end
	if editBoxText and editBoxText ~= "" then
		ChatFrameEditBox:SetText("")
	end
	ChatFrameEditBox:Insert(message)
	ChatFrameEditBox:HighlightText()
end

local function HyperLinkedURL(data)
	if strsub(data, 1, 3) == "url" then
		local currentLink = strsub(data, 5)
		if currentLink and currentLink ~= "" then
			CH:SetChatEditBoxMessage(currentLink)
		end
	end
end

local SetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(data, ...)
	if strsub(data, 1, 3) == "url" then
		HyperLinkedURL(data)
	else
		SetHyperlink(self, data, ...)
	end
end

local hyperLinkEntered
function CH:OnHyperlinkEnter(frame, refString)
	if InCombatLockdown() then return end
	local linkToken = strmatch(refString, "^([^:]+)")
	if hyperlinkTypes[linkToken] then
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(refString)
		hyperLinkEntered = frame
		GameTooltip:Show()
	end
end

function CH:OnHyperlinkLeave(_, refString)
	-- local linkToken = refString:match("^([^:]+)")
	-- if hyperlinkTypes[linkToken] then
		-- HideUIPanel(GameTooltip)
		-- hyperLinkEntered = nil
	-- end

	if hyperLinkEntered then
		HideUIPanel(GameTooltip)
		hyperLinkEntered = nil
	end
end

function CH:OnMessageScrollChanged(frame)
	if hyperLinkEntered == frame then
		HideUIPanel(GameTooltip)
		hyperLinkEntered = false
	end
end

function CH:EnableHyperlink()
	for _, frameName in pairs(CHAT_FRAMES) do
		local frame = _G[frameName]
		if (not self.hooks or not self.hooks[frame] or not self.hooks[frame].OnHyperlinkEnter) then
			self:HookScript(frame, "OnHyperlinkEnter")
			self:HookScript(frame, "OnHyperlinkLeave")
			self:HookScript(frame, "OnMessageScrollChanged")
		end
	end
end

function CH:DisableHyperlink()
	for _, frameName in pairs(CHAT_FRAMES) do
		local frame = _G[frameName]
		if self.hooks and self.hooks[frame] and self.hooks[frame].OnHyperlinkEnter then
			self:Unhook(frame, "OnHyperlinkEnter")
			self:Unhook(frame, "OnHyperlinkLeave")
			self:Unhook(frame, "OnMessageScrollChanged")
		end
	end
end

function CH:DisableChatThrottle()
	wipe(msgList)
	wipe(msgCount)
	wipe(msgTime)
end

function CH:ShortChannel()
	return format("|Hchannel:%s|h[%s]|h", self, DEFAULT_STRINGS[strupper(self)] or gsub(self, "channel:", ""))
end

local PluginIconsCalls = {}
function CH:AddPluginIcons(func)
	tinsert(PluginIconsCalls, func)
end

function CH:GetPluginIcon(sender, name, realm)
	local icon
	for _,func in ipairs(PluginIconsCalls) do
		icon = func(sender, name, realm)
		if icon and icon ~= "" then break end
	end
	return icon
end

function CH:GetColoredName(event, _, arg2, _, _, _, _, _, arg8, _, _, _, arg12)
	local chatType = strsub(event, 10)
	if strsub(chatType, 1, 7) == "WHISPER" then
		chatType = "WHISPER"
	end
	if strsub(chatType, 1, 7) == "CHANNEL" then
		chatType = "CHANNEL"..arg8
	end
	local info = ChatTypeInfo[chatType]

	if info and info.colorNameByClass and arg12 ~= "" then
		local _, englishClass = GetPlayerInfoByGUID(arg12)

		if englishClass then
			local classColorTable = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[englishClass] or RAID_CLASS_COLORS[englishClass]
			if not classColorTable then
				return arg2
			end
			return format("\124cff%.2x%.2x%.2x", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255)..arg2.."\124r"
		end
	end

	return arg2
end

function CH:ChatFrame_MessageEventHandler(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, isHistory, historyTime, historyName)
	if strsub(event, 1, 8) == "CHAT_MSG" then
		local historySavedName --we need to extend the arguments on CH.ChatFrame_MessageEventHandler so we can properly handle saved names without overriding
		if isHistory == "ElvUI_ChatHistory" then
			historySavedName = historyName
		end

		local chatType = strsub(event, 10)
		local info = ChatTypeInfo[chatType]

		local chatFilters = ChatFrame_GetMessageEventFilters(event)
		if chatFilters then
			for _, filterFunc in next, chatFilters do
				local filter, newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12 = filterFunc(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
				if filter then
					return true
				elseif newarg1 then
					arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12 = newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12
				end
			end
		end

		local _, _, englishClass, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, arg12)
		local coloredName = historySavedName or CH:GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)

		--Cache name->class
		local nameWithRealm = strmatch(realm ~= "" and realm or E.myrealm, "%s*(%S+)$") -- TODO
		if name and name ~= "" then
			CH.ClassNames[strlower(name)] = englishClass
			nameWithRealm = name.."-"..nameWithRealm
			CH.ClassNames[strlower(nameWithRealm)] = englishClass
		end

		local channelLength = strlen(arg4)
		local infoType = chatType
		if (strsub(chatType, 1, 7) == "CHANNEL") and (chatType ~= "CHANNEL_LIST") and ((arg1 ~= "INVITE") or (chatType ~= "CHANNEL_NOTICE_USER")) then
			if arg1 == "WRONG_PASSWORD" then
				local staticPopup = _G[StaticPopup_Visible("CHAT_CHANNEL_PASSWORD") or ""]
				if staticPopup and strupper(staticPopup.data) == strupper(arg9) then
					-- Don't display invalid password messages if we're going to prompt for a password (bug 102312)
					return
				end
			end

			local found = 0
			for index, value in pairs(frame.channelList) do
				if channelLength > strlen(value) then
					-- arg9 is the channel name without the number in front...
					if ((arg7 > 0) and (frame.zoneChannelList[index] == arg7)) or (strupper(value) == strupper(arg9)) then
						found = 1
						infoType = "CHANNEL"..arg8
						info = ChatTypeInfo[infoType]
						if (chatType == "CHANNEL_NOTICE") and (arg1 == "YOU_LEFT") then
							frame.channelList[index] = nil
							frame.zoneChannelList[index] = nil
						end
						break
					end
				end
			end
			if (found == 0) or not info then
				return true
			end
		end

		local chatGroup = Chat_GetChatCategory(chatType)
		local chatTarget
		if chatGroup == "CHANNEL" or chatGroup == "BN_CONVERSATION" then
			chatTarget = tostring(arg8)
		elseif chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" then
			chatTarget = strupper(arg2)
		end

		if FCFManager_ShouldSuppressMessage(frame, chatGroup, chatTarget) then
			return true
		end

		if chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" then
			if frame.privateMessageList and not frame.privateMessageList[strlower(arg2)] then
				return true
			elseif frame.excludePrivateMessageList and frame.excludePrivateMessageList[strlower(arg2)] then
				return true
			end
		elseif chatGroup == "BN_CONVERSATION" then
			if frame.bnConversationList and not frame.bnConversationList[arg8] then
				return true
			elseif frame.excludeBNConversationList and frame.excludeBNConversationList[arg8] then
				return true
			end
		end

		if chatType == "SYSTEM" or chatType == "SKILL" or chatType == "LOOT" or chatType == "MONEY"
		or chatType == "OPENING" or chatType == "TRADESKILLS" or chatType == "PET_INFO" or chatType == "TARGETICONS" then
			frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,7) == "COMBAT_" then
			frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,6) == "SPELL_" then
			frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,10) == "BG_SYSTEM_" then
			frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,11) == "ACHIEVEMENT" then
			frame:AddMessage(format(arg1, "|Hplayer:"..arg2.."|h".."["..coloredName.."]".."|h"), info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,18) == "GUILD_ACHIEVEMENT" then
			frame:AddMessage(format(arg1, "|Hplayer:"..arg2.."|h".."["..coloredName.."]".."|h"), info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
		elseif chatType == "IGNORED" then
			frame:AddMessage(format(CHAT_IGNORED, arg2), info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
		elseif chatType == "FILTERED" then
			frame:AddMessage(format(CHAT_FILTERED, arg2), info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
		elseif chatType == "RESTRICTED" then
			frame:AddMessage(CHAT_RESTRICTED, info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
		elseif chatType == "CHANNEL_LIST" then
			if channelLength > 0 then
				frame:AddMessage(format(_G["CHAT_"..chatType.."_GET"]..arg1, tonumber(arg8), arg4), info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
			else
				frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
			end
		elseif chatType == "CHANNEL_NOTICE_USER" then
			local globalstring = _G["CHAT_"..arg1.."_NOTICE_BN"]
			if not globalstring then
				globalstring = _G["CHAT_"..arg1.."_NOTICE"]
			end

			if strlen(arg5) > 0 then
				-- TWO users in this notice (E.G. x kicked y)
				frame:AddMessage(format(globalstring, arg8, arg4, arg2, arg5), info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
			elseif arg1 == "INVITE" then
				frame:AddMessage(format(globalstring, arg4, arg2), info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
			else
				frame:AddMessage(format(globalstring, arg8, arg4, arg2), info.r, info.g, info.b, info.id, nil, nil, isHistory, historyTime)
			end
		elseif chatType == "CHANNEL_NOTICE" then
			if arg1 == "NOT_IN_LFG" then return end
			local globalstring = _G["CHAT_"..arg1.."_NOTICE_BN"]
			if not globalstring then
				globalstring = _G["CHAT_"..arg1.."_NOTICE"]
			end
			if arg10 > 0 then
				arg4 = arg4.." "..arg10
			end

			local accessID = ChatHistory_GetAccessID(Chat_GetChatCategory(chatType), arg8)
			local typeID = ChatHistory_GetAccessID(infoType, arg8)
			frame:AddMessage(format(globalstring, arg8, arg4), info.r, info.g, info.b, info.id, accessID, typeID, isHistory, historyTime)
		else
			local body

			-- Add AFK/DND flags
			-- Player Flags
			local pflag, chatIcon, pluginChatIcon = "", specialChatIcons[nameWithRealm], CH:GetPluginIcon(nameWithRealm, name, realm)
			if type(chatIcon) == "function" then chatIcon = chatIcon() end
			if arg6 ~= "" then
				if arg6 == "GM" then
					--If it was a whisper, dispatch it to the GMChat addon.
					if chatType == "WHISPER" then
						return
					end
					--Add Blizzard Icon, this was sent by a GM
					pflag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:0:2:0:-3|t "
				elseif arg6 == "DEV" then
					--Add Blizzard Icon, this was sent by a Dev
					pflag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:0:2:0:-3|t "
				elseif arg6 == "DND" or arg6 == "AFK" then
					pflag = (pflag or "").._G["CHAT_FLAG_"..arg6]
				else
					pflag = _G["CHAT_FLAG_"..arg6]
				end
			else
				-- Special Chat Icon
				if chatIcon then
					pflag = pflag..chatIcon
				end
				-- Plugin Chat Icon
				if pluginChatIcon then
					pflag = pflag..pluginChatIcon
				end
			end

			if chatType == "WHISPER_INFORM" and GMChatFrame_IsGM and GMChatFrame_IsGM(arg2) then
				return
			end

			local showLink = 1
			if strsub(chatType, 1, 7) == "MONSTER" or strsub(chatType, 1, 9) == "RAID_BOSS" then
				showLink = nil
			else
				arg1 = gsub(arg1, "%%", "%%%%")
			end

			if chatType == "PARTY_LEADER" and HasLFGRestrictions() then
				chatType = "PARTY_GUIDE"
			end

			-- Search for icon links and replace them with texture links.
			local term
			for tag in gmatch(arg1, "%b{}") do
				term = strlower(gsub(tag, "[{}]", ""))
				if ICON_TAG_LIST[term] and ICON_LIST[ICON_TAG_LIST[term]] then
					arg1 = gsub(arg1, tag, ICON_LIST[ICON_TAG_LIST[term]].."0|t")
				end
			end

			local playerLink

			if chatType ~= "BN_WHISPER" and chatType ~= "BN_WHISPER_INFORM" and chatType ~= "BN_CONVERSATION" then
				playerLink = "|Hplayer:"..arg2..":"..arg11..":"..chatGroup..(chatTarget and ":"..chatTarget or "").."|h"
			else
				playerLink = "|HBNplayer:"..arg2..":"..arg13..":"..arg11..":"..chatGroup..(chatTarget and ":"..chatTarget or "").."|h"
			end

			if (strlen(arg3) > 0) and (arg3 ~= "Universal") and (arg3 ~= frame.defaultLanguage) then
				local languageHeader = "["..arg3.."] "
				if showLink and (strlen(arg2) > 0) then
					body = format(_G["CHAT_"..chatType.."_GET"]..languageHeader..arg1, pflag..playerLink.."["..coloredName.."]".."|h")
				else
					body = format(_G["CHAT_"..chatType.."_GET"]..languageHeader..arg1, pflag..arg2)
				end
			else
				if not showLink or strlen(arg2) == 0 then
					if find(arg1, "% ") and GetLocale() == "ruRU" then
						arg1 = arg1:gsub("%%", "%%s")
					end
					body = format(_G["CHAT_"..chatType.."_GET"]..arg1, pflag..arg2, arg2)
				else
					if chatType == "EMOTE" then
						body = format(_G["CHAT_"..chatType.."_GET"]..arg1, pflag..playerLink..coloredName.."|h")
					elseif chatType == "TEXT_EMOTE" then
						body = string.gsub(arg1, arg2, pflag..playerLink..coloredName.."|h", 1)
					else
						body = format(_G["CHAT_"..chatType.."_GET"]..arg1, pflag..playerLink.."["..coloredName.."]".."|h")
					end
				end
			end

			-- Add Channel
			arg4 = gsub(arg4, "%s%-%s.*", "")
			if chatGroup == "BN_CONVERSATION" then
				body = format(CHAT_BN_CONVERSATION_GET_LINK, arg8, MAX_WOW_CHAT_CHANNELS + arg8)..body
			elseif channelLength > 0 then
				body = "|Hchannel:channel:"..arg8.."|h["..arg4.."]|h "..body
			end

			local accessID = ChatHistory_GetAccessID(chatGroup, chatTarget)
			local typeID = ChatHistory_GetAccessID(infoType, chatTarget)
			if CH.db.shortChannels then
				body = body:gsub("|Hchannel:(.-)|h%[(.-)%]|h", CH.ShortChannel)
				body = body:gsub("CHANNEL:", "")
				body = body:gsub("^(.-|h) "..L["whispers"], "%1")
				body = body:gsub("^(.-|h) "..L["says"], "%1")
				body = body:gsub("^(.-|h) "..L["yells"], "%1")
				body = body:gsub("<"..AFK..">", "[|cffFF0000"..L["AFK"].."|r] ")
				body = body:gsub("<"..DND..">", "[|cffE7E716"..L["DND"].."|r] ")
				body = body:gsub("%[BN_CONVERSATION:", "%[".."")
				body = body:gsub("^%["..RAID_WARNING.."%]", "["..L["RW"].."]")
			end
			frame:AddMessage(body, info.r, info.g, info.b, info.id, accessID, typeID, isHistory, historyTime)
		end

		if (isHistory ~= "ElvUI_ChatHistory") and (chatType == "WHISPER" or chatType == "BN_WHISPER") then
			--BN_WHISPER FIXME
			ChatEdit_SetLastTellTarget(arg2)
			if frame.tellTimer and (GetTime() > frame.tellTimer) then
				PlaySound("TellMessage")
			end
			frame.tellTimer = GetTime() + CHAT_TELL_ALERT_TIME
			--FCF_FlashTab(frame)
		end

		if (isHistory ~= "ElvUI_ChatHistory") and (not frame:IsShown()) then
			if (frame == DEFAULT_CHAT_FRAME and info.flashTabOnGeneral) or (frame ~= DEFAULT_CHAT_FRAME and info.flashTab) then
				if not CHAT_OPTIONS.HIDE_FRAME_ALERTS or chatType == "WHISPER" or chatType == "BN_WHISPER" then	--BN_WHISPER FIXME
					FCF_StartAlertFlash(frame) --This would taint if we were not using LibChatAnims
				end
			end
		end

		return true
	end
end

function CH:ChatFrame_ConfigEventHandler(...)
	return ChatFrame_ConfigEventHandler(...)
end

function CH:ChatFrame_SystemEventHandler(...)
	return ChatFrame_SystemEventHandler(...)
end

function CH:ChatFrame_OnEvent(...)
	if CH:ChatFrame_ConfigEventHandler(...) then return end
	if CH:ChatFrame_SystemEventHandler(...) then return end
	if CH:ChatFrame_MessageEventHandler(...) then return end
end

function CH:FloatingChatFrame_OnEvent(...)
	CH:ChatFrame_OnEvent(...)
	FloatingChatFrame_OnEvent(...)
end

local function FloatingChatFrameOnEvent(...)
	CH:FloatingChatFrame_OnEvent(...)
end

function CH:SetupChat()
	if E.private.chat.enable ~= true then return end

	for _, frameName in pairs(CHAT_FRAMES) do
		local frame = _G[frameName]
		local id = frame:GetID()
		local _, fontSize = FCF_GetChatWindowInfo(id)
		self:StyleChat(frame)
		FCFTab_UpdateAlpha(frame)
		frame:FontTemplate(LSM:Fetch("font", self.db.font), fontSize, self.db.fontOutline)
		if self.db.fontOutline ~= "NONE" then
			frame:SetShadowColor(0, 0, 0, 0.2)
		else
			frame:SetShadowColor(0, 0, 0, 1)
		end
		frame:SetTimeVisible(100)
		frame:SetShadowOffset(E.mult, -E.mult)
		frame:SetFading(self.db.fade)

		if not frame.scriptsSet then
			frame:SetScript("OnMouseWheel", ChatFrame_OnMouseScroll)

			if id ~= 2 then
				frame:SetScript("OnEvent", FloatingChatFrameOnEvent)
			end

			hooksecurefunc(frame, "SetScript", function(f, script, func)
				if script == "OnMouseWheel" and func ~= ChatFrame_OnMouseScroll then
					f:SetScript(script, ChatFrame_OnMouseScroll)
				end
			end)
			frame.scriptsSet = true
		end
	end

	if self.db.hyperlinkHover then
		self:EnableHyperlink()
	end

	GeneralDockManager:SetParent(LeftChatPanel)
	-- self:ScheduleRepeatingTimer("PositionChat", 1)
	self:PositionChat(true)

	if not self.HookSecured then
		self:SecureHook("FCF_OpenTemporaryWindow", "SetupChat")
		self.HookSecured = true
	end
end

local function PrepareMessage(author, message)
	return format("%s%s", strupper(author), message)
end

function CH:ChatThrottleHandler(_, arg1, arg2) -- event, arg1, arg2
	if arg2 ~= "" then
		local message = PrepareMessage(arg2, arg1)
		if msgList[message] == nil then
			msgList[message] = true
			msgCount[message] = 1
			msgTime[message] = time()
		else
			msgCount[message] = msgCount[message] + 1
		end
	end
end

function CH:CHAT_MSG_CHANNEL(event, message, author, ...)
	local blockFlag = false
	local msg = PrepareMessage(author, message)

	-- ignore player messages
	if author == UnitName("player") then return CH.FindURL(self, event, message, author, ...) end
	if msgList[msg] and CH.db.throttleInterval ~= 0 then
		if difftime(time(), msgTime[msg]) <= CH.db.throttleInterval then
			blockFlag = true
		end
	end

	if blockFlag then
		return true
	else
		if CH.db.throttleInterval ~= 0 then
			msgTime[msg] = time()
		end

		return CH.FindURL(self, event, message, author, ...)
	end
end

function CH:CHAT_MSG_YELL(event, message, author, ...)
	local blockFlag = false
	local msg = PrepareMessage(author, message)

	if msg == nil then return CH.FindURL(self, event, message, author, ...) end

	-- ignore player messages
	if author == UnitName("player") then return CH.FindURL(self, event, message, author, ...) end
	if msgList[msg] and msgCount[msg] > 1 and CH.db.throttleInterval ~= 0 then
		if difftime(time(), msgTime[msg]) <= CH.db.throttleInterval then
			blockFlag = true
		end
	end

	if blockFlag then
		return true
	else
		if CH.db.throttleInterval ~= 0 then
			msgTime[msg] = time()
		end

		return CH.FindURL(self, event, message, author, ...)
	end
end

function CH:CHAT_MSG_SAY(event, message, author, ...)
	return CH.FindURL(self, event, message, author, ...)
end

function CH:ThrottleSound()
	CH.SoundTimer = nil
end

local protectLinks = {}
function CH:CheckKeyword(message, author)
	for hyperLink in gmatch(message, "|%x+|H.-|h.-|h|r") do
		protectLinks[hyperLink]=gsub(hyperLink,"%s","|s")
		for keyword in pairs(CH.Keywords) do
			if hyperLink == keyword then
				if (self.db.keywordSound ~= "None") and not self.SoundTimer then
					if (self.db.noAlertInCombat and not InCombatLockdown()) or not self.db.noAlertInCombat then
						PlaySoundFile(LSM:Fetch("sound", self.db.keywordSound), "Master")
					end

					self.SoundTimer = E:Delay(1, CH.ThrottleSound)
				end
			end
		end
	end

	for hyperLink, tempLink in pairs(protectLinks) do
		message = gsub(message, gsub(hyperLink, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1"), tempLink)
	end

	local rebuiltString
	local isFirstWord = true
	for word in gmatch(message, "%s-%S+%s*") do
		if not next(protectLinks) or not protectLinks[gsub(gsub(word,"%s",""),"|s"," ")] then
			local tempWord = gsub(word, "[%s%p]", "")
			local lowerCaseWord = strlower(tempWord)

			for keyword in pairs(CH.Keywords) do
				if lowerCaseWord == strlower(keyword) then
					word = gsub(word, tempWord, format("%s%s|r", E.media.hexvaluecolor, tempWord))
					if (author ~= UnitName("player")) and (self.db.keywordSound ~= "None") and not self.SoundTimer then
						if (self.db.noAlertInCombat and not InCombatLockdown()) or not self.db.noAlertInCombat then
							PlaySoundFile(LSM:Fetch("sound", self.db.keywordSound), "Master")
						end

						self.SoundTimer = E:Delay(1, CH.ThrottleSound)
					end
				end
			end

			if self.db.classColorMentionsChat then
				tempWord = gsub(word,"^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$","%1%2")
				lowerCaseWord = strlower(tempWord)

				local classMatch = CH.ClassNames[lowerCaseWord]
				local wordMatch = classMatch and lowerCaseWord

				if wordMatch and not E.global.chat.classColorMentionExcludedNames[wordMatch] then
					local classColorTable = _G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[classMatch] or _G.RAID_CLASS_COLORS[classMatch]
					word = gsub(word, gsub(tempWord, "%-","%%-"), format("\124cff%.2x%.2x%.2x%s\124r", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255, tempWord))
				end
			end
		end

		if isFirstWord then
			rebuiltString = word
			isFirstWord = false
		else
			rebuiltString = rebuiltString..word
		end
	end

	for hyperLink, tempLink in pairs(protectLinks) do
		rebuiltString = gsub(rebuiltString, gsub(tempLink, "([%(%)%.%%%+%-%*%?%[%^%$])","%%%1"), hyperLink)
		protectLinks[hyperLink] = nil
	end

	return rebuiltString
end

function CH:AddLines(lines, ...)
	for i = select("#", ...), 1, -1 do
		local x = select(i, ...)
		if x:GetObjectType() == "FontString" and not x:GetName() then
			tinsert(lines, x:GetText())
		end
	end
end

function CH:ChatEdit_OnEnterPressed(editBox)
	local chatType = editBox:GetAttribute("chatType")
	local chatFrame = chatType and editBox:GetParent()
	if chatFrame and (not chatFrame.isTemporary) and (ChatTypeInfo[chatType].sticky == 1) then
		if not self.db.sticky then chatType = "SAY" end
		editBox:SetAttribute("chatType", chatType)
	end
end

function CH:SetChatFont(dropDown, chatFrame, fontSize)
	if not chatFrame then
		chatFrame = FCF_GetCurrentChatFrame()
	end
	if not fontSize then
		fontSize = dropDown.value
	end
	chatFrame:FontTemplate(LSM:Fetch("font", self.db.font), fontSize, self.db.fontOutline)
	if self.db.fontOutline ~= "NONE" then
		chatFrame:SetShadowColor(0, 0, 0, 0.2)
	else
		chatFrame:SetShadowColor(0, 0, 0, 1)
	end
	chatFrame:SetShadowOffset(E.mult, -E.mult)
end

function CH:ChatEdit_AddHistory(_, line) -- editBox, line
	line = line and strtrim(line)

	if line and strlen(line) > 0 then
		if find(line, "/rl") then return end

		for index, text in pairs(ElvCharacterDB.ChatEditHistory) do
			if text == line then
				tremove(ElvCharacterDB.ChatEditHistory, index)
				break
			end
		end

		tinsert(ElvCharacterDB.ChatEditHistory, line)

		if #ElvCharacterDB.ChatEditHistory > 20 then
			tremove(ElvCharacterDB.ChatEditHistory, 1)
		end
	end
end

function CH:UpdateChatKeywords()
	wipe(CH.Keywords)

	local keywords = self.db.keywords
	keywords = gsub(keywords,",%s",",")

	for stringValue in gmatch(keywords, "[^,]+") do
		if stringValue ~= "" then
			CH.Keywords[stringValue] = true
		end
	end
end

function CH:UpdateFading()
	for _, frameName in pairs(CHAT_FRAMES) do
		local frame = _G[frameName]
		if frame then
			frame:SetFading(self.db.fade)
		end
	end
end

function CH:DisplayChatHistory()
	local data, d = ElvCharacterDB.ChatHistoryLog
	if not (data and next(data)) then return end

	if not GetPlayerInfoByGUID(E.myguid) then
		E:Delay(0.1, CH.DisplayChatHistory)
		return
	end

	CH.SoundTimer = true
	for _, chat in pairs(CHAT_FRAMES) do
		for i = 1, #data do
			d = data[i]
			if type(d) == "table" then
				for _, messageType in pairs(_G[chat].messageTypeList) do
					if gsub(strsub(d[50],10),"_INFORM","") == messageType then
						CH:ChatFrame_MessageEventHandler(_G[chat],d[50],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],0,"ElvUI_ChatHistory",d[51],d[52])
					end
				end
			end
		end
	end
	CH.SoundTimer = nil
end

tremove(ChatTypeGroup.GUILD, 2)
function CH:DelayGuildMOTD()
	local delay, checks, delayFrame, chat = 0, 0, CreateFrame("Frame")
	tinsert(ChatTypeGroup.GUILD, 2, "GUILD_MOTD")
	delayFrame:SetScript("OnUpdate", function(df, elapsed)
		delay = delay + elapsed
		if delay < 5 then return end
		local msg = GetGuildRosterMOTD()
		if msg and strlen(msg) > 0 then
			for _, frame in pairs(CHAT_FRAMES) do
				chat = _G[frame]
				if chat and chat:IsEventRegistered("CHAT_MSG_GUILD") then
					CH:ChatFrame_SystemEventHandler(chat, "GUILD_MOTD", msg)
					chat:RegisterEvent("GUILD_MOTD")
				end
			end
			df:SetScript("OnUpdate", nil)
		else -- 5 seconds can be too fast for the API response. let's try once every 5 seconds (max 5 checks).
			delay, checks = 0, checks + 1
			if checks >= 5 then
				df:SetScript("OnUpdate", nil)
			end
		end
	end)
end

function CH:SaveChatHistory(event, ...)
	if not self.db.chatHistory then return end
	local data = ElvCharacterDB.ChatHistoryLog

	local temp = {}
	for i = 1, select("#", ...) do
		temp[i] = select(i, ...) or false
	end

	if #temp > 0 then
		temp[50] = event
		temp[51] = time()
		temp[52] = CH:GetColoredName(event, ...)

		tinsert(data, temp)
		while #data >= 128 do
			tremove(data, 1)
		end
	end

	if self.db.throttleInterval ~= 0 and (event == "CHAT_MESSAGE_SAY" or event == "CHAT_MESSAGE_YELL" or event == "CHAT_MSG_CHANNEL") then
		self:ChatThrottleHandler(event, ...)

		local message, author = ...
		local msg = PrepareMessage(author, message)
		if author ~= E.myname and msgList[msg] then
			if difftime(time(), msgTime[msg]) <= CH.db.throttleInterval then
				return
			end
		end
	end
end

function CH:FCF_SetWindowAlpha(frame, alpha)
	frame.oldAlpha = alpha or 1
end

function CH:ON_FCF_SavePositionAndDimensions(_, noLoop)
	if not noLoop then
		CH:PositionChat()
	end

	if not E.db.chat.lockPositions then
		CH:UpdateChatTabs() --It was not done in PositionChat, so do it now
	end
end

local FindURL_Events = {
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_BN_WHISPER",
	"CHAT_MSG_BN_WHISPER_INFORM",
	"CHAT_MSG_GUILD_ACHIEVEMENT",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_AFK",
	"CHAT_MSG_DND",
}

function CH:DefaultSmileys()
	local x = ":16:16"
	if next(CH.Smileys) then
		wipe(CH.Smileys)
	end

	-- new keys
	CH:AddSmiley(":angry:", E:TextureString(E.Media.ChatEmojis.Angry,x))
	CH:AddSmiley(":blush:", E:TextureString(E.Media.ChatEmojis.Blush,x))
	CH:AddSmiley(":broken_heart:", E:TextureString(E.Media.ChatEmojis.BrokenHeart,x))
	CH:AddSmiley(":call_me:", E:TextureString(E.Media.ChatEmojis.CallMe,x))
	CH:AddSmiley(":cry:", E:TextureString(E.Media.ChatEmojis.Cry,x))
	CH:AddSmiley(":facepalm:", E:TextureString(E.Media.ChatEmojis.Facepalm,x))
	CH:AddSmiley(":grin:", E:TextureString(E.Media.ChatEmojis.Grin,x))
	CH:AddSmiley(":heart:", E:TextureString(E.Media.ChatEmojis.Heart,x))
	CH:AddSmiley(":heart_eyes:", E:TextureString(E.Media.ChatEmojis.HeartEyes,x))
	CH:AddSmiley(":joy:", E:TextureString(E.Media.ChatEmojis.Joy,x))
	CH:AddSmiley(":kappa:", E:TextureString(E.Media.ChatEmojis.Kappa,x))
	CH:AddSmiley(":middle_finger:", E:TextureString(E.Media.ChatEmojis.MiddleFinger,x))
	CH:AddSmiley(":murloc:", E:TextureString(E.Media.ChatEmojis.Murloc,x))
	CH:AddSmiley(":ok_hand:", E:TextureString(E.Media.ChatEmojis.OkHand,x))
	CH:AddSmiley(":open_mouth:", E:TextureString(E.Media.ChatEmojis.OpenMouth,x))
	CH:AddSmiley(":poop:", E:TextureString(E.Media.ChatEmojis.Poop,x))
	CH:AddSmiley(":rage:", E:TextureString(E.Media.ChatEmojis.Rage,x))
	CH:AddSmiley(":sadkitty:", E:TextureString(E.Media.ChatEmojis.SadKitty,x))
	CH:AddSmiley(":scream:", E:TextureString(E.Media.ChatEmojis.Scream,x))
	CH:AddSmiley(":scream_cat:", E:TextureString(E.Media.ChatEmojis.ScreamCat,x))
	CH:AddSmiley(":slight_frown:", E:TextureString(E.Media.ChatEmojis.SlightFrown,x))
	CH:AddSmiley(":smile:", E:TextureString(E.Media.ChatEmojis.Smile,x))
	CH:AddSmiley(":smirk:", E:TextureString(E.Media.ChatEmojis.Smirk,x))
	CH:AddSmiley(":sob:", E:TextureString(E.Media.ChatEmojis.Sob,x))
	CH:AddSmiley(":sunglasses:", E:TextureString(E.Media.ChatEmojis.Sunglasses,x))
	CH:AddSmiley(":thinking:", E:TextureString(E.Media.ChatEmojis.Thinking,x))
	CH:AddSmiley(":thumbs_up:", E:TextureString(E.Media.ChatEmojis.ThumbsUp,x))
	CH:AddSmiley(":semi_colon:", E:TextureString(E.Media.ChatEmojis.SemiColon,x))
	CH:AddSmiley(":wink:", E:TextureString(E.Media.ChatEmojis.Wink,x))
	CH:AddSmiley(":zzz:", E:TextureString(E.Media.ChatEmojis.ZZZ,x))
	CH:AddSmiley(":stuck_out_tongue:", E:TextureString(E.Media.ChatEmojis.StuckOutTongue,x))
	CH:AddSmiley(":stuck_out_tongue_closed_eyes:", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes,x))

	-- Darth"s keys
	CH:AddSmiley(":meaw:", E:TextureString(E.Media.ChatEmojis.Meaw,x))

	-- Simpy"s keys
	CH:AddSmiley(">:%(", E:TextureString(E.Media.ChatEmojis.Rage,x))
	CH:AddSmiley(":%$", E:TextureString(E.Media.ChatEmojis.Blush,x))
	CH:AddSmiley("<\\3", E:TextureString(E.Media.ChatEmojis.BrokenHeart,x))
	CH:AddSmiley(":\'%)", E:TextureString(E.Media.ChatEmojis.Joy,x))
	CH:AddSmiley(";\'%)", E:TextureString(E.Media.ChatEmojis.Joy,x))
	CH:AddSmiley(",,!,,", E:TextureString(E.Media.ChatEmojis.MiddleFinger,x))
	CH:AddSmiley("D:<", E:TextureString(E.Media.ChatEmojis.Rage,x))
	CH:AddSmiley(":o3", E:TextureString(E.Media.ChatEmojis.ScreamCat,x))
	CH:AddSmiley("XP", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes,x))
	CH:AddSmiley("8%-%)", E:TextureString(E.Media.ChatEmojis.Sunglasses,x))
	CH:AddSmiley("8%)", E:TextureString(E.Media.ChatEmojis.Sunglasses,x))
	CH:AddSmiley(":%+1:", E:TextureString(E.Media.ChatEmojis.ThumbsUp,x))
	CH:AddSmiley(":;:", E:TextureString(E.Media.ChatEmojis.SemiColon,x))
	CH:AddSmiley(";o;", E:TextureString(E.Media.ChatEmojis.Sob,x))

	-- old keys
	CH:AddSmiley(":%-@", E:TextureString(E.Media.ChatEmojis.Angry,x))
	CH:AddSmiley(":@", E:TextureString(E.Media.ChatEmojis.Angry,x))
	CH:AddSmiley(":%-%)", E:TextureString(E.Media.ChatEmojis.Smile,x))
	CH:AddSmiley(":%)", E:TextureString(E.Media.ChatEmojis.Smile,x))
	CH:AddSmiley(":D", E:TextureString(E.Media.ChatEmojis.Grin,x))
	CH:AddSmiley(":%-D", E:TextureString(E.Media.ChatEmojis.Grin,x))
	CH:AddSmiley(";%-D", E:TextureString(E.Media.ChatEmojis.Grin,x))
	CH:AddSmiley(";D", E:TextureString(E.Media.ChatEmojis.Grin,x))
	CH:AddSmiley("=D", E:TextureString(E.Media.ChatEmojis.Grin,x))
	CH:AddSmiley("xD", E:TextureString(E.Media.ChatEmojis.Grin,x))
	CH:AddSmiley("XD", E:TextureString(E.Media.ChatEmojis.Grin,x))
	CH:AddSmiley(":%-%(", E:TextureString(E.Media.ChatEmojis.SlightFrown,x))
	CH:AddSmiley(":%(", E:TextureString(E.Media.ChatEmojis.SlightFrown,x))
	CH:AddSmiley(":o", E:TextureString(E.Media.ChatEmojis.OpenMouth,x))
	CH:AddSmiley(":%-o", E:TextureString(E.Media.ChatEmojis.OpenMouth,x))
	CH:AddSmiley(":%-O", E:TextureString(E.Media.ChatEmojis.OpenMouth,x))
	CH:AddSmiley(":O", E:TextureString(E.Media.ChatEmojis.OpenMouth,x))
	CH:AddSmiley(":%-0", E:TextureString(E.Media.ChatEmojis.OpenMouth,x))
	CH:AddSmiley(":P", E:TextureString(E.Media.ChatEmojis.StuckOutTongue,x))
	CH:AddSmiley(":%-P", E:TextureString(E.Media.ChatEmojis.StuckOutTongue,x))
	CH:AddSmiley(":p", E:TextureString(E.Media.ChatEmojis.StuckOutTongue,x))
	CH:AddSmiley(":%-p", E:TextureString(E.Media.ChatEmojis.StuckOutTongue,x))
	CH:AddSmiley("=P", E:TextureString(E.Media.ChatEmojis.StuckOutTongue,x))
	CH:AddSmiley("=p", E:TextureString(E.Media.ChatEmojis.StuckOutTongue,x))
	CH:AddSmiley(";%-p", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes,x))
	CH:AddSmiley(";p", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes,x))
	CH:AddSmiley(";P", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes,x))
	CH:AddSmiley(";%-P", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes,x))
	CH:AddSmiley(";%-%)", E:TextureString(E.Media.ChatEmojis.Wink,x))
	CH:AddSmiley(";%)", E:TextureString(E.Media.ChatEmojis.Wink,x))
	CH:AddSmiley(":S", E:TextureString(E.Media.ChatEmojis.Smirk,x))
	CH:AddSmiley(":%-S", E:TextureString(E.Media.ChatEmojis.Smirk,x))
	CH:AddSmiley(":,%(", E:TextureString(E.Media.ChatEmojis.Cry,x))
	CH:AddSmiley(":,%-%(", E:TextureString(E.Media.ChatEmojis.Cry,x))
	CH:AddSmiley(":\'%(", E:TextureString(E.Media.ChatEmojis.Cry,x))
	CH:AddSmiley(":\'%-%(", E:TextureString(E.Media.ChatEmojis.Cry,x))
	CH:AddSmiley(":F", E:TextureString(E.Media.ChatEmojis.MiddleFinger,x))
	CH:AddSmiley("<3", E:TextureString(E.Media.ChatEmojis.Heart,x))
	CH:AddSmiley("</3", E:TextureString(E.Media.ChatEmojis.BrokenHeart,x))
end

function CH:BuildCopyChatFrame()
	local frame = CreateFrame("Frame", "CopyChatFrame", E.UIParent)
	tinsert(UISpecialFrames, "CopyChatFrame")
	frame:SetTemplate("Transparent")
	frame:Size(700, 200)
	frame:Point("BOTTOM", E.UIParent, "BOTTOM", 0, 3)
	frame:Hide()
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetResizable(true)
	frame:SetMinResize(350, 100)
	frame:SetScript("OnMouseDown", function(copyChat, button)
		if button == "LeftButton" and not copyChat.isMoving then
			copyChat:StartMoving()
			copyChat.isMoving = true
		elseif button == "RightButton" and not copyChat.isSizing then
			copyChat:StartSizing()
			copyChat.isSizing = true
		end
	end)
	frame:SetScript("OnMouseUp", function(copyChat, button)
		if button == "LeftButton" and copyChat.isMoving then
			copyChat:StopMovingOrSizing()
			copyChat.isMoving = false
		elseif button == "RightButton" and copyChat.isSizing then
			copyChat:StopMovingOrSizing()
			copyChat.isSizing = false
		end
	end)
	frame:SetScript("OnHide", function(copyChat)
		if copyChat.isMoving or copyChat.isSizing then
			copyChat:StopMovingOrSizing()
			copyChat.isMoving = false
			copyChat.isSizing = false
		end
	end)
	frame:SetFrameStrata("DIALOG")

	local scrollArea = CreateFrame("ScrollFrame", "CopyChatScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollArea:Point("TOPLEFT", frame, "TOPLEFT", 8, -30)
	scrollArea:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 8)
	Skins:HandleScrollBar(CopyChatScrollFrameScrollBar)
	scrollArea:SetScript("OnSizeChanged", function(scroll)
		CopyChatFrameEditBox:Width(scroll:GetWidth())
		CopyChatFrameEditBox:Height(scroll:GetHeight())
	end)
	scrollArea:HookScript("OnVerticalScroll", function(scroll, offset)
		CopyChatFrameEditBox:SetHitRectInsets(0, 0, offset, (CopyChatFrameEditBox:GetHeight() - offset - scroll:GetHeight()))
	end)

	local editBox = CreateFrame("EditBox", "CopyChatFrameEditBox", frame)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(99999)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(ChatFontNormal)
	editBox:Width(scrollArea:GetWidth())
	editBox:Height(200)
	editBox:SetScript("OnEscapePressed", function() CopyChatFrame:Hide() end)
	scrollArea:SetScrollChild(editBox)
	CopyChatFrameEditBox:SetScript("OnTextChanged", function(_, userInput)
		if userInput then return end
		local _, max = CopyChatScrollFrameScrollBar:GetMinMaxValues()
		for _ = 1, max do
			ScrollFrameTemplate_OnMouseWheel(CopyChatScrollFrame, -1)
		end
	end)

	local close = CreateFrame("Button", "CopyChatFrameCloseButton", frame, "UIPanelCloseButton")
	close:Point("TOPRIGHT")
	close:SetFrameLevel(close:GetFrameLevel() + 1)
	close:EnableMouse(true)
	Skins:HandleCloseButton(close)
end

function CH:Initialize()
	self:DelayGuildMOTD() --Keep this before `is Chat Enabled` check

	if E.private.chat.enable ~= true then return end
	self.Initialized = true
	self.db = E.db.chat

	if not ElvCharacterDB.ChatEditHistory then ElvCharacterDB.ChatEditHistory = {} end
	if not ElvCharacterDB.ChatHistoryLog or not self.db.chatHistory then ElvCharacterDB.ChatHistoryLog = {} end

	FriendsMicroButton:Kill()
	ChatFrameMenuButton:Kill()

	self:SetupChat()
	self:DefaultSmileys()
	self:UpdateChatKeywords()
	self:UpdateFading()
	self:UpdateAnchors()
	self:Panels_ColorUpdate()

	self:SecureHook("ChatEdit_OnEnterPressed")
	self:SecureHook("FCF_SetWindowAlpha")
	self:SecureHook("FCF_SetChatWindowFontSize", "SetChatFont")
	self:SecureHook("FCF_SavePositionAndDimensions", "ON_FCF_SavePositionAndDimensions")
	self:RegisterEvent("UPDATE_CHAT_WINDOWS", "SetupChat")
	self:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "SetupChat")

	if WIM then
		WIM.RegisterWidgetTrigger("chat_display", "whisper,chat,w2w,demo", "OnHyperlinkClick", function(self) CH.clickedframe = self end)
		WIM.RegisterItemRefHandler("url", HyperLinkedURL)
	end

	if not E.db.chat.lockPositions then CH:UpdateChatTabs() end --It was not done in PositionChat, so do it now

	for _, event in pairs(FindURL_Events) do
		ChatFrame_AddMessageEventFilter(event, CH[event] or CH.FindURL)
		local nType = strsub(event, 10)
		if nType ~= "AFK" and nType ~= "DND" then
			self:RegisterEvent(event, "SaveChatHistory")
		end
	end

	if self.db.chatHistory then self:DisplayChatHistory() end
	self:BuildCopyChatFrame()

	-- Editbox Backdrop Color
	hooksecurefunc("ChatEdit_UpdateHeader", function(editbox)
		local chatType = editbox:GetAttribute("chatType")
		if not chatType then return end

		local ChatTypeInfo = _G.ChatTypeInfo
		local info = ChatTypeInfo[chatType]
		local chanTarget = editbox:GetAttribute("channelTarget")
		local chanName = chanTarget and GetChannelName(chanTarget)

		--Increase inset on right side to make room for character count text
		local insetLeft, insetRight, insetTop, insetBottom = editbox:GetTextInsets()
		editbox:SetTextInsets(insetLeft, insetRight + 30, insetTop, insetBottom)

		if chanName and (chatType == "CHANNEL") then
			if chanName == 0 then
				editbox:SetBackdropBorderColor(unpack(E.media.bordercolor))
			else
				info = ChatTypeInfo[chatType..chanName]
				editbox:SetBackdropBorderColor(info.r, info.g, info.b)
			end
		else
			editbox:SetBackdropBorderColor(info.r, info.g, info.b)
		end
	end)

	GeneralDockManagerOverflowButton:ClearAllPoints()
	GeneralDockManagerOverflowButton:Point("BOTTOMRIGHT", LeftChatTab, "BOTTOMRIGHT", -2, 2)
	GeneralDockManagerOverflowButtonList:SetTemplate("Transparent")
	hooksecurefunc(GeneralDockManagerScrollFrame, "SetPoint", function(self, point, anchor, attachTo, x, y)
		if anchor == GeneralDockManagerOverflowButton and x == 0 and y == 0 then
			self:Point(point, anchor, attachTo, -2, -6)
		end
	end)

	-- Combat Log Skinning (credit: Aftermathh)
	local CombatLogButton = _G.CombatLogQuickButtonFrame_Custom
	CombatLogButton:StripTextures()
	CombatLogButton:CreateBackdrop("Default", true)
	CombatLogButton.backdrop:Point("TOPLEFT", 0, -1)
	CombatLogButton.backdrop:Point("BOTTOMRIGHT", -22, -1)

	CombatLogQuickButtonFrame_CustomProgressBar:StripTextures()
	CombatLogQuickButtonFrame_CustomProgressBar:SetStatusBarTexture(E.media.normTex)
	CombatLogQuickButtonFrame_CustomProgressBar:SetStatusBarColor(0.31, 0.31, 0.31)
	CombatLogQuickButtonFrame_CustomProgressBar:ClearAllPoints()
	CombatLogQuickButtonFrame_CustomProgressBar:SetInside(CombatLogButton.backdrop)

	Skins:HandleNextPrevButton(CombatLogQuickButtonFrame_CustomAdditionalFilterButton)
	CombatLogQuickButtonFrame_CustomAdditionalFilterButton:Size(20, 22)
	CombatLogQuickButtonFrame_CustomAdditionalFilterButton:Point("TOPRIGHT", CombatLogButton, "TOPRIGHT", 0, -1)
	CombatLogQuickButtonFrame_CustomAdditionalFilterButton:SetHitRectInsets(0, 0, 0, 0)
end

local function InitializeCallback()
	CH:Initialize()
end

E:RegisterModule(CH:GetName(), InitializeCallback)