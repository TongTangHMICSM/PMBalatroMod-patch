SMODS.Enhancement {
    key = "sinking",
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 3, y = 2},
    config = { reduction = 0.05},
    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.triggersLeft}}
    end,
    calculate = function(self, card, context)

        -- Tremor reads the deck, not the hand: it amplifies while simply sitting there
        local tremorCounting = PMCMOD.tremor_count()

        if context.main_scoring and context.cardarea == G.play then
			G.E_MANAGER:add_event(Event({func = function()
				-- +1 percentage point per Tremor card, added to the card's own 5%
				local factor = card.ability.reduction + 0.01 * tremorCounting
				G.GAME.blind.chips = G.GAME.blind.chips - math.floor(G.GAME.blind.chips * factor)
				G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
				G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
				G.HUD_blind:recalculate() 
				G.hand_text_area.blind_chips:juice_up()
			return true end }))
		end

    end,
    update = function(self, card, dt)
        
    end
}