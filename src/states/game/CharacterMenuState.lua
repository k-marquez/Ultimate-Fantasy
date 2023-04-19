--[[
    ISPPJ1 2023
    Study Case: Ultimate Fantasy (RPG)

    Author: Lewis Ochoa (lewis8a@gmail.com)
    Modified by: Kevin Márquez (marquezberriosk@gmail.com)
    
    This class contains the class CharacterMenuState.
]]
CharacterMenuState = Class{__includes = BaseState}

function CharacterMenuState:init(characters,i)
    self.classType = 'CharacterMenuState'
    self.entity = characters[i]
    local menuItems = {}

    for k, a in pairs(self.entity.actions) do
        if a.name == 'Attack' or a.name == 'Arrows' or a.name == 'Flame' then
            table.insert(menuItems, {
                text = a.name,
                onSelect = function()
                    stateStack:pop()
                end
            })
        else
            table.insert(menuItems, {
                text = a.name,
                onSelect = function()
                    SOUNDS[a.sound_effect]:stop()
                    local targets = characters

                    if a.require_target then
                        -- Select target on targets with a
                        stateStack:push(SelectTargetState("Menu", targets,
                        -- callback for when a target has been selected
                        function(selectedTarget)
                            local amount = a.func(self.entity, selectedTarget, a.strength)
                            SOUNDS[a.sound_effect]:play()
                            stateStack:push(BattleMessageState("Menu", a.name .. ' for ' .. amount .. ' HP to ' .. selectedTarget.name .. '.',
                            function()               
                                stateStack:pop()
                            end))
                        end))
                    else
                        -- Apply action on targets
                        local amount = a.func(self.entity, targets, a.strength)
                        SOUNDS[a.sound_effect]:play()
                        stateStack:push(BattleMessageState("Menu", a.name .. ' for ' .. amount .. ' HP to each target.',
                        function()
                            stateStack:pop()
                        end))
                    end
                end
            })
        end
    end

    table.insert(menuItems, {
        text = 'Nothing',
        onSelect = function()
            stateStack:pop()
        end
    })

    self.c = characters
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
    if "Rinoa" == self.c[4].name then
        space1 = "\t "
    else
        space1 = ""
    end
    if "Tifa" == self.c[3].name then
        space2 = "\t"
    else
        space2 = ""
    end
    if "Celes" == self.c[1].name then
        space3 = " "
    else
        space3 = ""
    end
    h = 34
    if self.c[1].currentHP > 0 then
        character1 = current1..self.c[1].name..'\t\t'..space3..self.c[1].currentHP..' / '..self.c[1].HP..'\t'..self.c[1].level..'\t\t'..self.c[1].currentExp..'\t\t'..self.c[1].attack..'\t\t'..self.c[1].defense..'\t\t'..self.c[1].magic..'\n'
    else
        character1 = ""
        h = 52
    end
    if self.c[2].currentHP > 0 then
        character2 = current2..self.c[2].name..'\t     '..self.c[2].currentHP..' / '..self.c[2].HP..'\t'..self.c[2].level..'\t\t'..self.c[2].currentExp..'\t\t'..self.c[2].attack..'\t\t'..self.c[2].defense..'\t\t'..self.c[2].magic..'\n' 
    else
        character2 = ""
        h = 52
    end
    if self.c[3].currentHP > 0 then
        character3 = current3..self.c[3].name..'\t   '..space2..self.c[3].currentHP..' / '..self.c[3].HP..'\t'..self.c[3].level..'\t\t'..self.c[3].currentExp..'\t\t'..self.c[3].attack..'\t\t'..self.c[3].defense..'\t\t'..self.c[3].magic..'\n'
    else
        character3 = ""
    end
    if self.c[4].currentHP > 0 then
        character4 = current4..self.c[4].name..'\t'..space1..self.c[4].currentHP..' / '..self.c[4].HP..'\t'..self.c[4].level..'\t\t'..self.c[4].currentExp..'\t\t'..self.c[4].attack..'\t\t'..self.c[4].defense..'\t\t'..self.c[4].magic..'\n'
    else
        character4 = ""
    end
    if self.c[1].currentHP <= 0 and self.c[2].currentHP <= 0 then
        h = 68
    end
    self.battleInfo = Textbox(0, VIRTUAL_HEIGHT - 84, VIRTUAL_WIDTH, 84,'\t\t\t\t  HP\t\tLEVEL\tEXP\tATTACK\tDEFENSE\tMAGIC\n'..character1..character2, FONTS['small'])
    self.battleInfo2 = Textbox(0, VIRTUAL_HEIGHT - h, VIRTUAL_WIDTH, 84,character3..character4, FONTS['small'])
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

function CharacterMenuState:update(dt)
    self.actionMenu:update(dt)
end

function CharacterMenuState:render()
    self.battleInfo:render()
    self.battleInfo2:render()
    self.actionMenu:render()
end