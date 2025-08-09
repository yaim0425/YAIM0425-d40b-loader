---------------------------------------------------------------------------------------------------
---> data-final-fixes.lua <---
---------------------------------------------------------------------------------------------------

--- Contenedor de funciones y datos usados
--- unicamente en este archivo
local This_MOD = {}

---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
function This_MOD.start()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Obtener información desde el nombre de MOD
    GPrefix.split_name_folder(This_MOD)

    --- Valores de la referencia
    This_MOD.setting_mod()

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Entidades a afectar
    This_MOD.build_info()

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear las todo
    for _, Space in pairs(This_MOD.info) do
        This_MOD.create_recipe(Space)
        This_MOD.create_item(Space)
        This_MOD.create_entity(Space)
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Valores de la referencia
function This_MOD.setting_mod()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Valores de referencia
    This_MOD.ref = {}
    This_MOD.ref.under = "underground-belt"
    This_MOD.ref.loader = data.raw["loader-1x1"]["loader-1x1"]
    This_MOD.ref.subgroup = This_MOD.prefix .. This_MOD.name
    This_MOD.ref.to_find = string.gsub(This_MOD.ref.under, "%-", "%%-")

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear el subgroup
    GPrefix.duplicate_subgroup(
        GPrefix.items["splitter"].subgroup,
        This_MOD.ref.subgroup
    )

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicializar la variable
    local Graphics = "__" .. This_MOD.prefix .. This_MOD.name .. "__/graphics/"
    This_MOD.graphics = {
        icon = {
            base = Graphics .. "icon-base.png",
            mask = Graphics .. "icon-mask.png"
        },
        tech = {
            base = Graphics .. "tech-base.png",
            mask = Graphics .. "tech-mask.png"
        },
        entity = {
            base = Graphics .. "entity-base.png",
            mask = Graphics .. "entity-mask.png",
            back = Graphics .. "entity-back.png",
            shadow = Graphics .. "entity-shadow.png"
        }
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Contenedor de datos
    This_MOD.info = {
        [""]             = { color = { r = 210, g = 180, b = 080 } },
        ["fast-"]        = { color = { r = 210, g = 060, b = 060 } },
        ["express-"]     = { color = { r = 080, g = 180, b = 210 } },
        ["turbo-"]       = { color = { r = 160, g = 190, b = 080 } },

        ["basic-"]       = { color = { r = 185, g = 185, b = 185 } },
        ["supersonic-"]  = { color = { r = 213, g = 041, b = 209 } },

        ["kr-advanced-"] = { color = { r = 160, g = 190, b = 080 } },
        ["kr-superior-"] = { color = { r = 213, g = 041, b = 209 } },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Entidades a afectar
function This_MOD.build_info()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Recorrer las entidades
    for _, Entity in pairs(data.raw[This_MOD.ref.under]) do
        repeat
            --- Validación
            if Entity.hidden then break end

            --- Identificar el objeto
            local Item = GPrefix.get_item_create_entity(Entity)
            if not Item then break end
            if not GPrefix.recipes[Item.name] then break end

            --- Identificar el tier
            local Name = GPrefix.delete_prefix(Entity.name)
            Name = string.gsub(Name, "^[0-9%-]+", "")
            Name = string.gsub(Name, This_MOD.ref.to_find, "")
            if not This_MOD.info[Name] then break end

            --- Crear el espacio para la información
            local Space = This_MOD.info[Name] or {}
            This_MOD.info[Name] = Space

            --- Guardar la información
            Space.item = Item
            Space.name = Name
            Space.entity = Entity
            Space.recipe = GPrefix.recipes[Space.item.name][1]
            Space.tech = GPrefix.get_technology(Space.recipe)
        until true
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Niveles sin entidades
    for key, Tier in pairs(This_MOD.info) do
        if not Tier.name then
            This_MOD.info[key] = nil
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------

--- Crear las recetas
function This_MOD.create_recipe(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Cópiar los valores de la receta de referencia
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Recipe = util.copy(space.recipe)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores variables
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Sobre escribir los valores constantes
    Recipe.subgroup = This_MOD.ref.subgroup

    --- Nombre, apodo y descripción
    Recipe.name = This_MOD.prefix .. GPrefix.delete_prefix(space.item.name)
    Recipe.name = string.gsub(Recipe.name, This_MOD.ref.to_find, This_MOD.name)

    local localised_name = { "entity-name." .. This_MOD.prefix .. space.name .. This_MOD.name }
    Recipe.localised_name = { "", localised_name }

    local localised_description = { "entity-description." .. This_MOD.prefix .. This_MOD.name }
    Recipe.localised_description = { "", localised_description }

    --- Remplazar el resultado principal
    local result = GPrefix.get_table(Recipe.results, "name", space.item.name)
    result.name = Recipe.name

    --- Remplazar los ingredientes
    for _, ingredient in pairs(Recipe.ingredients) do
        if string.find(ingredient.name, This_MOD.ref.to_find) then
            local name = GPrefix.delete_prefix(ingredient.name)
            name = string.gsub(name, "^[0-9%-]+", "")
            name = string.gsub(name, This_MOD.ref.to_find, "")
            if This_MOD.info[name] then
                ingredient.name = string.gsub(ingredient.name, This_MOD.ref.to_find, This_MOD.name)
                ingredient.name = This_MOD.prefix .. GPrefix.delete_prefix(ingredient.name)
            end
        end
    end

    --- Imagen de la receta
    Recipe.icons = {
        { icon = This_MOD.graphics.icon.base },
        { icon = This_MOD.graphics.icon.mask, tint = space.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear la receta
    GPrefix.extend(Recipe)

    --- Agregar a la tecnología
    local Tech = GPrefix.create_tech(This_MOD.prefix, space.tech, Recipe)
    Tech.localised_description = { "entity-description." .. This_MOD.prefix .. "loader" }
    Tech.icons = {
        { icon = This_MOD.graphics.tech.base, icon_size = 128 },
        { icon = This_MOD.graphics.tech.mask, tint = space.color, icon_size = 128 },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Crear el objeto
function This_MOD.create_item(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Cópiar los valores del objeto de referencia
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Item = GPrefix.duplicate_item(space.item)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores variables
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Sobre escribir los valores constantes
    Item.subgroup = This_MOD.ref.subgroup

    --- Nombre, apodo y descripción
    Item.name = This_MOD.prefix .. GPrefix.delete_prefix(space.item.name)
    Item.name = string.gsub(Item.name, This_MOD.ref.to_find, This_MOD.name)

    local localised_name = { "entity-name." .. This_MOD.prefix .. space.name .. This_MOD.name }
    Item.localised_name = { "", localised_name }

    local localised_description = { "entity-description." .. This_MOD.prefix .. This_MOD.name }
    Item.localised_description = { "", localised_description }

    Item.place_result = Item.name

    Item.icons = {
        { icon = This_MOD.graphics.icon.base },
        { icon = This_MOD.graphics.icon.mask, tint = space.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Ordernar y crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear el prototipo
    GPrefix.extend(Item)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Crear la entidad a usa
function This_MOD.create_entity(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Cópiar los valores de la entidad de referencia
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Entity = util.copy(space.entity)
    Entity.hidden = nil

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores constantes
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    Entity.type = "loader-1x1"

    local fast_replaceable_group = Entity.fast_replaceable_group
    fast_replaceable_group = GPrefix.delete_prefix(fast_replaceable_group)
    Entity.fast_replaceable_group = This_MOD.prefix .. fast_replaceable_group

    Entity.filter_count = 5
    Entity.container_distance = 1

    Entity.structure = {
        back_patch = {
            sheet = {
                filename = This_MOD.graphics.entity.back,
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
                    filename = This_MOD.graphics.entity.shadow,
                    priority = "medium",
                    shift = { 0.5, 0 },
                    height = 96,
                    width = 144,
                    scale = 0.5
                },
                {
                    filename = This_MOD.graphics.entity.base,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5
                },
                {
                    filename = This_MOD.graphics.entity.mask,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5,
                    tint = space.color
                }
            }
        },
        direction_out = {
            sheets = {
                {
                    draw_as_shadow = true,
                    filename = This_MOD.graphics.entity.shadow,
                    priority = "medium",
                    shift = { 0.5, 0 },
                    height = 96,
                    width = 144,
                    scale = 0.5,
                },
                {
                    filename = This_MOD.graphics.entity.base,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5,
                    y = 96,
                },
                {
                    filename = This_MOD.graphics.entity.mask,
                    priority = "extra-high",
                    shift = { 0, 0 },
                    height = 96,
                    width = 96,
                    scale = 0.5,
                    tint = space.color,
                    y = 96
                }
            }
        }
    }

    Entity.icons = {
        { icon = This_MOD.graphics.icon.base },
        { icon = This_MOD.graphics.icon.mask, tint = space.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Sobre escribir los valores variables
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    Entity.name = This_MOD.prefix .. GPrefix.delete_prefix(space.entity.name)
    Entity.name = string.gsub(Entity.name, This_MOD.ref.to_find, This_MOD.name)

    local localised_name = { "entity-name." .. This_MOD.prefix .. space.name .. This_MOD.name }
    Entity.localised_name = { "", localised_name }

    local localised_description = { "entity-description." .. This_MOD.prefix .. This_MOD.name }
    Entity.localised_description = { "", localised_description }

    Entity.minable = {
        mining_time = 0.5,
        results = { {
            type = "item",
            name = Entity.name,
            amount = 1
        } }
    }

    if Entity.next_upgrade then
        local name = GPrefix.delete_prefix(Entity.next_upgrade)
        name = string.gsub(name, "^[0-9%-]+", "")
        name = string.gsub(name, This_MOD.ref.to_find, "")
        if This_MOD.info[name] then
            local next_upgrade = GPrefix.delete_prefix(Entity.next_upgrade)
            next_upgrade = string.gsub(next_upgrade, This_MOD.ref.to_find, This_MOD.name)
            Entity.next_upgrade = This_MOD.prefix .. next_upgrade
        else
            Entity.next_upgrade = nil
        end
    else
        Entity.next_upgrade = nil
    end

    Entity.icons = {
        { icon = This_MOD.graphics.icon.base },
        { icon = This_MOD.graphics.icon.mask, tint = space.color },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Ejemplo en la simulación
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    Entity.factoriopedia_simulation = nil

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear el prototipo
    GPrefix.extend(Entity)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
This_MOD.start()

---------------------------------------------------------------------------------------------------
