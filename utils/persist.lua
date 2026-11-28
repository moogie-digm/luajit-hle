--[=[
-- Create a permanent space that your teardown function is forbidden to delete
_G.MOD_REGISTRY = _G.MOD_REGISTRY or {}


-- Define this globally so all scripts can see it
function _G.persist(key, default_value)
    -- If the value already exists in the registry (from a previous session/load), keep it!
    -- If it's the very first time the mod is loading, initialize it with the default.
    if _G.MOD_REGISTRY[key] == nil then
        _G.MOD_REGISTRY[key] = default_value
    end
    
    -- Return a proxy table so they can read/write to it seamlessly
    return setmetatable({}, {
        __index = function(_, k) 
            return _G.MOD_REGISTRY[key][k] 
        end,
        __newindex = function(_, k, v) 
            _G.MOD_REGISTRY[key][k] = v 
        end
    })
end



-- At the top of their file:
local session = persist("hud_state", {
    score = 0,
    active_powerups = {},
    menu_open = false
})

-- Later in their code (inside a frame hook or collision callback):
function on_enemy_defeat()
    session.score = session.score + 100  -- Updates live memory!
    print("Current Score: " .. session.score)
end

--]=]
