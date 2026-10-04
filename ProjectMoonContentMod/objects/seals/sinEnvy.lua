SMODS.Seal {
    key = 'sinEnvy',
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 5, y = 4 },
    config = { extra = { odds = 4 } },
    badge_colour = G.C.RED,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            if pseudorandom('envy') < G.GAME.probabilities.normal / self.config.extra.odds then
                local rand = math.random(1, 3)
                if rand == 1 then
                    card.ability.perma_chips = (card.ability.perma_chips or 0) + 10
                    return { message = "+10 Chips", colour = G.C.CHIPS }
                elseif rand == 2 then
                    card.ability.perma_mult = (card.ability.perma_mult or 0) + 2
                    return { message = "+2 Mult", colour = G.C.MULT }
                else
                    card.ability.perma_p_dollars = (card.ability.perma_p_dollars or 0) + 1
                    return { message = "+$1", colour = G.C.GOLD }
                end
            end
        end
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME.probabilities.normal or 1), self.config.extra.odds } }
    end
}