SMODS.Seal {
    key = 'sinGluttony',
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 3, y = 4 },
    config = { },
    badge_colour = G.C.RED,
    calculate = function(self, card, context)
        local slothCount = 0
        for _, playing_card in ipairs(G.playing_cards) do
            if playing_card.seal == "pmcmod_sinSloth" then slothCount = slothCount + 1 end
        end

        if (context.main_scoring and context.cardarea == G.play) or (context.individual and context.cardarea == G.hand) then
            local bonus = math.random(1, 5) + slothCount
            card.ability.perma_bonus = (card.ability.perma_bonus or 0) + bonus
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.CHIPS,
                card = card
            }
        end
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = {  } }
    end
}