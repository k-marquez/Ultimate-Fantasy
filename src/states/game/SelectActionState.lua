--[[
    ISPPJ1 2023
    Study Case: Ultimate Fantasy (RPG)

    Author: Alejandro Mujica
    aledrums@gmail.com

    Modified by: Lewis Ochoa (lewis8a@gmail.com)
    
    This class contains the class SelectActionState.
]]
SelectActionState = Class{__includes = BaseState}

function SelectActionState:init(battleState, entity, onActionSelected)
    self.classType = 'SelectActionState'
    self.battleState = battleState
    self.entity = entity

    local menuItems = {}

    for k, a in pairs(self.entity.actions) do
        table.insert(menuItems, {
            text = a.name,
            onSelect = function()
                SOUNDS[a.sound_effect]:stop()
                local targets = a.target_type == 'enemy' and self.battleState.enemies or self.battleState.party.characters

                if a.require_target then
                    -- Select target on targets with a
                    stateStack:push(SelectTargetState(self.battleState, targets,
                    -- callback for when a target has been selected
                    function(selectedTarget)
                        local amount = a.func(self.entity, selectedTarget, a.strength)
                        SOUNDS[a.sound_effect]:play()
                        -- update energy bar
                        Timer.tween(0.5, {
                            [self.battleState.energyBars[selectedTarget.name]] = {value = selectedTarget.currentHP}
                        })     
                        stateStack:push(BattleMessageState(self.battleState, a.name .. ' for ' .. amount .. ' HP to ' .. selectedTarget.name .. '.',
                        function()               
                            stateStack:pop()
                            onActionSelected()
                        end))
                    end))
                else
                    -- Apply action on targets
                    local amount = a.func(self.entity, targets, a.strength)
                    SOUNDS[a.sound_effect]:play()

                    -- update energy bars
                    for k, e in pairs(targets) do
                        Timer.tween(0.5, {
                            [self.battleState.energyBars[e.name]] = {value = e.currentHP}
                        })
                    end
                    stateStack:push(BattleMessageState(self.battleState, a.name .. ' for ' .. amount .. ' HP to each target.',
                        function()
                            stateStack:pop()
                            onActionSelected()
                        end))
                end
            end
        })
    end

    table.insert(menuItems, {
        text = 'Nothing',
        onSelect = function()
            -- only pop select action menu
            stateStack:pop()
            onActionSelected()
        end
    })
    
    self.c = self.battleState.party.characters
    if self.entity.name == self.c[1].name then
        current1 = "-> "
    else
        current1 = "   "
    end
    if self.entity.name == self.c[2].name then
        current2 = "-> "
    else
        current2 = "   "
    end
    if self.entity.name == self.c[3].name then
        current3 = "-> "
    else
        current3 = "   "
    end
    if self.entity.name == self.c[4].name then
        current4 = "-> "
    else
        current4 = "   "
    end
    self.battleInfo = Textbox(0, VIRTUAL_HEIGHT - 84, VIRTUAL_WIDTH, 84,'\t\t\t\t  HP\t\tLEVEL\tEXP\tATTACK\tDEFENSE\tMAGIC\n'..current4..self.c[4].name..'\t'..self.c[4].currentHP..' / '..self.c[4].HP..'\t'..self.c[4].level..'\t\t'..self.c[4].currentExp..'\t\t'..self.c[4].attack..'\t\t'..self.c[4].defense..'\t\t'..self.c[4].magic..'\n'..current3..self.c[3].name..'\t   '..self.c[3].currentHP..' / '..self.c[3].HP..'\t'..self.c[3].level..'\t\t'..self.c[3].currentExp..'\t\t'..self.c[3].attack..'\t\t'..self.c[3].defense..'\t\t'..self.c[3].magic..'\n', FONTS['small'])
    self.battleInfo2 = Textbox(0, VIRTUAL_HEIGHT - 34, VIRTUAL_WIDTH, 84,current2..self.c[2].name..'\t     '..self.c[2].currentHP..' / '..self.c[2].HP..'\t'..self.c[2].level..'\t\t'..self.c[2].currentExp..'\t\t'..self.c[2].attack..'\t\t'..self.c[2].defense..'\t\t'..self.c[2].magic..'\n'..current1..self.c[1].name..'\t\t'..self.c[1].currentHP..' / '..self.c[1].HP..'\t'..self.c[1].level..'\t\t'..self.c[1].currentExp..'\t\t'..self.c[1].attack..'\t\t'..self.c[1].defense..'\t\t'..self.c[1].magic, FONTS['small'])
    self.battleInfo2:toggle()

    self.actionMenu = Menu {
        x = VIRTUAL_WIDTH - 84,
        y = VIRTUAL_HEIGHT - 84,
        width = 84,
        height = 84,
        items = menuItems,
        font = FONTS['small']
    }
end

function SelectActionState:update(dt)
    for k, e in pairs(self.battleState.enemies) do
        e:update(dt)
    end
    self.actionMenu:update(dt)
end

function SelectActionState:render()
    self.battleInfo:render()
    self.battleInfo2:render()
    self.actionMenu:render()
end