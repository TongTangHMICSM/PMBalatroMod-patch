SMODS.Joker {
	key = 'niko',
	name = "Niko",
	pronouns = "he_him",
	config = { extra = { mult = 0, handSize = 1} },
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 2,
	cost = 8,
	atlas = 'ModdedProjectMoon',
	pos = { x = 7, y = 3 },
	attributes = {'mult', 'hand_size'},
	pools = {},
    
	loc_vars = function(self, info_queue, card)
		-- Dynamically calculate the current mult for the UI if a run is active
		local current_mult = card.ability.extra.mult
		if G.hand and G.hand.cards then
			current_mult = #G.hand.cards * 3
		end
		
		return { vars = { current_mult, card.ability.extra.handSize } }
	end,
    
	calculate = function(self, card, context)
		if context.joker_main then
			local mult_amount = #G.hand.cards * 3
			card.ability.extra.mult = mult_amount
			
			return {
				mult = mult_amount,
				message = localize { type = 'variable', key = 'a_mult', vars = { mult_amount } }
			}
		end
	end,
    
	set_badges = function(self, card, badges)
		badges[#badges+1] = create_badge(localize('pmcmod_badge_rosespanner'), HEX('380e21'), HEX('ed2680'), 1.2 )
	end,
    
	add_to_deck = function(self, card, from_debuff)
		G.hand:change_size(card.ability.extra.handSize)
	end,
    
	remove_from_deck = function(self, card, from_debuff)
		G.hand:change_size(-card.ability.extra.handSize)
	end
}