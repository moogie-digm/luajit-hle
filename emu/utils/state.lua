_G.emu.loadstate = create_overlays_system()
_G.emu.savestate = create_overlays_system()



local error_handler = function(err)
    local traceback = debug.traceback("", 2)

    print(string.format(
        "--------------------------------------------------\n" ..
        "❌ MOD HOOK CRASHED!\n" ..
        "Hook Origin: %s\n" ..
        "Error Reason: %s\n" ..
        "%s\n" ..
        "--------------------------------------------------\n",
        tostring(nil), tostring(err), traceback
    ))
end



-- extern func
emu.loadstate_run = function()
	xpcall(emu.loadstate.run, error_handler)
end



-- extern func
emu.savestate_run = function()
	emu.savestate.run()
end
