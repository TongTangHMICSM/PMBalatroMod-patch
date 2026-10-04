SMODS.Joker {
	key = 'garnet',
	name = "Garnet",
	pronouns = "he_him",
	config = { selectedJoker = "None", extra = {} }, -- Removed availableJokers from config to prevent save bloat
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
	atlas = 'ModdedProjectMoon2',
	pos = { x = 3, y = 2 },
	attributes = {'random', 'copying'},
	pools = {
		["Thumb"] = true,
		["Index"] = true,
		["Middle"] = true,
		["Ring"] = true,
		["Pinky"] = true,
		["Bloodfiends"] = true,
		["LCorp"] = true,
		["Limbus"] = true,
		["Sinner"] = true,
	},

	loc_vars = function(self, info_queue, card)
		local keyToLocalize = "j_pmcmod_garnet"
		
		-- Safety check: Ensure the key is a string, isn't corrupted, and actually exists in the game database
		if type(card.ability.selectedJoker) == "string" 
		and card.ability.selectedJoker ~= "None" 
		and card.ability.selectedJoker ~= "MANUAL_REPLACE" 
		and G.P_CENTERS[card.ability.selectedJoker] then
			
			keyToLocalize = card.ability.selectedJoker
			card.children.center:set_sprite_pos({x = 0, y = 10})
			
			-- FIX: Pass the full Joker definition object so the UI generator has all the ability data
			info_queue[#info_queue+1] = G.P_CENTERS[card.ability.selectedJoker]
		else
			-- Fallback if the saved data is corrupted, empty, or missing
			card.children.center:set_sprite_pos(self.pos)
		end

		return { vars = { localize{type = "name_text", set = "Joker", key = keyToLocalize} } }
	end,
	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			local availableJokers = {}
			
			-- Collect string keys only, not full tables
			for i = 1, #G.P_CENTER_POOLS["Joker"] do
				local jkr = G.P_CENTER_POOLS["Joker"][i]
				if jkr.key ~= card.config.center.key and jkr.blueprint_compat and jkr.unlocked then
					availableJokers[#availableJokers + 1] = jkr.key
				end
			end

			-- Store only the string key
			card.ability.selectedJoker = #availableJokers > 0 and pseudorandom_element(availableJokers, pseudoseed('garnet')) or "None"

			if card.ability.selectedJoker ~= "None" then
				-- Dissolve the old card in the hidden area
				if ProjectMoonMod.garnetJoker and #ProjectMoonMod.garnetJoker.cards >= 1 then
					local old_card = ProjectMoonMod.garnetJoker.cards[1]
					G.E_MANAGER:add_event(Event({
						func = function()
							card:juice_up(0.8, 0.8)
							old_card:start_dissolve({G.C.RED}, nil, 1.6)
							return true 
						end 
					}))
				end

				-- Spawn the new card into the hidden area
				SMODS.add_card({ key = card.ability.selectedJoker, area = ProjectMoonMod.garnetJoker })
			end
		end

		-- Ensure the hidden area exists and has a card before trying to blueprint it
		if ProjectMoonMod.garnetJoker and #ProjectMoonMod.garnetJoker.cards >= 1 then
			local ret = SMODS.blueprint_effect(card, ProjectMoonMod.garnetJoker.cards[1], context)
			if ret then
				ret.colour = G.C.BLUE
				return ret
			end
		end
	end,

	set_badges = function(self, card, badges)
		badges[#badges+1] = create_badge(localize('pmcmod_badge_fixer'), G.C.BLACK, G.C.WHITE, 1.2)
	end,

	check_for_unlock = function(self, args)
		if args.type == 'discard_custom' then
			local eval = evaluate_poker_hand(args.cards)
			
			-- Changed from 'Flush House' to 'Straight Flush' for a true Royal Flush check
			if next(eval['Straight Flush']) then
				local min = 14 -- Start high, looking for the lowest card
				for j = 1, #args.cards do
					if args.cards[j]:get_id() < min then 
						min = args.cards[j]:get_id() 
					end
				end
				-- If the lowest card in a Straight Flush is 10, it's a Royal Flush
				if min == 10 then
					return true
				end
			end
		end
		return false
	end
}