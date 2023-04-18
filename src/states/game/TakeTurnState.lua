--[[
    ISPPJ1 2023
    Study Case: Ultimate Fantasy (RPG)

    Author: Alejandro Mujica
    aledrums@gmail.com

    Modified by: Kevin Márquez
    marquezberriosk@gmail.com

    Modified by: Lewis Ochoa
    lewis8a@gmail.com

    This class contains the class TakeTurnState.
]]
TakeTurnState = Class{__includes = BaseState}

function TakeTurnState:init(battleState)
    self.classType = 'TakeTurnState'
    self.battleState = battleState
    self.party = battleState.party
    self.characters = self.party.characters
    self.enemies = battleState.enemies
    self.enemyAttacksInARow = 0
    self.allEntitys = {}
    self.attackQueue = {}
    
    local k = 1
    for index, c in ipairs(self.characters) do
        if not c.dead then
            -- Timer.every(0.2,function()
            --     c:updateElapsedRestTime(0.2, self.battleState.restTimeBars[c.name])
            -- end)
            local ent = {entity = c, type = 'c', i = index}
            table.insert(self.attackQueue, ent)

        end
    end

    for index, e in ipairs(self.enemies) do
        -- Timer.every(0.2,function()
        --     e:updateElapsedRestTime(0.2,self.battleState.restTimeBars[e.name])
        -- end)
        local ent = {entity = e, type = 'e', i = index}
        table.insert(self.attackQueue, ent)
    end
end

function TakeTurnState:update(dt)
    print('Entidades')
    for index, register in ipairs(self.allEntitys) do
        print(index, register.entity.name, register.inQueue)
    end

    for k, e in pairs(self.enemies) do
        e:update(dt)
    end

    print("Registrando entidades en cola de ataque")
    for k = #self.allEntitys, 1, -1 do
        self.allEntitys[k].entity:updateElapsedRestTime(
            dt,
            self.battleState.restTimeBars[self.allEntitys[k].entity.name]
        )
        if self.allEntitys[k].entity.canAttack then
            self.allEntitys[k].entity.canAttack = false
            print(
                self.allEntitys[k].entity.elapsedRestTime,
                self.allEntitys[k].entity.name
            )
            table.insert(self.attackQueue, table.remove(self.allEntitys, k))
        end
    end

    if #self.attackQueue >= 1 then
        local attackEntity = table.remove(self.attackQueue, 1)
        print('Entidad atacante:', attackEntity.entity.name)
        if attackEntity.type == 'c' then
            self:takePartyTurn(attackEntity.i)
        else
            self:takeEnemyTurn(attackEntity.i)
        end
        print('Entidades en cola')
        for index, register in ipairs(self.attackQueue) do
            print(index, register.entity.name)
        end
        table.insert(self.allEntitys,attackEntity)
    end
end

function TakeTurnState:takePartyTurn(i)
    local c = self.characters[i]

    if i > #self.characters or c.dead then
        return
    end

    stateStack:push(SelectActionState(self.battleState, c,
    
    -- callback for when the action has been selected
    function()
        if self:checkAllDeath(self.enemies) then
            self:victory()
        end
    end))
end

function TakeTurnState:takeEnemyTurn(i)
    local e = self.enemies[i]

    if i > #self.enemies or e.dead then
        return
    end

    self.enemyAttacksInARow = self.enemyAttacksInARow + 1

    local message = ''

    -- choose a randoms action
    local action = e.actions[math.random(#e.actions)]

    local targets = action.target_type == 'enemy' and self.characters or self.enemies

    if action.require_target then
        local target_p = math.random(#targets)

        while targets[target_p].dead do
            target_p = math.random(#targets)
        end

        local target = targets[target_p]

        local amount = action.func(e, target)

        SOUNDS[action.sound_effect]:stop()
        SOUNDS[action.sound_effect]:play()

        Timer.tween(0.5, {
            [self.battleState.energyBars[target.name]] = {value = target.currentHP}
        })

        message = e.name .. ' used ' .. action.name .. ' for '.. amount .. ' HP on ' .. target.name .. '.'
    else
        local amount = action.func(e, targets)

        SOUNDS[action.sound_effect]:stop()
        SOUNDS[action.sound_effect]:play()

        local targetName = action.target_type == 'enemy' and 'you' or 'them'

        message = e.name .. ' used ' .. action.name .. ' for ' .. amount .. ' HP on all of ' .. targetName .. '.'
    end

    local gameOver = self:checkAllDeath(self.characters)

    if gameOver then
        self:faint()
    else
        stateStack:push(BattleMessageState(self.battleState, message,
            -- callback for when the battle message is closed
            function()
                -- chance to attack again
                if self.enemyAttacksInARow < 3 and e.type == 'boss' and math.random(3) == 1 then
                    self:takeEnemyTurn(i)
                else
                    self.enemyAttacksInARow = 0
                end
            end))
    end
end

function TakeTurnState:checkAllDeath(team)
    for k, e in pairs(team) do
        if not e.dead then
            return false
        end
    end
    return true
end

function TakeTurnState:faint()
    SOUNDS['battle']:stop()
    SOUNDS['game-over']:play()
    stateStack:push(FadeInState({
        r = 0, g = 0, b = 0
    }, 1,
    function()
        stateStack:push(GameOverState())
    end))
end

function TakeTurnState:incExp(i, opponentLevel)
    if i > #self.characters then
        self:fadeOut()
        return
    end

    local c = self.characters[i]

    if c.dead then
        self:incExp(i + 1, opponentLevel)
    else
        local exp = math.ceil((c.HPIV + c.attackIV + c.defenseIV + c.magicIV) * opponentLevel)

        stateStack:push(BattleMessageState(self.battleState, c.name .. ' earned ' .. tostring(exp) .. ' experience points!',
        function() end, false))

        Timer.after(1.5, function()
            SOUNDS['exp']:play()

            -- animate the exp filling up
            Timer.tween(0.5, {
                [self.battleState.expBars[c.name]] = {value = math.min(c.currentExp + exp, c.expToLevel)}
            })
            :finish(function()
                
                -- pop exp message off
                stateStack:pop()

                c.currentExp = c.currentExp + exp

                -- level up if we've gone over the needed amount
                if c.currentExp >= c.expToLevel then
                    
                    SOUNDS['levelup']:play()

                    -- set our exp to whatever the overlap is
                    c.currentExp = c.currentExp - c.expToLevel
                    local lastLevel = c.level
                    local HPIncrease, attackIncrease, defenseIncrease, magicIncrease = c:levelUp()

                    Timer.tween(0.5, {
                        [self.battleState.energyBars[c.name]] = {value = c.currentHP - HPIncrease}
                    })

                    stateStack:push(BattleMessageState(self.battleState, 'Congratulations! ' .. c.name ..
                                                        ' advanced from level ' .. lastLevel .. ' level ' .. c.level .. '!',
                    function()
                        stateStack:push(StatsMenuState(c,
                            {
                                HPIncrease = HPIncrease,
                                attackIncrease = attackIncrease,
                                defenseIncrease = defenseIncrease,
                                magicIncrease = magicIncrease
                            },
                            function()
                                self:incExp(i + 1, opponentLevel)
                            end))
                    end))
                else
                    self:incExp(i + 1, opponentLevel)
                end
            end)
        end)

    end
end

function TakeTurnState:victory()
    -- play victory music
    SOUNDS['battle']:stop()

    SOUNDS['victory']:setLooping(true)
    SOUNDS['victory']:play()

    -- when finished, push a victory message
    stateStack:push(BattleMessageState(self.battleState, 'Victory!',
        function()
            local opponentLevel = 0

            for k, e in pairs(self.enemies) do
                opponentLevel = opponentLevel + e.level
            end
            self:incExp(1, opponentLevel/#self.characters)
        end)) 
end

function TakeTurnState:fadeOut()
    print("Antes del FadeInState y de eliminar")
    for index, state in ipairs(stateStack.states) do
        print(index,state.classType)
    end

    -- while true do
    --     if stateStack.states[#stateStack.states].classType ~= 'BattleState' then
    --         stateStack:pop()
    --     else
    --         break
    --     end
    -- end

    if self.battleState.finalBoss then

        SOUNDS['victory']:stop()

        stateStack:push(FadeInState({
            r = 0, g = 0, b = 0
        }, 3,
        function()
            SOUNDS['the-end']:play()

            stateStack:push(TheEndState())

            stateStack:push(FadeOutState({
                r = 0, g = 0, b = 0
            }, 1,
            function() end))
        end))
    else
        -- fade in
        stateStack:push(FadeInState({
            r = 255, g = 255, b = 255
        }, 1, 
        function()
            -- resume field music
            SOUNDS['victory']:stop()
            SOUNDS['world']:play()

            -- pop off the take turn state
            stateStack:pop() -- Si descomentó el while de arriba de esta función comente esta línea
            -- pop off the battle state
            stateStack:pop()
            print("Antes del FadeOutState")
            for index, state in ipairs(stateStack.states) do
                print(index,state.classType)
            end
            stateStack:push(FadeOutState({
                r = 255, g = 255, b = 255
            }, 1, function()
                print("Despues del FadeOutState")
                for index, state in ipairs(stateStack.states) do
                    print(index,state.classType)
                end
            end))
        end))
    end
end