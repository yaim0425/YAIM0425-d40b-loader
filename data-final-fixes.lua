---------------------------------------------------------------------------------------------------
---> data-final-fixes.lua <---
---------------------------------------------------------------------------------------------------

--- Contenedor de funciones y datos usados
--- unicamente en este archivo
local ThisMOD = {}

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
function ThisMOD.Start()
    --- Valores de la referencia
    ThisMOD.setSetting()

    --- Entidades a afectar
    ThisMOD.BuildTiers()

    --- Crear el subgrupo para los cargadores
    local subgroup = GPrefix.items[ThisMOD.oldSubgroup].subgroup
    GPrefix.duplicate_subgroup(subgroup, ThisMOD.newSubgroup)

    --- Crear las todo
    for _, Tier in pairs(ThisMOD.Tiers) do
        ThisMOD.CreateRecipe(Tier)
        ThisMOD.CreateItem(Tier)
        ThisMOD.CreateEntity(Tier)
    end
end

--- Valores de la referencia
function ThisMOD.setSetting()
    --- Otros valores
    ThisMOD.Prefix      = "zzzYAIM0425-5000-"
    ThisMOD.name        = "loader"

    --- Referencias
    ThisMOD.newSubgroup = ThisMOD.Prefix .. ThisMOD.name
    ThisMOD.oldSubgroup = "splitter"

    ThisMOD.Under       = "underground-belt"
    ThisMOD.Loader      = data.raw["loader-1x1"]["loader-1x1"]

    --- Contenedor de datos
    ThisMOD.Tiers       = {
        [""]             = { color = { r = 210, g = 180, b = 080 } },
        ["fast-"]        = { color = { r = 210, g = 060, b = 060 } },
        ["express-"]     = { color = { r = 080, g = 180, b = 210 } },
        ["turbo-"]       = { color = { r = 160, g = 190, b = 080 } },

        ["basic-"]       = { color = { r = 185, g = 185, b = 185 } },
        ["supersonic-"]  = { color = { r = 213, g = 041, b = 209 } },

        ["kr-advanced-"] = { color = { r = 160, g = 190, b = 080 } },
        ["kr-superior-"] = { color = { r = 213, g = 041, b = 209 } },
    }

    --- Variables a usar
    local Icons         = "__" .. ThisMOD.Prefix .. ThisMOD.name .. "__/graphics/icons/"
    local Entity        = "__" .. ThisMOD.Prefix .. ThisMOD.name .. "__/graphics/entities/"

    --- Inicializar la variable
    ThisMOD.Graphics    = {
        Icon   = {
            Base = Icons .. "base.png",
            Mask = Icons .. "mask.png"
        },
        Entity = {
            Back   = Entity .. "back.png",
            Base   = Entity .. "base.png",
            Mask   = Entity .. "mask.png",
            Shadow = Entity .. "shadow.png"
        }
    }
end

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

--- Entidades a afectar
function ThisMOD.BuildTiers()
    local toFind = string.gsub(ThisMOD.Under, "%-", "%%-")
    for _, Entity in pairs(data.raw[ThisMOD.Under]) do
        --- Validación
        if Entity.hidden then goto JumpEntity end
        if not Entity.minable then goto JumpEntity end
        if not Entity.minable.results then goto JumpEntity end

        --- Eliminar los indicadores
        local tier = GPrefix.delete_prefix(Entity.name)
        tier = string.gsub(tier, "^[0-9%-]+", "")
        tier = string.gsub(tier, toFind, "")
        if not ThisMOD.Tiers[tier] then goto JumpEntity end

        --- Crear el espacio para la entidad
        local Space         = ThisMOD.Tiers[tier] or {}
        ThisMOD.Tiers[tier] = Space

        --- Guardar la información
        if Entity.minable and Entity.minable.results then
            for _, result in pairs(Entity.minable.results) do
                local item = GPrefix.items[result.name]
                if item and item.place_result then
                    if item.place_result == Entity.name then
                        Space.item = item
                        break
                    end
                end
            end
        end

        if not Space.item or not GPrefix.recipes[Space.item.name] then
            goto JumpEntity
        end

        Space.name       = tier
        Space.entity     = Entity
        Space.recipe     = GPrefix.recipes[Space.item.name][1]
        Space.technology = GPrefix.getTechnology(Space.recipe.name)

        if not Space.technology then
            local Default    = GPrefix.get_recipe_of_ingredient(Space.recipe)
            Space.technology = GPrefix.getTechnology(Default, true)
        end

        --- Receptor del salto
        :: JumpEntity ::
    end

    --- Niveles sin  entidades
    for key, Tier in pairs(ThisMOD.Tiers) do
        if not Tier.name then
            ThisMOD.Tiers[key] = nil
        end
    end
end

--- Crear las recetas
function ThisMOD.CreateRecipe(tier)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Cópiar los valores de la receta de referencia
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local recipe                 = util.copy(tier.recipe)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores variables
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Sobre escribir los valores constantes
    recipe.subgroup              = ThisMOD.newSubgroup

    --- Nombre, apodo y descripción
    local toFind                 = string.gsub(ThisMOD.Under, "%-", "%%-")
    recipe.name                  = ThisMOD.Prefix .. GPrefix.delete_prefix(tier.item.name)
    recipe.name                  = string.gsub(recipe.name, toFind, ThisMOD.name)

    local localised_name         = { "entity-name." .. ThisMOD.Prefix .. tier.name .. ThisMOD.name }
    recipe.localised_name        = { "", localised_name }

    local localised_description  = { "entity-description." .. ThisMOD.Prefix .. ThisMOD.name }
    recipe.localised_description = { "", localised_description }

    --- Remplazar el resultado principal
    local result                 = GPrefix.get_table(recipe.results, "name", tier.item.name)
    result.name                  = recipe.name

    --- Remplazar los ingredientes
    toFind                       = string.gsub(ThisMOD.Under, "%-", "%%-")
    for _, ingredient in pairs(recipe.ingredients) do
        if string.find(ingredient.name, toFind) then
            local name = GPrefix.delete_prefix(ingredient.name)
            name = string.gsub(name, "^[0-9%-]+", "")
            name = string.gsub(name, toFind, "")
            if ThisMOD.Tiers[name] then
                ingredient.name = string.gsub(ingredient.name, toFind, ThisMOD.name)
                ingredient.name = ThisMOD.Prefix .. GPrefix.delete_prefix(ingredient.name)
            end
        end
    end

    --- Imagen de la receta
    recipe.icons = {
        { icon = ThisMOD.Graphics.Icon.Base },
        { icon = ThisMOD.Graphics.Icon.Mask, tint = tier.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear el prototipo
    GPrefix.addDataRaw({ recipe })

    --- Agregar a la tecnología
    GPrefix.addRecipeToTechnology(nil, tier.recipe.name, recipe)
end

--- Crear el objeto
function ThisMOD.CreateItem(tier)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Cópiar los valores del objeto de referencia
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local item                  = GPrefix.duplicate_item(tier.item)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores variables
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Sobre escribir los valores constantes
    item.subgroup               = ThisMOD.newSubgroup

    --- Nombre, apodo y descripción
    item.name                   = ThisMOD.Prefix .. GPrefix.delete_prefix(tier.item.name)
    local toFind                = string.gsub(ThisMOD.Under, "%-", "%%-")
    item.name                   = string.gsub(item.name, toFind, ThisMOD.name)

    local localised_name        = { "entity-name." .. ThisMOD.Prefix .. tier.name .. ThisMOD.name }
    item.localised_name         = { "", localised_name }

    local localised_description = { "entity-description." .. ThisMOD.Prefix .. ThisMOD.name }
    item.localised_description  = { "", localised_description }

    item.place_result           = item.name
    item.icons                  = {
        { icon = ThisMOD.Graphics.Icon.Base },
        { icon = ThisMOD.Graphics.Icon.Mask, tint = tier.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Ordernar y crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear el prototipo
    GPrefix.addDataRaw({ item })
end

--- Crear la entidad a usa
function ThisMOD.CreateEntity(tier)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Cópiar los valores de la entidad de referencia
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local entity                  = util.copy(tier.entity)
    entity.hidden                 = nil

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores constantes
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    entity.type                   = "loader-1x1"

    local fast_replaceable_group  = entity.fast_replaceable_group
    fast_replaceable_group        = GPrefix.delete_prefix(fast_replaceable_group)
    entity.fast_replaceable_group = ThisMOD.Prefix .. fast_replaceable_group

    entity.filter_count           = 5
    entity.container_distance     = 1

    entity.structure              = {
        back_patch = {
            sheet = {
                filename = ThisMOD.Graphics.Entity.Back,
                priority = "extra-high",
                shift = { 0, 0 },
                height = 96,
                width = 96,
                scale = 0.5
            }
        },
        direction_in = {
            sheets = {
                {
                    draw_as_shadow = true,
                    filename = ThisMOD.Graphics.Entity.Shadow,
                    priority = "medium",
                    shift = { 0.5, 0 },
                    height = 96,
                    width = 144,
                    scale = 0.5
                },
                {
                    filename = ThisMOD.Graphics.Entity.Base,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5
                },
                {
                    filename = ThisMOD.Graphics.Entity.Mask,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5,
                    tint = tier.color
                }
            }
        },
        direction_out = {
            sheets = {
                {
                    draw_as_shadow = true,
                    filename = ThisMOD.Graphics.Entity.Shadow,
                    priority = "medium",
                    shift = { 0.5, 0 },
                    height = 96,
                    width = 144,
                    scale = 0.5,
                },
                {
                    filename = ThisMOD.Graphics.Entity.Base,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5,
                    y = 96,
                },
                {
                    filename = ThisMOD.Graphics.Entity.Mask,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5,
                    tint = tier.color,
                    y = 96
                }
            }
        }
    }

    entity.icons                  = {
        { icon = ThisMOD.Graphics.Icon.Base },
        { icon = ThisMOD.Graphics.Icon.Mask, tint = tier.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores variables
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    entity.name                   = ThisMOD.Prefix .. GPrefix.delete_prefix(tier.entity.name)
    local toFind                  = string.gsub(ThisMOD.Under, "%-", "%%-")
    entity.name                   = string.gsub(entity.name, toFind, ThisMOD.name)

    local localised_name          = { "entity-name." .. ThisMOD.Prefix .. tier.name .. ThisMOD.name }
    entity.localised_name         = { "", localised_name }

    local localised_description   = { "entity-description." .. ThisMOD.Prefix .. ThisMOD.name }
    entity.localised_description  = { "", localised_description }

    entity.minable                = {
        mining_time = 0.5,
        results = { {
            type = "item",
            name = entity.name,
            amount = 1
        } }
    }

    if entity.next_upgrade then
        local name = GPrefix.delete_prefix(entity.next_upgrade)
        name = string.gsub(name, "^[0-9%-]+", "")
        name = string.gsub(name, toFind, "")
        if ThisMOD.Tiers[name] then
            local next_upgrade  = GPrefix.delete_prefix(entity.next_upgrade)
            next_upgrade        = string.gsub(next_upgrade, toFind, ThisMOD.name)
            entity.next_upgrade = ThisMOD.Prefix .. next_upgrade
        else
            entity.next_upgrade = nil
        end
    else
        entity.next_upgrade = nil
    end

    entity.icons                  = {
        { icon = ThisMOD.Graphics.Icon.Base },
        { icon = ThisMOD.Graphics.Icon.Mask, tint = tier.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Ejemplo en la simulación
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    entity.factoriopedia_simulation = nil

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear el prototipo
    GPrefix.addDataRaw({ entity })
end

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
ThisMOD.Start()

---------------------------------------------------------------------------------------------------
