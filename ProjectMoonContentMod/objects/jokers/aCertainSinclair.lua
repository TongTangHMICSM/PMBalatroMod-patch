SMODS.Joker {
	key = 'aCertainSinclair',
	name = "A Certain Sinclair",
	pronouns = "he_him",
	config = { extra = { counter = 0, currentPosition = 1 } },
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 10,
    atlas = 'ModdedProjectMoon2',
	pos = { x = 7, y = 6 },
	attributes = {'position', 'retrigger'},
    pools =
	{
		["Sinners"] = true,
 	},
	loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.counter } }
	end,
	calculate = function(self, card, context)
		if context.before then
			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i] == card then
					card.ability.extra.currentPosition = i
					break
				end
			end
		end

		-- Count the left neighbour's triggers, reported by PMCMOD's trigger reporter in the main
		-- file: every joker that returns an effect for a real context is broadcast with
		-- context.other_card, so silent keypages only need to return something (see ren.lua).
		if context.pmcmod_trigger and not context.blueprint then
			local left = G.jokers.cards[card.ability.extra.currentPosition - 1]
			if card.ability.extra.currentPosition > 1 and left and context.other_card
				and left.config.center.key == context.other_card.config.center.key then
				card.ability.extra.counter = card.ability.extra.counter + 1
			end
		end

		-- Retrigger the Keypage to the right by that amount, once per hand, which is what
		-- joker_main is. SMODS's retrigger API cannot target another joker - answering
		-- retrigger_joker_check only repeats the joker that answers (src/utils.lua:1704-1708
		-- re-evaluates that card, retrigger_card just tags the context) - so the neighbour's effect
		-- is re-invoked directly and applied through SMODS.calculate_effect. Per-card effects are
		-- deliberately not replayed; that would multiply the payout by the cards played.
		if context.joker_main and not context.blueprint then
			local right = G.jokers.cards[card.ability.extra.currentPosition + 1]

			if right and right.calculate_joker and card.ability.extra.counter > 0 then
				for _ = 1, card.ability.extra.counter do
					-- Hand the neighbour a copy: jokers write into the context they are given
					-- (Blueprint sets context.blueprint / blueprint_card), and those writes must not
					-- leak into the engine's live context - other Keypages read it, and e.g. jiaXichun
					-- guards every increment with `if not context.blueprint then`.
					local copy = {}
					for k, v in pairs(context) do copy[k] = v end
					-- pcall: a neighbour that errors must not abort the rest of the hand
					local ok, eff = pcall(right.calculate_joker, right, copy)
					if not ok then
						local who = right.config and right.config.center and right.config.center.key
						print("pmcmod aCertainSinclair: retriggering " .. tostring(who) .. " failed: " .. tostring(eff))
					end
					if ok and type(eff) == 'table' and not eff.repetitions and not eff.remove then
						SMODS.calculate_effect(eff, right)
					end
				end
			end
		end

		if context.after then
			card.ability.extra.counter = 0
		end
	end,
	check_for_unlock = function(self, args)
		local callistoOK = false
		local albinaOK = false
        for _, v in pairs(G.P_CENTER_POOLS["Joker"]) do
            if v.key == "j_pmcmod_callisto" then
                if get_joker_win_sticker(v, true) >= 1 then
                    callistoOK = true
                end
            end
			if v.key == "j_pmcmod_albina" then
                if get_joker_win_sticker(v, true) >= 1 then
                    albinaOK = true
                end
            end
        end

		if callistoOK and albinaOK then
			return true
		end
    end,
	set_badges = function(self, card, badges)
 		badges[#badges+1] = create_badge(localize('pmcmod_badge_abraxas'), G.C.BLACK, G.C.WHITE, 1.2 )
 	end,
}