SMODS.Joker {
	key = 'kira',
	name = "Kira",
	pronouns = "she_her",
	config = { extra = { currentPosition = 1, kiraDeathCounter = 0, dollars = 4, matthiasPresent = false,
		triggerHand = -1, banned = false, matthiasPos = nil } },
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 2,
	cost = 6,
    atlas = 'ModdedProjectMoon2',
	pos = { x =1, y = 6 },
	attributes = {'economy', 'burn', 'position'},
    pools =
	{
		["Middle"] = true,
 	},
	loc_vars = function(self, info_queue, card)
        return {vars = { PMCMOD.pair_trigger_display(card), card.ability.extra.dollars, card.ability.extra.dollars * 2} }
	end,
	calculate = function(self, card, context)
		-- the pairing is locked in at the start of the Scene and held for it
		if context.setting_blind and not context.blueprint then
			card.ability.extra.matthiasPresent = PMCMOD.pair_linked(card)
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

		if context.individual and context.cardarea == G.play and SMODS.has_enhancement(context.other_card, 'm_pmcmod_burn') then
			-- The adjacency still counts for her trigger total even though the payout is flat, and
			-- it counts once per HAND: this sits in context.individual, so without the guard a hand
			-- scoring three Burn Cards would count three times.
			local rr = G.GAME.round_resets or {}
			local handKey = (rr.ante or 0) * 10000 + (G.GAME.round or 0) * 100
				+ (((G.GAME.current_round or {}).hands_played) or 0)
			if card.ability.extra.matthiasPresent and card.ability.extra.triggerHand ~= handKey
				and not context.blueprint then
				card.ability.extra.triggerHand = handKey
				PMCMOD.add_pair_trigger(card, 1)
			end
			return {
				dollars = card.ability.extra.dollars,
			}
        end

		if context.after and not card.ability.extra.banned and PMCMOD.pair_triggers(card) >= 3 then
			card.ability.extra.banned = true
			-- Dying this way bans her from the pool, the same as Matthias's seal taking her,
			-- but it no longer spends a Laevateinn counter: his tolls are swappable, so a dead
			-- Kira just makes her toll uncollectable and the seal takes something else.
			G.GAME.banned_keys['j_pmcmod_kira'] = true
			card.getting_sliced = true
			G.E_MANAGER:add_event(Event({func = function()
				card:start_dissolve({G.C.RED}, nil, 1.6)
				return true end }))
		end
    end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_spiders'), HEX('121212'), HEX('d90000'), 1.2 )
 	end,
	get_weight = function(self, weight)
    	return PMCMOD.bonus_weight(weight, #SMODS.find_card('j_pmcmod_matthias')*G.GAME.round_resets.ante)
	end,
	check_for_unlock = function(self, args)
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_pmcmod_matthias" then
                if get_joker_win_sticker(v, true) >= 1 then
                    return true
                end
                break
            end
        end
    end
}