---------------------------------------------------------------------------------------------------
---> migrations.lua <---
---------------------------------------------------------------------------------------------------

--- Actualizar las recetas habilitadas
for _, Force in pairs( game.forces ) do
    for _, Technology in pairs( Force.technologies ) do
        for _, Effect in pairs( Technology.prototype.effects ) do
            if Effect.type == "unlock-recipe" then
                local Recipes = Force.recipes[ Effect.recipe ]
                Recipes.enabled = Technology.researched
            end
        end
    end
end

---------------------------------------------------------------------------------------------------
