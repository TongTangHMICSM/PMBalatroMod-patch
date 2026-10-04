SMODS.Seal {
    key = 'sinGloom',
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 2, y = 4 },
    config = {    },
    badge_colour = G.C.RED,
    calculate = function(self, card, context)
        if context.end_of_round and context.cardarea == G.hand then
            local blind_req = math.max(1, G.GAME.blind.chips)
            if G.GAME.chips > blind_req then
                local excess_ratio = (G.GAME.chips - blind_req) / blind_req
                local chip_gain = math.floor(excess_ratio / 0.10)
                if chip_gain > 0 then
                    card.ability.perma_chips = (card.ability.perma_chips or 0) + chip_gain
                    return {
                        message = '+'..chip_gain..' Chips!',
                        colour = G.C.CHIPS
                    }
                end
            end
        end
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = {  } }
    end
}