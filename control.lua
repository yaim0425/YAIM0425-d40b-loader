---------------------------------------------------------------------------------------------------
---> control.lua <---
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

    -- Agregar la acción a los eventos
    script.on_event(defines.events.on_built_entity, ThisMOD.onBuiltEntity, ThisMOD.Filter)
    script.on_event(defines.events.on_robot_built_entity, ThisMOD.onBuiltEntity, ThisMOD.Filter)
end

--- Valores de la referencia
function ThisMOD.setSetting()
    --- Direcciones con las que funciona
    ThisMOD.Opposite = {
        [defines.direction.north] = defines.direction.south,
        [defines.direction.south] = defines.direction.north,
        [defines.direction.east]  = defines.direction.west,
        [defines.direction.west]  = defines.direction.east,
    }

    --- Filtrar los cargadores
    ThisMOD.Filter = { { filter = "type", type = "loader-1x1" } }
end

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

--- Sumar dos vectores
function ThisMOD.AddVectors(v1, v2)
    return { v1.x + v2.x, v1.y + v2.y }
end

--- Devuelve todas las entidades situadas a
--- 1 baldosa en la dirección especificada
function ThisMOD.getNeighbourEntities(entity, direction)
    local dir2vector = {
        [defines.direction.north] = { x = 0, y = -1 },
        [defines.direction.south] = { x = 0, y = 1 },
        [defines.direction.east]  = { x = 1, y = 0 },
        [defines.direction.west]  = { x = -1, y = 0 },
    }

    local Table = { position = ThisMOD.AddVectors(entity.position, dir2vector[direction]) }
    return entity.surface.find_entities_filtered(Table)
end

--- La entidad tiene un inventario
--- @param entities table # Entidad a evaluar
--- @return boolean
function ThisMOD.hasInventory(entities)
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
function ThisMOD.isDirection(entities, direction)
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
function ThisMOD.onBuiltEntity(event)
    --- Renombrar la entidad a construir
    local Built = event.entity

    --- ¿Construcción inválida? no te molestes con la falsa propiedad "revived" de los
    --- Nanobots/Bluebuild anteriores a la versión 1.0, ahora esas travesuras sólo pueden pasar en eventos script_raised_*.
    --- Tampoco es necesario comprobar el tipo de entidad ya que podemos filtrarlo en el manejador de eventos
    if not Built or not Built.valid then return end

    --- Obtener las entidades de ambos extremos
    local belt = ThisMOD.getNeighbourEntities(Built, Built.direction)                      -- Front [ > ]
    local loading = ThisMOD.getNeighbourEntities(Built, ThisMOD.Opposite[Built.direction]) -- Back  [ = ]

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
    if ThisMOD.isDirection(belt, ThisMOD.Opposite[Built.direction]) then
        Built.rotate()
        return
    end

    --- Inicio:  >  [ => ]     Resultado:  >  [ >= ]
    --- Inicio: =>  [ => ]     Resultado: =>  [ >= ]
    if ThisMOD.isDirection(loading, Built.direction) then
        Built.direction = ThisMOD.Opposite[Built.direction]
        Built.rotate()
        return
    end

    --- Inicio:  <  [ => ]     Resultado:  <  [ <= ]
    if ThisMOD.isDirection(loading, ThisMOD.Opposite[Built.direction]) then
        Built.direction = ThisMOD.Opposite[Built.direction]
        return
    end

    --- Inicio:  X  [ <= ]     Resultado:  X  [ =< ]
    if ThisMOD.hasInventory(belt) then
        if not ThisMOD.isDirection(loading, Built.direction) then
            Built.direction = ThisMOD.Opposite[Built.direction]
            Built.rotate()
        end
        return
    end

    --- Inicio:  X  [ => ]     Resultado:  X  [ => ]
    if ThisMOD.hasInventory(loading) then
        return
    end
end

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
ThisMOD.Start()

---------------------------------------------------------------------------------------------------
