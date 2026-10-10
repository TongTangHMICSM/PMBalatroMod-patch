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

        local my_pos = nil
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i] == G.jokers.highlighted[1] then
                my_pos = i
                break
            end
        end

        for i = 0, my_pos-1 do
            local target = G.jokers.cards[my_pos-i]
            -- Eternal Keypages are immune: that is what the sticker promises, and it covers every
            -- deck and sleeve starter (they are all granted with stickers = {"eternal"}). Same
            -- check SMODS.destroy_cards uses at src/utils.lua:3064.
            if target and not SMODS.is_eternal(target, { destroy_cards = true }) then
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