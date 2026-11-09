SMODS.Joker {
	key = 'pip_alt',
	name = "Crew member of The Pequod, Pip",
	pronouns = "he_him",
	config = { extra = { chips = 30} },
	unlocked = false,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,	
	rarity = 1,
	cost = 4,
    atlas = 'ModdedProjectMoon',
	pos = { x = 4, y = 10 },
	attributes = {'chips', 'pallid'},
    pools =
	{

 	},
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.m_pmcmod_pallid
		return { vars = { card.ability.extra.chips } }
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.play and SMODS.has_enhancement(context.other_card, 'm_pmcmod_pallid') then
			return {
                chips = card.ability.extra.chips
            }
        end
    end,
	in_pool = function(self, args)
		local jokers = (G and G.jokers and G.jokers.cards) or {}
		for i = 1, #jokers do
			local center = jokers[i].config and jokers[i].config.center
			if center and center.key == 'j_pmcmod_pip' then return false end
		end
        for _, playing_card in ipairs(G.playing_cards or {}) do
            if SMODS.has_enhancement(playing_card, 'm_pmcmod_pallid') then
                return true
            end
        end
        return false
    end,
	get_weight = function(self, weight)
		local pallid_card_tally = 0
		if G.GAME.blind then
			if G.playing_cards then
				for _, playing_card in ipairs(G.playing_cards) do
					if SMODS.has_enhancement(playing_card, 'm_pmcmod_pallid') then pallid_card_tally = pallid_card_tally + 1 end
				end
			end
		end
    	return PMCMOD.bonus_weight(weight, pallid_card_tally)
	end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_pequod'), HEX('c9c9c9'), HEX('c20a0a'), 1.2 )
 	end,
	check_for_unlock = function(self, args)
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_pmcmod_pip" then
                if get_joker_win_sticker(v, true) >= 1 then
                    return true
                end
                break
            end
        end
    end
}
