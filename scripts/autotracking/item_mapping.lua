-- use this file to map the AP item ids to your items
-- first value is the code of the target item and the second is the item type override. The third value is an optional increment multiplier for consumables. (feel free to expand the table with any other values you might need (i.e. special initial values, etc.)!)
-- here are the SM items as an example: https://github.com/Cyb3RGER/sm_ap_tracker/blob/main/scripts/autotracking/item_mapping.lua
BASE_ITEM_ID = 0
ITEM_MAPPING = {
	-- [BASE_ITEM_ID + 00000] = { { "toggle" } },
	-- [BASE_ITEM_ID + 00001] = { { "progressive" } },
	-- [BASE_ITEM_ID + 00002] = { { "consumable" } },
	-- -- handle progressive_toggle as toggle, only changing it's active state
	-- [BASE_ITEM_ID + 00003] = { { "progressive_toggle", "toggle" } },
	-- -- multiple items on this id, add the consumable 3 times
	-- [BASE_ITEM_ID + 00004] = { { "toggle" }, { "consumable", nil, 3 } }
	[BASE_ITEM_ID + 0x24e] = {{"cog", "toggle"}},

	[BASE_ITEM_ID + 0x260] = {{"Colosseum Key", "toggle"}},
	[BASE_ITEM_ID + 0x261] = {{"Cavern Key", "toggle"}},
	[BASE_ITEM_ID + 0x262] = {{"Tower Base Key", "toggle"}},
	[BASE_ITEM_ID + 0x263] = {{"Clock Key", "toggle"}},
	[BASE_ITEM_ID + 0x264] = {{"Gallery Key", "toggle"}},
	[BASE_ITEM_ID + 0x265] = {{"Throne Key", "toggle"}},
	[BASE_ITEM_ID + 0x266] = {{"City Key", "toggle"}},
	[BASE_ITEM_ID + 0x267] = {{"Sandy Key", "toggle"}},
	[BASE_ITEM_ID + 0x268] = {{"Circus Arena Key", "toggle"}},
	[BASE_ITEM_ID + 0x269] = {{"Forest Key", "toggle"}},
	[BASE_ITEM_ID + 0x26a] = {{"Street Key", "toggle"}},
	[BASE_ITEM_ID + 0x26b] = {{"Forgotten Key", "toggle"}},
	[BASE_ITEM_ID + 0x26c] = {{"Burnt Key", "toggle"}},
	[BASE_ITEM_ID + 0x26d] = {{"Academy Key", "toggle"}},
	[BASE_ITEM_ID + 0x26e] = {{"Nest Key", "toggle"}},

	[BASE_ITEM_ID + 0x703] = {{"stella_locket", "toggle"}},

	[BASE_ITEM_ID + 0x801] = {{"puppet_master", "toggle"}},

	[BASE_ITEM_ID + 0x827] = {{"toad_morph", "toggle"}},
	[BASE_ITEM_ID + 0x828] = {{"owl_morph", "toggle"}},
	[BASE_ITEM_ID + 0x829] = {{"sanctuary", "toggle"}},
	[BASE_ITEM_ID + 0x82a] = {{"speed_up", "toggle"}},

	[BASE_ITEM_ID + 0x85c] = {{"change_cube", "toggle"}},
	[BASE_ITEM_ID + 0x85d] = {{"call_cube", "toggle"}},
	[BASE_ITEM_ID + 0x85e] = {{"skill_cube", "toggle"}},
	[BASE_ITEM_ID + 0x85f] = {{"wait_cube", "toggle"}},
	[BASE_ITEM_ID + 0x860] = {{"acrobat_cube", "toggle"}},
	[BASE_ITEM_ID + 0x861] = {{"push_cube", "toggle"}},
	[BASE_ITEM_ID + 0x862] = {{"lizard_tail", "toggle"}},
	[BASE_ITEM_ID + 0x863] = {{"stone_of_flight", "toggle"}},
	[BASE_ITEM_ID + 0x864] = {{"griffon_wing", "toggle"}},
	[BASE_ITEM_ID + 0x865] = {{"strength_glove", "toggle"}},
}
