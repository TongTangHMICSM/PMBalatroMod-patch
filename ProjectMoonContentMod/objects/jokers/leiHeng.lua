SMODS.Joker {
	key = 'leiHeng',
	name = "Lei Heng",
	pronouns = "he_him",
	config = { extra = { my_pos = 1 } },
	unlocked = true,	
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
    atlas = 'ModdedProjectMoon2',
	pos = { x = 3, y = 5 },
	attributes = {'position', 'retrigger', 'ammo', 'position'},
    pools =
	{
		["Thumb"] = true,
 	},
	loc_vars = function(self, info_queue, card)
        return {vars = {  } }
	end,
	calculate = function(self, card, context)
		if context.before then
			for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == card then
                    card.ability.extra.my_pos = i
                    break
                end
            end
		end
		
		if context.retrigger_joker_check and context.other_card == G.jokers.cards[card.ability.extra.my_pos -1] then
			local coinToss = pseudorandom('pmcmod_leiHeng_toss', 0, 4)
			local neighbour = G.jokers.cards[card.ability.extra.my_pos -1]

			-- Eternal Keypages cannot be destroyed. SMODS.destroy_cards refuses them on its own
			-- (src/utils.lua:3064 checks SMODS.is_eternal), and we ask here too so that a protected
			-- neighbour turns the slice into a retrigger instead of quietly wasting the toss.
			local can_destroy = neighbour and not SMODS.is_eternal(neighbour, { destroy_cards = true })

			if coinToss == 0 and can_destroy then
                -- `self` here is the SMODS object, not the card, so this check never saw the real flag
                if not (context.blueprint_card or card).getting_sliced then
                    G.E_MANAGER:add_event(Event({func = function()
                        card:juice_up(0.8, 0.8)
                        SMODS.destroy_cards(neighbour, { colours = {G.C.RED}, dissolve_time_fac = 1.6 })
                    return true end }))
                end
			else
				return {
					repetitions = coinToss == 0 and 1 or coinToss
				}
			end
		end
    end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_spiders'), HEX('121212'), HEX('d90000'), 1.2 )
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