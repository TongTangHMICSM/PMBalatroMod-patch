SMODS.Joker {
	key = 'ren',
	no_pool_flag = 'ren_extinct',
	name = "Ren",
	pronouns = "he_him",
	config = { extra = { shiomiPresent = false, shiomiPos = nil, baseChance = 1, maxChance = 2,
		blade = 0 } },
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 2,
	cost = 6,
    atlas = 'ModdedProjectMoon2',
	pos = { x = 3, y = 6 },
	attributes = {'passive', 'chance', 'poise', 'position', 'scaling'},
    pools =
	{
		["Pinky"] = true,
 	},
	loc_vars = function(self, info_queue, card)
        local new_numerator, new_denominator = SMODS.get_probability_vars(card, card.ability.extra.baseChance, card.ability.extra.maxChance, 'ren')
        return {vars = { PMCMOD.pair_trigger_display(card), new_numerator, new_denominator, card.ability.extra.blade or 0 } }
	end,
	calculate = function(self, card, context)
		-- the pairing is locked in at the start of the Scene and held for it
		if context.setting_blind and not context.blueprint then
			card.ability.extra.shiomiPresent = PMCMOD.pair_linked(card)
			-- one step per encounter while linked
			if card.ability.extra.shiomiPresent then
				PMCMOD.add_pair_trigger(card, 1)
			end
		end
		if context.before then
			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i] == card then
					card.ability.extra.currentPosition = i
					break
				end
			end

			-- only the partner exactly on the correct side counts
			
		end

		if context.individual and context.cardarea == G.play then
			local gavePoise = false
			-- only plain cards are converted, never one that already carries an enhancement
			local plain = context.other_card.config and context.other_card.config.center
				and context.other_card.config.center.key == 'c_base'
			if not plain then
				-- already enhanced: nothing to give
			elseif card.ability.extra.shiomiPresent then
				context.other_card:set_ability("m_pmcmod_poise", nil, true)
				gavePoise = true
			else
				if SMODS.pseudorandom_probability(card, 'ren', card.ability.extra.baseChance, card.ability.extra.maxChance, 'ren') then
					context.other_card:set_ability("m_pmcmod_poise", nil, true)
					gavePoise = true
				end
			end

			-- every poise crit charges his Blade
			if context.other_card.poise_trigger and not context.blueprint then
				card.ability.extra.blade = (card.ability.extra.blade or 0)
					+ pseudorandom('pmcmod_moonlitBlade', 1, 3)
			end

			if PMCMOD.pair_triggers(card) >= 5 then
				
				card.getting_sliced = true
				G.E_MANAGER:add_event(Event({func = function()
					card:juice_up(0.8, 0.8)
					card:start_dissolve({G.C.RED}, nil, 1.6)
				return true end }))
			end

			-- An effect table is how a joker tells the engine it triggered: SMODS only fires the
			-- post_trigger context when the return is truthy (the patched eval_card tests
			-- `if jokers or triggered`, and the base Card:calculate_joker never sets that second
			-- return). {} keeps Ren silent while letting post_trigger fire - `return true` would
			-- be wrong, the patch rewrites it into { remove = true } and would destroy Ren.
			if gavePoise and not context.blueprint then return {} end
		end

		
    end,
	add_to_deck = function(self, card, from_debuff)
		-- obtainable once, like the mod's other unique Keypages
		if G.GAME then G.GAME.pool_flags.ren_extinct = true end
	end,
	update = function(self, card, dt)
		PMCMOD.update_use_button(card, (card.ability.extra.blade or 0) >= 20, 'pmcmod_ren_blade')
	end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_spiders'), HEX('121212'), HEX('d90000'), 1.2 )
 	end,
	get_weight = function(self, weight)
		local poise_card_tally = 0
		if G.GAME.blind then
			if G.playing_cards then
				for _, playing_card in ipairs(G.playing_cards) do
					if SMODS.has_enhancement(playing_card, 'm_pmcmod_poise') then poise_card_tally = poise_card_tally + 1 end
				end
			end
		end
    	return PMCMOD.bonus_weight(weight, poise_card_tally)
	end,
	check_for_unlock = function(self, args)
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_pmcmod_shiomiYoru" then
                if get_joker_win_sticker(v, true) >= 1 then
                    return true
                end
                break
            end
        end
    end
}