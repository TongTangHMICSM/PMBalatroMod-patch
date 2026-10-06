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
                -- Already edited: spread the Envy seal through the scored hand instead
                if card.edition then
                    if context.scoring_hand then
                        for _, other_card in ipairs(context.scoring_hand) do
                            if other_card ~= card and not other_card.seal then
                                other_card:set_seal("pmcmod_sinEnvy", nil, true)
                                G.E_MANAGER:add_event(Event({
                                    func = function()
                                        other_card:juice_up()
                                        return true
                                    end
                                }))
                            end
                        end
                    end
                    return {
                        message = localize('k_upgrade_ex'),
                        colour = G.C.RED
                    }
                end

                -- Not edited yet: hand out a random Edition (never Negative)
                local edition = SMODS.poll_edition {
                    key = 'sinEnvy',
                    guaranteed = true,
                    no_negative = true,
                    options = { 'e_foil', 'e_holo', 'e_polychrome', 'e_pmcmod_charge' }
                }
                if edition then
                    card:set_edition(edition, true)
                    return {
                        message = localize('k_upgrade_ex'),
                        colour = G.C.EDITION
                    }
                end
            end
        end
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = { (G.GAME.probabilities.normal or 1), self.config.extra.odds } }
    end
}
