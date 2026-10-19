SMODS.Joker {
	key = 'rudolph',
	no_pool_flag = 'rudolph_extinct',
	name = "Rudolph",
	pronouns = "he_him",
	config = { extra = { repetitions = 1 } },
	unlocked = false,
	eternal_compat = true,
	perishable_compat = true,
    blueprint_compat = false,
	rarity = 3,
	cost = 8,
	atlas = 'ModdedProjectMoonTrue',
	pos = { x = 9, y = 5 },
	attributes = {'charge'},
	pools =
	{
        ["RCorp"] = true,
 	},
	loc_vars = function (self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.e_pmcmod_charge
    	return {vars = {  }}
	end,
	calculate = function(self, card, context)

		-- A scored card holding Charge triggers once more.
		if context.repetition and context.cardarea == G.play and not context.blueprint then
			local scored = context.other_card
			if scored and scored.edition and scored.edition.key == 'e_pmcmod_charge' then
				return {
					repetitions = card.ability.extra.repetitions
				}
			end
		end

		-- Mult equal to the sell value of every other Keypage on the team.
		if context.joker_main then
			local total = 0
			for i = 1, #G.jokers.cards do
				local other = G.jokers.cards[i]
				if other ~= card then
					total = total + (other.sell_cost or 0)
				end
			end
			if total > 0 then
				return {
					mult = total
				}
			end
		end
	end,
	add_to_deck = function(self, card, from_debuff)
		-- obtainable once: a second Rudolph doubles his Mult and his bonus trigger
		if G.GAME then G.GAME.pool_flags.rudolph_extinct = true end
	end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_RCorp'), HEX('2e2b2b'), HEX('c4560c'), 1.2 )
 	end,
	check_for_unlock = function(self, args)
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_swashbuckler" then
                if get_joker_win_sticker(v, true) >= 8 then
                    return true
                end
                break
            end
        end
    end
}