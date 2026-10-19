SMODS.Joker {
	key = 'nikolai',
	no_pool_flag = 'nikolai_extinct',
	name = "Nikolai",
	pronouns = "she_her",
	config = { extra = { mult = 0, mult_mod = 5, rcorpXmult = 1.5, savedJokers = {}, highlightedJokerStatus = "" } },	
	unlocked = false,
	eternal_compat = true,
	perishable_compat = true,
    blueprint_compat = true,
	rarity = 3,
	cost = 8,
	atlas = 'ModdedProjectMoonTrue',
	pos = { x = 3, y = 3 },
	attributes = {'mult', 'scaling'},
	pools =
	{
        ["RCorp"] = true,
 	},
	loc_vars = function (self, info_queue, card)


		if G.GAME.blind then
			if G.jokers.highlighted[1] then
				card.ability.extra.highlightedJokerStatus = localize('pmcmod_nikolaiCataloguedFalse')
				for i=1, #card.ability.extra.savedJokers do
					if card.ability.extra.savedJokers[i] == G.jokers.highlighted[1].config.center.key then
						card.ability.extra.highlightedJokerStatus = localize('pmcmod_nikolaiCataloguedTrue')
						break
					end
				end
			else
				card.ability.extra.highlightedJokerStatus = ""
			end
		end

    	return {vars = { card.ability.extra.mult, card.ability.extra.mult_mod, card.ability.extra.highlightedJokerStatus, card.ability.extra.rcorpXmult }}
	end,
	calculate = function(self, card, context)

        -- aspects are not Keypages of the Index - they do not count towards the catalogue
        if context.buying_card and context.card.ability.set == "Joker" and not context.blueprint
            and not PMCMOD.is_aspect(context.card.config.center.key) then

            local cardAlreadySaved = false

            if #card.ability.extra.savedJokers >=1 then
                for i=1, #card.ability.extra.savedJokers do
                   if card.ability.extra.savedJokers[i] == context.card.config.center.key then
                        cardAlreadySaved = true
                    break
                   else
                        cardAlreadySaved = false
                    end
                end
            end

            if cardAlreadySaved == false then
                card.ability.extra.savedJokers[#card.ability.extra.savedJokers + 1] = context.card.config.center.key
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
            end

        end

		if context.joker_main then
			return { mult = card.ability.extra.mult }
		end

		-- R Corp Keypages give x1.5 Mult each time they trigger, the way Baseball Card gives its
		-- Uncommon Jokers the same multiplier: the payout lands per trigger, so retriggers compound
		-- it, and Nikolai does not count himself.
		if context.other_joker and context.other_joker ~= card then
			local center = context.other_joker.config and context.other_joker.config.center
			if center and center.pools and center.pools.RCorp then
				G.E_MANAGER:add_event(Event({
					func = function()
						context.other_joker:juice_up(0.5, 0.5)
						return true
					end
				}))
				return {
					message = localize{type = 'variable', key = 'a_xmult', vars = {card.ability.extra.rcorpXmult}},
					Xmult_mod = card.ability.extra.rcorpXmult,
				}
			end
		end

	end,
	add_to_deck = function(self, card, from_debuff)
		-- obtainable once: a second Nikolai doubles every R Corp X Mult trigger
		if G.GAME then G.GAME.pool_flags.nikolai_extinct = true end
	end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_RCorp'), HEX('2e2b2b'), HEX('c4560c'), 1.2 )
 	end,
	check_for_unlock = function(self, args)
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_abstract" then
                if get_joker_win_sticker(v, true) >= 8 then
                    return true
                end
                break
            end
        end
    end
}