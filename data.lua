
local quality_assembler_item = table.deepcopy(data.raw["item"]["assembling-machine-2"])
quality_assembler_item.name = "mix-n-matcher-assembler"
quality_assembler_item.place_result = "mix-n-matcher-assembler"
data:extend({quality_assembler_item})


local qualityAssembler = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
qualityAssembler.name = "mix-n-matcher-assembler"
qualityAssembler.crafting_speed = 1
-- qualityAssembler.selection_box = nil       -- Cannot be hovered over or clicked
qualityAssembler.minable.result = "mix-n-matcher-assembler"
data:extend({qualityAssembler})

local maxRecipe = 0
local maxOutputs = 0
for _, recipe in pairs(data.raw.recipe) do
    local ingredients = recipe.ingredients
    if ingredients then
        
        local count = 0
        for _, _ in pairs(ingredients) do
            count = count + 1
        end
        
        maxRecipe = math.max(maxRecipe, count)
    end
    local products = recipe.products
    if products then
        local count = 0
        for _, _ in pairs(products) do
            count = count + 1
        end
        
        maxOutputs = math.max(maxOutputs, count)
    end

end

local maxQuality = 0
for name, _ in pairs(data.raw.quality) do
    if name ~= "quality-unknown" then
        maxQuality = maxQuality + 1
    end
end

local hiddenChest = table.deepcopy(data.raw["car"]["car"])
hiddenChest.name = "mix-n-matcher-hidden-chest"
-- Strip out collision and selection properties
hiddenChest.collision_mask = {layers = {}} -- Empty layers = no collision with anything
hiddenChest.selection_box = {{-0.75,-0.75}, {0.75,0.75}}            -- Cannot be hovered over or clicked
hiddenChest.collision_box =  {{-0.75,-0.75}, {0.75,0.75}} 
hiddenChest.draw_copper_wires = false
hiddenChest.minable = nil
hiddenChest.inventory_size = (maxRecipe + maxOutputs) * (maxQuality) 
hiddenChest.flags = {"not-blueprintable", "not-deconstructable", "placeable-off-grid"}
hiddenChest.energy_source = {type="void"}
hiddenChest.consumption = "0W"
hiddenChest.braking_force = "0W"
hiddenChest.effectivity = 0
hiddenChest.guns = nil
hiddenChest.animation = nil
-- Make it completely invisible
hiddenChest.hidden = true
hiddenChest.picture = {
    filename = "__core__/graphics/blank.png",
    priority = "extra-high", 
    width = 1, 
    height = 1
}
data:extend({hiddenChest})


data:extend({{
    type = "item",
    name = "dummy-item",
    icon = "__base__/graphics/icons/coin.png", -- Uses a built-in invisible square
    icon_size = 64,
    stack_size = 100,                     -- Required by the engine to load
    
    -- Hides the item from the game GUI, production stats, and filters
    hidden = true,
}})
