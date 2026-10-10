SMODS.Consumable {
    key = 'conceptIncinerator',
    name = "Concept Incinerator",
    set = 'Spectral',
    pos = { x = 1, y = 5 },
    atlas = 'ModdedProjectMoonSpectrals',
    config = { max_highlighted = 1 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.max_highlighted } }
    end,
    use = function(self, card, area, copier)

        -- Keypages that came with a deck or sleeve are not erased; anything else is fair game,
        -- Eternal included. All seven are summon-only (in_pool = false), so the key identifies them.
        local deck_starters = {
            j_pmcmod_shylook = true,
            j_pmcmod_silence = true,
            j_pmcmod_censored = true,
            j_pmcmod_laetitia = true,
            j_pmcmod_voiceOfTheCity = true,
            j_pmcmod_queenOfHatred = true,
            j_pmcmod_childrenOfTheGalaxy = true,
        }

        local my_pos = nil
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i] == G.jokers.highlighted[1] then
                my_pos = i
                break
            end
        end

        for i = 0, my_pos-1 do
            local target = G.jokers.cards[my_pos-i]
            if target and not deck_starters[target.config.center.key] then
                G.GAME.banned_keys[target.config.center.key] = true
                G.E_MANAGER:add_event(Event({func = function()
                    target:start_dissolve({G.C.RED}, nil, 1.6)
                return true end }))
            end
        end
    end,
    can_use = function(self, card)
        return G.jokers and #G.jokers.highlighted <= card.ability.max_highlighted and #G.jokers.highlighted > 0
    end
}