SMODS.Joker {
	key = 'silence',
	name = "Time Flowing",
	pronouns = "it_its",
	config = { extra = { current_timer = 0, total_timer = 30, display_timer = '0' } },
	no_collection = true,
	eternal_compat = true,
	perishable_compat = false,
	blueprint_compat = false,
	rarity = 3,
	cost = 8,
	atlas = 'ModdedProjectMoon',
	pos = { x = 5, y = 15 },
	attributes = {'timer', 'game_over'},
	loc_vars = function (self, info_queue, card)
		local extra = card.ability.extra
		local main_end = {
			{n=G.UIT.T, config={text = localize('pmcmod_elapsedTime')..":", colour = G.C.MULT, scale = 0.32}},
			-- Bound to a live field (not a snapshot string) so the readout ticks
			-- while the tooltip is open - DynaText re-reads ref_table[ref_value]
			-- every frame.
			{n=G.UIT.O, config={object = DynaText({
				string = {{ref_table = extra, ref_value = 'display_timer'}},
				colours = {G.C.RED}, pop_in_rate = 9999999, silent = true,
				pop_delay = 0.2011, scale = 0.32, min_cycle_time = 0})}},
			{n=G.UIT.T, config={text = "/ "..extra.total_timer..localize('pmcmod_seconds'), colour = G.C.MULT, scale = 0.32}},
		}
		return {main_end = main_end, vars = { math.floor(extra.current_timer), extra.total_timer }}
	end,
	update = function (self, card, dt)
		local extra = card.ability.extra
		local in_blind = G.GAME.blind and G.GAME.blind.in_blind

		-- Only the player's own turn counts: while they can actually pick and play
		-- cards. The blind intro, scoring/cash-out animations, booster packs, the
		-- shop and the pause menu no longer drain the clock.
		local counting = in_blind
			and G.STATE == G.STATES.SELECTING_HAND
			and not (G.SETTINGS and G.SETTINGS.paused)

		if counting then
			-- G.real_dt is raw wall-clock seconds per frame, so this is independent of
			-- the Game Speed setting. Clamped so a frame hitch or an alt-tab spike
			-- can't swallow a chunk of the timer at once.
			extra.current_timer = extra.current_timer + math.min(G.real_dt or 0, 0.1)
		end

		-- Live readout used by the tooltip DynaText above.
		extra.display_timer = tostring(math.floor(extra.current_timer))

		-- Sprite frames still track the timer even when it is not counting.
		if card.children and card.children.center then
			local t = extra.current_timer
			if t < 7 then
				card.children.center:set_sprite_pos({x = 5, y = 15})
			elseif t < 14 then
				card.children.center:set_sprite_pos({x = 6, y = 15})
			elseif t < 21 then
				card.children.center:set_sprite_pos({x = 7, y = 15})
			elseif t < 29 then
				card.children.center:set_sprite_pos({x = 8, y = 15})
			else
				card.children.center:set_sprite_pos({x = 9, y = 15})
			end
		end

		-- Fresh clock for every encounter.
		if not in_blind then
			extra.current_timer = 0
			extra.display_timer = '0'
		end

		if counting and extra.current_timer >= extra.total_timer then
			extra.current_timer = 0
			extra.display_timer = '0'
			G.E_MANAGER:add_event(Event({
				func = function()
					G.STATE = G.STATES.GAME_OVER
					G.STATE_COMPLETE = false
					return true
				end
			}))
		end
	end,
	in_pool = function(self, args)
		return G.GAME.pool_flags.fake_silent_flag
	end,
	set_badges = function(self, card, badges)
		badges[#badges+1] = create_badge(localize('pmcmod_badge_abnormality'), G.C.BLACK, HEX('9e13bd'), 1.2 )
	end
}
