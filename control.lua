---------------------------------------------------------------------------------------------------
---> control.lua <---
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

    --- Cambiar la propiedad necesaria
    This_MOD.load_events()

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Valores de la referencia
function This_MOD.setting_mod()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Direcciones con las que funciona
    This_MOD.opposite = {
        [defines.direction.north] = defines.direction.south,
        [defines.direction.south] = defines.direction.north,
        [defines.direction.east]  = defines.direction.west,
        [defines.direction.west]  = defines.direction.east,
    }

    --- Filtrar los cargadores
    This_MOD.filter = { { filter = "type", type = "loader-1x1" } }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Cargar los eventos a ejecutar
function This_MOD.load_events()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    -- Agregar la acción a los eventos
    script.on_event(defines.events.on_built_entity, This_MOD.onBuiltEntity, This_MOD.filter)
    script.on_event(defines.events.on_robot_built_entity, This_MOD.onBuiltEntity, This_MOD.filter)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Sumar dos vectores
function This_MOD.AddVectors(v1, v2)
    return { v1.x + v2.x, v1.y + v2.y }
end

--- Devuelve todas las entidades situadas a
--- 1 baldosa en la dirección especificada
function This_MOD.getNeighbourEntities(entity, direction)
    local dir2vector = {
        [defines.direction.north] = { x = 0, y = -1 },
        [defines.direction.south] = { x = 0, y = 1 },
        [defines.direction.east]  = { x = 1, y = 0 },
        [defines.direction.west]  = { x = -1, y = 0 },
    }

    local Table = { position = This_MOD.AddVectors(entity.position, dir2vector[direction]) }
    return entity.surface.find_entities_filtered(Table)
end

--- La entidad tiene un inventario
--- @param entities table # Entidad a evaluar
--- @return boolean
function This_MOD.hasInventory(entities)
    for _, entity in pairs(entities) do
        if entity.get_inventory(defines.inventory.chest) or
            entity.get_inventory(defines.inventory.furnace_source) or
            entity.get_inventory(defines.inventory.assembling_machine_input) or
            entity.get_inventory(defines.inventory.lab_input) or
            entity.get_inventory(defines.inventory.rocket_silo_rocket)
        then
            return true
        end
    end
    return false
end

--- Detección de la cara del cinturón
--- @param entities table # Entidad a evaluar
--- @param direction table # Dirección esperada
--- @return boolean
function This_MOD.isDirection(entities, direction)
    for _, entity in pairs(entities) do
        local Flag = false
        Flag = Flag or entity.type == "splitter"
        Flag = Flag or entity.type == "loader-1x1"
        Flag = Flag or entity.type == "transport-belt"
        Flag = Flag or entity.type == "underground-belt"
        Flag = Flag and entity.direction == direction
        if Flag then return true end
    end
    return false
end

--- Receptor de los eventos a ejecutar
--- @param event table
function This_MOD.onBuiltEntity(event)
    --- Renombrar la entidad a construir
    local Built = event.entity

    --- ¿Construcción inválida? no te molestes con la falsa propiedad "revived" de los
    --- Nanobots/Bluebuild anteriores a la versión 1.0, ahora esas travesuras sólo pueden pasar en eventos script_raised_*.
    --- Tampoco es necesario comprobar el tipo de entidad ya que podemos filtrarlo en el manejador de eventos
    if not Built or not Built.valid then return end

    --- Obtener las entidades de ambos extremos
    local belt = This_MOD.getNeighbourEntities(Built, Built.direction)                      -- Front [ > ]
    local loading = This_MOD.getNeighbourEntities(Built, This_MOD.opposite[Built.direction]) -- Back  [ = ]

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Representación grafica
    ---    =   Lado del cargador
    ---    >   Cinta or Lado de la cita
    ---    X   Entidad con inventario
    --- [ <= ] Cargador a construir
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicio:  >  [ <= ]     Resultado:  >  [ >= ]
    --- Inicio: =>  [ <= ]     Resultado: =>  [ >= ]
    if This_MOD.isDirection(belt, This_MOD.opposite[Built.direction]) then
        Built.rotate()
        return
    end

    --- Inicio:  >  [ => ]     Resultado:  >  [ >= ]
    --- Inicio: =>  [ => ]     Resultado: =>  [ >= ]
    if This_MOD.isDirection(loading, Built.direction) then
        Built.direction = This_MOD.opposite[Built.direction]
        Built.rotate()
        return
    end

    --- Inicio:  <  [ => ]     Resultado:  <  [ <= ]
    if This_MOD.isDirection(loading, This_MOD.opposite[Built.direction]) then
        Built.direction = This_MOD.opposite[Built.direction]
        return
    end

    --- Inicio:  X  [ <= ]     Resultado:  X  [ =< ]
    if This_MOD.hasInventory(belt) then
        if not This_MOD.isDirection(loading, Built.direction) then
            Built.direction = This_MOD.opposite[Built.direction]
            Built.rotate()
        end
        return
    end

    --- Inicio:  X  [ => ]     Resultado:  X  [ => ]
    if This_MOD.hasInventory(loading) then
        return
    end
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
This_MOD.start()

---------------------------------------------------------------------------------------------------
