SMODS.Joker {
	key = 'valencina',
	no_pool_flag = 'valencina_extinct',
	name = "Valencina",
	pronouns = "she_her",
	config = { extra = { precognition = 20, overheat = 0, overheated = false,
		chipsX = 0, lucioPresent = false, lucioGone = false, deathXmult = false,
		currentPosition = 1 } },
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
        return {vars = { card.ability.extra.precognition or 0, card.ability.extra.overheat or 0,
            PMCMOD.pair_trigger_display(card) } }
	end,
	calculate = function(self, card, context)
		local ex = card.ability.extra

		-- ------------------------------------------------------------------ entering an encounter
		if context.setting_blind and not context.blueprint then
			ex.lucioPresent = PMCMOD.pair_linked(card)

			if not ex.overheated and (ex.precognition or 0) > 10
				and G.GAME.blind and G.GAME.blind.boss and not G.GAME.blind.disabled then
				-- read the boss open
				ex.precognition = ex.precognition - 10
				G.GAME.blind:disable()
				card_eval_status_text(card, 'extra', nil, nil, nil, {
					message = localize('pmcmod_valencinaRead'), colour = G.C.BLUE,
				})
			end

			if ex.overheated and (ex.overheat or 0) > 0
				and G.GAME.blind and G.GAME.blind.boss and not G.GAME.blind.disabled then
				-- burn overheat to soften the boss
				local spend = math.min(10, ex.overheat)
				ex.overheat = ex.overheat - spend
				G.GAME.blind.chips = math.max(1, math.floor(G.GAME.blind.chips * (1 - spend * 0.05)))
				card_eval_status_text(card, 'extra', nil, nil, nil, {
					message = localize('pmcmod_valencinaHate'), colour = G.C.RED,
				})
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

		-- the pairing's bonus needs only Lucio exactly to her right
		local bonus = ex.lucioPresent

		-- ------------------------------------------------------------------ scoring more than two
		if context.individual and context.cardarea == G.play and not context.blueprint then
			local scored = context.scoring_hand or {}

			if #scored > 2 then
				if context.other_card == scored[#scored] then
					if not ex.overheated and (ex.precognition or 0) > 0 then
						ex.precognition = ex.precognition - 1
						context.other_card:set_ability('m_pmcmod_tremor', nil, true)
					elseif ex.overheated and (ex.overheat or 0) > 0
						and SMODS.has_enhancement(context.other_card, 'm_pmcmod_tremor') then
						ex.overheat = ex.overheat - 1
						context.other_card:set_ability('m_pmcmod_burn', nil, true)
					end
				end

				if bonus and context.other_card == scored[1] then
					-- free, and only while the pairing holds
					context.other_card:set_ability('m_pmcmod_tremor', nil, true)
					card_eval_status_text(card, 'extra', nil, nil, nil, {
						message = localize('pmcmod_valencinaBonus'), colour = G.C.BLUE,
					})
				end
			end
		end

		-- ------------------------------------------------------------------ overheated discard
		if context.discard and not context.blueprint and context.other_card
			and ex.overheated and (ex.overheat or 0) > 0
			and (G.GAME.pmcmod_discardSize or 0) == 1 then
			ex.overheat = ex.overheat - 1
			ex.chipsX = (ex.chipsX or 0) + 0.2
			local victim = context.other_card
			G.E_MANAGER:add_event(Event({ trigger = 'immediate', func = function()
				SMODS.destroy_cards(victim)
				return true
			end }))
			card_eval_status_text(card, 'extra', nil, nil, nil, {
				message = localize('pmcmod_valencinaDestroyed'), colour = G.C.RED,
			})
		end

		-- ------------------------------------------------------------------ payout
		if context.joker_main and not context.blueprint then
			local ret = {}
			if (ex.chipsX or 0) > 0 then ret.xchips = 1 + ex.chipsX end
			if ex.deathXmult then ret.xmult = 3 end
			if next(ret) then return ret end
		end

		-- ------------------------------------------------------------------ switching state
		if context.after and not context.blueprint then
			if not ex.overheated and (ex.precognition or 0) <= 0 then
				ex.overheated = true
				ex.overheat = 20
				card_eval_status_text(card, 'extra', nil, nil, nil, {
					message = localize('pmcmod_valencinaOverheat'), colour = G.C.RED,
				})
			elseif ex.overheated and (ex.overheat or 0) <= 0 then
				ex.overheated = false
				ex.precognition = 20
				card_eval_status_text(card, 'extra', nil, nil, nil, {
					message = localize('pmcmod_valencinaCool'), colour = G.C.BLUE,
				})
			end
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