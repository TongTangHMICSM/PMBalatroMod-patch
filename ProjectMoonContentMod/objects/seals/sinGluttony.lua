SMODS.Seal {
    key = 'sinGluttony',
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 3, y = 4 },
    config = { },
    badge_colour = G.C.RED,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            local bonus = math.random(1, 5)
            card.ability.perma_chips = (card.ability.perma_chips or 0) + bonus
            return {
                message = '+'..bonus..' Chips!',
                colour = G.C.CHIPS
            }
        end
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = {  } }
    end
}