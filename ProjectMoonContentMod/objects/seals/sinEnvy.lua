SMODS.Seal {
    key = 'sinEnvy',
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 1, y = 4 },
    config = { extra = { odds = 4 } },
    badge_colour = G.C.RED,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            local slothCount = 0
            for _, playing_card in ipairs(G.playing_cards) do
                if playing_card.seal == "pmcmod_sinSloth" then slothCount = slothCount + 1 end
            end

            if pseudorandom('envy') < (G.GAME.probabilities.normal + slothCount) / self.config.extra.odds then
                local rand = math.random(1, 3)
                if rand == 1 then
                    card.ability.perma_bonus = (card.ability.perma_bonus or 0) + 10 + slothCount * 2
                    return { message = localize('k_upgrade_ex'), colour = G.C.CHIPS }
                elseif rand == 2 then
                    card.ability.perma_mult = (card.ability.perma_mult or 0) + 2 + slothCount
                    return { message = localize('k_upgrade_ex'), colour = G.C.MULT }
                else
                    card.ability.perma_p_dollars = (card.ability.perma_p_dollars or 0) + 1
                    return { message = localize('k_upgrade_ex'), colour = G.C.GOLD }
                end
            end
        end
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME.probabilities.normal or 1), self.config.extra.odds } }
    end
}