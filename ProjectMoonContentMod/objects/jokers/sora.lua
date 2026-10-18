SMODS.Joker {
	key = 'sora',
	no_pool_flag = 'sora_extinct',
	name = "Sora",
	pronouns = "she_her",
	config = { extra = { chips = 0, chips_mod = 20, mult = 0, xmult = 1, chargeStacks = 0, chargeHand = -1, chargeSpendHand = -1, chargeTriggers = 0, doubleReception = -1, lastReception = -1, soraDeathCounter = 0, rienPresent = false, rienPos = nil, locked = false, counter = 0 } },
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 2,
	cost = 6,
    atlas = 'ModdedProjectMoon2',
	pos = { x =0, y = 6 },
	attributes = {'chips', 'editions', 'scaling', 'destroy_itself', 'position'},
    pools =
	{
		["Index"] = true,
 	},
	-- She only turns up while a Keypage is wearing an Edition, or while Rien is on the team.
	in_pool = function(self, args)
		if #SMODS.find_card('j_pmcmod_rien') > 0 then return true end
		local jokers = (G.jokers and G.jokers.cards) or {}
		for i = 1, #jokers do
			if jokers[i].edition then return true end
		end
		return false
	end,
	loc_vars = function(self, info_queue, card)
		
		if card.edition then
			card.children.center:set_sprite_pos({x = 0 , y = 11})
		end
		
		if card.ability.extra.locked then
			card.children.center:set_sprite_pos({x = 1 , y = 11})
		end

		-- she carries the Charge edition's rules once she has absorbed one
		if card.ability.extra.chargeStacks > 0 then
			info_queue[#info_queue + 1] = G.P_CENTERS.e_pmcmod_charge
		end



		-- the stats as the player will actually get them, i.e. after the net-Grace factor, plus how
		-- many times her keypage triggers this hand
		local ex = card.ability.extra
		local sgv = PMCMOD.sora_grace()
		local factor = ex.locked and (1 + 0.1 * sgv) or 1
		local xmNow = ex.locked and (ex.xmult ^ (1 + 0.5 * sgv)) or ex.xmult
		local here = (G.GAME.round_resets.ante or 0) * 10000 + (G.GAME.round or 0)
		local triggersNow = 1 + (((ex.doubleReception == here) and 1) or 0) + (ex.chargeTriggers or 0)

        return {vars = {
            ex.chips * factor,                    -- #1# Chips, after the net-Grace factor
            triggersNow,                          -- #2# triggers this hand
            PMCMOD.pair_trigger_display(card),     -- #3#
            PMCMOD.grace(),                       -- #4#
            PMCMOD.karma(),                       -- #5#
            ex.mult * factor,                     -- #6# Mult, after the factor
            xmNow,                                -- #7# XMult, after the net-Grace power
            ex.chargeStacks,                      -- #8#
            PMCMOD.sora_grace(),                  -- #9#
        } }
	end,
	-- taken once and never offered again
	add_to_deck = function(self, card, from_debuff)
		if G.GAME then G.GAME.pool_flags.sora_extinct = true end
	end,
	calculate = function(self, card, context)
		-- the pairing is locked in at the start of the Scene and held for it
		if context.setting_blind and not context.blueprint then
			card.ability.extra.rienPresent = PMCMOD.pair_linked(card)
		end

		if context.before then
			-- Rien has to be exactly to her left (she is the apprentice)
		end

		-- three Receptions WITHOUT stealing and she reveals her second form. Gated on setting_blind,
		-- which fires exactly once per Scene - running this on every calculate call, keyed on
		-- G.GAME.round, advanced it several times inside a single Scene.
		if context.setting_blind and not card.ability.extra.locked and not context.blueprint then
			card.ability.extra.dryReceptions = (card.ability.extra.dryReceptions or 0) + 1
			if card.ability.extra.dryReceptions >= 3 then
				card.ability.extra.locked = true
			end
		end

		if context.setting_blind and not card.ability.extra.locked and not context.blueprint then

			-- any Keypage holding an edition is fair game, however many Sora has taken already
			local wearingNegative = card.edition and card.edition.key == 'e_negative'
			local editionJokers = {}
			local priority = nil
			for i = 1, #G.jokers.cards do
				local other = G.jokers.cards[i]
				-- Rien sits directly to her left (she is the apprentice): his Edition goes first
				if other == card then
					local father = G.jokers.cards[i - 1]
					if father and father.config.center.key == "j_pmcmod_rien" and father.edition
						and not (wearingNegative and father.edition.key == 'e_negative') then
						priority = father
					end
				end
				-- she wears one Negative and never takes a second
				if other ~= card and other.edition
					and not (wearingNegative and other.edition.key == 'e_negative') then
					editionJokers[#editionJokers + 1] = other
				end
			end

			if priority or #editionJokers > 0 then
				card.ability.extra.dryReceptions = 0   -- a steal restarts the three-Reception count
				local eligible_card = priority or pseudorandom_element(editionJokers, 'sora')
				local stolen = eligible_card.edition.key
				eligible_card:set_edition()          -- it always leaves its owner


				if stolen == 'e_negative' then
					-- the one edition Sora wears rather than absorbs, and the only steal that pays
					card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chips_mod
					card:set_edition('e_negative', true)
				elseif stolen == 'e_foil' then
					card.ability.extra.chips = card.ability.extra.chips + 50
				elseif stolen == 'e_holo' then
					card.ability.extra.mult = card.ability.extra.mult + 10
				elseif stolen == 'e_polychrome' then
					card.ability.extra.xmult = card.ability.extra.xmult * 1.5
				elseif stolen == 'e_pmcmod_charge' then
					card.ability.extra.chargeStacks = card.ability.extra.chargeStacks + 1
				else
					card:set_edition(stolen, true)   -- unknown edition: keep the old behaviour
				end
			end

		end

		-- The adjacency double is registered before the engine asks about retriggers, and it lasts
		-- for the rest of the Reception. The shared counter rises once per Reception.
		if context.before and not context.blueprint then
			local reception = (G.GAME.round_resets.ante or 0) * 10000 + (G.GAME.round or 0)
			if card.ability.extra.rienPresent and card.ability.extra.doubleReception ~= reception then
				card.ability.extra.doubleReception = reception
				PMCMOD.add_pair_trigger(card, 1)
			end
		end

		-- Charge stacks: Sora feeds the pool from them, and spends the usual 5 to buy extra triggers
		-- with each stack. Give and triggers both scale with the stacks, the spend never does.
		if card.ability.extra.chargeStacks > 0 then
			local rr = G.GAME.round_resets or {}
			local handKey = (rr.ante or 0) * 10000 + (G.GAME.round or 0) * 100 + ((G.GAME.current_round or {}).hands_played or 0)

			if context.individual and context.cardarea == G.play and not context.blueprint
				and card.ability.extra.chargeHand ~= handKey then
				card.ability.extra.chargeHand = handKey
				PMCMOD.add_charge(PMCMOD.charge_gain() * card.ability.extra.chargeStacks)
			end

			-- 5 Charge buys her own keypage another trigger, once per hand. This used to sit in
			-- context.repetition - the card-retrigger context - which is why she retriggered played
			-- cards. Per stack her keypage triggers once more, for the same single spend.
			-- The spend happens at context.before: the engine asks about retriggers before
			-- joker_main runs, so spending any later would miss this hand's repetitions.
			if context.before and not context.blueprint then
				card.ability.extra.chargeTriggers = 0   -- only a spend made in this hand counts
				if PMCMOD.get_charge() >= 5 and card.ability.extra.chargeSpendHand ~= handKey then
					card.ability.extra.chargeSpendHand = handKey
					PMCMOD.add_charge(-5)
					card.ability.extra.chargeTriggers = card.ability.extra.chargeStacks
					card_eval_status_text(card, 'extra', nil, nil, nil, {
						message = localize('pmcmod_chargeSpend'),
						colour = G.C.BLUE,
					})
				end
			end
		end

		-- Physical retriggers, the way leiHeng does it: answer the engine's retrigger check for
		-- ourselves and let it run this keypage again that many times, each with its own popup.
		if context.retrigger_joker_check and context.other_card == card and not context.blueprint then
			local receptionNow = (G.GAME.round_resets.ante or 0) * 10000 + (G.GAME.round or 0)
			local extra = (card.ability.extra.chargeTriggers or 0)
				+ ((card.ability.extra.doubleReception == receptionNow) and 1 or 0)
			if extra > 0 then
				return { repetitions = extra }
			end
		end

		if context.joker_main then



			if PMCMOD.pair_triggers(card) >= 5 then
				card.getting_sliced = true
				G.E_MANAGER:add_event(Event({func = function()
					card:start_dissolve({G.C.RED}, nil, 1.6)
				return true end }))
			end

			local ex = card.ability.extra
			local ret = {}
			-- applied once; the extra triggers are real repetitions granted through the retrigger
			-- check above, so they show up as their own applications

			if ex.locked then
				-- second form: the net Grace (Grace less Karma, which can go negative) is added to
				-- each channel on top of what she absorbed
				local sg = PMCMOD.sora_grace()
				local factor = 1 + 0.1 * sg
				ret.chips = ex.chips * factor
				ret.mult = ex.mult * factor
				-- XMult is a power of the absorbed value rather than a factor of it
				local xm = ex.xmult ^ (1 + 0.5 * sg)
				if xm > 0 then ret.xmult = xm end
			else
				ret.chips = ex.chips
				if ex.mult > 0 then ret.mult = ex.mult end
				if ex.xmult ~= 1 then ret.xmult = ex.xmult end
			end

			return ret
		end
    end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_spiders'), HEX('121212'), HEX('d90000'), 1.2 )
 	end,
	-- Rien on the team (times the Act) and Grace of the City both raise the odds of Sora showing up.
	get_weight = function(self, weight)
    	return PMCMOD.bonus_weight(weight, #SMODS.find_card('j_pmcmod_rien')*G.GAME.round_resets.ante + PMCMOD.grace())
	end,
	check_for_unlock = function(self, args)
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_pmcmod_rien" then
                if get_joker_win_sticker(v, true) >= 1 then
                    return true
                end
                break
            end
        end
    end
}