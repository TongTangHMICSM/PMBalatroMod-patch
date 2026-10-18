SMODS.Joker {
	key = 'angelaLoR',
	name = "Angela",
	pronouns = "she_her",
	config = { extra = { creates = 5, chips = 0, chips_mod = 15} },
	unlocked = false,
	eternal_compat = true,
	perishable_compat = true,	
    blueprint_compat = false,
	rarity = 3,
	cost = 8,
	atlas = 'ModdedProjectMoonTrue',
	pos = { x = 1, y = 12 },
	attributes = {'chips', 'scaling', 'summoning'},
	loc_vars = function (self, info_queue, card)
		info_queue[#info_queue + 1] = { key = "perishable", set = "Other", vars = { G.GAME.perishable_rounds, G.GAME.perishable_rounds } }
    	return {vars = { card.ability.extra.creates, card.ability.extra.chips, card.ability.extra.chips_mod}}
	end,
	update = function (self, card, dt)
		-- Perished Keypages are collected when a shop opens, not when a blind starts: calculate only runs
		-- on game events, so the earliest it fired was setting_blind, with the old shop still alive.
		-- update runs every frame, and a per-shop key keeps this to one pass per shop.
		if not (G.STATE == G.STATES.SHOP and G.shop) then return end
		local key = tostring(G.GAME.round_resets.ante) .. '_' .. tostring(G.GAME.round)
		if card.ability.extra.shopDone == key then return end
		card.ability.extra.shopDone = key

		local taken = 0
		for i2 = 1, #G.jokers.cards do
			local other = G.jokers.cards[i2]
			if other ~= card and not other.getting_sliced
				and not other.ability.eternal and other.ability.perish_tally == 0 then
				taken = taken + 1
				other.getting_sliced = true
				G.E_MANAGER:add_event(Event({func = function()
					card:juice_up(0.8, 0.8)
					other:start_dissolve({G.C.RED}, nil, 1.6)
					return true end }))
			end
		end

		if taken > 0 then
			local gain = taken * card.ability.extra.chips_mod
			card.ability.extra.chips = card.ability.extra.chips + gain
			card_eval_status_text(card, 'extra', nil, nil, nil, {
				message = localize { type = 'variable', key = 'a_chips', vars = { gain } },
				colour = G.C.CHIPS,
			})
		end
	end,
	calculate = function(self, card, context)
		if context.setting_blind and #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit and not context.blueprint then
            local jokers_to_create = math.min(card.ability.extra.creates,
                G.jokers.config.card_limit - (#G.jokers.cards + G.GAME.joker_buffer))
            G.GAME.joker_buffer = G.GAME.joker_buffer + jokers_to_create
            G.E_MANAGER:add_event(Event({
                func = function()
                    for _ = 1, jokers_to_create do
                        SMODS.add_card {
                            set = 'Joker',
                            key_append = 'vremade_riff_raff',
							stickers = {"perishable"},
							force_stickers = true
                        }
                        G.GAME.joker_buffer = 0
                    end
                    return true
                end
            }))
            return {
                message = localize('k_plus_joker'),
                colour = G.C.BLUE,
            }
        end
		-- perished Keypages are collected in update, when a shop opens
		if context.joker_main then
			return
			{
				chips = card.ability.extra.chips
			}
		end
	end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_library'), HEX('998350'), HEX('0cf07e'), 1.2 )
 	end,
	check_for_unlock = function(self, args)
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_riff_raff" then
                if get_joker_win_sticker(v, true) >= 8 then
                    return true
                end
                break
            end
        end
    end
}