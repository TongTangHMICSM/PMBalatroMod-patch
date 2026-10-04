SMODS.Joker {
	key = 'alan',
	name = "Alan",
	pronouns = "he_him",
	config = { spotSelected = 0, target_id = nil, jokerName = "None", jokerSelectedFlag = false, jokerFailed = false, counter = 0 },
	unlocked = true,
	eternal_compat = false,
	perishable_compat = true,
	blueprint_compat = false,	
	rarity = 2,
	cost = 6,
	atlas = 'ModdedProjectMoon2',
	pos = { x = 5, y = 7 },
	attributes = {'edition', 'painted'},
	pools = {},

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.spotSelected, card.ability.jokerName, card.ability.counter } }
	end,

	calculate = function(self, card, context)

		local availableJokers = {}
		local possible_editions = {'e_foil', 'e_holo', 'e_polychrome', 'e_pmcmod_charge'}

		-- MID-RUN SAVE REPAIR: If flag is true but target_id is missing, reset it to try again next blind
		if card.ability.jokerSelectedFlag and not card.ability.target_id then
			card.ability.jokerSelectedFlag = false
			card.ability.jokerFailed = false
		end

		if context.setting_blind and #G.jokers.cards > 1 and not card.ability.jokerSelectedFlag and not context.blueprint then
			for i = 1, #G.jokers.cards do
				local jkr = G.jokers.cards[i]
				if jkr ~= card and not jkr.ability.eternal and not jkr.edition then
					availableJokers[#availableJokers + 1] = jkr
				end
			end

			if #availableJokers < 1 then
				G.E_MANAGER:add_event(Event({
					func = function()
						play_sound('tarot1')
						card.T.r = -0.2
						card:juice_up(0.3, 0.4)
						card.states.drag.is = true
						card.children.center.pinch.x = true

						G.E_MANAGER:add_event(Event({
							trigger = 'after',
							delay = 0.3,
							blockable = false,
							func = function()
								G.jokers:remove_card(card)
								card:remove()
								card = nil
								return true
							end
						}))
						return true
					end
				}))
				G.GAME.pool_flags.alan_extinct = true
				return {
					message = 'The job is done'
				}
			else
				local cardToSelect = pseudorandom_element(availableJokers, pseudoseed('alan'))

				card.ability.spotSelected = math.random(1, #G.jokers.cards)
				card.ability.target_id = cardToSelect.unique_val
				card.ability.jokerSelectedFlag = true
				card.ability.jokerFailed = false
				card.ability.jokerName = localize { type = 'name_text', set = "Joker", key = cardToSelect.config.center.key }
			end
		end

		if context.joker_main and card.ability.jokerSelectedFlag and not context.blueprint then
			local selectedJokerPos = nil
			local selectedJoker = nil

			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i].unique_val == card.ability.target_id then
					selectedJokerPos = i
					selectedJoker = G.jokers.cards[i]
					break
				end
			end

			-- Check if the targeted joker is in the correct assigned spot
			if selectedJoker and card.ability.spotSelected == selectedJokerPos then
				card.ability.counter = card.ability.counter + 1
				
				-- Fire the edition event if counter hits 5
				if card.ability.counter >= 5 then
					selectedJoker:set_edition(pseudorandom_element(possible_editions, pseudoseed('alan')), nil, true)
					card.ability.jokerSelectedFlag = false
					card.ability.target_id = nil
					card.ability.spotSelected = nil
					card.ability.counter = 0
					card.ability.jokerFailed = false
				else
					-- Show counter progress if under 5
					return {
						message = card.ability.counter .. '/5',
						colour = G.C.FILTER
					}
				end
			else
				card.ability.jokerFailed = true
			end
		end
	
		if context.end_of_round and context.game_over == false and context.main_eval and card.ability.jokerSelectedFlag and card.ability.jokerFailed and not context.blueprint then
			local joker_to_destroy = nil

			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i].unique_val == card.ability.target_id then
					joker_to_destroy = G.jokers.cards[i]
					break
				end
			end

			if joker_to_destroy and not (context.blueprint_card or self).getting_sliced then
				card.ability.jokerSelectedFlag = false
				card.ability.target_id = nil
				card.ability.spotSelected = nil
				card.ability.counter = 0
				card.ability.jokerFailed = false

				joker_to_destroy.getting_sliced = true
				G.E_MANAGER:add_event(Event({
					func = function()
						card:juice_up(0.8, 0.8)
						joker_to_destroy:start_dissolve({G.C.RED}, nil, 1.6)
						return true 
					end 
				}))
			end
		end
	end,

	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_spiders'), HEX('121212'), HEX('d90000'), 1.2 )
 	end,

	check_for_unlock = function(self, args)
		local targets = {
			j_pmcmod_valencina = false,
			j_pmcmod_rien = false,
			j_pmcmod_matthias = false,
			j_pmcmod_callisto = false,
			j_pmcmod_shiomiYoru = false
		}

		for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
			if targets[v.key] ~= nil and get_joker_win_sticker(v, true) >= 1 then
				targets[v.key] = true
			end
		end

		for _, unlocked in pairs(targets) do
			if not unlocked then return false end
		end

		return true
    end
}