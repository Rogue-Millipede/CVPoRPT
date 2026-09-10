-- this is an example/default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via their ids
-- it will also keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
-- if you run into issues when touching A LOT of items/locations here, see the comment about Tracker.AllowDeferredLogicUpdate in autotracking.lua
ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")
-- used for hint tracking to quickly map hint status to a value from the Highlight enum
HINT_STATUS_MAPPING = {}
if Highlight then
	HINT_STATUS_MAPPING = {
		[20] = Highlight.Avoid,
		[40] = Highlight.None,
		[10] = Highlight.NoPriority,
		[0] = Highlight.Unspecified,
		[30] = Highlight.Priority,
	}
end

PORTRAIT_LOCATION_NAMES = {
	[1] = "hub_portrait",
    [2] = "underground_portrait",
    [3] = "stairs_portrait",
    [4] = "tower_portrait",
    [5] = "brauner_portrait_1",
    [6] = "brauner_portrait_2",
    [7] = "brauner_portrait_3",
    [8] = "brauner_portrait_4",
    [9] = "passage_portrait"
}

PORTRAIT_DESTINATION_NAMES = {
	[1] = "City of Haze",
    [2] = "13th Street",
    [3] = "Sandy Grave",
    [4] = "Forgotten City",
    [5] = "Nation of Fools",
    [6] = "Burnt Paradise",
    [7] = "Forest of Doom",
    [8] = "Dark Academy",
    [9] = "Nest of Evil"
}

LEVEL_POSITIONS = {}
VISITED_PORTRAITS = {}
SAVED_PORTRAITS_BY_SLOT = SAVED_PORTRAITS_BY_SLOT or {}

CUR_INDEX = -1
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}

PLAYER_ID = -1
TEAM_NUMBER = 0

-- gets the data storage key for hints for the current player
-- returns nil when not connected to AP
function getHintDataStorageKey()
	if AutoTracker:GetConnectionState("AP") ~= 3 or Archipelago.TeamNumber == nil or Archipelago.TeamNumber == -1 or Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == -1 then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("Tried to call getHintDataStorageKey while not connect to AP server")
		end
		return nil
	end
	return string.format("_read_hints_%s_%s", Archipelago.TeamNumber, Archipelago.PlayerNumber)
end

-- resets an item to its initial state
function resetItem(item_code, item_type)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: resetting item %s of type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = false
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			obj.CurrentStage = 0
			obj.Active = false
		elseif item_type == "consumable" then
			obj.AcquiredCount = 0
		elseif item_type == "custom" then
			-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: tried to reset static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"resetItem: tried to reset composite_toggle item %s but composite_toggle cannot be accessed via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("resetItem: could not find item object for code %s", item_code))
	end
end

-- advances the state of an item
function incrementItem(item_code, item_type, multiplier)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: code: %s, type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = true
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			if obj.Active then
				obj.CurrentStage = obj.CurrentStage + 1
			else
				obj.Active = true
			end
		elseif item_type == "consumable" then
			obj.AcquiredCount = obj.AcquiredCount + obj.Increment * multiplier
		elseif item_type == "custom" then
			-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: tried to increment static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"incrementItem: tried to increment composite_toggle item %s but composite_toggle cannot be access via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("incrementItem: could not find object for code %s", item_code))
	end
end

-- apply everything needed from slot_data, called from onClear
function apply_slot_data(slot_data)
	-- put any code here that slot_data should affect (toggling setting items for example)

	local goal = Tracker:FindObjectForCode("goal")
	goal.CurrentStage = slot_data["goal"]

	local brauner_portraits = Tracker:FindObjectForCode("brauner_portraits")
	brauner_portraits.AcquiredCount = slot_data["brauner_portraits"]

	local dracula_portraits = Tracker:FindObjectForCode("dracula_portraits")
	dracula_portraits.AcquiredCount = slot_data["dracula_portraits"]

	local nest_portraits = Tracker:FindObjectForCode("nest_portraits")
	nest_portraits.AcquiredCount = slot_data["nest_portraits"]

	local brauner_setting = Tracker:FindObjectForCode("brauner_setting")
	brauner_setting.CurrentStage = slot_data["brauner_required"]

	local nest_setting = Tracker:FindObjectForCode("nest_setting")
	nest_setting.CurrentStage = slot_data["nest_of_evil"]

	local change_cube_setting = Tracker:FindObjectForCode("change_cube_setting")
	local change_cube_tracker = Tracker:FindObjectForCode("change_cube")
	change_cube_setting.CurrentStage = slot_data["start_with_change_cube"]
	change_cube_tracker.Active = slot_data["start_with_change_cube"]

	local stronger_glove_setting = Tracker:FindObjectForCode("stronger_glove_setting")
	stronger_glove_setting.CurrentStage = slot_data["stronger_glove"]

	-- portrait shuffle is not saved in slot_data

	-- local portrait_shuffle_obj = Tracker:FindObjectForCode("portrait_shuffle")
	-- local portrait_shuffle_data = slot_data["portrait_shuffle"]

	-- if portrait_shuffle_data == "split" then
	-- 	portrait_shuffle_obj.CurrentStage = 1
	-- end
	--portrait_shuffle.CurrentStage = slot_data["portrait_shuffle"]

	-- if all portraits vanilla, assume portrait shuffle is off
	if slot_data["hub_portrait"] == "City of Haze"
			and slot_data["underground_portrait"] == "Sandy Grave"
			and slot_data["stairs_portrait"] == "Nation of Fools"
			and slot_data["tower_portrait"] == "Forest of Doom"
			and slot_data["brauner_portrait_1"] == "Forgotten City"
			and slot_data["brauner_portrait_2"] == "13th Street"
			and slot_data["brauner_portrait_3"] == "Burnt Paradise"
			and slot_data["brauner_portrait_4"] == "Dark Academy"
			and slot_data["passage_portrait"] == "Nest of Evil" then
		Tracker:FindObjectForCode("portrait_shuffle").CurrentStage = 0 -- off
	else
		-- the various options don't actually do anything different right now
		Tracker:FindObjectForCode("portrait_shuffle").CurrentStage = 2 -- full
	end

	local call_cube_setting = Tracker:FindObjectForCode("call_cube_setting")
	local call_cube_tracker = Tracker:FindObjectForCode("call_cube")
	call_cube_setting.CurrentStage = slot_data["start_with_call_cube"]
	call_cube_tracker.Active = slot_data["start_with_call_cube"]

	local boss_keys = Tracker:FindObjectForCode("boss_keys")
	boss_keys.CurrentStage = slot_data["add_bosskeys"]

	local throne_settings = Tracker:FindObjectForCode("throne_settings")
	throne_settings.CurrentStage = slot_data["open_throne"]

	-- individual boss keys settings
	local removed_boss_keys = slot_data["disabled_bosskeys"]
	local boss_key_list = {
		"Colosseum Key", "Cavern Key", "Tower Base Key", "Clock Key", "Gallery Key",
		"City Key", "Sandy Key", "Circus Arena Key", "Forest Key", "Throne Key",
		"Street Key", "Forgotten Key", "Burnt Key", "Academy Key", "Nest Key"
	}
    for k, v in pairs(boss_key_list) do
        local obj = Tracker:FindObjectForCode("shuffle_"..v)
        if obj then
            for k2, v2 in pairs(removed_boss_keys) do
            	if v == v2 then
            		-- key is in removed keys
            		obj.Active = false
            		break
            	end
            	-- key is not in removed keys
            	obj.Active = true
            end
        end
    end
end

-- called right after an AP slot is connected
function onClear(slot_data)
	-- use bulk update to pause logic updates until we are done resetting all items/locations
	Tracker.BulkUpdate = true
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
	end
	CUR_INDEX = -1
	-- reset locations
	for _, mapping_entry in pairs(LOCATION_MAPPING) do
		for _, location_table in ipairs(mapping_entry) do
			if location_table then
				local location_code = location_table[1]
				if location_code then
					if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
						print(string.format("onClear: clearing location %s", location_code))
					end
					if location_code:sub(1, 1) == "@" then
						local obj = Tracker:FindObjectForCode(location_code)
						if obj then
							obj.AvailableChestCount = obj.ChestCount
							if obj.Highlight then
								obj.Highlight = Highlight.None
							end
						elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
							print(string.format("onClear: could not find location object for code %s", location_code))
						end
					else
						-- reset hosted item
						local item_type = location_table[2]
						resetItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping location_table with no location_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty location_table"))
			end
		end
	end
	-- reset items
	for _, mapping_entry in pairs(ITEM_MAPPING) do
		for _, item_table in ipairs(mapping_entry) do
			if item_table then
				local item_code = item_table[1]
				local item_type = item_table[2]
				if item_code then
					resetItem(item_code, item_type)
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping item_table with no item_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty item_table"))
			end
		end
	end
	-- reset portrait mappings
	for _, portrait in pairs(PORTRAIT_LOCATION_NAMES) do
		resetItem(portrait, "progressive")
	end
    -- Always clear visited portraits when connecting to a new slot
    VISITED_PORTRAITS = {} 
	apply_slot_data(slot_data)

    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
	LOCAL_ITEMS = {}
	GLOBAL_ITEMS = {}
	-- manually run snes interface functions after onClear in case we need to update them (i.e. because they need slot_data)
	if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
		-- add snes interface functions here
	end
	-- setup data storage tracking for hint tracking
	local data_strorage_keys = {}
	if PopVersion >= "0.32.0" then
		data_strorage_keys = { getHintDataStorageKey() }
	end
	-- subscribes to the data storage keys for updates
	-- triggers callback in the SetNotify handler on update
	Archipelago:SetNotify(data_strorage_keys)
	-- gets the current value for the data storage keys
	-- triggers callback in the Retrieved handler when result is received
	Archipelago:Get(data_strorage_keys)

	load_visited_portraits(slot_data)
	process_level_order(slot_data)

	-- watch map id value
    Archipelago:SetNotify({"map_id"})
    Archipelago:Get({"map_id"})
	-- watch event values
    Archipelago:SetNotify({"ElevatorSwitch"})
    Archipelago:Get({"ElevatorSwitch"})
    Archipelago:SetNotify({"Dullahan"})
    Archipelago:Get({"Dullahan"})
    Archipelago:SetNotify({"Keremet"})
    Archipelago:Get({"Keremet"})
    Archipelago:SetNotify({"Legion"})
    Archipelago:Get({"Legion"})
    Archipelago:SetNotify({"Dagon"})
    Archipelago:Get({"Dagon"})
    Archipelago:SetNotify({"Astarte"})
    Archipelago:Get({"Astarte"})
    Archipelago:SetNotify({"Werewolf"})
    Archipelago:Get({"Werewolf"})
    Archipelago:SetNotify({"TheCreature"})
    Archipelago:Get({"TheCreature"})
    Archipelago:SetNotify({"MummyMan"})
    Archipelago:Get({"MummyMan"})
    Archipelago:SetNotify({"Medusa"})
    Archipelago:Get({"Medusa"})
    -- "Stella": (boss_death_flags >> 13) & 1,
    -- "Stella&Loretta": (boss_death_flags >> 14) & 1,
    Archipelago:SetNotify({"Brauner"})
    Archipelago:Get({"Brauner"})
    Archipelago:SetNotify({"Death"})
    Archipelago:Get({"Death"})
    Archipelago:SetNotify({"Dracula"})
    Archipelago:Get({"Dracula"})
    Archipelago:SetNotify({"Doppelganger"})
    Archipelago:Get({"Doppelganger"})

	Tracker.BulkUpdate = false
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
	end
	if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
		return
	end
	if index <= CUR_INDEX then
		return
	end
	local is_local = player_number == Archipelago.PlayerNumber
	CUR_INDEX = index
	local mapping_entry = ITEM_MAPPING[item_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onItem: could not find item mapping for id %s", item_id))
		end
		return
	end
	for _, item_table in pairs(mapping_entry) do
		if item_table then
			local item_code = item_table[1]
			local item_type = item_table[2]
			local multiplier = item_table[3] or 1
			if item_code then
				incrementItem(item_code, item_type, multiplier)
				-- keep track which items we touch are local and which are global
				if is_local then
					if LOCAL_ITEMS[item_code] then
						LOCAL_ITEMS[item_code] = LOCAL_ITEMS[item_code] + 1
					else
						LOCAL_ITEMS[item_code] = 1
					end
				else
					if GLOBAL_ITEMS[item_code] then
						GLOBAL_ITEMS[item_code] = GLOBAL_ITEMS[item_code] + 1
					else
						GLOBAL_ITEMS[item_code] = 1
					end
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping item_table with no item_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onClear: skipping empty item_table"))
		end
	end
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
		print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
	end
	-- track local items via snes interface
	if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
		-- add snes interface functions for local item tracking here
	end
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onLocation: %s, %s", location_id, location_name))
	end
	if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local mapping_entry = LOCATION_MAPPING[location_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: could not find location mapping for id %s", location_id))
		end
		return
	end
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			if location_code then
				local obj = Tracker:FindObjectForCode(location_code)
				if obj then
					if location_code:sub(1, 1) == "@" then
						obj.AvailableChestCount = obj.AvailableChestCount - 1
					else
						-- increment hosted item
						local item_type = location_table[2]
						incrementItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onLocation: could not find object for code %s", location_code))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onLocation: skipping location_table with no location_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: skipping empty location_table"))
		end
	end
end

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
			item_player))
	end
	-- not implemented yet :(
end

-- called when a bounce message is received
function onBounce(json)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onBounce: %s", dump_table(json)))
	end
	-- your code goes here
end

-- called whenever Archipelago:Get returns data from the data storage or
-- whenever a subscribed to (via Archipelago:SetNotify) key in data storgae is updated
-- oldValue might be nil (always nil for "_read" prefixed keys and via retrieved handler (from Archipelago:Get))
function onDataStorageUpdate(key, value, oldValue)
	--if you plan to only use the hints key, you can remove this if
	if key == getHintDataStorageKey() then
		onHintsUpdate(value)
	end
	if key == "map_id" then
		onMapChange(key, value, oldValue)
	elseif key == "ElevatorSwitch" and value then
		Tracker:FindObjectForCode("tower_elevator_active").Active = (value == 1)
		Tracker:FindObjectForCode("@Tower of Death - Top of the Tower/Tower of Death: Elevator Switch/").AvailableChestCount = 1 - value
	elseif key == "Dullahan" and value then
		Tracker:FindObjectForCode("dullahan_defeated").Active = (value == 1)
		recalculate_portrait_clears()
		Tracker:FindObjectForCode("@City of Haze - East/City of Haze: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "Keremet" and value then
		Tracker:FindObjectForCode("@Great Stairway - Lower/Great Stairway: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "Legion" and value then
		Tracker:FindObjectForCode("legion_defeated").Active = (value == 1)
		recalculate_portrait_clears()
		Tracker:FindObjectForCode("@Nation of Fools - Main/Nation of Fools: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "Dagon" and value then
		Tracker:FindObjectForCode("dagon_defeated").Active = (value == 1)
		recalculate_portrait_clears()
		Tracker:FindObjectForCode("@Forest of Doom - Cave/Forest of Doom: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "Astarte" and value then
		Tracker:FindObjectForCode("astarte_defeated").Active = (value == 1)
		recalculate_portrait_clears()
		Tracker:FindObjectForCode("@Sandy Grave - Pyramid Top/Sandy Grave: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "Werewolf" and value then
		Tracker:FindObjectForCode("werewolf_defeated").Active = (value == 1)
		recalculate_portrait_clears()
		Tracker:FindObjectForCode("@13th Street - Main/13th Street: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "TheCreature" and value then
		Tracker:FindObjectForCode("creature_defeated").Active = (value == 1)
		recalculate_portrait_clears()
		Tracker:FindObjectForCode("@Dark Academy - Main/Dark Academy: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "MummyMan" and value then
		Tracker:FindObjectForCode("mummy_man_defeated").Active = (value == 1)
		recalculate_portrait_clears()
		Tracker:FindObjectForCode("@Forgotten City - Inner Upper/Forgotten City: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "Medusa" and value then
		Tracker:FindObjectForCode("medusa_defeated").Active = (value == 1)
		recalculate_portrait_clears()
		Tracker:FindObjectForCode("@Burnt Paradise - Entrance/Burnt Paradise: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "Death" and value then
		Tracker:FindObjectForCode("death_defeated").Active = (value == 1)
		Tracker:FindObjectForCode("@Tower of Death - Top of the Tower/Tower of Death: Boss Room/").AvailableChestCount = 1 - value
	elseif key == "Brauner" and value then
		Tracker:FindObjectForCode("brauner_defeated").Active = (value == 1)
		Tracker:FindObjectForCode("@Master's Keep - Portrait Room/Lost Gallery: Studio Portrait Fight/").AvailableChestCount = 1 - value
	elseif key == "Dracula" and value then
		Tracker:FindObjectForCode("dracula_defeated").Active = (value == 1)
		Tracker:FindObjectForCode("@The Throne Room/The Throne Room: Dracula/").AvailableChestCount = 1 - value
	elseif key == "Doppelganger" and value then
		Tracker:FindObjectForCode("dopppelganger_defeated").Active = (value == 1)
	end
end

-- called whenever the hints key in data storage updated
-- NOTE: this should correctly handle having multiple mapped locations in a section.
--       if you only map sections 1 to 1 you can simplfy this. for an example see
--       https://github.com/Cyb3RGER/sm_ap_tracker/blob/main/scripts/autotracking/archipelago.lua
function onHintsUpdate(hints)
	-- Highlight is only supported since version 0.32.0
	if PopVersion < "0.32.0" or not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local player_number = Archipelago.PlayerNumber
	-- get all new highlight values per section
	local sections_to_update = {}
	for _, hint in ipairs(hints) do
		-- we only care about hints in our world
		if hint.finding_player == player_number then
			updateHint(hint, sections_to_update)
		end
	end
	-- update the sections
	for location_code, highlight_code in pairs(sections_to_update) do
		-- find the location object
		local obj = Tracker:FindObjectForCode(location_code)
		-- check if we got the location and if it supports Highlight
		if obj and obj.Highlight then
			obj.Highlight = highlight_code
		end
	end
end

-- update section highlight based on the hint
function updateHint(hint, sections_to_update)
	-- get the highlight enum value for the hint status
	local hint_status = hint.status
	local highlight_code = nil
	if hint_status then
		highlight_code = HINT_STATUS_MAPPING[hint_status]
	end
	if not highlight_code then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("updateHint: unknown hint status %s for hint on location id %s", hint.status,
				hint.location))
		end
		-- try to "recover" by checking hint.found (older AP versions without hint.status)
		if hint.found == true then
			highlight_code = Highlight.None
		elseif hint.found == false then
			highlight_code = Highlight.Unspecified
		else
			return
		end
	end
	-- get the location mapping for the location id
	local mapping_entry = LOCATION_MAPPING[hint.location]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("updateHint: could not find location mapping for id %s", hint.location))
		end
		return
	end
	--get the "highest" highlight value pre section
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			-- skip hosted items, they don't support Highlight
			if location_code and location_code:sub(1, 1) == "@" then
				-- see if we already set a Highlight for this section
				local existing_highlight_code = sections_to_update[location_code]
				if existing_highlight_code then
					-- make sure we only replace None or "increase" the highlight but never overwrite with None
					-- this so sections with mulitple mapped locations show the "highest" Highlight and
					-- only show no Highlight when all hints are found
					if existing_highlight_code == Highlight.None or (existing_highlight_code < highlight_code and highlight_code ~= Highlight.None) then
						sections_to_update[location_code] = highlight_code
					end
				else
					sections_to_update[location_code] = highlight_code
				end
			end
		end
	end
end

-- when map changed (for revealing shuffled portraits when discovered)
-- thanks to Umed's dk64 tracker for this
function onMapChange(id, value, old)
	print("onMapChange:")
    print("got  " .. id .. " = " .. tostring(value) .. " (was " .. tostring(old) .. ")")
    if not id == "map_id" then
    	return
    end
    --if has("automap_on") then
    local map_id = tostring(value)
    -- tabs = MAP_MAPPING[map_id]
    
    local updated = false
    
    if map_id == "1" and not VISITED_PORTRAITS["City of Haze"] then
        VISITED_PORTRAITS["City of Haze"] = true
        updated = true
        print("visited city of haze")
    elseif map_id == "2" and not VISITED_PORTRAITS["13th Street"] then
        VISITED_PORTRAITS["13th Street"] = true
        updated = true
        print("visited 13th street")
    elseif map_id == "3" and not VISITED_PORTRAITS["Sandy Grave"] then
        VISITED_PORTRAITS["Sandy Grave"] = true
        updated = true
        print("visited sandy grave")
    elseif map_id == "4" and not VISITED_PORTRAITS["Forgotten City"] then
        VISITED_PORTRAITS["Forgotten City"] = true
        updated = true
        print("visited forgotten city")
    elseif map_id == "5" and not VISITED_PORTRAITS["Nation of Fools"] then
        VISITED_PORTRAITS["Nation of Fools"] = true
        updated = true
        print("visited nation of fools")
    elseif map_id == "6" and not VISITED_PORTRAITS["Burnt Paradise"] then
        VISITED_PORTRAITS["Burnt Paradise"] = true
        updated = true
        print("visited burnt paradise")
    elseif map_id == "7" and not VISITED_PORTRAITS["Forest of Doom"] then
        VISITED_PORTRAITS["Forest of Doom"] = true
        updated = true
        print("visited forest of doom")
    elseif map_id == "8" and not VISITED_PORTRAITS["Dark Academy"] then
        VISITED_PORTRAITS["Dark Academy"] = true
        updated = true
        print("visited dark academy")
    elseif map_id == "9" and not VISITED_PORTRAITS["Nest of Evil"] then
        VISITED_PORTRAITS["Nest of Evil"] = true
        updated = true
        print("visited nest of evil")
    end
    
    -- If we've discovered a new portrait, update the level display
    if updated then
        update_level_display(slot_data)
    end
    
    -- for i, tab in ipairs(tabs) do
    --     Tracker:UiHint("ActivateTab", tab)
    -- end
end

function process_level_order(slot_data)
    LEVEL_POSITIONS = {}
    LEVEL_POSITIONS[1] = slot_data["hub_portrait"]
    LEVEL_POSITIONS[2] = slot_data["underground_portrait"]
    LEVEL_POSITIONS[3] = slot_data["stairs_portrait"]
    LEVEL_POSITIONS[4] = slot_data["tower_portrait"]
    LEVEL_POSITIONS[5] = slot_data["brauner_portrait_1"]
    LEVEL_POSITIONS[6] = slot_data["brauner_portrait_2"]
    LEVEL_POSITIONS[7] = slot_data["brauner_portrait_3"]
    LEVEL_POSITIONS[8] = slot_data["brauner_portrait_4"]
    LEVEL_POSITIONS[9] = slot_data["passage_portrait"]

    -- After setting up LEVEL_POSITIONS, call update_level_display to show the accessible levels
    update_level_display(slot_data)
end

function update_level_display(slot_data)
    if next(LEVEL_POSITIONS) == nil then
        return
    end
    
    for i = 1, 9 do
        local obj = Tracker:FindObjectForCode(PORTRAIT_LOCATION_NAMES[i])
        if obj then
            local current_stage = obj.CurrentStage
            
            local level_id = LEVEL_POSITIONS[i]
            if level_id then
                for id, level_name in pairs(PORTRAIT_DESTINATION_NAMES) do
                    if level_id == level_name and VISITED_PORTRAITS[level_name] then
                        obj.CurrentStage = id
                        break
                    end
                end
                if obj.CurrentStage == 0 and current_stage > 0 then
                    obj.CurrentStage = current_stage
                end
            else
                if current_stage > 0 then
                    obj.CurrentStage = current_stage
                end
            end
        end
    end
    save_visited_portraits(slot_data)
end

function save_visited_portraits(slot_data)
    if not PLAYER_ID or PLAYER_ID < 0 then
        return
    end
    
    local slot_key = PLAYER_ID .. "_" .. (TEAM_NUMBER or 0)
    
    if not SAVED_PORTRAITS_BY_SLOT[slot_key] then
        SAVED_PORTRAITS_BY_SLOT[slot_key] = {
            hub_portrait = slot_data['hub_portrait'],
            underground_portrait = slot_data['underground_portrait'],
            stairs_portrait = slot_data['stairs_portrait'],
            tower_portrait = slot_data['tower_portrait'],
            brauner_portrait_1 = slot_data['brauner_portrait_1'],
            brauner_portrait_2 = slot_data['brauner_portrait_2'],
            brauner_portrait_3 = slot_data['brauner_portrait_3'],
            brauner_portrait_4 = slot_data['brauner_portrait_4'],
            passage_portrait = slot_data['passage_portrait'],
            portraits = {}
        }
    end
    
    SAVED_PORTRAITS_BY_SLOT[slot_key].portraits = {}
    
    for portrait_name, visited in pairs(VISITED_PORTRAITS) do
        if visited then
        	print(string.format("saving visited portrait %s", portrait_name))
            SAVED_PORTRAITS_BY_SLOT[slot_key].portraits[portrait_name] = true
        end
    end

    print("saved visited portraits")
    print(dump_table(SAVED_PORTRAITS_BY_SLOT))
end

function load_visited_portraits(slot_data)
	print("loading visited portraits...")
    if not PLAYER_ID or PLAYER_ID < 0 then
        return
    end
    
    local slot_key = PLAYER_ID .. "_" .. (TEAM_NUMBER or 0)
    
    if SAVED_PORTRAITS_BY_SLOT[slot_key] then
        -- if slot_data['LevelOrder'] and SAVED_PORTRAITS_BY_SLOT[slot_key].level_order 
        --    and slot_data['LevelOrder'] ~= SAVED_PORTRAITS_BY_SLOT[slot_key].level_order then
        --    	print("error: visited portraits data is incorrect")
        --     return false
        -- end
        
        for portrait_name, visited in pairs(SAVED_PORTRAITS_BY_SLOT[slot_key].portraits or {}) do
            if visited then
                VISITED_PORTRAITS[portrait_name] = true
            end
        end
        
        if next(LEVEL_POSITIONS) ~= nil then
            update_level_display()
        end
        
    	print("successfully loaded visited portraits")
        return true
    end
    
    print("error: failed to find visited portraits data")
    return false
end

function recalculate_portrait_clears()
	print("calculating portrait clears")
	local portrait_clear_obj = Tracker:FindObjectForCode("portrait_clear")
	if portrait_clear_obj then
		local portraits_cleared = 0
		if Tracker:FindObjectForCode("dullahan_defeated").Active then
			portraits_cleared = portraits_cleared + 1
		end
		if Tracker:FindObjectForCode("astarte_defeated").Active then
			portraits_cleared = portraits_cleared + 1
		end
		if Tracker:FindObjectForCode("legion_defeated").Active then
			portraits_cleared = portraits_cleared + 1
		end
		if Tracker:FindObjectForCode("dagon_defeated").Active then
			portraits_cleared = portraits_cleared + 1
		end
		if Tracker:FindObjectForCode("werewolf_defeated").Active then
			portraits_cleared = portraits_cleared + 1
		end
		if Tracker:FindObjectForCode("mummy_man_defeated").Active then
			portraits_cleared = portraits_cleared + 1
		end
		if Tracker:FindObjectForCode("medusa_defeated").Active then
			portraits_cleared = portraits_cleared + 1
		end
		if Tracker:FindObjectForCode("creature_defeated").Active then
			portraits_cleared = portraits_cleared + 1
		end
		portrait_clear_obj.AcquiredCount = portraits_cleared
	end
end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
	Archipelago:AddLocationHandler("location handler", onLocation)
end
Archipelago:AddRetrievedHandler("retrieved handler", onDataStorageUpdate)
Archipelago:AddSetReplyHandler("set reply handler", onDataStorageUpdate)
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)