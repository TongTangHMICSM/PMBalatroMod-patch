SMODS.Joker {
	key = 'valencina',
	no_pool_flag = 'valencina_extinct',
	name = "Valencina",
	pronouns = "she_her",
	config = { extra = { currentPosition = 1, lucioPresent = false, lucioGone = false,
		deathXmult = false, discardXchips = 0, destroyedHere = 0, bonesUsed = false } },
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
    atlas = 'ModdedProjectMoon2',
	pos = { x = 4, y = 5 },
	attributes = {'tremor', 'ammo', 'modify_card', 'position'},
    pools =
	{
		["Heretics"] = true,
		["Thumb"] = true,
 	},
	loc_vars = function(self, info_queue, card)
        return {vars = { PMCMOD.pair_trigger_display(card), card.ability.extra.destroyedHere or 0 } }
	end,
	calculate = function(self, card, context)
		local ex = card.ability.extra

		-- the pairing is locked in at the start of the Scene and held for it
		if context.setting_blind and not context.blueprint then
			ex.lucioPresent = PMCMOD.pair_linked(card)
			ex.discardXchips = 0
			ex.destroyedHere = 0
			ex.deathXmult = false       -- the X3 lasts one encounter
			-- the counter rises here, once, and the bonus it grants holds for the encounter
			if ex.lucioPresent and not context.blueprint then
				PMCMOD.add_pair_trigger(card, 1)
			end
		end
		if context.before and not context.blueprint then
			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i] == card then
					ex.currentPosition = i
					break
				end
			end
		end

		-- A discard of exactly one card destroys it: Trading Card's rule without the first-discard
		-- limit. The size comes from PMCMOD.install_discard_reporter.
		if context.discard and not context.blueprint and context.other_card
			and (G.GAME.pmcmod_discardSize or 0) == 1
			and ex.lastDiscardId ~= (G.GAME.pmcmod_discardId or 0) then
			ex.lastDiscardId = G.GAME.pmcmod_discardId
			-- deferred: the discard loop is still iterating this card
			local victim = context.other_card
			G.E_MANAGER:add_event(Event({ trigger = 'immediate', func = function()
				SMODS.destroy_cards(victim)
				return true
			end }))
			ex.discardXchips = 2
			ex.destroyedHere = (ex.destroyedHere or 0) + 1
			G.GAME.pmcmod_valencina_destroyed = (G.GAME.pmcmod_valencina_destroyed or 0) + 1
			card_eval_status_text(card, 'extra', nil, nil, nil, {
				message = localize('pmcmod_valencinaDestroyed'), colour = G.C.RED,
			})
		end

		-- with Lucio to her right the FIRST scored card turns too
		if ex.lucioPresent and context.individual and context.cardarea == G.play
			and context.other_card == context.scoring_hand[1] then
			context.other_card:set_ability('m_pmcmod_tremor', nil, true)
		end

		-- she changes the LAST scored card; a hand of one has nothing to change
		if context.individual and context.cardarea == G.play and #context.scoring_hand >= 2
			and context.other_card == context.scoring_hand[#context.scoring_hand] then
			context.other_card:set_ability('m_pmcmod_tremor', nil, true)

			-- the new Tremor card can gain chips: a chance equal to this encounter's destroyed count
			-- in 10, worth 0.001% of the Encounter per Burn Card in the deck
			local destroyed = ex.destroyedHere or 0
			if destroyed > 0 and SMODS.pseudorandom_probability(card, 'valencina_tremor_bonus',
				destroyed, 10, 'valencina_tremor_bonus') then
				local burn = 0
				for _, pc in ipairs(G.playing_cards or {}) do
					if SMODS.has_enhancement(pc, 'm_pmcmod_burn') then burn = burn + 1 end
				end
				if burn > 0 and G.GAME.blind then
					local bonus = G.GAME.blind.chips * 0.001 * burn
					context.other_card.ability.bonus = (context.other_card.ability.bonus or 0) + bonus
					card_eval_status_text(context.other_card, 'extra', nil, nil, nil, {
						message = localize('pmcmod_valencinaTremor'), colour = G.C.CHIPS,
					})
				end
			end

			-- the bonus is the linked half: Lucio exactly to her right
			if ex.lucioPresent and not context.blueprint then
				if PMCMOD.pair_triggers(card) >= 5 and not ex.lucioGone then
					ex.lucioGone = true
					ex.deathXmult = true
					G.GAME.banned_keys['j_pmcmod_lucio'] = true
					local lucio = nil
					local jokers = G.jokers.cards or {}
					for i = 1, #jokers do
						if PMCMOD.bare_key(jokers[i].config.center.key) == 'lucio' then lucio = jokers[i] end
					end
					if lucio then
						lucio.getting_sliced = true
						G.E_MANAGER:add_event(Event({func = function()
							card:juice_up(0.8, 0.8)
							lucio:start_dissolve({G.C.RED}, nil, 1.6)
							return true end }))
					end
				end
			end
		end

		-- once he is gone she keeps a permanent x3 Mult
		if context.joker_main and not context.blueprint then
			local ret = {}
			-- X3 for this encounter only, and X2 Chips for every card destroyed in it
			if ex.deathXmult then ret.xmult = 3 end
			local destroyed = ex.destroyedHere or 0
			if destroyed > 0 then ret.xchips = 2 * destroyed end
			if next(ret) then return ret end
		end
    end,
	add_to_deck = function(self, card, from_debuff)
		-- obtainable once, like the mod's other unique Keypages
		if G.GAME then G.GAME.pool_flags.valencina_extinct = true end
	end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_spiders'), HEX('121212'), HEX('d90000'), 1.2 )
 	end,
	get_weight = function(self, weight)
    	return PMCMOD.bonus_weight(weight, #SMODS.find_card('j_pmcmod_lucio')*G.GAME.round_resets.ante)
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