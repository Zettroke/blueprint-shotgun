if not mods["pyalternativeenergy"] then return end

-- In py contruction bots are unlocked at late py1, so it makes sense to fully upgrade BP shotgun at the start of py1
data.raw.technology["blueprint-shotgun-upgrade-2"].prerequisites[2] = "py-science-pack-1"
data.raw.technology["blueprint-shotgun-upgrade-2"].unit.ingredients[2] = {"py-science-pack-1", 1}

