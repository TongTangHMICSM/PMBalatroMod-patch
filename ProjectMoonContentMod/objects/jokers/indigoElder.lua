SMODS.Joker {
	key = 'indigoElder',
	name = "Indigo Elder",
	pronouns = "he_him",
	config = { 
		extra = { 
			dollars = 2, chips = 10, mult = 5, xchips = 1, 
			dollars_mod = 1, chips_mod = 10, mult_mod = 3, xchips_mod = 0.2,
			lockedPosition = 0
		} 
	},
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 4,
	cost = 8,
	atlas = 'ModdedProjectMoon',
	pos = { x = 3, y = 8 },
	soul_pos = { x = 3, y = 9 },
	attributes = {'chips', 'mult', 'xchips', 'scaling', 'position', 'economy'},
	pools = {},

	loc_vars = function(self, info_queue, card)
		return { 
			vars = { 
				card.ability.extra.dollars, 
				card.ability.extra.chips, 
				card.ability.extra.mult, 
				card.ability.extra.xchips, 
				card.ability.extra.lockedPosition 
			} 
		}
	end,

	calculate = function(self, card, context)
		-- Reset position variable when in shop
		if G.shop then
			card.ability.extra.lockedPosition = 0
		end

		-- Lock position when setting blind
		if context.setting_blind and card.ability.extra.lockedPosition == 0 then
			local my_pos = 1
			for i, jkr in ipairs(G.jokers.cards) do
				if jkr == card then
					my_pos = i
					break
				end
			end
			card.ability.extra.lockedPosition = my_pos
		end

		-- Card Scoring Context: Position 4 (or Position 1 "All Effects") gives Mult per played card
		if context.individual and context.cardarea == G.play then
			if card.ability.extra.lockedPosition == 1 or card.ability.extra.lockedPosition == 4 then
				return {
					mult = card.ability.extra.mult,
					card = card
				}
			end
		end

		-- Joker Main Evaluation (Chips and XChips)
		if context.joker_main then
			local pos = card.ability.extra.lockedPosition
			local results = {}
			local trigger = false
			
			-- Position 3 or Position 1: Add Base Chips
			if pos == 3 or pos == 1 then
				results.chips = card.ability.extra.chips
				trigger = true
			end

			-- Position 5+ or Position 1: Add XChips
			if (pos >= 5 or pos == 1) and card.ability.extra.xchips > 1 then
				results.xchips = card.ability.extra.xchips
				trigger = true
			end

			if trigger then
				return results
			end
		end

		-- End of round scaling check
		if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
			local pos = card.ability.extra.lockedPosition

			-- Position 1: All effects active during play, but bonuses DO NOT increase
			if pos == 1 or pos == 0 then
				return
			end

			-- Upgrade EVERY OTHER position (skip the active one)
			if pos ~= 2 then card.ability.extra.dollars = card.ability.extra.dollars + card.ability.extra.dollars_mod end
			if pos ~= 3 then card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chips_mod end
			if pos ~= 4 then card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod end
			if pos < 5 then card.ability.extra.xchips = card.ability.extra.xchips + card.ability.extra.xchips_mod end

			return {
				message = localize('k_upgrade_ex'),
				colour = G.C.BLUE
			}
		end
	end,

	calc_dollar_bonus = function(self, card)
		local pos = card.ability.extra.lockedPosition
		if pos == 1 or pos == 2 then
			return card.ability.extra.dollars
		end
	end,

	set_badges = function(self, card, badges)
		badges[#badges+1] = create_badge(localize('pmcmod_badge_colorFixer'), HEX('243542'), HEX('35c5e6'), 1.2)
	end
}