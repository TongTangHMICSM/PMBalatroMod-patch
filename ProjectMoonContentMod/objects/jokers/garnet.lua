-- Garnet copies a random working Keypage. Prescripts, Yuri and the hidden Charge manager are
-- not playable copies, so they are skipped.
local GARNET_SKIP = { j_pmcmod_yuri = true, j_pmcmod_chargeManager = true }

-- Numeric view of a card's ability: the usual stats plus every numeric counter in extra.
-- Deltas are measured against the baseline saved when the copy was made, never against the
-- centre config, so a static value like Driver's License's X3 never reads as accumulation.
local GARNET_STATS = {'mult', 'x_mult', 'xmult', 'chips', 'x_chips', 'dollars', 'extra_value'}

local function garnet_snapshot(card)
	local out, a = {}, card.ability
	for _, k in ipairs(GARNET_STATS) do
		if type(a[k]) == 'number' then out[k] = a[k] end
	end
	if type(a.extra) == 'table' then
		for k, v in pairs(a.extra) do
			if type(v) == 'number' then out['extra.' .. k] = v end
		end
	end
	return out
end

local function garnet_delta(card)
	local out = {}
	local base = card.ability.garnet_base
	if type(base) ~= 'table' then return out end
	for k, v in pairs(garnet_snapshot(card)) do
		local b = base[k]
		if type(b) == 'number' and v ~= b then out[k] = v - b end
	end
	return out
end

local function garnet_apply(card, stats)
	local a = card.ability
	-- SMODS can hand out the centre's own extra table; copying it keeps the transfer
	-- from permanently raising the base stats of every later copy of that Keypage
	if type(a.extra) == 'table' then a.extra = copy_table(a.extra) end
	for k, d in pairs(stats) do
		local sub = k:match('^extra%.(.+)$')
		if sub then
			if type(a.extra) == 'table' and type(a.extra[sub]) == 'number' then
				a.extra[sub] = a.extra[sub] + d
			end
		elseif type(a[k]) == 'number' then
			a[k] = a[k] + d
		end
	end
end

local function garnet_num(v)
	if v == math.floor(v) then return tostring(math.floor(v)) end
	return tostring(v)
end

-- What the copy has accumulated since it appeared, for the tooltip.
local function garnet_summary(card)
	if not card then return 'nothing' end
	local d = garnet_delta(card)
	local parts = {}
	if d.mult then parts[#parts + 1] = '+' .. garnet_num(d.mult) .. ' Mult' end
	local xm = d.x_mult or d.xmult
	if xm then parts[#parts + 1] = '+' .. garnet_num(xm) .. 'x' end
	if d.chips then parts[#parts + 1] = '+' .. garnet_num(d.chips) .. ' Chips' end
	if d.x_chips then parts[#parts + 1] = '+' .. garnet_num(d.x_chips) .. 'x Chips' end
	if d.dollars then parts[#parts + 1] = '+$' .. garnet_num(d.dollars) end
	if d.extra_value then parts[#parts + 1] = '+$' .. garnet_num(d.extra_value) end
	for k, v in pairs(d) do
		local sub = k:match('^extra%.(.+)$')
		if sub and sub ~= 'mult' and sub ~= 'chips' and sub ~= 'x_mult' and sub ~= 'xmult' then
			parts[#parts + 1] = '+' .. garnet_num(v) .. ' ' .. sub
		end
	end
	return #parts > 0 and table.concat(parts, ', ') or 'nothing'
end

function PMCMOD.garnet_transfer(from, to)
	if from and to then garnet_apply(to, garnet_stats(from)) end
end

-- Draw a new copy. The old copy's accumulated value is carried into the new one, so swapping
-- never resets progress; the old card is dissolved.
function PMCMOD.garnet_reroll(card)
	local area = ProjectMoonMod.garnetJoker
	if not area then return end

	local pool = {}
	for _, jkr in ipairs(G.P_CENTER_POOLS['Joker']) do
		if jkr.key ~= card.config.center.key and jkr.unlocked and jkr.blueprint_compat
			and not jkr.no_collection and not PMCMOD.is_prescript_key(jkr.key)
			and not GARNET_SKIP[jkr.key] then
			pool[#pool + 1] = jkr.key
		end
	end
	if #pool == 0 then return end

	local key = pseudorandom_element(pool, pseudoseed('garnet'))
	local old = area.cards[#area.cards]
	local carried = old and garnet_delta(old) or {}
	card.ability.selectedJoker = key

	if old then
		G.E_MANAGER:add_event(Event({
			func = function()
				card:juice_up(0.8, 0.8)
				old:start_dissolve({G.C.RED}, nil, 1.6)
				return true
			end
		}))
	end

	local new = SMODS.add_card({ key = key, area = area })
	if new then
		garnet_apply(new, carried)
		new.ability.garnet_base = garnet_snapshot(new)
	end
end

SMODS.Joker {
	key = 'garnet',
	name = "Garnet",
	pronouns = "he_him",
	config = { selectedJoker = "None", extra = {} }, -- Removed availableJokers from config to prevent save bloat
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
	atlas = 'ModdedProjectMoon2',
	pos = { x = 3, y = 2 },
	attributes = {'random', 'copying'},
	pools = {
		["Thumb"] = true,
		["Middle"] = true,
		["Ring"] = true,
		["Pinky"] = true,
		["Bloodfiends"] = true,
		["LCorp"] = true,
		["Limbus"] = true,
		["Sinners"] = true,
	},

	loc_vars = function(self, info_queue, card)
		local keyToLocalize = "j_pmcmod_garnet"
		
		-- Safety check: Ensure the key is a string, isn't corrupted, and actually exists in the game database
		if type(card.ability.selectedJoker) == "string" 
		and card.ability.selectedJoker ~= "None" 
		and card.ability.selectedJoker ~= "MANUAL_REPLACE" 
		and G.P_CENTERS[card.ability.selectedJoker] then
			
			keyToLocalize = card.ability.selectedJoker
			card.children.center:set_sprite_pos({x = 0, y = 10})
			
			-- FIX: Pass the full Joker definition object so the UI generator has all the ability data
			info_queue[#info_queue+1] = G.P_CENTERS[card.ability.selectedJoker]
		else
			-- Fallback if the saved data is corrupted, empty, or missing
			card.children.center:set_sprite_pos(self.pos)
		end

		local copy = ProjectMoonMod.garnetJoker and ProjectMoonMod.garnetJoker.cards[#ProjectMoonMod.garnetJoker.cards]
		return { vars = { localize{type = "name_text", set = "Joker", key = keyToLocalize}, garnet_summary(copy) } }
	end,
	calculate = function(self, card, context)
		local area = ProjectMoonMod.garnetJoker
		if not area then return end

		-- first copy when he lands, so he is never dead weight for his first Scene
		if context.setting_blind and not context.blueprint and #area.cards == 0 then
			PMCMOD.garnet_reroll(card)
		end

		-- the copy's own shop-end effects have to fire before it is replaced: the blueprint pass
		-- below runs on this context, and the reroll only lands afterwards
		local reroll = context.ending_shop and not context.blueprint

		local current = area.cards[#area.cards]
		local ret = current and SMODS.blueprint_effect(card, current, context) or nil

		if reroll then PMCMOD.garnet_reroll(card) end

		if ret then
			ret.colour = G.C.BLUE
			return ret
		end

		-- released on sale: the Keypage he was copying walks out as a real card, with his
		-- Edition and Rental, keeping everything it accumulated
		if context.selling_self and not context.blueprint then
			local copy = area.cards[#area.cards]
			if copy then
				local made = SMODS.add_card({ key = copy.config.center.key })
				if made then
					if card.edition then made:set_edition(card.edition) end
					made:set_rental(true)
					PMCMOD.garnet_transfer(copy, made)
				end
				copy:start_dissolve({G.C.RED}, nil, 1.6)
			end
		end
	end,

	set_badges = function(self, card, badges)
		badges[#badges+1] = create_badge(localize('pmcmod_badge_fixer'), G.C.BLACK, G.C.WHITE, 1.2)
	end,

	check_for_unlock = function(self, args)
		if args.type == 'discard_custom' then
			local eval = evaluate_poker_hand(args.cards)
			
			-- Changed from 'Flush House' to 'Straight Flush' for a true Royal Flush check
			if next(eval['Straight Flush']) then
				local min = 14 -- Start high, looking for the lowest card
				for j = 1, #args.cards do
					if args.cards[j]:get_id() < min then 
						min = args.cards[j]:get_id() 
					end
				end
				-- If the lowest card in a Straight Flush is 10, it's a Royal Flush
				if min == 10 then
					return true
				end
			end
		end
		return false
	end
}
