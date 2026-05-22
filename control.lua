-- control.lua

local qualityLookup = {}
local qualityReverseLookup = {}

local j = 0
for name, quality in pairs(prototypes.quality) do
    j = j + 1
    qualityLookup[name] = j
    qualityReverseLookup[j] = name
end


local qualityMixNMatchCopies = {}
if script.active_mods["base"] then
    qualityMixNMatchCopies["assembling-machine-2"] = "mix-n-matcher-".."assembling-machine-2"
end
if script.active_mods["space-age"] then
    qualityMixNMatchCopies["foundry"] = "mix-n-matcher-".."foundry"
    qualityMixNMatchCopies["electromagnetic-plant"] = "mix-n-matcher-".."electromagnetic-plant"
    qualityMixNMatchCopies["biochamber"] = "mix-n-matcher-".."biochamber"
    qualityMixNMatchCopies["cryogenic-plant"] = "mix-n-matcher-".."cryogenic-plant"
end


script.on_init(function ()
    storage.assemblerBuffers = {}
end)

script.on_event({defines.events.on_robot_built_entity, defines.events.on_built_entity, defines.events.script_raised_revive, defines.events.on_player_rotated_entity}, function (event)
    local entity = event.entity
    if not entity or not entity.valid then return end
    for copyName, machine in pairs(qualityMixNMatchCopies) do
        if entity.name == machine then
            local id = entity.unit_number
            
            -- Spawn the hidden chest directly centered on top of the assembler
            local hidden_chest = entity.surface.create_entity{
                name = "mix-n-matcher-hidden-chest-"..copyName,
                position = entity.position,
                force = entity.force
            }
            hidden_chest.destructible = false -- Make sure it cannot be accidentally destroyed
            -- hidden_chest.active = false
            local x = 0
            local trunk = hidden_chest.get_inventory(defines.inventory.car_trunk)

            while x < #trunk do
                x = x + 1
                trunk.set_filter(x, {name = "dummy-item"})
            end
            
            storage.assemblerBuffers[id] = {
                ["entity"] = entity,
                ["chest"] = hidden_chest,
                ["bufferMax"] = {},
                ["buffers"] = {},
                ["quality"] = {},
                ["recipe"] = "",
                ["inserters"] = {},
                ["averageQuality"] = 1,
                ["RollRand"] = true,
                ["RandRoll"] = 0
            }
            -- Run your existing function to discover old/existing inserters pointing here
                GetInsertersPointingAtMe(entity, id)
                return
        end
    end
        if entity.type == "inserter" then
            -- Look at where the inserter drops items to see if it targets our assembler
            local targetList = entity.surface.find_entities_filtered{position = entity.drop_position}
            for i = 1, #targetList do
                local target = targetList[i]
                for copyName, machine in pairs(qualityMixNMatchCopies) do
                    if target and (target.name == machine or target.name == "mix-n-matcher-hidden-chest-"..copyName) then
                        local assemblerId = target.unit_number
                        if storage.assemblerBuffers[assemblerId] then
                            storage.assemblerBuffers[assemblerId]["inserters"][entity.unit_number] = entity
                            entity.drop_target = storage.assemblerBuffers[assemblerId]["chest"]
                        end
                    end
                end
            end
        end
    end)
        
script.on_event({defines.events.on_entity_died, defines.events.on_robot_mined_entity, defines.events.on_player_mined_entity,defines.events.script_raised_destroy }, function (event)
    local entity = event.entity
    if not entity or not entity.valid then return end
    
    for _, machine in pairs(qualityMixNMatchCopies) do
        
        if entity.name == machine then
            local id = entity.unit_number
            local data = storage.assemblerBuffers[id]
            
            if data then
                
                -- 2. Spill any stray items physically sitting in the hidden chest right now
                if data.chest and data.chest.valid then
                    local inv = data.chest.get_inventory(defines.inventory.car_trunk)
                    if inv then
                        for i = 1, #inv do
                            local stack = inv[i]
                            if stack.valid_for_read then
                                entity.surface.spill_item_stack{
                                    position = entity.position,
                                    stack = stack,
                                    enable_looted = true,
                                    force = entity.force
                                }
                            end
                        end
                    end
                    -- Completely clean up the invisible entity from the map
                    data.chest.destroy()
                end
                -- 1. First spill everything trapped inside the internal script buffer tables
                for itemName, amount in pairs(data.buffers) do 
                    if amount > 0 then
                        entity.surface.spill_item_stack{
                            position = entity.position,
                            stack = {name = itemName, count = amount,},
                            enable_looted = true,
                            force = entity.force
                        }
                    end
                end
                storage.assemblerBuffers[id] = nil
                return
            end
        end
        if entity.type == "inserter" then
            local target = entity.drop_target
            if target then
                for _, copyName in pairs(qualityMixNMatchCopies) do
                    if entity.drop_target.name == "mix-n-matcher-hidden-chest-"..copyName then
                        storage.assemblerBuffers[entity.drop_target.unit_number]["inserters"][entity.unit_number] = nil
                    end
                end
            end
        end
    end
end)

            

script.on_nth_tick(1, function ()
    if not storage.assemblerBuffers then return end
    for id, data in pairs(storage.assemblerBuffers) do
        local entity = data.entity
        if entity and entity.valid then
            AbsorbItems(entity, id)
            AttemptCraft(entity, id)
        else
            storage.assemblerBuffers[id] = nil
        end
    end
end)

function AbsorbItems(entity, id)
    local hiddenChest = storage.assemblerBuffers[id]["chest"]
    local inventory = hiddenChest.get_inventory(defines.inventory.car_trunk)
    if inventory and inventory.valid and inventory.get_item_count() > 0 then
        for i=#inventory, 1, -1 do
            local stack = inventory[i]
            if stack and stack.valid and stack.valid_for_read then
                if (storage.assemblerBuffers[id]["bufferMax"][stack.name] or 0) > (storage.assemblerBuffers[id]["buffers"][stack.name] or 0) then 
                    local difference = (storage.assemblerBuffers[id]["bufferMax"][stack.name] or 0)
                    - (storage.assemblerBuffers[id]["buffers"][stack.name] or 0)
                    local actual = math.min(math.max(stack.count, 0), difference)
                    storage.assemblerBuffers[id]["buffers"][stack.name] = 
                        (storage.assemblerBuffers[id]["buffers"][stack.name] or 0) + actual
                    storage.assemblerBuffers[id]["quality"][stack.name] = 
                        (storage.assemblerBuffers[id]["quality"][stack.name] or 0) + (qualityLookup[stack.quality.name] * actual * 10)
                    stack.count = stack.count - actual
                end
            end
        end
    end
    ClearInserterHandsIfStuck(entity, id)
end

function ClearInserterHandsIfStuck(entity, id)
    for _, inserter in pairs(storage.assemblerBuffers[id]["inserters"]) do
        if inserter.valid and inserter.status == defines.entity_status.waiting_for_space_in_destination and inserter.drop_target and (inserter.drop_target == entity or inserter.drop_target == storage.assemblerBuffers[id]["chest"]) then
            local stack = inserter.held_stack
            if stack and stack.valid_for_read then
                storage.assemblerBuffers[id]["buffers"][stack.name] = (storage.assemblerBuffers[id]["buffers"][stack.name] or 0) + stack.count
                storage.assemblerBuffers[id]["quality"][stack.name] = (storage.assemblerBuffers[id]["quality"][stack.name] or 0) + qualityLookup[stack.quality.name] * 10 * stack.count
                stack.clear()
            end
        end
    end
end

function AttemptCraft(entity, id)

    local outputInv = entity.get_inventory(defines.inventory.crafter_output)
    if outputInv.get_item_count() > 0 then
        local chest = storage.assemblerBuffers[id]["chest"]
        local q = storage.assemblerBuffers[id]["averageQuality"]
        if q < 10 then q = 10 end
        if storage.assemblerBuffers[id]["RollRand"] then
            storage.assemblerBuffers[id]["RollRand"] = false
            storage.assemblerBuffers[id]["RandRoll"] = math.random() * 10
        end
        local foundStack = nil
        for i = 1, #outputInv do
            local stack = outputInv[i]
            if stack and stack.valid_for_read then
                foundStack = stack
            end
        end
        local insertQuality = ""
        if foundStack then
            
            local baseQuality = qualityLookup[foundStack.quality.name] - 1
            while true do
                if q - 10 >= 0 then
                    q = q - 10
                    baseQuality = math.min(baseQuality + 1, #(prototypes.quality) - 1)
                else
                    break
                end
            end
            
            insertQuality = qualityReverseLookup[math.min(baseQuality, #(prototypes.quality) - 1)]
            if q > 0 then
                if storage.assemblerBuffers[id]["RandRoll"] < q then
                    insertQuality = qualityReverseLookup[math.min(baseQuality + 1 , #(prototypes.quality) - 1)]
                end
            end
        end
        if insertQuality == "" then insertQuality = qualityReverseLookup[1] end
        for i = 1, #outputInv do
            local data = outputInv[i]       
            if data and data.valid_for_read then
                local inserted = chest.insert({name = data.name, quality = insertQuality, count = data.count})
                data.count = data.count - inserted
                if data.count > 0 then
                    return
                end
            end       
        end
    end

    if entity.is_crafting() then return end
    local recipe = entity.get_recipe()
    if not recipe then return end
    if storage.assemblerBuffers[id]["recipe"] ~= recipe.name then
        storage.assemblerBuffers[id]["recipe"] = recipe.name
        if storage.assemblerBuffers[id]["chest"] then
            local chest = storage.assemblerBuffers[id]["chest"]
            local trunk = chest.get_inventory(defines.inventory.car_trunk)
            local x = 0
            local ingredients = recipe.ingredients
            local qualities = prototypes.quality
            if ingredients and qualities then
                for i = 1, #ingredients do
                    if ingredients[i].type == "item" then
                        storage.assemblerBuffers[id]["bufferMax"][ingredients[i].name] = math.ceil(ingredients[i].amount * entity.crafting_speed * 2)
                        for q, _ in pairs(qualities) do
                            if q ~= "quality-unknown" then
                                x = x + 1
                                trunk.set_filter(x, {name = ingredients[i].name, quality = q})
                                local stack = trunk[x]
                                if stack.valid_for_read and not (stack.name == ingredients[i].name) then
                                    storage.assemblerBuffers[id]["buffers"][stack.name] = 
                                        (storage.assemblerBuffers[id]["buffers"][stack.name] or 0) + stack.count
                                    storage.assemblerBuffers[id]["quality"][stack.name] = 
                                        (storage.assemblerBuffers[id]["quality"][stack.name] or 0) + (qualityLookup[stack.quality.name] * stack.count * 10)
                                    stack.clear()
                                end
                            end
                        end
                    end
                end
                for _, data in pairs(recipe.products) do
                    if data.type == "item" then
                        
                        for q, _ in pairs(qualities) do
                            if q ~= "quality-unknown" then
                                x = x + 1
                                trunk.set_filter(x, {name = data.name, quality = q})
                                local stack = trunk[x]
                                if stack.valid_for_read and not (stack.name == data.name) then
                                    storage.assemblerBuffers[id]["buffers"][stack.name] = 
                                    (storage.assemblerBuffers[id]["buffers"][stack.name] or 0) + stack.count
                                    storage.assemblerBuffers[id]["quality"][stack.name] = 
                                    (storage.assemblerBuffers[id]["quality"][stack.name] or 0) + (qualityLookup[stack.quality.name] * stack.count * 10)
                                    stack.clear()
                                end
                            end
                        end
                    end
                end
                while x < #trunk do
                    
                    x = x + 1
                    trunk.set_filter(x, {name = "dummy-item"})
                    
                end
            end
        end
        for _, ingredient in pairs(recipe.ingredients) do
            storage.assemblerBuffers[id]["bufferMax"]["max " .. ingredient.name] = ingredient.amount * 5  / recipe.energy
        end
    end

    for _, ingredient in pairs(entity.get_recipe().ingredients) do
        if ingredient.type == "item" then
            if (storage.assemblerBuffers[id]["buffers"][ingredient.name] or 0) < ingredient.amount then return end
        end
    end
    ActuallyCraft(entity, id, recipe)
end

function ActuallyCraft(entity, id, recipe)
    local averageQuality = {}
    
    -- Keep track of global totals for a true weighted average
    local totalQualitySum = 0
    local totalItemCount = 0

    -- Cache references to clean up long lines
    local buffer_counts = storage.assemblerBuffers[id]["buffers"]
    local buffer_qualities = storage.assemblerBuffers[id]["quality"]

    for _, ingredient in pairs(recipe.ingredients) do
        if ingredient.type == "item" then
            local name = ingredient.name
            local amount = ingredient.amount

            -- 1. Get average quality of a single item of this type
            local single_item_avg = buffer_qualities[name] / buffer_counts[name]
            averageQuality[name] = single_item_avg

            -- 2. Calculate total quality being removed for this specific ingredient group
            local total_quality_removed = single_item_avg * amount

            -- 3. Update the running grand totals for the recipe average
            totalQualitySum = totalQualitySum + total_quality_removed
            totalItemCount = totalItemCount + amount

            -- 4. Deduct exactly what was used from the buffers
            buffer_qualities[name] = buffer_qualities[name] - total_quality_removed
            buffer_counts[name] = buffer_counts[name] - amount

            -- 5. Physically put items into the assembler
            entity.get_inventory(defines.inventory.crafter_input).insert({name = name, count = amount})
        end
    end


    -- Print individual item averages (matching your style)
    -- for key, value in pairs(averageQuality) do
    -- end

    -- -- Calculate the TRUE mathematical average of all inserted items combined
    local totalAverage = (totalItemCount > 0 and (totalQualitySum / totalItemCount)) or 10
    

    storage.assemblerBuffers[id]["averageQuality"] = totalAverage
    storage.assemblerBuffers[id]["RollRand"] = true
end


function GetInsertersPointingAtMe(entity, id)
    if entity and entity.valid then
        local surface = entity.surface
        -- Find all inserters in the vicinity
        local nearby_inserters = surface.find_entities_filtered{
            position = entity.position,
            radius = 10,
            type = "inserter",
        }
        for _, inserter in pairs(nearby_inserters) do
            local targets = surface.find_entities_filtered{
                position = inserter.drop_position
            }
            for _, target in pairs(targets) do
                if target == entity then
                    storage.assemblerBuffers[id]["inserters"][inserter.unit_number] = inserter
                end
            end
        end
    end
end



script.on_nth_tick(1800, function ()
    for _, surface in pairs(game.surfaces) do
        for machine, _ in pairs(qualityMixNMatchCopies) do
            local assemblers = surface.find_entities_filtered({name = machine})
            if assemblers then
                for _, assembler in pairs(assemblers) do
                    local id = assembler.unit_number
                    local inserters = surface.find_entities_filtered({type = "inserter", position = assembler.position, radius = 5})
                    if inserters then
                        for _, inserter in pairs(inserters) do
                            local target = inserter.drop_position
                            if target then 
                                local dropCandidates = surface.find_entities_filtered({position = target})
                                if dropCandidates then
                                    
                                    for _, test in pairs(dropCandidates) do
                                        if test.name == "mix-n-matcher-assembler" then
                                            local addInserter = storage.assemblerBuffers[id]["inserters"][inserter.unit_number]
                                            if not addInserter then
                                                storage.assemblerBuffers[id]["inserters"][inserter.unit_number] = inserter
                                            end
                                        end
                                    end
                                else
                                    local dropInserter = storage.assemblerBuffers[id]["inserters"][inserter.unit_number]
                                    if dropInserter then
                                        storage.assemblerBuffers[id]["inserters"][inserter.unit_number] = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)