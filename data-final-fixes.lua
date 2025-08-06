---------------------------------------------------------------------------------------------------
---> data-final-fixes.lua <---
---------------------------------------------------------------------------------------------------

--- Contenedor de funciones y datos usados
--- unicamente en este archivo
local This_MOD = {}

---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
function This_MOD.Start()
    --- Valores de la referencia
    This_MOD.setSetting()

    --- Entidades a afectar
    This_MOD.BuildTiers()

    --- Crear el subgrupo para los cargadores
    local subgroup = GPrefix.items[This_MOD.oldSubgroup].subgroup
    GPrefix.duplicate_subgroup(subgroup, This_MOD.newSubgroup)

    --- Crear las todo
    for _, Tier in pairs(This_MOD.Tiers) do
        This_MOD.CreateRecipe(Tier)
        This_MOD.CreateItem(Tier)
        This_MOD.CreateEntity(Tier)
    end
end

--- Valores de la referencia
function This_MOD.setSetting()
    --- Otros valores
    This_MOD.Prefix      = "zzzYAIM0425-5000-"
    This_MOD.name        = "loader"

    --- Referencias
    This_MOD.newSubgroup = This_MOD.Prefix .. This_MOD.name
    This_MOD.oldSubgroup = "splitter"

    This_MOD.Under       = "underground-belt"
    This_MOD.Loader      = data.raw["loader-1x1"]["loader-1x1"]

    --- Contenedor de datos
    This_MOD.Tiers       = {
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
    local Icons         = "__" .. This_MOD.Prefix .. This_MOD.name .. "__/graphics/icons/"
    local Entity        = "__" .. This_MOD.Prefix .. This_MOD.name .. "__/graphics/entities/"

    --- Inicializar la variable
    This_MOD.Graphics    = {
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
function This_MOD.BuildTiers()
    local toFind = string.gsub(This_MOD.Under, "%-", "%%-")
    for _, Entity in pairs(data.raw[This_MOD.Under]) do
        --- Validación
        if Entity.hidden then goto JumpEntity end
        if not Entity.minable then goto JumpEntity end
        if not Entity.minable.results then goto JumpEntity end

        --- Eliminar los indicadores
        local tier = GPrefix.delete_prefix(Entity.name)
        tier = string.gsub(tier, "^[0-9%-]+", "")
        tier = string.gsub(tier, toFind, "")
        if not This_MOD.Tiers[tier] then goto JumpEntity end

        --- Crear el espacio para la entidad
        local Space         = This_MOD.Tiers[tier] or {}
        This_MOD.Tiers[tier] = Space

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
    for key, Tier in pairs(This_MOD.Tiers) do
        if not Tier.name then
            This_MOD.Tiers[key] = nil
        end
    end
end

--- Crear las recetas
function This_MOD.CreateRecipe(tier)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Cópiar los valores de la receta de referencia
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local recipe                 = util.copy(tier.recipe)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores variables
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Sobre escribir los valores constantes
    recipe.subgroup              = This_MOD.newSubgroup

    --- Nombre, apodo y descripción
    local toFind                 = string.gsub(This_MOD.Under, "%-", "%%-")
    recipe.name                  = This_MOD.Prefix .. GPrefix.delete_prefix(tier.item.name)
    recipe.name                  = string.gsub(recipe.name, toFind, This_MOD.name)

    local localised_name         = { "entity-name." .. This_MOD.Prefix .. tier.name .. This_MOD.name }
    recipe.localised_name        = { "", localised_name }

    local localised_description  = { "entity-description." .. This_MOD.Prefix .. This_MOD.name }
    recipe.localised_description = { "", localised_description }

    --- Remplazar el resultado principal
    local result                 = GPrefix.get_table(recipe.results, "name", tier.item.name)
    result.name                  = recipe.name

    --- Remplazar los ingredientes
    toFind                       = string.gsub(This_MOD.Under, "%-", "%%-")
    for _, ingredient in pairs(recipe.ingredients) do
        if string.find(ingredient.name, toFind) then
            local name = GPrefix.delete_prefix(ingredient.name)
            name = string.gsub(name, "^[0-9%-]+", "")
            name = string.gsub(name, toFind, "")
            if This_MOD.Tiers[name] then
                ingredient.name = string.gsub(ingredient.name, toFind, This_MOD.name)
                ingredient.name = This_MOD.Prefix .. GPrefix.delete_prefix(ingredient.name)
            end
        end
    end

    --- Imagen de la receta
    recipe.icons = {
        { icon = This_MOD.Graphics.Icon.Base },
        { icon = This_MOD.Graphics.Icon.Mask, tint = tier.color },
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
function This_MOD.CreateItem(tier)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Cópiar los valores del objeto de referencia
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local item                  = GPrefix.duplicate_item(tier.item)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores variables
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Sobre escribir los valores constantes
    item.subgroup               = This_MOD.newSubgroup

    --- Nombre, apodo y descripción
    item.name                   = This_MOD.Prefix .. GPrefix.delete_prefix(tier.item.name)
    local toFind                = string.gsub(This_MOD.Under, "%-", "%%-")
    item.name                   = string.gsub(item.name, toFind, This_MOD.name)

    local localised_name        = { "entity-name." .. This_MOD.Prefix .. tier.name .. This_MOD.name }
    item.localised_name         = { "", localised_name }

    local localised_description = { "entity-description." .. This_MOD.Prefix .. This_MOD.name }
    item.localised_description  = { "", localised_description }

    item.place_result           = item.name
    item.icons                  = {
        { icon = This_MOD.Graphics.Icon.Base },
        { icon = This_MOD.Graphics.Icon.Mask, tint = tier.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Ordernar y crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear el prototipo
    GPrefix.addDataRaw({ item })
end

--- Crear la entidad a usa
function This_MOD.CreateEntity(tier)
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
    entity.fast_replaceable_group = This_MOD.Prefix .. fast_replaceable_group

    entity.filter_count           = 5
    entity.container_distance     = 1

    entity.structure              = {
        back_patch = {
            sheet = {
                filename = This_MOD.Graphics.Entity.Back,
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
                    filename = This_MOD.Graphics.Entity.Shadow,
                    priority = "medium",
                    shift = { 0.5, 0 },
                    height = 96,
                    width = 144,
                    scale = 0.5
                },
                {
                    filename = This_MOD.Graphics.Entity.Base,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5
                },
                {
                    filename = This_MOD.Graphics.Entity.Mask,
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
                    filename = This_MOD.Graphics.Entity.Shadow,
                    priority = "medium",
                    shift = { 0.5, 0 },
                    height = 96,
                    width = 144,
                    scale = 0.5,
                },
                {
                    filename = This_MOD.Graphics.Entity.Base,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5,
                    y = 96,
                },
                {
                    filename = This_MOD.Graphics.Entity.Mask,
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
        { icon = This_MOD.Graphics.Icon.Base },
        { icon = This_MOD.Graphics.Icon.Mask, tint = tier.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores variables
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    entity.name                   = This_MOD.Prefix .. GPrefix.delete_prefix(tier.entity.name)
    local toFind                  = string.gsub(This_MOD.Under, "%-", "%%-")
    entity.name                   = string.gsub(entity.name, toFind, This_MOD.name)

    local localised_name          = { "entity-name." .. This_MOD.Prefix .. tier.name .. This_MOD.name }
    entity.localised_name         = { "", localised_name }

    local localised_description   = { "entity-description." .. This_MOD.Prefix .. This_MOD.name }
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
        if This_MOD.Tiers[name] then
            local next_upgrade  = GPrefix.delete_prefix(entity.next_upgrade)
            next_upgrade        = string.gsub(next_upgrade, toFind, This_MOD.name)
            entity.next_upgrade = This_MOD.Prefix .. next_upgrade
        else
            entity.next_upgrade = nil
        end
    else
        entity.next_upgrade = nil
    end

    entity.icons                  = {
        { icon = This_MOD.Graphics.Icon.Base },
        { icon = This_MOD.Graphics.Icon.Mask, tint = tier.color },
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
This_MOD.Start()

---------------------------------------------------------------------------------------------------
