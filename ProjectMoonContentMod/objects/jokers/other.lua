-- Dummy Ricardo
SMODS.Joker {
	key = 'dummyRicardo',
	name = "Dummy Ricardo",
	pronouns = "it_its",
	config = { extra = { ricardoDefeatCounter = 0, canSpawnRicardo = false, baseChance = 1, maxChance = 3} },
	no_collection = true,
	perishable_compat = true,
	eternal_compat = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
    atlas = 'ModdedProjectMoon',
	pos = { x = 5, y = 4 },
    pools =
	{

 	},
	loc_vars = function(self, info_queue, card)
		local new_numerator, new_denominator = SMODS.get_probability_vars(card, card.ability.extra.baseChance, card.ability.extra.maxChance, 'wernerChance')
		return { vars = { card.ability.extra.ricardoDefeatCounter, card.ability.extra.canSpawnRicardo, new_numerator, new_denominator } }
	end,
	calculate = function(self, card, context)

		if context.joker_type_destroyed and context.card.config.center.key == "j_pmcmod_ricardo" then
--			print("Testing Ricardo increment")
			if not context.blueprint then card.ability.extra.ricardoDefeatCounter = card.ability.extra.ricardoDefeatCounter + 1 end
			card.ability.extra.canSpawnRicardo = true
		end

		if context.ending_shop and not context.blueprint and G.jokers and card.ability.extra.canSpawnRicardo == true then
			SMODS.add_card({ key = "j_pmcmod_ricardo" })
			if SMODS.pseudorandom_probability(card, 'seed', card.ability.extra.baseChance, card.ability.extra.maxChance, 'wernerChance') then
				SMODS.add_card({ key = "j_pmcmod_werner" })
			end
			card.ability.extra.canSpawnRicardo = false
		end
    end,
	in_pool = function(self, args)
        return G.GAME.pool_flags.fake_robot_flag
    end,
}

-- Charge manager
-- Invisible helper that lives in ProjectMoonMod.dummyJoker (spawned in
-- ProjectMoonContentMod.lua). Steamodded 26.1002.0 never evaluates an Edition's
-- `calculate`, so this card is the only place the Charge edition's shared pool can
-- be fed and spent. It never enters a shop, pack or the collection.
SMODS.Joker {
	key = 'chargeManager',
	name = "Charge Manager",
	pronouns = "it_its",
	config = { extra = {} },
	no_collection = true,
	unlocked = true,
	eternal_compat = false,
	perishable_compat = false,
	blueprint_compat = false,
	rarity = 1,
	cost = 0,
	atlas = 'ModdedProjectMoon',
	pos = { x = 5, y = 4 },
	loc_vars = function(self, info_queue, card)
		return { vars = { PMCMOD.get_charge() } }
	end,
	calculate = function(self, card, context)
		-- Feed the pool: a scored page holding the Charge edition
		if context.individual and context.cardarea == G.play and not context.blueprint then
			local scored = context.other_card
			if scored and scored.edition and scored.edition.key == 'e_pmcmod_charge' then
				PMCMOD.add_charge(PMCMOD.charge_gain())
			end
		end

		-- Feed the pool: a Keypage holding the Charge edition, once per hand
		if context.joker_main and not context.blueprint then
			local jokers = (G.jokers and G.jokers.cards) or {}
			for i = 1, #jokers do
				if jokers[i].edition and jokers[i].edition.key == 'e_pmcmod_charge' then
					PMCMOD.add_charge(PMCMOD.charge_gain())
				end
			end
		end

		-- Spend 5 charges (-5, leftovers carry over) to score the first card twice
		if not context.blueprint and context.repetition and context.cardarea == G.play
			and context.scoring_hand and context.other_card == context.scoring_hand[1]
			and PMCMOD.get_charge() >= 5 and PMCMOD.has_charge_keypage() then
			PMCMOD.add_charge(-5)
			return { repetitions = 1 }
		end
	end,
	in_pool = function(self, args)
		return false
	end,
}