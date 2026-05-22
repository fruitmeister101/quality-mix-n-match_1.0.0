QualityMixNMatchCopies = {}

if mods["base"] then
    QualityMixNMatchCopies["assembling-machine-2"] = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
end
if mods["space-age"] then
    QualityMixNMatchCopies["foundry"] = table.deepcopy(data.raw["assembling-machine"]["foundry"])
    QualityMixNMatchCopies["electromagnetic-plant"] = table.deepcopy(data.raw["assembling-machine"]["electromagnetic-plant"])
    QualityMixNMatchCopies["biochamber"] = table.deepcopy(data.raw["assembling-machine"]["biochamber"])
    QualityMixNMatchCopies["cryogenic-plant"] = table.deepcopy(data.raw["assembling-machine"]["cryogenic-plant"])
end


for machine, _ in pairs(QualityMixNMatchCopies) do
    local quality_assembler_item = table.deepcopy(data.raw["item"][machine])
    quality_assembler_item.name = "mix-n-matcher-"..machine
    quality_assembler_item.place_result = "mix-n-matcher-"..machine
    data:extend({quality_assembler_item})
    local qualityAssembler = table.deepcopy(data.raw["assembling-machine"][machine])
    qualityAssembler.name = "mix-n-matcher-"..machine
    qualityAssembler.tint = {r = 0.7, g = 0.2, b = 0.9, a = 1.0} 
    qualityAssembler.minable.result = "mix-n-matcher-"..machine
    qualityAssembler.allow_inserter_to_pull_from_or_target = false
    qualityAssembler.collision_mask = {
        layers = {
            floor = true,
            object = true
        }
    }
    qualityAssembler.next_upgrade = nil
    qualityAssembler.dump_inventory_size = 0


    data:extend({qualityAssembler})
    local hiddenChest = table.deepcopy(data.raw["car"]["car"])
    hiddenChest.name = "mix-n-matcher-hidden-chest-"..machine
    data:extend({hiddenChest})
end