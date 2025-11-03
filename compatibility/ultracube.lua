if not mods["Ultracube"] then return end
require("__Ultracube__/prototypes/lib/tech_costs")

local technologies = {
    ["blueprint-shotgun"] = "0",
    ["blueprint-shotgun-upgrade-1"] = "0",
    ["blueprint-shotgun-upgrade-2"] = "1a",
}

for tech, level in pairs(technologies) do
    local technology = data.raw.technology[tech]
    ---@diagnostic disable-next-line: undefined-global
    technology.unit = tech_cost_unit(level, technology.unit.count)
end

data.raw.technology["blueprint-shotgun"].prerequisites = {"cube-electronics"}
data.raw.technology["blueprint-shotgun-upgrade-2"].prerequisites[2] = "cube-fundamental-comprehension-card"

table.remove(data.raw.technology["blueprint-shotgun"].effects, 3)


local gun = data.raw.recipe["blueprint-shotgun"]
gun.subgroup = "cube-repair"
gun.ingredients = {
    {type = "item", name = "cube-ultradense-utility-cube", amount = 1},
    {type = "item", name = "cube-electronic-circuit", amount = 5},
    {type = "item", name = "cube-basic-motor-unit", amount = 10},
}
table.insert(gun.results, 1, {type = "item", name = "cube-ultradense-utility-cube", amount = 1})
gun.main_product = "blueprint-shotgun"

local canister = data.raw.recipe["item-canister"]
canister.subgroup = "cube-repair"
canister.ingredients = {
    {type = "item", name = "cube-basic-motor-unit", amount = 1},
    {type = "item", name = "cube-basic-matter-unit", amount = 4},
}