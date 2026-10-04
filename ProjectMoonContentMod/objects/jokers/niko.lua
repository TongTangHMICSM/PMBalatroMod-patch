SMODS.Joker {
	key = 'niko',
	name = "Niko",
	pronouns = "he_him",
	-- h_size is a native Balatro variable. Keep it outside of "extra"
	config = { h_size = 1, extra = { mult = 0 } }, 
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
		
		-- Use card.ability.h_size instead of extra
		return { vars = { current_mult, card.ability.h_size } }
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
	end
}