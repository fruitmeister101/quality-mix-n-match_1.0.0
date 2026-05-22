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




data:extend({{
    type = "item",
    name = "dummy-item",
    icon = "__base__/graphics/icons/coin.png", 
    icon_size = 64,
    stack_size = 1,                     
    
    -- Hides the item from the game GUI, production stats, and filters
    hidden = true,
}})

for machine, mdata in pairs(QualityMixNMatchCopies) do
    
    local hiddenChest = data.raw["car"]["mix-n-matcher-hidden-chest-"..machine]
    if hiddenChest then
        
        hiddenChest.collision_mask = {layers = {}} -- Empty layers = no collision with anything
        local selBox = mdata.selection_box
        local colBox = mdata.collision_box
        hiddenChest.selection_box = {{selBox[1][1] * 0.5,selBox[1][2] * 0.5},{selBox[2][1] * 0.5,selBox[2][2] * 0.5}}
        hiddenChest.collision_box = {{colBox[1][1] + 0.25,colBox[1][2] + 0.25},{colBox[2][1] - 0.25,colBox[2][2] - 0.25}}
        hiddenChest.draw_copper_wires = false
        hiddenChest.minable = nil
        hiddenChest.inventory_size = (maxRecipe + maxOutputs + 1) * (maxQuality) 
        hiddenChest.flags = {"not-blueprintable", "not-deconstructable", "placeable-off-grid"}
        hiddenChest.energy_source = {type="void"}
        hiddenChest.consumption = "0W"
        hiddenChest.braking_force = "0W"
        hiddenChest.effectivity = 0
        hiddenChest.guns = nil
        hiddenChest.animation = nil
        hiddenChest.turret_animation = nil
        -- Make it completely invisible
        hiddenChest.hidden = true
        hiddenChest.picture = {
            filename = "__core__/graphics/blank.png",
            priority = "extra-high", 
            width = 1, 
            height = 1
        }
    end
end