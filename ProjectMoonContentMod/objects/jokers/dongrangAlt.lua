SMODS.Joker {
	key = 'dongrang_alt',
	name = "Dongrang, Who Denies All",
	pronouns = "he_him",
	config = { extra = { xmult = 1, xmult_gain = 1 } },
	unlocked = false,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 9,
	atlas = 'ModdedProjectMoon',
	pos = { x = 0, y = 10 },
	attributes = {'xmult', 'scaling', 'polychrome', 'modify_card', 'editions'},
	pools =
	{
		["KCorp"] = true,
	},
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult, card.ability.extra.xmult_gain } }
	end,
	calculate = function(self, card, context)

		local joker_count = 0
		for i = 1, #G.jokers.cards do
			if G.jokers.cards[i].edition then
				if G.jokers.cards[i].ability.set == 'Joker' and G.jokers.cards[i].edition.key == "e_polychrome" then
					joker_count = joker_count + 1
				end
			end
		end
		card.ability.extra.xmult = 1 + joker_count

		if context.joker_main then
			return {
				xmult = card.ability.extra.xmult,
				message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.extra.xmult } }
			}
		end

		if context.end_of_round and context.game_over == false and G.GAME.last_blind and G.GAME.last_blind.boss and context.main_eval and not context.blueprint then
			local editionless_jokers = SMODS.Edition:get_edition_cards(G.jokers, true)

			if (#editionless_jokers > 0) then
				local eligible_card = pseudorandom_element(editionless_jokers, 'dongrang_alt')
				local edition = 'e_polychrome'
				eligible_card:set_edition(edition, true)
				check_for_unlock({ type = 'have_edition' })
			end

		end

    end,
	in_pool = function(self, args)
		if not (G and G.jokers and G.jokers.cards) then return true end
		for i = 1, #G.jokers.cards do
			local center = G.jokers.cards[i].config and G.jokers.cards[i].config.center
			if center and center.key == 'j_pmcmod_dongrang' then return false end
		end
		return true
	end,
	check_for_unlock = function(self, args)
		return args.type == 'pmcmod_dongrang_destroyed' and G.GAME and G.GAME.pmcmod_dongrang_destroyed == true
	end,
	set_badges = function(self, card, badges)
		badges[#badges+1] = create_badge(localize('pmcmod_badge_KCorp'), G.C.GREEN, G.C.BLACK, 1.2 )
	end,
}
