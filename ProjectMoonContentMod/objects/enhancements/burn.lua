SMODS.Enhancement {
    key = "burn",
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 0, y = 2},
    config = { },
    loc_vars = function(self, info_queue, card)
        return { vars = { PMCMOD.burn_chips() } }
    end,
    calculate = function(self, card, context)
        -- Paid as chips rather than folded into the card's own chip value through ability.bonus, and
        -- with no use limit: a Burn Card never burns out. main_scoring is the context the other
        -- enhancements in this mod pay out on (bleed, poise, rupture, sinking); context.after was too
        -- late for a returned effect to reach the score, which is why this used ability.bonus.
        if context.main_scoring and context.cardarea == G.play then
            -- Tremor multiplies what Burn pays; with none on the board it is unchanged
            local tremor = math.max(1, PMCMOD.tremor_count())
            return { chips = PMCMOD.burn_chips() * tremor }
        end
    end,
}
