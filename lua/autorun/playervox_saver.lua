-- PlayerVOX support for saving/loading presets

function file.Copy(source, dest, path)
    local content = file.Read(source, path)
    
    if content then
        file.Write(dest, content)
        return true
    end

    return false
end

function PVOX_SendNotification(ply, mesg)
    ply:SendLua("notification.AddLegacy(" .. mesg .. ", NOTIFY_GENERIC, 5)")
end

if SERVER then

    -- Store the presets in memory on the server for quick access
    local PVOX_DataStore = {}
    local SAVE_FILE_NAME = "pvox_presets.txt"

    -- Function to load ALL data from file into the server's memory
    function PVOX_InitializeData()
        print("[PVOX] Initializing data...")

        local rawData = file.Read(SAVE_FILE_NAME, "DATA")
        if not rawData or rawData == "" then
            print("[PVOX] No existing data file found or file is empty. Starting fresh.")
            PVOX_DataStore = {}
            return
        end

        local success, decodedData = pcall(util.JSONToTable, rawData)

        if not success or type(decodedData) ~= "table" then
            print("[PVOX] ERROR: Could not decode JSON data from " .. SAVE_FILE_NAME .. ". Backing up and starting fresh.")
            print("[PVOX] Error details: ", decodedData)
            
            file.Copy(SAVE_FILE_NAME, SAVE_FILE_NAME .. ".bak", "DATA")
            
            PVOX_DataStore = {}

            return
        end

        PVOX_DataStore = decodedData
        print("[PVOX] Successfully loaded data for " .. table.Count(PVOX_DataStore) .. " players.")
    end

    -- Function to save ALL data from memory to the file
    function PVOX_SaveAllDataToFile()
        if not PVOX_DataStore then
            print("[PVOX] ERROR: Data store does not exist, cannot save.")
            return
        end

        local success, encodedData = pcall(util.TableToJSON, PVOX_DataStore, true) -- Use true for pretty printing (optional)

        if not success then
            print("[PVOX] ERROR: Failed to encode data to JSON!")
            print("[PVOX] Error details: ", encodedData) -- Print the error message
            return
        end

        file.Write(SAVE_FILE_NAME, encodedData)
        print("[PVOX] All player data saved successfully.")
    end

    -- Function to load data for a SPECIFIC player when they join/spawn
    -- Call this from GM:PlayerInitialSpawn(ply) hook
    function PVOX_LoadPlayerData(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local steamID64 = ply:SteamID() -- Use SteamID64!

        note("[PVOX] Attempting to load data for player: " .. ply:Nick() .. " (" .. steamID64 .. ")")

        -- Check if data exists for this player in our memory store
        if PVOX_DataStore[steamID64] then
            local savedPreset = PVOX_DataStore[steamID64].preset

            if savedPreset and savedPreset ~= "none" then
                note("[PVOX] Found saved preset '" .. savedPreset .. "' for " .. ply:Nick())

                ply:SetNWString("vox_preset", savedPreset)
                PVOX_SendNotification(ply, string.format("'Loaded your preset %s from memory!'", savedPreset))
            else
                note("[PVOX] No valid preset found in saved data for " .. ply:Nick() .. ".. setting default")
                ply:SetNWString("vox_preset", "none") 
            end
        else
            
            ply:SetNWString("vox_preset", "none")
        end
    end

    function PVOX_UpdatePlayerData(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local steamID64 = ply:SteamID()
        local currentPreset = ply:GetNWString("vox_preset", "none") -- Get the current preset

        print("[PVOX] Updating data in memory for " .. ply:Nick() .. " - Preset: " .. currentPreset)

        -- if not exist add it
        if not PVOX_DataStore[steamID64] then
            PVOX_DataStore[steamID64] = {}
        end

        -- Store the data
        PVOX_DataStore[steamID64].preset = currentPreset
    end


    -- === Hooks ===

    -- Called when the server starts
    hook.Add("Initialize", "PVOX_LoadInitialData", function()
        PVOX_InitializeData()
    end)

    -- Called when a player first spawns in the server
    hook.Add("PlayerInitialSpawn", "PVOX_LoadPlayerOnSpawn", function(ply)
        -- Delay slightly to ensure player object is fully ready (sometimes needed)
        timer.Simple(0.5, function()
            if IsValid(ply) then
                PVOX_LoadPlayerData(ply)
            end
        end)
    end)

    -- Called when a player leaves
    hook.Add("PlayerDisconnect", "PVOX_SavePlayerOnLeave", function(ply)
        print("[PVOX] Player " .. ply:Nick() .. " disconnected.")
        -- Update their data in memory one last time based on NWString
        PVOX_UpdatePlayerData(ply)
        -- Save all data when a player leaves (good practice)
        PVOX_SaveAllDataToFile()
    end)

    -- Called when the server is shutting down
    hook.Add("ShutDown", "PVOX_SaveDataOnShutdown", function()
        print("[PVOX] Server shutting down. Saving all data...")
        PVOX_SaveAllDataToFile()
    end)

    concommand.Add("pvox_saveall", function(ply, cmd, args)
        if ply:IsAdmin() then
            print("[PVOX] Admin triggered manual data save.")
            PVOX_SaveAllDataToFile()
            ply:ChatPrint("[PVOX] All player data saved.")
        else
            ply:ChatPrint("You don't have permission to do that.")
        end
    end)

    -- Example: Add a command for players to manually set and save their preset
    concommand.Add("pvox_setpreset", function(ply, cmd, args)
        if not args[1] then
            ply:ChatPrint("Usage: pvox_setpreset <preset_name>")
            return
        end

        local newPreset = args[1]
        -- Add validation here if needed (e.g., check if preset name is valid)
        ply:SetNWString("vox_preset", newPreset)
        PVOX_UpdatePlayerData(ply)
        ply:ChatPrint("[PVOX] Your preset has been set to: " .. newPreset)
        ply:SendLua("notification.AddLegacy('PVOX preset saved: " .. newPreset .. "', NOTIFY_GENERIC, 5)")

    end)


end -- End of "if SERVER then" block