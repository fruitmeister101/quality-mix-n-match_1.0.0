QualityMixNMatchCopies = {}



if mods["base"] then
    QualityMixNMatchCopies["assembling-machine-2"] = {["machine"]=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"]), ["tech"]="automation-2"}
end
if mods["space-age"] then
    QualityMixNMatchCopies["foundry"] = {["machine"]=table.deepcopy(data.raw["assembling-machine"]["foundry"]), ["tech"]="foundry"}
    QualityMixNMatchCopies["electromagnetic-plant"] = {["machine"]=table.deepcopy(data.raw["assembling-machine"]["electromagnetic-plant"]), ["tech"]="electromagnetic-plant"}
    QualityMixNMatchCopies["biochamber"] = {["machine"]=table.deepcopy(data.raw["assembling-machine"]["biochamber"]), ["tech"]="biochamber"}
    QualityMixNMatchCopies["cryogenic-plant"] = {["machine"]=table.deepcopy(data.raw["assembling-machine"]["cryogenic-plant"]), ["tech"]="cryogenic-plant"}
end


for _, mdata in pairs(QualityMixNMatchCopies) do
    local machine = mdata["machine"].name
    local quality_assembler_item = table.deepcopy(data.raw["item"][machine])
    quality_assembler_item.name = "mix-n-matcher-"..machine
    quality_assembler_item.place_result = "mix-n-matcher-"..machine
    data:extend({quality_assembler_item})
    local qualityAssembler = table.deepcopy(data.raw["assembling-machine"][machine])
    qualityAssembler.name = "mix-n-matcher-"..machine
    -- qualityAssembler.tint = {r = 0.7, g = 0.2, b = 0.9, a = 1.0} 
    qualityAssembler.minable.result = "mix-n-matcher-"..machine
    qualityAssembler.allow_inserter_to_pull_from_or_target = false
    -- qualityAssembler.collision_mask = {
    --     layers = {
    --         floor = true,
    --         object = true
    --     }
    -- }
    qualityAssembler.flags = {
        "no-automated-item-removal",
        "no-automated-item-insertion"
    }
    qualityAssembler.next_upgrade = nil
    qualityAssembler.dump_inventory_size = 0


    data:extend({qualityAssembler})
    local hiddenChest = table.deepcopy(data.raw["car"]["car"])
    hiddenChest.name = "mix-n-matcher-hidden-chest-"..machine
    data:extend({hiddenChest})

    local machineRecipe = table.deepcopy(data.raw["recipe"][machine])
    machineRecipe.name = "mix-n-matcher-"..machine
    machineRecipe.results = {{type="item",name="mix-n-matcher-"..machine,amount=1}}
    data:extend({machineRecipe})

    local exchangeRecipe = {
        type= "recipe",
        name = "exchange-"..machine.."-for-quality-mix-n-matcher",
        ingredients = {{type="item",name=machine, amount = 1}},
        time = 0.1,
        results = {{type="item",name="mix-n-matcher-"..machine,amount=1}}
    }
    data:extend({exchangeRecipe})
    local exchangeRecipeBack = {
        type= "recipe",
        name = "exchange-quality-mix-n-matcher-for-"..machine,
        ingredients = {{type="item",name="mix-n-matcher-"..machine,amount=1}},
        time = 0.1,
        results = {{type="item",name=machine, amount = 1}},
    }
    data:extend({exchangeRecipeBack})

    local tech = data.raw["technology"][mdata["tech"]]
    local tech_icon = tech.icon
    local tech_icon_size = tech.icon_size
    local machine_tech = {
        type = "technology",
        name = "mix-n-matcher-"..machine,
        icon = tech_icon or "__base__/graphics/icons/coin.png",
        icon_size = tech_icon_size or 64,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "mix-n-matcher-"..machine -- Links directly to the recipe above
            },
            {
                type = "unlock-recipe",
                recipe = "exchange-"..machine.."-for-quality-mix-n-matcher"
            },
            {
                type = "unlock-recipe",
                recipe = "exchange-quality-mix-n-matcher-for-"..machine,
            },
        },
        prerequisites = {mdata["tech"], "quality-module"}, -- Automatically requires researching the vanilla machine first
        unit = {
            count = 100,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1}
            },
            time = 30
        }
    }
    data:extend({machine_tech})


end