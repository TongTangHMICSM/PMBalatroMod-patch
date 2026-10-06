SMODS.Seal {
    key = 'sinGloom',
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 2, y = 4 },
    config = {    },
    badge_colour = G.C.RED,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            local encounter = G.GAME.blind and G.GAME.blind.chips or 0
            local score = G.GAME.chips or 0

            -- +1 Perma Chip for every 1% of the Encounter Score above the first 10%.
            -- An encounter of 0 (or less) would divide by nothing, so it pays out nothing.
            local chip_gain = encounter > 0 and (math.floor(score / encounter * 100) - 10) or 0
            if chip_gain > 0 then
                local slothCount = 0
                for _, playing_card in ipairs(G.playing_cards) do
                    if playing_card.seal == "pmcmod_sinSloth" then slothCount = slothCount + 1 end
                end

                chip_gain = chip_gain + slothCount * 5
                card.ability.perma_bonus = (card.ability.perma_bonus or 0) + chip_gain
                return {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.CHIPS
                }
            end
        end
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = {  } }
    end
}
