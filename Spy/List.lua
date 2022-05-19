local Astrolabe = DongleStub("Astrolabe-0.4")
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Spy")
local _

function Spy:RefreshCurrentList(player, source)
	local MainWindow = Spy.MainWindow
	if not MainWindow:IsShown() then
		return
	end

	local mode = Spy.db.profile.CurrentList
	local manageFunction = Spy.ListTypes[mode][2]
	if manageFunction then
		manageFunction()
	end

	local button = 1
	for index, data in pairs(Spy.CurrentList) do
		if button <= Spy.ButtonLimit then
			local description = ""
			local level = "??"
			local class = "UNKNOWN"
			local guild = "??"
			local opacity = 1

			local playerData = SpyPerCharDB.PlayerData[data.player]
			if playerData then
				if playerData.level then
					level = playerData.level
					if playerData.isGuess == true and tonumber(playerData.level) < Spy.MaximumPlayerLevel then
						level = level.."+"
					end
				end
				if playerData.class then
					class = playerData.class
				end
				if playerData.guild then
					guild = playerData.guild
				end
			end
			
			if Spy.db.profile.DisplayListData == "NameLevelClass" then
				description = level.." "
				if L[class] and type(L[class]) == "string" then
					description = description..L[class]
				end
			elseif Spy.db.profile.DisplayListData == "NameLevelOnly" then
				description = level.." "
			elseif Spy.db.profile.DisplayListData == "NameGuild" then
					description = guild
			end
			
			if mode == 1 and Spy.InactiveList[data.player] then
				opacity = 0.5
			end
			if player == data.player then
				if not source or source ~= Spy.CharacterName then
					Spy:AlertPlayer(player, source)
					if not source then
						Spy:AnnouncePlayer(player)
					end
				end
			end

			Spy:SetBar(button, data.player, description, 100, "Class", class, nil, opacity)
			Spy.ButtonName[button] = data.player
			button = button + 1
		end
	end
	Spy.ListAmountDisplayed = button - 1

	if Spy.db.profile.ResizeSpy then
		Spy:AutomaticallyResize()
	else
		if not Spy.db.profile.InvertSpy then 		
			if not InCombatLockdown() and Spy.MainWindow:GetHeight()< 34 then
				Spy:RestoreMainWindowPosition(Spy.MainWindow:GetLeft(), Spy.MainWindow:GetTop(), Spy.MainWindow:GetWidth(), 34)
			end
		else
			if not InCombatLockdown() and Spy.MainWindow:GetHeight()< 34 then 
				Spy:RestoreMainWindowPosition(Spy.MainWindow:GetLeft(), Spy.MainWindow:GetBottom(), Spy.MainWindow:GetWidth(), 34)
			end
		end	
	end
	Spy:ManageBarsDisplayed()
end

function Spy:ManageNearbyList()
	local prioritiseKoS = Spy.db.profile.PrioritiseKoS

	local activeKoS = {}
	local active = {}
	for player in pairs(Spy.ActiveList) do
		local position = Spy.NearbyList[player]
		if position ~= nil then
			if prioritiseKoS and SpyPerCharDB.KOSData[player] then
				table.insert(activeKoS, { player = player, time = position })
			else
				table.insert(active, { player = player, time = position })
			end
		end
	end

	local inactiveKoS = {}
	local inactive = {}
	for player in pairs(Spy.InactiveList) do
		local position = Spy.NearbyList[player]
		if position ~= nil then
			if prioritiseKoS and SpyPerCharDB.KOSData[player] then
				table.insert(inactiveKoS, { player = player, time = position })
			else
				table.insert(inactive, { player = player, time = position })
			end
		end
	end

	table.sort(activeKoS, function(a, b) return a.time < b.time end)
	table.sort(inactiveKoS, function(a, b) return a.time < b.time end)
	table.sort(active, function(a, b) return a.time < b.time end)
	table.sort(inactive, function(a, b) return a.time < b.time end)

	local list = {}
	for player in pairs(activeKoS) do table.insert(list, activeKoS[player]) end
	for player in pairs(inactiveKoS) do table.insert(list, inactiveKoS[player]) end
	for player in pairs(active) do table.insert(list, active[player]) end
	for player in pairs(inactive) do table.insert(list, inactive[player]) end
	Spy.CurrentList = list
end

function Spy:ManageLastHourList()
	local list = {}
	for player in pairs(Spy.LastHourList) do
		table.insert(list, { player = player, time = Spy.LastHourList[player] })
	end
	table.sort(list, function(a, b) return a.time > b.time end)
	Spy.CurrentList = list
end

function Spy:ManageIgnoreList()
	local list = {}
	for player in pairs(SpyPerCharDB.IgnoreData) do
		local playerData = SpyPerCharDB.PlayerData[player]
		local position = time()
		if playerData then position = playerData.time end
		table.insert(list, { player = player, time = position })
	end
	table.sort(list, function(a, b) return a.time > b.time end)
	Spy.CurrentList = list
end

function Spy:ManageKillOnSightList()
	local list = {}
	for player in pairs(SpyPerCharDB.KOSData) do
		local playerData = SpyPerCharDB.PlayerData[player]
		local position = time()
		if playerData then position = playerData.time end
		table.insert(list, { player = player, time = position })
	end
	table.sort(list, function(a, b) return a.time > b.time end)
	Spy.CurrentList = list
end

function Spy:GetNearbyListSize()
	local entries = 0
	for v in pairs(Spy.NearbyList) do
		entries = entries + 1
	end
	return entries
end

function Spy:UpdateActiveCount()
    local activeCount = 0
    for k in pairs(Spy.ActiveList) do
        activeCount = activeCount + 1
    end
	local theFrame = Spy.MainWindow
    if activeCount > 0 then 
		theFrame.CountFrame.Text:SetText("|cFF0070DE" .. activeCount .. "|r") 
    else 
        theFrame.CountFrame.Text:SetText("|cFF0070DE0|r")
    end
end

function Spy:ManageExpirations()
	local mode = Spy.db.profile.CurrentList
	local expirationFunction = Spy.ListTypes[mode][3]
	if expirationFunction then
		expirationFunction()
	end
end

function Spy:ManageNearbyListExpirations()
	local expired = false
	local currentTime = time()
	for player in pairs(Spy.ActiveList) do
		if (currentTime - Spy.ActiveList[player]) > Spy.ActiveTimeout then
			Spy.InactiveList[player] = Spy.ActiveList[player]
			Spy.ActiveList[player] = nil
			expired = true
		end
	end
	if Spy.db.profile.RemoveUndetected ~= "Never" then
		for player in pairs(Spy.InactiveList) do
			if (currentTime - Spy.InactiveList[player]) > Spy.InactiveTimeout then
				if Spy.PlayerCommList[player] ~= nil then
					Spy.MapNoteList[Spy.PlayerCommList[player]].displayed = false
					Spy.MapNoteList[Spy.PlayerCommList[player]].worldIcon:Hide()
					Astrolabe:RemoveIconFromMinimap(Spy.MapNoteList[Spy.PlayerCommList[player]].miniIcon)
					Spy.PlayerCommList[player] = nil
				end
				Spy.InactiveList[player] = nil
				Spy.NearbyList[player] = nil
				expired = true
			end
		end
	end
	if expired then
		Spy:RefreshCurrentList()
		Spy:UpdateActiveCount()
		if Spy.db.profile.HideSpy and Spy:GetNearbyListSize() == 0 then 
			if not InCombatLockdown() then
				Spy.MainWindow:Hide()
			else	
				Spy:HideSpyCombatCheck()
			end
		end
	end
end

function Spy:ManageLastHourListExpirations()
	local expired = false
	local currentTime = time()
	for player in pairs(Spy.LastHourList) do
		if (currentTime - Spy.LastHourList[player]) > 3600 then
			Spy.LastHourList[player] = nil
			expired = true
		end
	end
	if expired then
		Spy:RefreshCurrentList()
	end
end

function Spy:RemovePlayerFromList(player)
	Spy.NearbyList[player] = nil
	Spy.ActiveList[player] = nil
	Spy.InactiveList[player] = nil
	if Spy.PlayerCommList[player] ~= nil then
		Spy.MapNoteList[Spy.PlayerCommList[player]].displayed = false
		Spy.MapNoteList[Spy.PlayerCommList[player]].worldIcon:Hide()
		Astrolabe:RemoveIconFromMinimap(Spy.MapNoteList[Spy.PlayerCommList[player]].miniIcon)
		Spy.PlayerCommList[player] = nil
	end
	Spy:RefreshCurrentList()
	Spy:UpdateActiveCount()	
end

function Spy:ClearList()
	if IsShiftKeyDown () then
		Spy:EnableSound(not Spy.db.profile.EnableSound, false)		
	else	
		Spy.NearbyList = {}
		Spy.ActiveList = {}
		Spy.InactiveList = {}
		Spy.PlayerCommList = {}
		Spy.ListAmountDisplayed = 0
		for i = 1, Spy.MapNoteLimit do
			Spy.MapNoteList[i].displayed = false
			Spy.MapNoteList[i].worldIcon:Hide()
			Astrolabe:RemoveIconFromMinimap(Spy.MapNoteList[i].miniIcon)
		end
		Spy:SetCurrentList(1)
		if IsControlKeyDown() then
			Spy:EnableSpy(not Spy.db.profile.Enabled, false)
		end
		Spy:UpdateActiveCount()
	end	
end

function Spy:AddPlayerData(name, class, level, race, guild, isEnemy, isGuess)
	local info = {}
	info.name = name  --++ added to normalize data
	info.class = class
	if type(level) == "number" then info.level = level end
	info.race = race
	info.guild = guild
	info.isEnemy = isEnemy
	info.isGuess = isGuess
	SpyPerCharDB.PlayerData[name] = info
	return SpyPerCharDB.PlayerData[name]
end

function Spy:UpdatePlayerData(name, class, level, race, guild, isEnemy, isGuess)
	local detected = true
	local playerData = SpyPerCharDB.PlayerData[name]
	if not playerData then
		playerData = Spy:AddPlayerData(name, class, level, race, guild, isEnemy, isGuess)
	else
		if name ~= nil then playerData.name = name end  
		if class ~= nil then playerData.class = class end
		if type(level) == "number" then playerData.level = level end
		if race ~= nil then playerData.race = race end
		if guild ~= nil then playerData.guild = guild end
		if isEnemy ~= nil then playerData.isEnemy = isEnemy end
		if isGuess ~= nil then playerData.isGuess = isGuess end
	end
	if playerData then
		playerData.time = time()
		if not Spy.ActiveList[name] then
			if WorldMapFrame:IsVisible() and Spy.db.profile.SwitchToZone then
				SetMapToCurrentZone()
			end
			local mapX, mapY = GetPlayerMapPosition("player")
			if mapX ~= 0 and mapY ~= 0 then
				mapX = math.floor(tonumber(mapX) * 100) / 100
				mapY = math.floor(tonumber(mapY) * 100) / 100
				playerData.mapX = mapX
				playerData.mapY = mapY
				playerData.zone = GetZoneText()
				playerData.subZone = GetSubZoneText()
			else
				detected = false
			end
		end
	end
	return detected
end

function Spy:UpdatePlayerStatus(name, class, level, race, guild, isEnemy, isGuess)
	local playerData = SpyPerCharDB.PlayerData[name]
	if not playerData then
		playerData = Spy:AddPlayerData(name, class, level, race, guild, isEnemy, isGuess)
	else
		if name ~= nil then playerData.name = name end  
		if class ~= nil then playerData.class = class end
		if type(level) == "number" then playerData.level = level end
		if race ~= nil then playerData.race = race end
		if guild ~= nil then playerData.guild = guild end
		if isEnemy ~= nil then playerData.isEnemy = isEnemy end
		if isGuess ~= nil then playerData.isGuess = isGuess end
	end
	if playerData.time == nil then
		playerData.time = time()
	end	
end

function Spy:RemovePlayerData(name)
	SpyPerCharDB.PlayerData[name] = nil
end

function Spy:AddIgnoreData(name)
	SpyPerCharDB.IgnoreData[name] = true
end

function Spy:RemoveIgnoreData(name)
	if SpyPerCharDB.IgnoreData[name] then
		SpyPerCharDB.IgnoreData[name] = nil
	end
end

function Spy:AddKOSData(name)
	SpyPerCharDB.KOSData[name] = time()
--	SpyPerCharDB.PlayerData[name].kos = 1 
	if Spy.db.profile.ShareKOSBetweenCharacters then
		SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][name] = nil
	end
end

function Spy:RemoveKOSData(name)
	if SpyPerCharDB.KOSData[name] then
		local playerData = SpyPerCharDB.PlayerData[name]
		if playerData and playerData.reason then
			playerData.reason = nil
		end
		SpyPerCharDB.KOSData[name] = nil
		SpyPerCharDB.PlayerData[name].kos = nil		
		if Spy.db.profile.ShareKOSBetweenCharacters then
			SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][name] = time()
		end
	end
end

function Spy:SetKOSReason(name, reason, other)
	local playerData = SpyPerCharDB.PlayerData[name]
	if playerData then
		if not reason then
			playerData.reason = nil
		else
			if not playerData.reason then playerData.reason = {} end
			if reason == L["KOSReasonOther"] then
				if not other then 
					local dialog = StaticPopup_Show("Spy_SetKOSReasonOther", name)
					if dialog then
						dialog.playerName = name
					end
				else
					if other == "" then
						playerData.reason[L["KOSReasonOther"]] = nil
					else
						playerData.reason[L["KOSReasonOther"]] = other
					end
					Spy:RegenerateKOSCentralList(name)
				end
			else
				if playerData.reason[reason] then
					playerData.reason[reason] = nil
				else
					playerData.reason[reason] = true
				end
				Spy:RegenerateKOSCentralList(name)
			end
		end
	end
end

function Spy:AlertPlayer(player, source)
	local playerData = SpyPerCharDB.PlayerData[player]
	if SpyPerCharDB.KOSData[player] and Spy.db.profile.WarnOnKOS then
--		if Spy.db.profile.DisplayWarningsInErrorsFrame then
		if Spy.db.profile.DisplayWarnings == "ErrorFrame" then
			local text = Spy.db.profile.Colors.Warning["Warning Text"]
			local msg = L["KOSWarning"]..player
			UIErrorsFrame:AddMessage(msg, text.r, text.g, text.b, 1.0, UIERRORS_HOLD_TIME)
		else
			if source ~= nil and source ~= Spy.CharacterName then
				Spy:ShowAlert("kosaway", player, source, Spy:GetPlayerLocation(playerData))
			else
				local reasonText = ""
				if playerData.reason then
					for reason in pairs(playerData.reason) do
						if reasonText ~= "" then reasonText = reasonText..", " end
						if reason == L["KOSReasonOther"] then
							reasonText = reasonText..playerData.reason[reason]
						else
							reasonText = reasonText..reason
						end
					end
				end
				Spy:ShowAlert("kos", player, nil, reasonText)
			end
		end
		if Spy.db.profile.EnableSound then
			if source ~= nil and source ~= Spy.CharacterName then
				PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-kosaway.mp3", Spy.db.profile.SoundChannel)
			else
				PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-kos.mp3", Spy.db.profile.SoundChannel)
			end
		end
		if Spy.db.profile.ShareKOSBetweenCharacters then Spy:RegenerateKOSCentralList(player) end
	elseif Spy.db.profile.WarnOnKOSGuild then
		if playerData and playerData.guild and Spy.KOSGuild[playerData.guild] then
--			if Spy.db.profile.DisplayWarningsInErrorsFrame then
			if Spy.db.profile.DisplayWarnings == "ErrorFrame" then
				local text = Spy.db.profile.Colors.Warning["Warning Text"]
				local msg = L["KOSGuildWarning"].."<"..playerData.guild..">"
				UIErrorsFrame:AddMessage(msg, text.r, text.g, text.b, 1.0, UIERRORS_HOLD_TIME)				
			else
				if source ~= nil and source ~= Spy.CharacterName then
					Spy:ShowAlert("kosguildaway", "<"..playerData.guild..">", source, Spy:GetPlayerLocation(playerData))
				else
					Spy:ShowAlert("kosguild", "<"..playerData.guild..">")
				end
			end
			if Spy.db.profile.EnableSound then
				if source ~= nil and source ~= Spy.CharacterName then
					PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-kosaway.mp3", Spy.db.profile.SoundChannel)
				else
					PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-kosguild.mp3", Spy.db.profile.SoundChannel)
				end
			end
		else
			if Spy.db.profile.EnableSound and not Spy.db.profile.OnlySoundKoS then 
				if source == nil or source == Spy.CharacterName then
					if playerData and Spy.db.profile.WarnOnRace and playerData.race == Spy.db.profile.SelectWarnRace then --++
						PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-race.mp3", Spy.db.profile.SoundChannel) 
					else
						PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-nearby.mp3", Spy.db.profile.SoundChannel)
					end
				end
			end
		end 
	elseif Spy.db.profile.EnableSound and not Spy.db.profile.OnlySoundKoS then 
		if source == nil or source == Spy.CharacterName then
			if playerData and Spy.db.profile.WarnOnRace and playerData.race == Spy.db.profile.SelectWarnRace then
				PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-race.mp3", Spy.db.profile.SoundChannel) 
			else
				PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-nearby.mp3", Spy.db.profile.SoundChannel)
			end
		end
	elseif Spy.db.profile.EnableSound and not Spy.db.profile.OnlySoundKoS then
		if source == nil or source == Spy.CharacterName then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-nearby.mp3", Spy.db.profile.SoundChannel)
		end
	end
end

function Spy:AlertStealthPlayer(player)
	if Spy.db.profile.WarnOnStealth then
--		if Spy.db.profile.DisplayWarningsInErrorsFrame then
		if Spy.db.profile.DisplayWarnings == "ErrorFrame" then
			local text = Spy.db.profile.Colors.Warning["Warning Text"]
			local msg = L["StealthWarning"]..player
			UIErrorsFrame:AddMessage(msg, text.r, text.g, text.b, 1.0, UIERRORS_HOLD_TIME)
		else
			Spy:ShowAlert("stealth", player)
		end
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-stealth.mp3", Spy.db.profile.SoundChannel)
		end
	end
end

function Spy:AlertProwlPlayer(player)
	if Spy.db.profile.WarnOnStealth then
--		if Spy.db.profile.DisplayWarningsInErrorsFrame then
		if Spy.db.profile.DisplayWarnings == "ErrorFrame" then
			local text = Spy.db.profile.Colors.Warning["Warning Text"]
			local msg = L["StealthWarning"]..player
			UIErrorsFrame:AddMessage(msg, text.r, text.g, text.b, 1.0, UIERRORS_HOLD_TIME)
		else
			Spy:ShowAlert("prowl", player)
		end
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-stealth.mp3", Spy.db.profile.SoundChannel)
		end
	end
end

function Spy:AnnouncePlayer(player, channel)
	if not Spy_IgnoreList[player] then
		local msg = ""
		local isKOS = SpyPerCharDB.KOSData[player]
		local playerData = SpyPerCharDB.PlayerData[player]

		local announce = Spy.db.profile.Announce  
		if channel or announce == "Self" or announce == "LocalDefense" or (announce == "Guild" and GetGuildInfo("player") ~= nil and not Spy.InInstance) or (announce == "Party" and GetNumGroupMembers() > 0) or (announce == "Raid" and UnitInRaid("player")) then --++
			if announce == "Self" and not channel then
				if isKOS then
					msg = msg..L["SpySignatureColored"]..L["KillOnSightDetectedColored"]..player.." "
				else
					msg = msg..L["SpySignatureColored"]..L["PlayerDetectedColored"]..player.." "
				end
			else
				if isKOS then
					msg = msg..L["KillOnSightDetected"]..player.." "
				else
					msg = msg..L["PlayerDetected"]..player.." "
				end
			end
			if playerData then
				if playerData.guild and playerData.guild ~= "" then
					msg = msg.."<"..playerData.guild.."> "
				end
				if playerData.level or playerData.race or (playerData.class and playerData.class ~= "") then
					msg = msg.."- "
					if playerData.level and playerData.isGuess == false then
						msg = msg..L["Level"].." "..playerData.level.." "
					end
					if playerData.race and playerData.race ~= "" then
						msg = msg..playerData.race.." "
					end
					if playerData.class and playerData.class ~= "" then
						msg = msg..L[playerData.class].." "
					end
				end
				if playerData.zone then
					if playerData.subZone and playerData.subZone ~= "" and playerData.subZone ~= playerData.zone then
						msg = msg.."- "..playerData.subZone..", "..playerData.zone
					else
						msg = msg.."- "..playerData.zone
					end
				end
				if playerData.mapX and playerData.mapY then
					msg = msg.." ("..math.floor(tonumber(playerData.mapX) * 100)..","..math.floor(tonumber(playerData.mapY) * 100)..")"
				end
			end

			if channel then
				-- announce to selected channel
				if (channel == "PARTY" and GetNumGroupMembers() > 0) or (channel == "RAID" and UnitInRaid("player")) or (channel == "GUILD" and GetGuildInfo("player") ~= nil) then
					SendChatMessage(msg, channel)
				elseif channel == "LOCAL" then
					SendChatMessage(msg, "CHANNEL", nil, GetChannelName(L["LocalDefenseChannelName"].." - "..GetZoneText()))
				end
			else
				-- announce to standard channel
				if isKOS or not Spy.db.profile.OnlyAnnounceKoS then
					if announce == "Self" then
						DEFAULT_CHAT_FRAME:AddMessage(msg)
					elseif announce == "LocalDefense" then
						SendChatMessage(msg, "CHANNEL", nil, GetChannelName(L["LocalDefenseChannelName"].." - "..GetZoneText()))
					else
						SendChatMessage(msg, strupper(announce))
					end
				end
			end
		end

		-- announce to other Spy users
		if Spy.db.profile.ShareData then
			local class, level, race, zone, subZone, mapX, mapY, guild = "", "", "", "", "", "", "", ""
			if playerData then
				if playerData.class then class = playerData.class end
				if playerData.level and playerData.isGuess == false then level = playerData.level end
				if playerData.race then race = playerData.race end
				if playerData.zone then zone = playerData.zone end
				if playerData.subZone then subZone = playerData.subZone end
				if playerData.mapX then mapX = playerData.mapX end
				if playerData.mapY then mapY = playerData.mapY end
				if playerData.guild then guild = playerData.guild end
			end
			local details = Spy.Version.."|"..player.."|"..class.."|"..level.."|"..race.."|"..zone.."|"..subZone.."|"..mapX.."|"..mapY.."|"..guild
			if strlen(details) < 240 then
				if channel then
					if (channel == "PARTY" and GetNumGroupMembers() > 0) or (channel == "RAID" and UnitInRaid("player")) or (channel == "GUILD" and GetGuildInfo("player") ~= nil) then
						Spy:SendCommMessage(Spy.Signature, details, channel)
					end
				else
					if GetNumGroupMembers() > 0 then
						Spy:SendCommMessage(Spy.Signature, details, "PARTY")
					end
					if UnitInRaid("player") then
						Spy:SendCommMessage(Spy.Signature, details, "RAID")
					end
					if Spy.InInstance == false and GetGuildInfo("player") ~= nil then
						Spy:SendCommMessage(Spy.Signature, details, "GUILD")
					end
				end
			end
		end
	end	
end

function Spy:SendKoStoGuild(player)
	local playerData = SpyPerCharDB.PlayerData[player]
	local class, level, race, zone, subZone, mapX, mapY, guild = "", "", "", "", "", "", "", ""
	if playerData then
		if playerData.class then class = playerData.class end
		if playerData.level and playerData.isGuess == false then level = playerData.level end
		if playerData.race then race = playerData.race end
		if playerData.zone then zone = playerData.zone end
		if playerData.subZone then subZone = playerData.subZone end
		if playerData.mapX then mapX = playerData.mapX end
		if playerData.mapY then mapY = playerData.mapY end
		if playerData.guild then guild = playerData.guild end
	end
	local details = Spy.Version.."|"..player.."|"..class.."|"..level.."|"..race.."|"..zone.."|"..subZone.."|"..mapX.."|"..mapY.."|"..guild
	if strlen(details) < 240 then
		if Spy.InInstance == false and GetGuildInfo("player") ~= nil then
			Spy:SendCommMessage(Spy.Signature, details, "GUILD")
		end
	end
end

function Spy:ToggleIgnorePlayer(ignore, player)
	if ignore then
		Spy:AddIgnoreData(player)
		Spy:RemoveKOSData(player)
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\list-add.mp3", Spy.db.profile.SoundChannel)
		end
		DEFAULT_CHAT_FRAME:AddMessage(L["SpySignatureColored"]..L["PlayerAddedToIgnoreColored"]..player)
	else
		Spy:RemoveIgnoreData(player)
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\list-remove.mp3", Spy.db.profile.SoundChannel)
		end
		DEFAULT_CHAT_FRAME:AddMessage(L["SpySignatureColored"]..L["PlayerRemovedFromIgnoreColored"]..player)
	end
	Spy:RegenerateKOSGuildList()
	if Spy.db.profile.ShareKOSBetweenCharacters then
		Spy:RegenerateKOSCentralList()
	end
	Spy:RefreshCurrentList()
end

function Spy:ToggleKOSPlayer(kos, player)
	if kos then
		Spy:AddKOSData(player)
		Spy:RemoveIgnoreData(player)
		if player ~= SpyPerCharDB.PlayerData[name] then
--			Spy:UpdatePlayerData(player, nil, nil, nil, nil, true, nil)
			Spy:UpdatePlayerStatus(player, nil, nil, nil, nil, true, nil)
			SpyPerCharDB.PlayerData[player].kos = 1 
		end	
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\list-add.mp3", Spy.db.profile.SoundChannel)
		end
		DEFAULT_CHAT_FRAME:AddMessage(L["SpySignatureColored"]..L["PlayerAddedToKOSColored"]..player)
	else
		Spy:RemoveKOSData(player)
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\list-remove.mp3", Spy.db.profile.SoundChannel)
		end
		DEFAULT_CHAT_FRAME:AddMessage(L["SpySignatureColored"]..L["PlayerRemovedFromKOSColored"]..player)
	end
	Spy:RegenerateKOSGuildList()
	if Spy.db.profile.ShareKOSBetweenCharacters then
		Spy:RegenerateKOSCentralList()
	end
	Spy:RefreshCurrentList()
end

function Spy:PurgeUndetectedData()
	local secondsPerDay = 60 * 60 * 24
	local timeout = 90 * secondsPerDay
	if Spy.db.profile.PurgeData == "OneDay" then
		timeout = secondsPerDay
	elseif Spy.db.profile.PurgeData == "FiveDays" then
		timeout = 5 * secondsPerDay
	elseif Spy.db.profile.PurgeData == "TenDays" then
		timeout = 10 * secondsPerDay
	elseif Spy.db.profile.PurgeData == "ThirtyDays" then
		timeout = 30 * secondsPerDay
	elseif Spy.db.profile.PurgeData == "SixtyDays" then
		timeout = 60 * secondsPerDay
	elseif Spy.db.profile.PurgeData == "NinetyDays" then
		timeout = 90 * secondsPerDay
	end

	-- remove expired players held in character data
	local currentTime = time()
	for player in pairs(SpyPerCharDB.PlayerData) do
		local playerData = SpyPerCharDB.PlayerData[player]
		if Spy.db.profile.PurgeWinLossData then
			if not playerData.time or (currentTime - playerData.time) > timeout or not playerData.isEnemy then
				Spy:RemoveIgnoreData(player)
				Spy:RemoveKOSData(player)
				SpyPerCharDB.PlayerData[player] = nil
			end
		else
			if ((playerData.loses == nil) and (playerData.wins == nil)) then
				if not playerData.time or (currentTime - playerData.time) > timeout or not playerData.isEnemy then
					Spy:RemoveIgnoreData(player)
					if Spy.db.profile.PurgeKoS then
						Spy:RemoveKOSData(player)
						SpyPerCharDB.PlayerData[player] = nil
					else
						if (playerData.kos == nil) then
							SpyPerCharDB.PlayerData[player] = nil
						end	
					end	
				end
			end
		end
	end
	
	-- remove expired kos players held in central data
	local kosData = SpyDB.kosData[Spy.RealmName][Spy.FactionName]
	for characterName in pairs(kosData) do
		local characterKosData = kosData[characterName]
		for player in pairs(characterKosData) do
			local kosPlayerData = characterKosData[player]
			if Spy.db.profile.PurgeKoS then
				if not kosPlayerData.time or (currentTime - kosPlayerData.time) > timeout or not kosPlayerData.isEnemy then
					SpyDB.kosData[Spy.RealmName][Spy.FactionName][characterName][player] = nil
					SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][player] = nil
				end
			end
		end
	end
	if not Spy.db.profile.AppendUnitNameCheck then 	
		Spy:AppendUnitNames() end
	if not Spy.db.profile.AppendUnitKoSCheck then
		Spy:AppendUnitKoS() end
end

function Spy:RegenerateKOSGuildList()
	Spy.KOSGuild = {}
	for player in pairs(SpyPerCharDB.KOSData) do
		local playerData = SpyPerCharDB.PlayerData[player]
		if playerData and playerData.guild then
			Spy.KOSGuild[playerData.guild] = true
		end
	end
end

function Spy:RemoveLocalKOSPlayers()
	for player in pairs(SpyPerCharDB.KOSData) do
		if SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][player] then
			Spy:RemoveKOSData(player)
		end
	end
end

function Spy:RegenerateKOSCentralList(player)
	if player then
		local playerData = SpyPerCharDB.PlayerData[player]
		SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player] = {}
		if playerData then
			SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player] = playerData
		end
		SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player].added = SpyPerCharDB.KOSData[player]
	else
		for player in pairs(SpyPerCharDB.KOSData) do
			local playerData = SpyPerCharDB.PlayerData[player]
			SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player] = {}
			if playerData then
				SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player] = playerData
			end
			SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player].added = SpyPerCharDB.KOSData[player]
		end
	end
end

function Spy:RegenerateKOSListFromCentral()
	local kosData = SpyDB.kosData[Spy.RealmName][Spy.FactionName]
	for characterName in pairs(kosData) do
		if characterName ~= Spy.CharacterName then
			local characterKosData = kosData[characterName]
			for player in pairs(characterKosData) do
				if not SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][player] then
					local playerData = SpyPerCharDB.PlayerData[player]
					if not playerData then
						playerData = Spy:AddPlayerData(player, class, level, race, guild, isEnemy, isGuess)
					end
					local kosPlayerData = characterKosData[player]
					if kosPlayerData.time and (not playerData.time or (playerData.time and playerData.time < kosPlayerData.time)) then
						playerData.time = kosPlayerData.time
						if kosPlayerData.class then
							playerData.class = kosPlayerData.class
						end
						if type(kosPlayerData.level) == "number" and (type(playerData.level) ~= "number" or playerData.level < kosPlayerData.level) then
							playerData.level = kosPlayerData.level
						end
						if kosPlayerData.race then
							playerData.race = kosPlayerData.race
						end
						if kosPlayerData.guild then
							playerData.guild = kosPlayerData.guild
						end
						if kosPlayerData.isEnemy then
							playerData.isEnemy = kosPlayerData.isEnemy
						end
						if kosPlayerData.isGuess then
							playerData.isGuess = kosPlayerData.isGuess
						end
						if type(kosPlayerData.wins) == "number" and (type(playerData.wins) ~= "number" or playerData.wins < kosPlayerData.wins) then
							playerData.wins = kosPlayerData.wins
						end
						if type(kosPlayerData.loses) == "number" and (type(playerData.loses) ~= "number" or playerData.loses < kosPlayerData.loses) then
							playerData.loses = kosPlayerData.loses
						end
						if kosPlayerData.mapX then
							playerData.mapX = kosPlayerData.mapX
						end
						if kosPlayerData.mapY then
							playerData.mapY = kosPlayerData.mapY
						end
						if kosPlayerData.zone then
							playerData.zone = kosPlayerData.zone
						end
						if kosPlayerData.subZone then
							playerData.subZone = kosPlayerData.subZone
						end
						if kosPlayerData.reason then
							playerData.reason = {}
							for reason in pairs(kosPlayerData.reason) do
								playerData.reason[reason] = kosPlayerData.reason[reason]
							end
						end
					end
					local characterKOSPlayerData = SpyPerCharDB.KOSData[player]
					if kosPlayerData.added and (not characterKOSPlayerData or characterKOSPlayerData < kosPlayerData.added) then
						SpyPerCharDB.KOSData[player] = kosPlayerData.added
					end
				end
			end
		end
	end
end

function Spy:ButtonClicked(self, button)
	local name = Spy.ButtonName[self.id]
	if name and name ~= "" then
		if button == "LeftButton" then
			if IsShiftKeyDown() then
				if SpyPerCharDB.KOSData[name] then
					Spy:ToggleKOSPlayer(false, name)
				else
					Spy:ToggleKOSPlayer(true, name)
				end
			elseif IsControlKeyDown() then
				if SpyPerCharDB.IgnoreData[name] then
					Spy:ToggleIgnorePlayer(false, name)
				else
					Spy:ToggleIgnorePlayer(true, name)
				end
			else
				if not InCombatLockdown() then
					self:SetAttribute("macrotext", "/targetexact "..name)
				end	
			end
		elseif button == "RightButton" then
			Spy:BarDropDownOpen(self)
			CloseDropDownMenus(1)
			ToggleDropDownMenu(1, nil, Spy_BarDropDownMenu)
		end
	end
end

function Spy:ParseMinimapTooltip(tooltip)
	local newTooltip = ""
	local newLine = false
	for text in string.gmatch(tooltip, "[^\n]*") do
		local name = text
		if string.len(text) > 0 then
			if strsub(text, 1, 2) == "|T" then
			name = strtrim(gsub(gsub(text, "|T.-|t", ""), "|r", ""))
			end
			local playerData = SpyPerCharDB.PlayerData[name]
			if not playerData then
				for index, v in pairs(Spy.LastHourList) do
					local realmSeparator = strfind(index, "-")
					if realmSeparator and realmSeparator > 1 and strsub(index, 1, realmSeparator - 1) == strsub(name, 1, realmSeparator - 1) then
						playerData = SpyPerCharDB.PlayerData[index]
						break
					end
				end
			end
			if playerData and playerData.isEnemy then
				local desc = ""
				if playerData.class and playerData.level then
					desc = L["MinimapClassText"..playerData.class].." ["..playerData.level.." "..L[playerData.class].."]|r"
				elseif playerData.class then
					desc = L["MinimapClassText"..playerData.class].." ["..L[playerData.class].."]|r"
				elseif playerData.level then
					desc = " ["..playerData.level.."]|r"
				end
				if (newTooltip and desc == "") then
					newTooltip = text 
				elseif (newTooltip == "") then	
					newTooltip = text.."|r"..desc
				else
					newTooltip = newTooltip.."\r"..text.."|r"..desc
				end	
				if not SpyPerCharDB.IgnoreData[name] and not Spy.InInstance then
					local detected = Spy:UpdatePlayerData(name, nil, nil, nil, nil, true, nil)
					if detected and Spy.db.profile.MinimapDetection then
						Spy:AddDetected(name, time(), false)
					end
				end
			else
				if (newTooltip == "") then
					newTooltip = text
				else	
					newTooltip = newTooltip.."\n"..text
				end
			end
			newLine = false
		elseif not newLine then
			newTooltip = newTooltip
			newLine = true
		end
	end
	return newTooltip
end

function Spy:ParseUnitAbility(analyseSpell, event, player, class, race, spellId, spellName)
	local learnt = false
	if player then
--		local class = nil
		local level = nil
--		local race = nil
		local isEnemy = true
		local isGuess = true

		local playerData = SpyPerCharDB.PlayerData[player]
		if not playerData or playerData.isEnemy == nil then
			learnt = true
		end

		if analyseSpell then
			local abilityType = strsub(event, 1, 5)
			if abilityType == "SWING" or abilityType == "SPELL" or abilityType == "RANGE" then
				local ability = Spy_AbilityList[spellName]
--				local ability = Spy_AbilityList[spellId]
				if ability then
					if class == nil then
						if ability.class and not (playerData and playerData.class) then
							class = ability.class
							learnt = true
						end
					end
					if ability.level then
						local playerLevelNumber = nil
						if playerData and playerData.level then
							playerLevelNumber = tonumber(playerData.level)
						end
						if type(playerLevelNumber) ~= "number" or playerLevelNumber < ability.level then
							level = ability.level
							learnt = true
						end
					end
					if race == nil then
						if ability.race and not (playerData and playerData.race) then
							race = ability.race
							learnt = true
						end
					end	
				else	
--					print(spellId, " - ", spellName)
				end
				if class and race and level == Spy.MaximumPlayerLevel then
					isGuess = false
					learnt = true
				end
			end
		end

		Spy:UpdatePlayerData(player, class, level, race, nil, isEnemy, isGuess)
		return learnt, playerData
	end
	return learnt, nil
end

function Spy:ParseUnitDetails(player, class, level, race, zone, subZone, mapX, mapY, guild)
	if player then
		local playerData = SpyPerCharDB.PlayerData[player]
		if not playerData then
			playerData = Spy:AddPlayerData(player, class, level, race, guild, true, true)
		else
			if not playerData.class then playerData.class = class end
			if level then
				local levelNumber = tonumber(level)
				if type(levelNumber) == "number" then
					if playerData.level then
						local playerLevelNumber = tonumber(playerData.level)
						if type(playerLevelNumber) == "number" and playerLevelNumber < levelNumber then playerData.level = levelNumber end
					else
						playerData.level = levelNumber
					end
				end
			end
			if not playerData.race then
				playerData.race = race
			end
			if not playerData.guild then
				playerData.guild = guild
			end
		end
		playerData.isEnemy = true
		playerData.time = time()
		playerData.zone = zone
		playerData.subZone = subZone
		playerData.mapX = mapX
		playerData.mapY = mapY

		return true, playerData
	end
	return true, nil
end

function Spy:AddDetected(player, timestamp, learnt, source)
	if Spy.db.profile.StopAlertsOnTaxi then
		if not UnitOnTaxi("player") then 
			Spy:AddDetectedToLists(player, timestamp, learnt, source)
		end
	else
		Spy:AddDetectedToLists(player, timestamp, learnt, source)
	end
--[[if Spy.db.profile.ShowOnlyPvPFlagged then
		if UnitIsPVP("target") then		
			Spy:AddDetectedToLists(player, timestamp, learnt, source)
		end	
	else
		Spy:AddDetectedToLists(player, timestamp, learnt, source)
	end ]]--
end

function Spy:AddDetectedToLists(player, timestamp, learnt, source)
	if not Spy.NearbyList[player] then
		if Spy.db.profile.ShowOnDetection and not Spy.db.profile.MainWindowVis then
			Spy:SetCurrentList(1)
			Spy:EnableSpy(true, true, true)
		end
		if Spy.db.profile.CurrentList ~= 1 and Spy.db.profile.MainWindowVis and Spy.db.profile.ShowNearbyList then
			Spy:SetCurrentList(1)
		end

		if source and source ~= Spy.CharacterName and not Spy.ActiveList[player] then
			Spy.NearbyList[player] = timestamp
			Spy.LastHourList[player] = timestamp
			Spy.InactiveList[player] = timestamp
		else
			Spy.NearbyList[player] = timestamp
			Spy.LastHourList[player] = timestamp
			Spy.ActiveList[player] = timestamp
			Spy.InactiveList[player] = nil
		end

		if Spy.db.profile.CurrentList == 1 then
			Spy:RefreshCurrentList(player, source)
			Spy:UpdateActiveCount()			
		else
			if not source or source ~= Spy.CharacterName then
				Spy:AlertPlayer(player, source)
				if not source then Spy:AnnouncePlayer(player) end
			end
		end
	elseif not Spy.ActiveList[player] then
		if Spy.db.profile.ShowOnDetection and not Spy.db.profile.MainWindowVis then
			Spy:SetCurrentList(1)
			Spy:EnableSpy(true, true, true)
		end
		if Spy.db.profile.CurrentList ~= 1 and Spy.db.profile.MainWindowVis and Spy.db.profile.ShowNearbyList then
			Spy:SetCurrentList(1)
		end

		Spy.LastHourList[player] = timestamp
		Spy.ActiveList[player] = timestamp
		Spy.InactiveList[player] = nil

		if Spy.PlayerCommList[player] ~= nil then
			if Spy.db.profile.CurrentList == 1 then
				Spy:RefreshCurrentList(player, source)
			else
				if not source or source ~= Spy.CharacterName then
					Spy:AlertPlayer(player, source)
					if not source then Spy:AnnouncePlayer(player) end
				end
			end
		else
			if Spy.db.profile.CurrentList == 1 then
				Spy:RefreshCurrentList()
				Spy:UpdateActiveCount()						
			end
		end
	else
		Spy.ActiveList[player] = timestamp
		Spy.LastHourList[player] = timestamp
		if learnt and Spy.db.profile.CurrentList == 1 then
			Spy:RefreshCurrentList()
			Spy:UpdateActiveCount()	
		end
	end
end

function Spy:AppendUnitNames()
	for key, unit in pairs(SpyPerCharDB.PlayerData) do	
		-- find any units without a name
		if not unit.name then			
			local name = key
		-- if unit.name does not exist update info
			if (not unit.name) and name then
				unit.name = key
			end		
		end
    end
	-- set profile so it only runs once
	Spy.db.profile.AppendUnitNameCheck=true
end

function Spy:AppendUnitKoS()
	for kosName, value in pairs(SpyPerCharDB.KOSData) do	
		if kosName then	
			local playerData = SpyPerCharDB.PlayerData[kosName]
			if not playerData then 
				Spy:UpdatePlayerData(kosName, nil, nil, nil, nil, true, nil) 
				SpyPerCharDB.PlayerData[kosName].kos = 1 
				SpyPerCharDB.PlayerData[kosName].time = value			
			end		
		end
    end
	-- set profile so it only runs once
	Spy.db.profile.AppendUnitKoSCheck=true
end

Spy.ListTypes = {
	{L["Nearby"], Spy.ManageNearbyList, Spy.ManageNearbyListExpirations},
	{L["LastHour"], Spy.ManageLastHourList, Spy.ManageLastHourListExpirations},
	{L["Ignore"], Spy.ManageIgnoreList},
	{L["KillOnSight"], Spy.ManageKillOnSightList},
}

Spy_AbilityList = {
--== Racials ==
	[GetSpellInfo(58984)] = {race = "Night Elf", level = 1},
	[GetSpellInfo(7744)] = {race = "Undead", level = 1},
	[GetSpellInfo(50642)] = {race = "Undead", level = 1},
	[GetSpellInfo(26297)] = {race = "Troll", level = 1},
	[GetSpellInfo(20549)] = {race = "Tauren", level = 1},
	[GetSpellInfo(20572)] = {race = "Orc", level = 1},
	[GetSpellInfo(25046)] = {race = "Blood Elf", level = 1},
	[GetSpellInfo(58985)] = {race = "Human", level = 1},
	[GetSpellInfo(20589)] = {race = "Gnome", level = 1},
	[GetSpellInfo(20594)] = {race = "Dwarf", level = 1},
	[GetSpellInfo(28880)] = {race = "Draenei", level = 1},

--== Death Knight ==
	[GetSpellInfo(53137)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49200)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49182)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(61154)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49027)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(48988)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(48979)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(50040)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49149)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49032)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(55666)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(51099)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49137)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(50880)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49004)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49015)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(51052)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49222)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49796)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(63560)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49203)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49016)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(55610)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49039)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49005)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(55233)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49146)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(48982)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49189)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(51271)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(55095)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(55078)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(53341)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(53331)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(53343)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(54447)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(53342)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(54446)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(53323)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(53344)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(62158)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(48778)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(54476)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(48977)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(55050)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49143)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(55090)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49158)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49194)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(50977)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(51399)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49410)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(49175)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(59133)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(53424)] = {class = "DEATHKNIGHT", level = 55},
	[GetSpellInfo(71489)] = {class = "DEATHKNIGHT", level = 56},
	[GetSpellInfo(51426)] = {class = "DEATHKNIGHT", level = 56},
	[GetSpellInfo(46585)] = {class = "DEATHKNIGHT", level = 56},
	[GetSpellInfo(48263)] = {class = "DEATHKNIGHT", level = 57},
	[GetSpellInfo(53550)] = {class = "DEATHKNIGHT", level = 57},
	[GetSpellInfo(65658)] = {class = "DEATHKNIGHT", level = 58},
	[GetSpellInfo(66020)] = {class = "DEATHKNIGHT", level = 58},
	[GetSpellInfo(48680)] = {class = "DEATHKNIGHT", level = 59},
	[GetSpellInfo(49028)] = {class = "DEATHKNIGHT", level = 60},
	[GetSpellInfo(52212)] = {class = "DEATHKNIGHT", level = 60},
	[GetSpellInfo(49184)] = {class = "DEATHKNIGHT", level = 60},
	[GetSpellInfo(49206)] = {class = "DEATHKNIGHT", level = 60},
	[GetSpellInfo(66972)] = {class = "DEATHKNIGHT", level = 61},
	[GetSpellInfo(61081)] = {class = "DEATHKNIGHT", level = 61},
	[GetSpellInfo(66023)] = {class = "DEATHKNIGHT", level = 62},
	[GetSpellInfo(51135)] = {class = "DEATHKNIGHT", level = 64},
	[GetSpellInfo(56222)] = {class = "DEATHKNIGHT", level = 65},
	[GetSpellInfo(57330)] = {class = "DEATHKNIGHT", level = 65},
	[GetSpellInfo(51956)] = {class = "DEATHKNIGHT", level = 66},
	[GetSpellInfo(62036)] = {class = "DEATHKNIGHT", level = 67},
	[GetSpellInfo(53766)] = {class = "DEATHKNIGHT", level = 68},
	[GetSpellInfo(49772)] = {class = "DEATHKNIGHT", level = 70},
	[GetSpellInfo(46619)] = {class = "DEATHKNIGHT", level = 72},
	[GetSpellInfo(47568)] = {class = "DEATHKNIGHT", level = 75},
	[GetSpellInfo(67761)] = {class = "DEATHKNIGHT", level = 80},

--== Druid == 
	["Healing Touch"] = {class = "DRUID", level = 1},
	["Mark of the Wild"] = {class = "DRUID", level = 1},
	["Wrath"] = {class = "DRUID", level = 1},
	["Moonfire"] = {class = "DRUID", level = 4},
	["Rejuvenation"] = {class = "DRUID", level = 4},
	["Cower"] = {class = "DRUID", level = 5},
	["Thorns"] = {class = "DRUID", level = 6},
	["Entangling Roots"] = {class = "DRUID", level = 8},
	["Bear Form"] = {class = "DRUID", level = 10},
	["Demoralizing Roar"] = {class = "DRUID", level = 10},
	["Growl"] = {class = "DRUID", level = 10},
	["Maul"] = {class = "DRUID", level = 10},
	["Nature's Grasp"] = {class = "DRUID", level = 10},
	["Teleport: Moonglade"] = {class = "DRUID", level = 10},
	["Furor"] = {class = "DRUID", level = 10},
	["Regrowth"] = {class = "DRUID", level = 12},
	["Revive"] = {class = "DRUID", level = 12},
	["Bash"] = {class = "DRUID", level = 14},
	["Aquatic Form"] = {class = "DRUID", level = 16},
	["Swipe (Bear)"] = {class = "DRUID", level = 16},
	["Hibernate"] = {class = "DRUID", level = 18},
	["Faerie Fire"] = {class = "DRUID", level = 18},
	["Faerie Fire (Feral)"] = {class = "DRUID", level = 18},
	["Cat Form"] = {class = "DRUID", level = 20},
	["Claw"] = {class = "DRUID", level = 20},
	["Feral Charge - Bear"] = {class = "DRUID", level = 20},
	["Feral Charge - Cat"] = {class = "DRUID", level = 20},
	["Master Shapeshifter"] = {class = "DRUID", level = 20},
	["Nature's Grace"] = {class = "DRUID", level = 20},
	["Omen of Clarity"] = {class = "DRUID", level = 20},
	["Prowl"] = {class = "DRUID", level = 20},
	["Starfire"] = {class = "DRUID", level = 20},
	["Rebirth"] = {class = "DRUID", level = 20},
	["Rip"] = {class = "DRUID", level = 20},
	["Survival Instincts"] = {class = "DRUID", level = 20},
	["Soothe Animal"] = {class = "DRUID", level = 22},
	["Shred"] = {class = "DRUID", level = 22},
	["Tiger's Fury"] = {class = "DRUID", level = 24},
	["Rake"] = {class = "DRUID", level = 24},
	["Primal Fury"] = {class = "DRUID", level = 25},
	["Abolish Poison"] = {class = "DRUID", level = 26},
	["Dash"] = {class = "DRUID", level = 26},
	["Challenging Roar"] = {class = "DRUID", level = 28},
	["Tranquility"] = {class = "DRUID", level = 30},
	["Travel Form"] = {class = "DRUID", level = 30},
	["Nature's Swiftness"] = {class = "DRUID", level = 30},
	["Insect Swarm"] = {class = "DRUID", level = 30},
	["Ferocious Bite"] = {class = "DRUID", level = 32},
	["Ravage"] = {class = "DRUID", level = 32},
	["Pounce"] = {class = "DRUID", level = 36},
	["Frenzied Regeneration"] = {class = "DRUID", level = 36},
	["Swiftmend"] = {class = "DRUID", level = 40},
	["Dire Bear Form"] = {class = "DRUID", level = 40},
	["Moonkin Form"] = {class = "DRUID", level = 40},
	["Feline Grace"] = {class = "DRUID", level = 40},
	["Hurricane"] = {class = "DRUID", level = 40},
	["Innervate"] = {class = "DRUID", level = 40},
	["Natural Perfection"] = {class = "DRUID", level = 40},
	["Savage Defense"] = {class = "DRUID", level = 40},
	["Barkskin"] = {class = "DRUID", level = 44},
	["Infected Wounds"] = {class = "DRUID", level = 45},
	["Living Seed"] = {class = "DRUID", level = 45},
	["Owlkin Frenzy"] = {class = "DRUID", level = 45},
	["Mangle (Cat)"] = {class = "DRUID", level = 50},
	["Mangle (Bear)"] = {class = "DRUID", level = 50},
	["Force of Nature"] = {class = "DRUID", level = 50},
	["Tree of Life"] = {class = "DRUID", level = 50},
	["Gift of the Wild"] = {class = "DRUID", level = 50},
	["Typhoon"] = {class = "DRUID", level = 50},
	["Force of Nature"] = {class = "DRUID", level = 50},
	["Eclipse"] = {class = "DRUID", level = 50},
	["Earth and Moon"] = {class = "DRUID", level = 55},
	["Starfall"] = {class = "DRUID", level = 60},
	["Wild Growth"] = {class = "DRUID", level = 60},
	["Berserk"] = {class = "DRUID", level = 60},
	["Maim"] = {class = "DRUID", level = 62},
	["Lifebloom"] = {class = "DRUID", level = 64},
	["Lacerate"] = {class = "DRUID", level = 66},
	["Flight Form"] = {class = "DRUID", level = 68},
	["Cyclone"] = {class = "DRUID", level = 70},
	["Swift Flight Form"] = {class = "DRUID", level = 70},
	["Swipe (Cat)"] = {class = "DRUID", level = 71},
	["Savage Roar"] = {class = "DRUID", level = 75},
	["Nourish"] = {class = "DRUID", level = 80},

--== Hunter == 

	["Auto Shot"] = {class = "HUNTER", level = 1}, 
	["Raptor Strike"] = {class = "HUNTER", level = 1}, 
	["Track Beasts"] = {class = "HUNTER", level = 1},
	["Aspect of the Monkey"] = {class = "HUNTER", level = 4},
	["Serpent Sting"] = {class = "HUNTER", level = 4},
	["Arcane Shot"] = {class = "HUNTER", level = 6},
	["Hunter's Mark"] = {class = "HUNTER", level = 6},
	["Concussive Shot"] = {class = "HUNTER", level = 8},
	["Aspect of the Hawk"] = {class = "HUNTER", level = 10},
	["Revive Pet"] = {class = "HUNTER", level = 10},
	["Dismiss Pet"] = {class = "HUNTER", level = 10},
	["Feed Pet"] = {class = "HUNTER", level = 10},
	["Call Pet"] = {class = "HUNTER", level = 10},
	["Improved Aspect of the Hawk"] = {class = "HUNTER", level = 10}, 
	["Tame Beast"] = {class = "HUNTER", level = 10},
	["Wing Clip"] = {class = "HUNTER", level = 12},
	["Distracting Shot"] = {class = "HUNTER", level = 12},
	["Mend Pet"] = {class = "HUNTER", level = 12},
	["Scare Beast"] = {class = "HUNTER", level = 14},
	["Eagle Eye"] = {class = "HUNTER", level = 14},
	["Eyes of the Beast"] = {class = "HUNTER", level = 14},
	["Immolation Trap"] = {class = "HUNTER", level = 16},
	["Mongoose Bite"] = {class = "HUNTER", level = 16},
	["Multi-Shot"] = {class = "HUNTER", level = 18},
	["Track Undead"] = {class = "HUNTER", level = 18},
	["Aspect of the Viper"] = {class = "HUNTER", level = 20},
	["Rapid Killing"] = {class = "HUNTER", level = 20},
	["Aimed Shot"] = {class = "HUNTER", level = 20},
	["Aspect of the Cheetah"] = {class = "HUNTER", level = 20},
	["Disengage"] = {class = "HUNTER", level = 20},
	["Freezing Trap"] = {class = "HUNTER", level = 20},
	["Scorpid Sting"] = {class = "HUNTER", level = 22},
	["Track Hidden"] = {class = "HUNTER", level = 24},
	["Beast Lore"] = {class = "HUNTER", level = 24},
	["Lock and Load"] = {class = "HUNTER", level = 25}, 
	["Rapid Fire"] = {class = "HUNTER", level = 26},
	["Track Elementals"] = {class = "HUNTER", level = 26},
	["Frost Trap"] = {class = "HUNTER", level = 28},
	["Counterattack"] = {class = "HUNTER", level = 30},
	["Aspect of the Beast"] = {class = "HUNTER", level = 30},
	["Feign Death"] = {class = "HUNTER", level = 30},
	["Spirit Bond"] = {class = "HUNTER", level = 30}, 
	["Scatter Shot"] = {class = "HUNTER", level = 30},
	["Track Demons"] = {class = "HUNTER", level = 32},
	["Flare"] = {class = "HUNTER", level = 32},
	["Explosive Trap"] = {class = "HUNTER", level = 34},
	["Viper Sting"] = {class = "HUNTER", level = 36},
	["Track Giants"] = {class = "HUNTER", level = 40},
	["Thrill of the Hunt"] = {class = "HUNTER", level = 40}, 
	["Trueshot Aura"] = {class = "HUNTER", level = 40},
	["Ferocious Inspiration"] = {class = "HUNTER", level = 40}, 
	["Volley"] = {class = "HUNTER", level = 40},
	["Aspect of the Pack"] = {class = "HUNTER", level = 40},
	["Wyvern Sting"] = {class = "HUNTER", level = 40},
	["Expose Weakness"] = {class = "HUNTER", level = 40},
	["Master Tactician"] = {class = "HUNTER", level = 45}, 
	["Rapid Recuperation"] = {class = "HUNTER", level = 45}, 
	["Aspect of the Wild"] = {class = "HUNTER", level = 46},
	["Silencing Shot"] = {class = "HUNTER", level = 50},
	["Track Dragonkin"] = {class = "HUNTER", level = 50},
	["The Beast Within"] = {class = "HUNTER", level = 50},
	["Sniper Training"] = {class = "HUNTER", level = 50}, 
	["Steady Shot"] = {class = "HUNTER", level = 50},
	["Readiness"] = {class = "HUNTER", level = 50},
	["Kindred Spirits"] = {class = "HUNTER", level = 55}, 
	["Hunting Party"] = {class = "HUNTER", level = 55}, 
	["Tranquilizing Shot"] = {class = "HUNTER", level = 60},
	["Chimera Shot"] = {class = "HUNTER", level = 60}, 
	["Deterrence"] = {class = "HUNTER", level = 60},
	["Explosive Shot"] = {class = "HUNTER", level = 60}, 
	["Kill Command"] = {class = "HUNTER", level = 66},
	["Snake Trap"] = {class = "HUNTER", level = 68},
	["Misdirection"] = {class = "HUNTER", level = 70},
	["Kill Shot"] = {class = "HUNTER", level = 71}, 
	["Aspect of the Dragonhawk"] = {class = "HUNTER", level = 74},
	["Master's Call"] = {class = "HUNTER", level = 71}, 
	["Call Stabled Pet"] = {class = "HUNTER", level = 80}, 
	["Freezing Arrow"] = {class = "HUNTER", level = 80}, 

--== Mage == 
	["Arcane Intellect"] = {class = "MAGE", level = 1},
	["Fiery Payback"] = {class = "MAGE", level = 1},
	["Fireball"] = {class = "MAGE", level = 1},
	["Frost Armor"] = {class = "MAGE", level = 1},
	["Frostbolt"] = {class = "MAGE", level = 4},
	["Conjure Water"] = {class = "MAGE", level = 4},
	["Conjure Food"] = {class = "MAGE", level = 6},
	["Fire Blast"] = {class = "MAGE", level = 6},
	["Polymorph"] = {class = "MAGE", level = 8},
	["Arcane Missiles"] = {class = "MAGE", level = 8},
	["Fireball!"] = {class = "MAGE", level = 10},
	["Frost Nova"] = {class = "MAGE", level = 10},
	["Slow Fall"] = {class = "MAGE", level = 12},
	["Dampen Magic"] = {class = "MAGE", level = 12},
	["Arcane Explosion"] = {class = "MAGE", level = 14},
	["Magic Absorption"] = {class = "MAGE", level = 15},
	["Frostbite"] = {class = "MAGE", level = 15},
	["Burning Determination"] = {class = "MAGE", level = 15},
	["Ignite"] = {class = "MAGE", level = 15},
	["Detect Magic"] = {class = "MAGE", level = 16},
	["Flamestrike"] = {class = "MAGE", level = 16},
	["Remove Lesser Curse"] = {class = "MAGE", level = 18},
	["Amplify Magic"] = {class = "MAGE", level = 18},
	["Teleport: Ironforge"] = {class = "MAGE", level = 20},
	["Teleport: Exodar"] = {class = "MAGE", level = 20},
	["Teleport: Orgrimmar"] = {class = "MAGE", level = 20},
	["Teleport: Silvermoon"] = {class = "MAGE", level = 20},
	["Teleport: Stormwind"] = {class = "MAGE", level = 20},
	["Teleport: Undercity"] = {class = "MAGE", level = 20},
	["Focus Magic"] = {class = "MAGE", level = 20},
	["Blink"] = {class = "MAGE", level = 20},
	["Blizzard"] = {class = "MAGE", level = 20},
	["Cold Snap"] = {class = "MAGE", level = 20},
	["Evocation"] = {class = "MAGE", level = 20},
	["Fire Ward"] = {class = "MAGE", level = 20},
	["Mana Shield"] = {class = "MAGE", level = 20},
	["Pyroblast"] = {class = "MAGE", level = 20},
	["Icy Veins"] = {class = "MAGE", level = 20},
	["Scorch"] = {class = "MAGE", level = 22},
	["Frost Ward"] = {class = "MAGE", level = 22},
	["Counterspell"] = {class = "MAGE", level = 24},
	["Master of Elements"] = {class = "MAGE", level = 25},
	["Improved Scorch"] = {class = "MAGE", level = 25},
	["Cone of Cold"] = {class = "MAGE", level = 26},
	["Conjure Mana Gem"] = {class = "MAGE", level = 28},
	["Ice Block"] = {class = "MAGE", level = 30},
	["Ice Armor"] = {class = "MAGE", level = 30},
	["Presence of Mind"] = {class = "MAGE", level = 30},
	["Teleport: Darnassus"] = {class = "MAGE", level = 30},
	["Teleport: Thunder Bluff"] = {class = "MAGE", level = 30},
	["Blast Wave"] = {class = "MAGE", level = 30},
	["Mage Armor"] = {class = "MAGE", level = 34},
	["Winter's Chill"] = {class = "MAGE", level = 35},
	["Portal: Stonard"] = {class = "MAGE", level = 35},
	["Portal: Theramore"] = {class = "MAGE", level = 35},
	["Teleport: Stonard"] = {class = "MAGE", level = 35},
	["Teleport: Theramore"] = {class = "MAGE", level = 35},
	["Blazing Speed"] = {class = "MAGE", level = 35},
	["Combustion"] = {class = "MAGE", level = 40},
	["Ice Barrier"] = {class = "MAGE", level = 40},
	["Portal: Ironforge"] = {class = "MAGE", level = 40},
	["Portal: Orgrimmar"] = {class = "MAGE", level = 40},
	["Portal: Exodar"] = {class = "MAGE", level = 40},
	["Portal: Silvermoon"] = {class = "MAGE", level = 40},
	["Portal: Stormwind"] = {class = "MAGE", level = 40},
	["Portal: Undercity"] = {class = "MAGE", level = 40},
	["Fingers of Frost"] = {class = "MAGE", level = 45},
	["Portal: Thunder Bluff"] = {class = "MAGE", level = 50},
	["Portal: Darnassus"] = {class = "MAGE", level = 50},
	["Summon Water Elemental"] = {class = "MAGE", level = 50},
	["Slow"] = {class = "MAGE", level = 50},
	["Dragon's Breath"] = {class = "MAGE", level = 50},
	["Arcane Brilliance"] = {class = "MAGE", level = 56},
	["Polymorph: Black Cat"] = {class = "MAGE", level = 60},
	["Polymorph: Pig"] = {class = "MAGE", level = 60},
	["Polymorph: Rabbit"] = {class = "MAGE", level = 60},
	["Polymorph: Serpent"] = {class = "MAGE", level = 60},
	["Polymorph: Turkey"] = {class = "MAGE", level = 60},
	["Polymorph: Turtle"] = {class = "MAGE", level = 60},
	["Teleport: Shattrath"] = {class = "MAGE", level = 60},
	["Deep Freeze"] = {class = "MAGE", level = 60},
	["Arcane Barrage"] = {class = "MAGE", level = 60},
	["Living Bomb"] = {class = "MAGE", level = 60},
	["Molten Armor"] = {class = "MAGE", level = 62},
	["Arcane Blast"] = {class = "MAGE", level = 64},
	["Portal: Shattrath"] = {class = "MAGE", level = 65},
	["Ice Lance"] = {class = "MAGE", level = 66},
	["Invisibility"] = {class = "MAGE", level = 68},
	["Spellsteal"] = {class = "MAGE", level = 70},
	["Ritual of Refreshment"] = {class = "MAGE", level = 70},
	["Teleport: Dalaran"] = {class = "MAGE", level = 71},
	["Portal: Dalaran"] = {class = "MAGE", level = 74},
	["Conjure Refreshment"] = {class = "MAGE", level = 75},
	["Frostfire Bolt"] = {class = "MAGE", level = 75},
	["Mirror Image"] = {class = "MAGE", level = 80},

--== Paladin ==
	["Devotion Aura"] = {class = "PALADIN", level = 1},
	["Glyph of Holy Light"] = {class = "PALADIN", level = 1},
	["Holy Light"] = {class = "PALADIN", level = 1},
	["Seal of Righteousness"] = {class = "PALADIN", level = 1},
	["Blessing of Might"] = {class = "PALADIN", level = 4},
	["Judgement of Light"] = {class = "PALADIN", level = 4},
	["Seal of the Crusader"] = {class = "PALADIN", level = 6},
	["Divine Protection"] = {class = "PALADIN", level = 6},
	["Purify"] = {class = "PALADIN", level = 8},
	["Hammer of Justice"] = {class = "PALADIN", level = 8},
	["Lay on Hands"] = {class = "PALADIN", level = 10},
	["Hand of Protection"] = {class = "PALADIN", level = 10},
	["Redemption"] = {class = "PALADIN", level = 12},
	["Judgement of Wisdom"] = {class = "PALADIN", level = 12},
	["Righteous Defense"] = {class = "PALADIN", level = 14},
	["Blessing of Wisdom"] = {class = "PALADIN", level = 14},
	["Hand of Reckoning"] = {class = "PALADIN", level = 16},
	["Retribution Aura"] = {class = "PALADIN", level = 16},
	["Righteous Fury"] = {class = "PALADIN", level = 16},
	["Hand of Freedom"] = {class = "PALADIN", level = 18},
	["Spiritual Attunement"] = {class = "PALADIN", level = 18},
	["Seal of Command"] = {class = "PALADIN", level = 20},
	["Exorcism"] = {class = "PALADIN", level = 20},
	["Flash of Light"] = {class = "PALADIN", level = 20},
	["Blessing of Kings"] = {class = "PALADIN", level = 20},
	["Vindication"] = {class = "PALADIN", level = 20},
	["Aura Mastery"] = {class = "PALADIN", level = 20},
	["Divine Sacrifice"] = {class = "PALADIN", level = 20},
	["Sense Undead"] = {class = "PALADIN", level = 20},
	["Consecration"] = {class = "PALADIN", level = 20},
	["Concentration Aura"] = {class = "PALADIN", level = 22},
	["Seal of Justice"] = {class = "PALADIN", level = 22},
	["Turn Evil"] = {class = "PALADIN", level = 24},
	["Illumination"] = {class = "PALADIN", level = 25},
	["Eye for an Eye"] = {class = "PALADIN", level = 25},
	["Hand of Salvation"] = {class = "PALADIN", level = 26},
	["Shadow Resistance Aura"] = {class = "PALADIN", level = 28},
	["Judgement of Justice"] = {class = "PALADIN", level = 28},
	["Divine Favor"] = {class = "PALADIN", level = 30},
	["Divine Intervention"] = {class = "PALADIN", level = 30},
	["Reckoning"] = {class = "PALADIN", level = 30},
	["Sanctity Aura"] = {class = "PALADIN", level = 30},
	["Seal of Light"] = {class = "PALADIN", level = 30},
	["Summon Warhorse"] = {class = "PALADIN", level = 30},
	["Warhorse"] = {class = "PALADIN", level = 30},
	["Blessing of Sanctuary"] = {class = "PALADIN", level = 30},
	["Frost Resistance Aura"] = {class = "PALADIN", level = 32},
	["Divine Shield"] = {class = "PALADIN", level = 36},
	["Vengeance"] = {class = "PALADIN", level = 35},
	["Fire Resistance Aura"] = {class = "PALADIN", level = 36},
	["Seal of Wisdom"] = {class = "PALADIN", level = 38},
	["Light's Grace"] = {class = "PALADIN", level = 40},
	["Blessing of Light"] = {class = "PALADIN", level = 40},
	["Holy Shock"] = {class = "PALADIN", level = 40},
	["Repentance"] = {class = "PALADIN", level = 40},
	["Holy Shield"] = {class = "PALADIN", level = 40},
	["The Art of War"] = {class = "PALADIN", level = 40},
	["Cleanse"] = {class = "PALADIN", level = 42},
	["Hammer of Wrath"] = {class = "PALADIN", level = 44},
	["Redoubt"] = {class = "PALADIN", level = 45},
	["Sacred Cleansing"] = {class = "PALADIN", level = 45},
	["Hand of Sacrifice"] = {class = "PALADIN", level = 46},
	["Holy Wrath"] = {class = "PALADIN", level = 50},
	["Divine Illumination"] = {class = "PALADIN", level = 50},
	["Avenger's Shield"] = {class = "PALADIN", level = 50},
	["Crusader Strike"] = {class = "PALADIN", level = 50},
	["Greater Blessing of Might"] = {class = "PALADIN", level = 52},
	["Greater Blessing of Wisdom"] = {class = "PALADIN", level = 54},
	["Silenced - Shield of the Templar"] = {class = "PALADIN", level = 55},
	["Greater Blessing of Sanctuary"] = {class = "PALADIN", level = 60},
	["Greater Blessing of Kings"] = {class = "PALADIN", level = 60},
	["Greater Blessing of Might"] = {class = "PALADIN", level = 60},
	["Summon Charger"] = {class = "PALADIN", level = 60},
	["Charger"] = {class = "PALADIN", level = 60},
	["Beacon of Light"] = {class = "PALADIN", level = 60},
	["Light's Beacon"] = {class = "PALADIN", level = 60},
	["Divine Storm"] = {class = "PALADIN", level = 60},
	["Hammer of the Righteous"] = {class = "PALADIN", level = 60},
	["Crusader Aura"] = {class = "PALADIN", level = 62},
	["Seal of Blood"] = {class = "PALADIN", level = 64},
	["Seal of Vengeance"] = {class = "PALADIN", level = 64},
	["Seal of Corruption"] = {class = "PALADIN", level = 66},
	["Seal of the Martyr"] = {class = "PALADIN", level = 66},
	["Avenging Wrath"] = {class = "PALADIN", level = 70},
	["Divine Plea"] = {class = "PALADIN", level = 71},
	["Shield of Righteousness"] = {class = "PALADIN", level = 75},
	["Holy Mending"] = {class = "PALADIN", level = 80},
	["Sacred Shield"] = {class = "PALADIN", level = 80},

--== Priest == 
	["Power Word: Fortitude"] = {class = "PRIEST", level = 1},
	["Glyph of Dispel Magic"] = {class = "PRIEST", level = 1},
	["Glyph of Power Word: Shield"] = {class = "PRIEST", level = 1},
	["Glyph of Prayer of Healing"] = {class = "PRIEST", level = 1},
	["Lesser Heal"] = {class = "PRIEST", level = 1},
	["Smite"] = {class = "PRIEST", level = 1},
	["Shadow Word: Pain"] = {class = "PRIEST", level = 4},
	["Power Word: Shield"] = {class = "PRIEST", level = 6},
	["Fade"] = {class = "PRIEST", level = 8},
	["Renew"] = {class = "PRIEST", level = 8},
	["Mind Blast"] = {class = "PRIEST", level = 10},
	["Resurrection"] = {class = "PRIEST", level = 10},
	["Spirit Tap"] = {class = "PRIEST", level = 10},
	["Touch of Weakness"] = {class = "PRIEST", level = 10},
	["Inner Fire"] = {class = "PRIEST", level = 12},
	["Psychic Scream"] = {class = "PRIEST", level = 14},
	["Heal"] = {class = "PRIEST", level = 16},
	["Dispel Magic"] = {class = "PRIEST", level = 18},
	["Desperate Prayer"] = {class = "PRIEST", level = 20},
	["Flash Heal"] = {class = "PRIEST", level = 20},
	["Shackle Undead"] = {class = "PRIEST", level = 20},
	["Holy Fire"] = {class = "PRIEST", level = 20},
	["Mind Flay"] = {class = "PRIEST", level = 20},
	["Mind Soothe"] = {class = "PRIEST", level = 20},
	["Inner Focus"] = {class = "PRIEST", level = 20},
	["Holy Nova"] = {class = "PRIEST", level = 20},
	["Blessed Recovery"] = {class = "PRIEST", level = 20},
	["Inspiration"] = {class = "PRIEST", level = 20},
	["Devouring Plague"] = {class = "PRIEST", level = 20},
	["Fear Ward"] = {class = "PRIEST", level = 20},
	["Mind Vision"] = {class = "PRIEST", level = 22},
	["Mana Burn"] = {class = "PRIEST", level = 24},
	["Shadow Vulnerability"] = {class = "PRIEST", level = 25},
	["Mind Control"] = {class = "PRIEST", level = 30},
	["Reflective Shield"] = {class = "PRIEST", level = 30},
	["Prayer of Healing"] = {class = "PRIEST", level = 30},
	["Shadow Protection"] = {class = "PRIEST", level = 30},
	["Silence"] = {class = "PRIEST", level = 30},
	["Spirit of Redemption"] = {class = "PRIEST", level = 30},
	["Vampiric Embrace"] = {class = "PRIEST", level = 30},
	["Divine Spirit"] = {class = "PRIEST", level = 30},
	["Abolish Disease"] = {class = "PRIEST", level = 32},
	["Levitate"] = {class = "PRIEST", level = 34},
	["Surge of Light"] = {class = "PRIEST", level = 35},
	["Greater Heal"] = {class = "PRIEST", level = 40},
	["Shadowform"] = {class = "PRIEST", level = 40},
	["Focused Will"] = {class = "PRIEST", level = 40},
	["Power Infusion"] = {class = "PRIEST", level = 40},
	["Lightwell"] = {class = "PRIEST", level = 40},
	["Blessed Resilience"] = {class = "PRIEST", level = 40},
	["Serendipity"] = {class = "PRIEST", level = 45},
	["Prayer of Fortitude"] = {class = "PRIEST", level = 48},
	["Focused Will"] = {class = "PRIEST", level = 50},
	["Circle of Healing"] = {class = "PRIEST", level = 50},
	["Pain Suppression"] = {class = "PRIEST", level = 50},
	["Vampiric Touch"] = {class = "PRIEST", level = 50},
	["Psychic Horror"] = {class = "PRIEST", level = 50},
	["Prayer of Shadow Protection"] = {class = "PRIEST", level = 56},
	["Prayer of Spirit"] = {class = "PRIEST", level = 60},
	["Guardian Spirit"] = {class = "PRIEST", level = 60},
	["Dispersion"] = {class = "PRIEST", level = 60},
	["Penance"] = {class = "PRIEST", level = 60},
	["Shadow Word: Death"] = {class = "PRIEST", level = 62},
	["Binding Heal"] = {class = "PRIEST", level = 64},
	["Shadowfiend"] = {class = "PRIEST", level = 66},
	["Prayer of Mending"] = {class = "PRIEST", level = 68},
	["Mass Dispel"] = {class = "PRIEST", level = 70},
	["Mind Sear"] = {class = "PRIEST", level = 75},
	["Divine Hymn"] = {class = "PRIEST", level = 80},
	["Hymn of Hope"] = {class = "PRIEST", level = 80},

--== Rogue == 
	["Stealth"] = {class = "ROGUE", level = 1},
	["Sinister Strike"] = {class = "ROGUE", level = 1},
	["Eviscerate"] = {class = "ROGUE", level = 1},
	["Backstab"] = {class = "ROGUE", level = 4},
	["Pick Pocket"] = {class = "ROGUE", level = 4},
	["Gouge"] = {class = "ROGUE", level = 6},
	["Evasion"] = {class = "ROGUE", level = 8},
	["Remorseless"] = {class = "ROGUE", level = 10},
	["Sap"] = {class = "ROGUE", level = 10},
	["Slice and Dice"] = {class = "ROGUE", level = 10},
	["Master of Deception"] = {class = "ROGUE", level = 10},
	["Sprint"] = {class = "ROGUE", level = 10},
	["Relentless Strikes"] = {class = "ROGUE", level = 10},
	["Remorseless Attacks"] = {class = "ROGUE", level = 10},
	["Kick"] = {class = "ROGUE", level = 12},
	["Expose Armor"] = {class = "ROGUE", level = 14},
	["Garrote"] = {class = "ROGUE", level = 14},
	["Feint"] = {class = "ROGUE", level = 16},
	["Pick Lock"] = {class = "ROGUE", level = 16},
	["Ambush"] = {class = "ROGUE", level = 18},
	["Riposte"] = {class = "ROGUE", level = 20},
	["Dismantle"] = {class = "ROGUE", level = 20},
	["Rupture"] = {class = "ROGUE", level = 20},
	["Crippling Poison"] = {class = "ROGUE", level = 20},
	["Ghostly Strike"] = {class = "ROGUE", level = 20},
	["Instant Poison"] = {class = "ROGUE", level = 20},
	["Vanish"] = {class = "ROGUE", level = 22},
	["Distract"] = {class = "ROGUE", level = 22},
	["Detect Traps"] = {class = "ROGUE", level = 24},
	["Mind-numbing Poison"] = {class = "ROGUE", level = 24},
	["Cheap Shot"] = {class = "ROGUE", level = 26},
	["Instant Poison II"] = {class = "ROGUE", level = 28},
	["Cold Blood"] = {class = "ROGUE", level = 30},
	["Preparation"] = {class = "ROGUE", level = 30},
	["Disarm Trap"] = {class = "ROGUE", level = 30},
	["Blade Flurry"] = {class = "ROGUE", level = 30},
	["Deadly Poison"] = {class = "ROGUE", level = 30},
	["Kidney Shot"] = {class = "ROGUE", level = 30},
	["Hemorrhage"] = {class = "ROGUE", level = 30},
	["Wound Poison"] = {class = "ROGUE", level = 32},
	["Blind"] = {class = "ROGUE", level = 34},
	["Blinding Powder"] = {class = "ROGUE", level = 34},
	["Find Weakness"] = {class = "ROGUE", level = 35},
	["Instant Poison III"] = {class = "ROGUE", level = 36},
	["Deadly Poison II"] = {class = "ROGUE", level = 38},
	["Wound Poison II"] = {class = "ROGUE", level = 40},
	["Premeditation"] = {class = "ROGUE", level = 40},
	["Adrenaline Rush"] = {class = "ROGUE", level = 40},
	["Instant Poison IV"] = {class = "ROGUE", level = 44},
	["Combat Potency"] = {class = "ROGUE", level = 45},
	["Deadly Poison III"] = {class = "ROGUE", level = 46},
	["Wound Poison III"] = {class = "ROGUE", level = 48},
	["Mutilate"] = {class = "ROGUE", level = 50},
	["Shadowstep"] = {class = "ROGUE", level = 50},
	["Honor Among Thieves"] = {class = "ROGUE", level = 50},
	["Turn the Tables"] = {class = "ROGUE", level = 50},
	["Unfair Advantage"] = {class = "ROGUE", level = 50},
	["Instant Poison V"] = {class = "ROGUE", level = 52},
	["Deadly Poison IV"] = {class = "ROGUE", level = 54},
	["Wound Poison IV"] = {class = "ROGUE", level = 56},
	["Deadly Poison V"] = {class = "ROGUE", level = 60},
	["Instant Poison VI"] = {class = "ROGUE", level = 60},
	["Hunger For Blood"] = {class = "ROGUE", level = 60},
	["Killing Spree"] = {class = "ROGUE", level = 60},
	["Shadow Dance"] = {class = "ROGUE", level = 60},
	["Deadly Poison VI"] = {class = "ROGUE", level = 62},
	["Envenom"] = {class = "ROGUE", level = 62},
	["Deadly Throw"] = {class = "ROGUE", level = 64},
	["Wound Poison V"] = {class = "ROGUE", level = 64},
	["Cloak of Shadows"] = {class = "ROGUE", level = 66},
	["Instant Poison VII"] = {class = "ROGUE", level = 68},
	["Anesthetic Poison"] = {class = "ROGUE", level = 68},
	["Deadly Poison VII"] = {class = "ROGUE", level = 70},
	["Shiv"] = {class = "ROGUE", level = 70},
	["Wound Poison VI"] = {class = "ROGUE", level = 72},
	["Instant Poison VIII"] = {class = "ROGUE", level = 73},
	["Tricks of the Trade"] = {class = "ROGUE", level = 75},
	["Deadly Poison VIII"] = {class = "ROGUE", level = 76},
	["Wound Poison VII"] = {class = "ROGUE", level = 78},
	["Fan of Knives"] = {class = "ROGUE", level = 80},
	["Instant Poison IX"] = {class = "ROGUE", level = 79},
	["Deadly Poison IX"] = {class = "ROGUE", level = 80},

--== Shaman == 
	["Freeze"] = {class = "SHAMAN", level = 1},
	["Glyph of Healing Wave"] = {class = "SHAMAN", level = 1},
	["Rockbiter Weapon"] = {class = "SHAMAN", level = 1},
	["Healing Wave"] = {class = "SHAMAN", level = 1},
	["Lightning Bolt"] = {class = "SHAMAN", level = 1},
	["Stoneskin Totem"] = {class = "SHAMAN", level = 4},
	["Earth Shock"] = {class = "SHAMAN", level = 4},
	["Earthbind Totem"] = {class = "SHAMAN", level = 6},
	["Stoneclaw Totem"] = {class = "SHAMAN", level = 8},
	["Lightning Shield"] = {class = "SHAMAN", level = 8},
	["Flame Shock"] = {class = "SHAMAN", level = 10},
	["Flametongue Weapon"] = {class = "SHAMAN", level = 10},
	["Strength of Earth Totem"] = {class = "SHAMAN", level = 10},
	["Searing Totem"] = {class = "SHAMAN", level = 10},
	["Ancestral Spirit"] = {class = "SHAMAN", level = 12},
	["Fire Nova Totem"] = {class = "SHAMAN", level = 12},
	["Purge"] = {class = "SHAMAN", level = 12},
	["Ancestral Fortitude"] = {class = "SHAMAN", level = 15},
	["Elemental Devastation"] = {class = "SHAMAN", level = 15},
	["Wind Shock"] = {class = "SHAMAN", level = 16},
	["Tremor Totem"] = {class = "SHAMAN", level = 18},
	["Frost Shock"] = {class = "SHAMAN", level = 20},
	["Frostbrand Weapon"] = {class = "SHAMAN", level = 20},
	["Ghost Wolf"] = {class = "SHAMAN", level = 20},
	["Tidal Force"] = {class = "SHAMAN", level = 20},
	["Elemental Focus"] = {class = "SHAMAN", level = 20},
	["Lesser Healing Wave"] = {class = "SHAMAN", level = 20},
	["Healing Stream Totem"] = {class = "SHAMAN", level = 20},
	["Water Shield"] = {class = "SHAMAN", level = 20},
	["Poison Cleansing Totem"] = {class = "SHAMAN", level = 22},
	["Water Breathing"] = {class = "SHAMAN", level = 22},
	["Frost Resistance Totem"] = {class = "SHAMAN", level = 24},
	["Far Sight"] = {class = "SHAMAN", level = 26},
	["Magma Totem"] = {class = "SHAMAN", level = 26},
	["Mana Spring Totem"] = {class = "SHAMAN", level = 26},
	["Fire Resistance Totem"] = {class = "SHAMAN", level = 28},
	["Flametongue Totem"] = {class = "SHAMAN", level = 28},
	["Water Walking"] = {class = "SHAMAN", level = 28},
	["Astral Recall"] = {class = "SHAMAN", level = 30},
	["Grounding Totem"] = {class = "SHAMAN", level = 30},
	["Nature Resistance Totem"] = {class = "SHAMAN", level = 30},
	["Nature's Swiftness"] = {class = "SHAMAN", level = 30},
	["Reincarnation"] = {class = "SHAMAN", level = 30},
	["Healing Way"] = {class = "SHAMAN", level = 30},
	["Earthliving Weapon"] = {class = "SHAMAN", level = 30},
	["Windfury Weapon"] = {class = "SHAMAN", level = 30},
	["Spirit Weapons"] = {class = "SHAMAN", level = 30},
	["Totemic Call"] = {class = "SHAMAN", level = 30},
	["Chain Lightning"] = {class = "SHAMAN", level = 32},
	["Windfury Totem"] = {class = "SHAMAN", level = 32},
	["Sentry Totem"] = {class = "SHAMAN", level = 34},
	["Unleashed Rage"] = {class = "SHAMAN", level = 35},
	["Windwall Totem"] = {class = "SHAMAN", level = 36},
	["Cleansing Totem"] = {class = "SHAMAN", level = 38},
	["Nature's Guardian"] = {class = "SHAMAN", level = 40},
	["Cleanse Spirit"] = {class = "SHAMAN", level = 40},
	["Chain Heal"] = {class = "SHAMAN", level = 40},
	["Elemental Mastery"] = {class = "SHAMAN", level = 40},
	["Mana Tide Totem"] = {class = "SHAMAN", level = 40},
	["Stormstrike"] = {class = "SHAMAN", level = 40},
	["Grace of Air Totem"] = {class = "SHAMAN", level = 42},
	["Elemental Oath"] = {class = "SHAMAN", level = 45},
	["Lava Lash"] = {class = "SHAMAN", level = 45},
	["Totem of Wrath"] = {class = "SHAMAN", level = 50},
	["Shamanistic Rage"] = {class = "SHAMAN", level = 50},
	["Earth Shield"] = {class = "SHAMAN", level = 50},
	["Tranquil Air Totem"] = {class = "SHAMAN", level = 50},
	["Maelstrom Weapon"] = {class = "SHAMAN", level = 55},
	["Feral Spirit"] = {class = "SHAMAN", level = 60},
	["Riptide"] = {class = "SHAMAN", level = 60},
	["Thunderstorm"] = {class = "SHAMAN", level = 60},
	["Wrath of Air Totem"] = {class = "SHAMAN", level = 64},
	["Earth Elemental Totem"] = {class = "SHAMAN", level = 66},
	["Fire Elemental Totem"] = {class = "SHAMAN", level = 68},
	["Bloodlust"] = {class = "SHAMAN", level = 70},
	["Heroism"] = {class = "SHAMAN", level = 70},
	["Lava Burst"] = {class = "SHAMAN", level = 75},
	["Hex"] = {class = "SHAMAN", level = 80},

--== Warlock == 
	["Challenging Howl"] = {class = "WARLOCK", level = 1},
	["Blood Pact"] = {class = "WARLOCK", level = 1},
	["Immolate"] = {class = "WARLOCK", level = 1},
	["Summon Imp"] = {class = "WARLOCK", level = 1},
	["Demon Skin"] = {class = "WARLOCK", level = 1},
	["Shadow Bolt"] = {class = "WARLOCK", level = 1},
	["Corruption"] = {class = "WARLOCK", level = 4},
	["Curse of Weakness"] = {class = "WARLOCK", level = 4},
	["Life Tap"] = {class = "WARLOCK", level = 6},
	["Curse of Agony"] = {class = "WARLOCK", level = 8},
	["Fear"] = {class = "WARLOCK", level = 8},
	["Create Healthstone"] = {class = "WARLOCK", level = 10},
	["Summon Voidwalker"] = {class = "WARLOCK", level = 10},
	["Drain Soul"] = {class = "WARLOCK", level = 10},
	["Shadow Vulnerability"] = {class = "WARLOCK", level = 10},
	["Health Funnel"] = {class = "WARLOCK", level = 12},
	["Curse of Recklessness"] = {class = "WARLOCK", level = 14},
	["Drain Life"] = {class = "WARLOCK", level = 14},
	["Unending Breath"] = {class = "WARLOCK", level = 16},
	["Create Soulstone"] = {class = "WARLOCK", level = 18},
	["Searing Pain"] = {class = "WARLOCK", level = 18},
	["Demon Armor"] = {class = "WARLOCK", level = 20},
	["Amplify Curse"] = {class = "WARLOCK", level = 20},
	["Fel Domination"] = {class = "WARLOCK", level = 20},
	["Rain of Fire"] = {class = "WARLOCK", level = 20},
	["Ritual of Summoning"] = {class = "WARLOCK", level = 20},
	["Shadowburn"] = {class = "WARLOCK", level = 20},
	["Summon Succubus"] = {class = "WARLOCK", level = 20},
	["Soul Link"] = {class = "WARLOCK", level = 20},
	["Eye of Kilrogg"] = {class = "WARLOCK", level = 22},
	["Sense Demons"] = {class = "WARLOCK", level = 24},
	["Drain Mana"] = {class = "WARLOCK", level = 24},
	["Shadow Trance"] = {class = "WARLOCK", level = 25},
	["Detect Invisibility"] = {class = "WARLOCK", level = 26},
	["Curse of Tongues"] = {class = "WARLOCK", level = 26},
	["Banish"] = {class = "WARLOCK", level = 28},
	["Create Firestone"] = {class = "WARLOCK", level = 28},
	["Curse of Exhaustion"] = {class = "WARLOCK", level = 30},
	["Demonic Sacrifice"] = {class = "WARLOCK", level = 30},
	["Enslave Demon"] = {class = "WARLOCK", level = 30},
	["Summon Felsteed"] = {class = "WARLOCK", level = 30},
	["Felsteed"] = {class = "WARLOCK", level = 30},
	["Hellfire"] = {class = "WARLOCK", level = 30},
	["Siphon Life"] = {class = "WARLOCK", level = 30},
	["Summon Felhunter"] = {class = "WARLOCK", level = 30},
	["Backlash"] = {class = "WARLOCK", level = 30},
	["Shadow Embrace"] = {class = "WARLOCK", level = 30},
	["Curse of the Elements"] = {class = "WARLOCK", level = 32},
	["Shadow Ward"] = {class = "WARLOCK", level = 32},
	["Master Demonologist"] = {class = "WARLOCK", level = 35},
	["Molten Core"] = {class = "WARLOCK", level = 35},
	["Nether Protection"] = {class = "WARLOCK", level = 35},
	["Create Spellstone"] = {class = "WARLOCK", level = 36},
	["Howl of Terror"] = {class = "WARLOCK", level = 40},
	["Soul Link"] = {class = "WARLOCK", level = 40},
	["Eradication"] = {class = "WARLOCK", level = 40},
	["Pyroclasm"] = {class = "WARLOCK", level = 40},
	["Demonic Empowerment"] = {class = "WARLOCK", level = 40},
	["Demonic Knowledge"] = {class = "WARLOCK", level = 40},
	["Conflagrate"] = {class = "WARLOCK", level = 40},
	["Dark Pact"] = {class = "WARLOCK", level = 40},
	["Soul Leech"] = {class = "WARLOCK", level = 40},
	["Curse of Shadow"] = {class = "WARLOCK", level = 44},
	["Decimation"] = {class = "WARLOCK", level = 45},
	["Improved Soul Leech"] = {class = "WARLOCK", level = 45},
	["Soul Fire"] = {class = "WARLOCK", level = 48},
	["Inferno"] = {class = "WARLOCK", level = 50},
	["Backdraft"] = {class = "WARLOCK", level = 50},
	["Summon Felguard"] = {class = "WARLOCK", level = 50},
	["Unstable Affliction"] = {class = "WARLOCK", level = 50},
	["Shadowfury"] = {class = "WARLOCK", level = 50},
	["Ritual of Doom"] = {class = "WARLOCK", level = 60},
	["Curse of Doom"] = {class = "WARLOCK", level = 60},
	["Demonic Charge"] = {class = "WARLOCK", level = 60},
	["Immolation Aura"] = {class = "WARLOCK", level = 60},
	["Shadow Cleave"] = {class = "WARLOCK", level = 60},
	["Summon Dreadsteed"] = {class = "WARLOCK", level = 60},
	["Dreadsteed"] = {class = "WARLOCK", level = 61},
	["Metamorphosis"] = {class = "WARLOCK", level = 60},
	["Chaos Bolt"] = {class = "WARLOCK", level = 60},
	["Haunt"] = {class = "WARLOCK", level = 60},
	["Fel Armor"] = {class = "WARLOCK", level = 62},
	["Incinerate"] = {class = "WARLOCK", level = 64},
	["Soulshatter"] = {class = "WARLOCK", level = 66},
	["Ritual of Souls"] = {class = "WARLOCK", level = 68},
	["Seed of Corruption"] = {class = "WARLOCK", level = 70},
	["Shadowflame"] = {class = "WARLOCK", level = 75},
	["Demonic Circle: Summon"] = {class = "WARLOCK", level = 80},
	["Demonic Circle: Teleport"] = {class = "WARLOCK", level = 80},

--== Warrior == 
	["Battle Shout"] = {class = "WARRIOR", level = 1},
	["Heroic Strike"] = {class = "WARRIOR", level = 1},
	["Battle Stance"] = {class = "WARRIOR", level = 1},
	["Rend"] = {class = "WARRIOR", level = 4},
	["Charge"] = {class = "WARRIOR", level = 4},
	["Thunder Clap"] = {class = "WARRIOR", level = 6},
	["Hamstring"] = {class = "WARRIOR", level = 8},
	["Sunder Armor"] = {class = "WARRIOR", level = 10},
	["Bloodrage"] = {class = "WARRIOR", level = 10},
	["Taunt"] = {class = "WARRIOR", level = 10},
	["Defensive Stance"] = {class = "WARRIOR", level = 10},
	["Shield Bash"] = {class = "WARRIOR", level = 12},
	["Overpower"] = {class = "WARRIOR", level = 12},
	["Demoralizing Shout"] = {class = "WARRIOR", level = 14},
	["Revenge"] = {class = "WARRIOR", level = 14},
	["Shield Specialization"] = {class = "WARRIOR", level = 15},
	["Unbridled Wrath"] = {class = "WARRIOR", level = 15},
	["Mocking Blow"] = {class = "WARRIOR", level = 16},
	["Shield Block"] = {class = "WARRIOR", level = 16},
	["Disarm"] = {class = "WARRIOR", level = 18},
	["Piercing Howl"] = {class = "WARRIOR", level = 20},
	["Retaliation"] = {class = "WARRIOR", level = 20},
	["Blood Craze"] = {class = "WARRIOR", level = 20},
	["Cleave"] = {class = "WARRIOR", level = 20},
	["Last Stand"] = {class = "WARRIOR", level = 20},
	["Deep Wound"] = {class = "WARRIOR", level = 20},
	["Intimidating Shout"] = {class = "WARRIOR", level = 22},
	["Execute"] = {class = "WARRIOR", level = 24},
	["Taste for Blood"] = {class = "WARRIOR", level = 25},
	["Challenging Shout"] = {class = "WARRIOR", level = 26},
	["Shield Wall"] = {class = "WARRIOR", level = 28},
	["Concussion Blow"] = {class = "WARRIOR", level = 30},
	["Death Wish"] = {class = "WARRIOR", level = 30},
	["Intercept"] = {class = "WARRIOR", level = 30},
	["Slam"] = {class = "WARRIOR", level = 30},
	["Sweeping Strikes"] = {class = "WARRIOR", level = 30},
	["Berserker Stance"] = {class = "WARRIOR", level = 30},
	["Berserker Rage"] = {class = "WARRIOR", level = 32},
	["Trauma"] = {class = "WARRIOR", level = 35},
	["Whirlwind"] = {class = "WARRIOR", level = 36},
	["Pummel"] = {class = "WARRIOR", level = 38},
	["Shield Slam"] = {class = "WARRIOR", level = 40},
	["Mortal Strike"] = {class = "WARRIOR", level = 40},
	["Bloodthirst"] = {class = "WARRIOR", level = 40},
	["Vigilance"] = {class = "WARRIOR", level = 40},
	["Second Wind"] = {class = "WARRIOR", level = 40},
	["Furious Attacks"] = {class = "WARRIOR", level = 45},
	["Safeguard"] = {class = "WARRIOR", level = 45},
	["Devastate"] = {class = "WARRIOR", level = 50},
	["Slam!"] = {class = "WARRIOR", level = 50},
	["Sudden Death"] = {class = "WARRIOR", level = 50},
	["Rampage"] = {class = "WARRIOR", level = 50},
	["Recklessness"] = {class = "WARRIOR", level = 50},
	["Heroic Fury"] = {class = "WARRIOR", level = 50},
	["Sword and Board"] = {class = "WARRIOR", level = 55},
	["Bladestorm"] = {class = "WARRIOR", level = 60},
	["Shockwave"] = {class = "WARRIOR", level = 60},
	["Victory Rush"] = {class = "WARRIOR", level = 62},
	["Spell Reflection"] = {class = "WARRIOR", level = 64},
	["Commanding Shout"] = {class = "WARRIOR", level = 68},
	["Intervene"] = {class = "WARRIOR", level = 70},
	["Shattering Throw"] = {class = "WARRIOR", level = 71},
	["Enraged Regeneration"] = {class = "WARRIOR", level = 75},
	["Heroic Throw"] = {class = "WARRIOR", level = 80},
};