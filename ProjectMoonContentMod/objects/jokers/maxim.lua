SMODS.Joker {
	key = 'maxim',
	no_pool_flag = 'maxim_extinct',
	name = "Maxim",
	pronouns = "he_him",
	config = { extra = { chargeGain = 5, chargeCost = 1, chipsPerDollar = 2, dollarsPerCharge = 10, repetitions = 1 } },
	unlocked = false,
	eternal_compat = true,
	perishable_compat = true,
    blueprint_compat = false,
	rarity = 2,
	cost = 6,
	atlas = 'ModdedProjectMoonTrue',
	pos = { x = 7, y = 14 },
	attributes = {'economy', 'retrigger', 'charge'},
	pools =
	{
        ["RCorp"] = true,
 	},
	loc_vars = function (self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.e_pmcmod_charge
		return {vars = {
			card.ability.extra.chargeGain,
			card.ability.extra.chargeCost,
			card.ability.extra.chipsPerDollar,
			card.ability.extra.chipsPerDollar * (G.GAME.dollars or 0),
			card.ability.extra.dollarsPerCharge,
			math.floor(PMCMOD.get_charge() / card.ability.extra.dollarsPerCharge),
		}}
	end,
	calculate = function(self, card, context)

		-- A scored Face card feeds the shared Charge pool.
		if context.individual and context.cardarea == G.play and not context.blueprint then
			if context.other_card:is_face() then
				PMCMOD.add_charge(card.ability.extra.chargeGain)
			end
		end

		-- A scored number card spends Charge from the pool to trigger again.
		if context.repetition and context.cardarea == G.play and not context.blueprint then
			if not context.other_card:is_face() and PMCMOD.get_charge() >= card.ability.extra.chargeCost then
				PMCMOD.add_charge(-card.ability.extra.chargeCost)
				return {
					repetitions = card.ability.extra.repetitions
				}
			end
		end

		-- Chips per dollar held.
		if context.joker_main then
			return {
				chips = card.ability.extra.chipsPerDollar * (G.GAME.dollars or 0)
			}
		end
	end,
	calc_dollar_bonus = function(self, card)
		local due = math.floor(PMCMOD.get_charge() / card.ability.extra.dollarsPerCharge)
		if due >= 1 then return due end
	end,
	add_to_deck = function(self, card, from_debuff)
		-- obtainable once: a second Maxim doubles the Charge he feeds and his Chips per dollar
		if G.GAME then G.GAME.pool_flags.maxim_extinct = true end
	end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_RCorp'), HEX('2e2b2b'), HEX('c4560c'), 1.2 )
 	end,
	check_for_unlock = function(self, args)
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_bull" then
                if get_joker_win_sticker(v, true) >= 8 then
                    return true
                end
                break
            end
        end
    end
}