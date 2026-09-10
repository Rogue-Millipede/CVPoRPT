-- put logic functions here using the Lua API: https://github.com/black-sliver/PopTracker/blob/master/doc/PACKS.md#lua-interface
-- don't be afraid to use custom logic functions. it will make many things a lot easier to maintain, for example by adding logging.
-- to see how this function gets called, check: locations/locations.json
-- example:
function has_more_then_n_consumable(n)
    local count = Tracker:ProviderCountForCode('consumable')
    local val = (count > tonumber(n))
    if ENABLE_DEBUG_LOG then
        print(string.format("called has_more_then_n_consumable: count: %s, n: %s, val: %s", count, n, val))
    end
    if val then
        return 1 -- 1 => access is in logic
    end
    return 0 -- 0 => no access
end

function has(item, amount)
    local count = Tracker:ProviderCountForCode(item)
    amount = tonumber(amount)
    if not amount then
        return count > 0
    else
        return count >= amount
    end
end

-- Move Macros
function has_call_cube()
    return has("call_cube") or has("start_with_call_cube")
end

function has_change_cube()
    return has("change_cube") or has("start_with_change_cube")
end

function strongies()
    return has("strength_glove") and ((has("push_cube") and has_call_cube()) or has("stronger_glove"))
end

function can_cast_spell()
    return has("skill_cube") or has_change_cube()
end

function small_uppies()
    return has("stone_of_flight") or has("griffon_wing") or (has("acrobat_cube") and has_call_cube()) or (can_cast_spell() and has("owl_morph"))
end

function medium_uppies()
    return has("stone_of_flight") or has("griffon_wing") or (can_cast_spell() and has("owl_morph"))
end

function big_uppies()
    return has("griffon_wing") or (can_cast_spell() and has("owl_morph"))
end

function is_smol()
    return has("lizard_tail") or (can_cast_spell() and has("owl_morph")) or (can_cast_spell() and has("toad_morph"))
end

function can_purify_sisters()
    return has("sanctuary") and (has("skill_cube") or (has_change_cube() and has_call_cube()))
end

function nest_not_removed()
    return not has("nest_removed")
end

function has_enough_portraits_for_nest()
    local count = Tracker:ProviderCountForCode('portrait_clear')
    local req = Tracker:ProviderCountForCode('nest_portraits')
    return count >= req
end

function has_enough_portraits_for_brauner()
    local count = Tracker:ProviderCountForCode('portrait_clear')
    local req = Tracker:ProviderCountForCode('brauner_portraits')
    return count >= req
end

function has_enough_portraits_for_dracula()
    local count = Tracker:ProviderCountForCode("portrait_clear")
    local req = Tracker:ProviderCountForCode("dracula_portraits")
    return count >= req
end

function throne_available()
    if has("open_throne") then
        return true
    end
    if not has("goal_dracula") then
        return false
    end
    return dracula_available()
end

function dracula_available()
    local enough_portraits = has_enough_portraits_for_dracula()
    local brauner_state = has("brauner_optional") or has("brauner_defeated")
    local nest_state = has("doppelganger_defeated") or not has("nest_required")
    return enough_portraits and brauner_state and nest_state
end

function boss_door_open(door_key)
    if not has("add_boss_keys") then
        return true
    end
    local shuffle_door_key = "shuffle_" .. door_key
    return has(door_key) or not has(shuffle_door_key)
end

function brauner_available()
    local enough_portraits = has_enough_portraits_for_brauner()
    local nest_state = has("doppelganger_defeated") or not has("nest_required")
    local final_boss = has("goal_brauner")
    return enough_portraits and (not final_boss or nest_state)
end