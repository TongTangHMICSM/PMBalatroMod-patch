SMODS.Seal {
    key = 'sinLust',
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 1, y = 4 },
    config = {    },
    badge_colour = G.C.RED,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            local lustCount = 0
            for _, playing_card in ipairs(G.playing_cards) do
                if playing_card.seal == "pmcmod_sinLust" then lustCount = lustCount + 1 end
            end
            if lustCount > 0 then
                G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + lustCount
                G.E_MANAGER:add_event(Event({func = (function() G.GAME.dollar_buffer = 0; return true end)}))
                return {
                    dollars = lustCount,
                    message = localize('$')..lustCount,
                    colour = G.C.GOLD
                }
            end
        end
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = {  } }
    end
}