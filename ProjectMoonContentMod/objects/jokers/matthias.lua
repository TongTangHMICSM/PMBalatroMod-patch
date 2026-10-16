SMODS.Joker {
	key = 'matthias',
	name = "Matthias",
	pronouns = "he_him",
	config = { extra = { hands = 1, laevateinn = 3, price = 2, brokeHand = -1,
		kiraPresent = false, currentPosition = 1 } },
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
    atlas = 'ModdedProjectMoon2',
	pos = { x = 6, y = 5 },
	attributes = {'economy', 'burn', 'destroy_card', 'scaling', 'position'},
    pools =
	{
		["Middle"] = true,
 	},
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue+1] = G.P_CENTERS.m_pmcmod_burn
        return {vars = { card.ability.extra.hands, card.ability.extra.laevateinn, card.ability.extra.price,
			PMCMOD.laevateinn_scale() } }
	end,
	calculate = function(self, card, context)
		local ex = card.ability.extra

		-- the pairing is locked in at the start of the Scene and held for it
		if context.setting_blind and not context.blueprint then
			ex.kiraPresent = PMCMOD.pair_linked(card)
		end
		if context.before and not context.blueprint then
			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i] == card then
					ex.currentPosition = i
					break
				end
			end
		end

		-- With the Laevateinn spent the seal spreads on its own: every scored card rolls once,
		-- gaining Burn on a hit, and a hit on a card that already burns consumes it.
		if context.individual and context.cardarea == G.play and not context.blueprint
			and ex.laevateinn <= 0 then
			if SMODS.pseudorandom_probability(card, 'matthias_seal', 1, 5, 'matthias_seal') then
				if SMODS.has_enhancement(context.other_card, 'm_pmcmod_burn') then
					SMODS.destroy_cards(context.other_card)
				else
					context.other_card:set_ability('m_pmcmod_burn', nil, true)
				end
			end
		end

		if context.individual and context.cardarea == G.play and not context.blueprint
			and ex.laevateinn > 0 and G.GAME.current_round and G.GAME.current_round.hands_played == 0
			and not SMODS.has_enhancement(context.other_card, 'm_pmcmod_burn') then
			local scored = context.scoring_hand or {}

			local rr = G.GAME.round_resets or {}
			local handKey = (rr.ante or 0) * 10000 + (G.GAME.round or 0) * 100
				+ (((G.GAME.current_round or {}).hands_played) or 0)

			local linked = PMCMOD.pair_linked(card)

			if ex.brokeHand ~= handKey then
				-- A first hand: Burn is bought at the going price, which climbs by $1 each
				-- time. Kira to his right waives it entirely. Nothing is ever spent while
				-- short: the buy only happens at or above the price, and a Credit Card is
				-- the only way to pay below it.
				if linked then
					context.other_card:set_ability('m_pmcmod_burn', nil, true)
				elseif to_big(ex.price) <= to_big(G.GAME.dollars) then
					context.other_card:set_ability('m_pmcmod_burn', nil, true)
					-- paid instantly so every later check of the hand sees the real purse
					ease_dollars(-ex.price, true)
					ex.price = ex.price + 1
				elseif PMCMOD.credit_card_in_play() then
					context.other_card:set_ability('m_pmcmod_burn', nil, true)
					ease_dollars(-ex.price, true)
					ex.price = ex.price + 1
				else
					-- The price outruns the purse, so the buy is refused and the seal takes a
					-- counter instead, once per hand. The toll follows the counters left: the
					-- first seal wipes the scored hand, the second takes a random Keypage (it
					-- needs a destroyable one), the third takes Kira (it needs her in play).
					local took = false
					if ex.laevateinn >= 3 then
						ex.laevateinn = ex.laevateinn - 1
						ex.brokeHand = handKey
						SMODS.destroy_cards(scored)
						ease_dollars(20)
						took = true
					elseif ex.laevateinn == 2 then
						local pool = {}
						local jokers = G.jokers.cards or {}
						for i = 1, #jokers do
							local other = jokers[i]
							local otherKey = PMCMOD.bare_key(other.config.center.key)
							if other ~= card and otherKey ~= 'kira'
								and not SMODS.is_eternal(other, { destroy_cards = true }) then
								pool[#pool + 1] = other
							end
						end
						if #pool > 0 then
							local target = pseudorandom_element(pool, pseudoseed('pmcmod_laevateinn'))
							ex.laevateinn = ex.laevateinn - 1
							ex.brokeHand = handKey
							ease_dollars(20)
							target.getting_sliced = true
							G.E_MANAGER:add_event(Event({func = function()
								card:juice_up(0.8, 0.8)
								target:start_dissolve({G.C.RED}, nil, 1.6)
								return true end }))
							took = true
						end
					elseif ex.laevateinn == 1 then
						local kira = nil
						local jokers = G.jokers.cards or {}
						for i = 1, #jokers do
							if PMCMOD.bare_key(jokers[i].config.center.key) == 'kira' then kira = jokers[i] end
						end
						if kira then
							ex.laevateinn = ex.laevateinn - 1
							ex.brokeHand = handKey
							ease_dollars(20)
							G.GAME.banned_keys['j_pmcmod_kira'] = true
							kira.getting_sliced = true
							G.E_MANAGER:add_event(Event({func = function()
								card:juice_up(0.8, 0.8)
								kira:start_dissolve({G.C.RED}, nil, 1.6)
								return true end }))
							took = true
						end
					end
					if took then
						card_eval_status_text(card, 'extra', nil, nil, nil, {
							message = localize('pmcmod_laevateinnSpent'), colour = G.C.RED,
						})
					end
				end
			end
		end
    end,
	add_to_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands - card.ability.extra.hands
    end,
    remove_from_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands + card.ability.extra.hands
    end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_spiders'), HEX('121212'), HEX('d90000'), 1.2 )
 	end,
	get_weight = function(self, weight)
    	return PMCMOD.bonus_weight(weight, #SMODS.find_card('j_pmcmod_kira')*G.GAME.round_resets.ante)
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