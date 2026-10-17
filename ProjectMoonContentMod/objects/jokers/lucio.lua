SMODS.Joker {
	key = 'lucio',
	no_pool_flag = 'lucio_extinct',
	name = "Lucio",
	pronouns = "he_him",
	config = { extra = { currentPosition = 1, dollars = 3, bonusDollars = 6, valencinaPresent = false,
		xmultGain = 1, chipBonus = false, valencinaPos = nil } },
	unlocked = true,	
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 2,
	cost = 6,
    atlas = 'ModdedProjectMoon2',
	pos = { x =9, y = 5 },
	attributes = {},
    pools =
	{
		["Thumb"] = true,
 	},
	loc_vars = function(self, info_queue, card)
        return {vars = { PMCMOD.pair_trigger_display(card), card.ability.extra.dollars, card.ability.extra.bonusDollars, card.ability.extra.xmultGain or 1, card.ability.extra.chipBonus } }
	end,
	calculate = function(self, card, context)
		local ex = card.ability.extra

		if context.setting_blind and not context.blueprint then
			ex.valencinaPresent = PMCMOD.pair_linked(card)
			-- the apprentice's half: one step per encounter while linked
			if ex.valencinaPresent then
				PMCMOD.add_pair_trigger(card, 1)
			end
			if PMCMOD.pair_triggers(card) >= 3 and not card.ability.extra.banned then
				card.ability.extra.banned = true
				G.GAME.banned_keys['j_pmcmod_lucio'] = true
				local valencina = SMODS.find_card('j_pmcmod_valencina')
				if valencina and #valencina > 0 then
					local hers = valencina[1].ability and valencina[1].ability.extra
					if type(hers) == 'table' then hers.deathXmult = true end
				end
				card.getting_sliced = true
				G.E_MANAGER:add_event(Event({ trigger = 'immediate', func = function()
					card:start_dissolve({G.C.RED}, nil, 1.6)
					return true end }))
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

		if context.individual and context.cardarea == G.play
			and SMODS.has_enhancement(context.other_card, 'm_pmcmod_tremor') then
			return { dollars = ex.valencinaPresent and ex.bonusDollars or ex.dollars }
		end

		-- XMult grows with every card she has destroyed, for the rest of the run
		if context.joker_main and not context.blueprint then
			local destroyed = G.GAME.pmcmod_valencina_destroyed or 0
			local xm = 1 + 0.2 * destroyed
			local ret = {}
			if xm > 1 then ret.xmult = xm end
			if xm >= 3 then ret.xchips = 2 end
			if next(ret) then return ret end
		end
    end,
	add_to_deck = function(self, card, from_debuff)
		-- obtainable once, like the mod's other unique Keypages
		if G.GAME then G.GAME.pool_flags.lucio_extinct = true end
	end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_spiders'), HEX('121212'), HEX('d90000'), 1.2 )
 	end,
	get_weight = function(self, weight)
    	return PMCMOD.bonus_weight(weight, #SMODS.find_card('j_pmcmod_valencina')*G.GAME.round_resets.ante)
	end,
	check_for_unlock = function(self, args)
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_pmcmod_valencina" then
                if get_joker_win_sticker(v, true) >= 1 then
                    return true
                end
                break
            end
        end
    end
}