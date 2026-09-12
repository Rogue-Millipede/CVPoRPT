function initialize_watch_items()
	ScriptHost:AddWatchForCode("Boss Keys", "boss_keys", updateItemLayout)
	ScriptHost:AddWatchForCode("Portrait Shuffle", "portrait_shuffle", updateItemLayout)
end

function updateItemLayout(code)
	local boss_keys = Tracker:ProviderCountForCode("add_boss_keys")
	local portrait_shuffle_off = Tracker:ProviderCountForCode("portrait_shuffle_off")

	if boss_keys == 1 then
		Tracker:AddLayouts("layouts/boss_keys.jsonc")
	else
		Tracker:AddLayouts("layouts/boss_keys_off.jsonc")
	end
	if portrait_shuffle_off == 1 then
		Tracker:AddLayouts("layouts/portrait_shuffle_off.jsonc")
	else
		Tracker:AddLayouts("layouts/portrait_shuffle.jsonc")
	end
end