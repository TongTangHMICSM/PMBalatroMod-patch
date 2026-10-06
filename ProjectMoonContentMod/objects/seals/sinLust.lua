SMODS.Seal {
    key = 'sinLust',
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 5, y = 4 },
    config = {    },
    badge_colour = G.C.RED,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            -- Flat payout (no longer scaled by Lust/Sloth seals in the deck)
            card.ability.perma_p_dollars = (card.ability.perma_p_dollars or 0) + 1

            -- Spreads itself to other cards in the scored hand.
            -- 1 in 2, improved by Sloth seals: (1 + Sloth) in (2 + Sloth)
            local slothCount = 0
            for _, playing_card in ipairs(G.playing_cards) do
                if playing_card.seal == "pmcmod_sinSloth" then slothCount = slothCount + 1 end
            end

            if context.scoring_hand and pseudorandom('lust') < (1 + slothCount) / (2 + slothCount) then
                for _, other_card in ipairs(context.scoring_hand) do
                    if other_card ~= card and not other_card.seal then
                        other_card:set_seal("pmcmod_sinLust", nil, true)
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
                colour = G.C.GOLD
            }
        end
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = {  } }
    end
}
