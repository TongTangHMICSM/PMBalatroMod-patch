SMODS.Joker {
	key = 'shiomiYoru',
	no_pool_flag = 'shiomiYoru_extinct',
	name = "Shiomi Yoru",
	pronouns = "she_her",
	config = { extra = {renDeathCounter = 0, renPos = nil } },
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
    atlas = 'ModdedProjectMoon2',
	pos = { x = 8, y = 5 },
	attributes = {'passive', 'poise', 'chance', 'destroy_card', 'position'},
    pools =
	{
		["Pinky"] = true,
 	},
	loc_vars = function(self, info_queue, card)
        return {vars = { PMCMOD.pair_trigger_display(card) } }
	end,
	calculate = function(self, card, context)
		-- the pairing is locked in at the start of the Scene and held for it
		if context.setting_blind and not context.blueprint then
			card.ability.extra.renPresent = PMCMOD.pair_linked(card)
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

		if context.individual and context.cardarea == G.play and context.other_card.poise_trigger and card.ability.extra.renPresent then
					
			if not context.blueprint then PMCMOD.add_pair_trigger(card, 1) end
		
				if PMCMOD.pair_triggers(card) >= 5 then
					G.GAME.banned_keys["j_pmcmod_ren"] = true
					local ren = G.jokers.cards[card.ability.extra.renPos]
                    ren.getting_sliced = true
                    G.E_MANAGER:add_event(Event({func = function()
                        card:juice_up(0.8, 0.8)
                        ren:start_dissolve({G.C.RED}, nil, 1.6)
                    return true end }))
				end
		end
    end,
	add_to_deck = function(self, card, from_debuff)
		-- obtainable once, like the mod's other unique Keypages
		if G.GAME then G.GAME.pool_flags.shiomiYoru_extinct = true end
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
            if v.key == "j_flower_pot" then
                if get_joker_win_sticker(v, true) >= 8 then
                    return true
                end
                break
            end
        end
    end
}