SMODS.Joker {
	key = 'queenOfHatred',
	name = "Queen of Hatred",
	config = { extra = { cardsDiscarded = 0, cardsPlayed = 0, transformTime = 0, currentCount = 0, multScale = 0.5, bonusChips = 100} },
	unlocked = true,
	eternal_compat = true,
	perishable_compat = true,
    blueprint_compat = false,
	rarity = 3,
	cost = 8,
	atlas = 'ModdedProjectMoon',
	pos = { x = 0, y = 13 },
	loc_vars = function (self, info_queue, card)
    	return {vars = { card.ability.extra.cardsDiscarded, card.ability.extra.cardsPlayed, card.ability.extra.multScale, card.ability.extra.bonusChips * G.GAME.round_resets.ante, card.ability.extra.cardsDiscarded - card.ability.extra.cardsPlayed, card.ability.extra.cardsPlayed - card.ability.extra.cardsDiscarded, card.ability.extra.transformTime, math.abs(card.ability.extra.cardsDiscarded - card.ability.extra.cardsPlayed)}}
	end,
    update = function(self, card, dt)
        if G.STAGE == G.STAGES.RUN then
            local diff = math.abs(card.ability.extra.cardsDiscarded - card.ability.extra.cardsPlayed)
            local target_x = 2 -- Default (diff 7 to 10)
            
            if card.ability.extra.transformTime > 0 then
                target_x = 4 -- Transformed state
            elseif diff < 4 then
                target_x = 0
            elseif diff < 7 then
                target_x = 1
            elseif diff <= 10 then
                target_x = 2
            elseif diff <= 14 then
                target_x = 3
            else
                target_x = 4
            end
            
            if card.children.center and card.children.center.sprite_pos.x ~= target_x then
                card.children.center:set_sprite_pos({x = target_x, y = 13})
            end
        end
    end,
	calculate = function(self, card, context)
        -- Track played cards
        if context.cardarea == G.jokers and context.before and not context.blueprint then
            card.ability.extra.cardsPlayed = card.ability.extra.cardsPlayed + #context.full_hand
        end
        
        -- Track discarded cards
        if context.discard and not context.blueprint then
            card.ability.extra.cardsDiscarded = card.ability.extra.cardsDiscarded + 1
        end

        local diff = math.abs(card.ability.extra.cardsDiscarded - card.ability.extra.cardsPlayed)

        -- Transformation recovery and disabling
        if context.end_of_round and not context.blueprint and not context.repetition then
            if card.ability.extra.transformTime > 0 then
                card.ability.extra.transformTime = card.ability.extra.transformTime - 1
                if card.ability.extra.transformTime == 0 then
                    -- Reset value difference to 9 (e.g. 9 discarded, 0 played)
                    card.ability.extra.cardsPlayed = 0
                    card.ability.extra.cardsDiscarded = 9
                end
            end
        end

        if context.setting_blind and not context.blueprint then
            -- Trigger transformation if difference > 14
            if diff > 14 and card.ability.extra.transformTime == 0 then
                card.ability.extra.transformTime = 3
            end

            -- If transformed, disable a random Keypage (Joker)
            if card.ability.extra.transformTime > 0 then
                local valid_jokers = {}
                for i = 1, #G.jokers.cards do
                    if G.jokers.cards[i] ~= card and not G.jokers.cards[i].debuff then
                        valid_jokers[#valid_jokers+1] = G.jokers.cards[i]
                    end
                end
                if #valid_jokers > 0 then
                    local chosen = pseudorandom_element(valid_jokers, pseudoseed('qoh'))
                    chosen.ability.pmcmod_qoh_disabled = true
                    chosen:set_debuff(true)
                    card_eval_status_text(card, 'extra', nil, nil, nil, {message = "Transformed!"})
                    card_eval_status_text(chosen, 'extra', nil, nil, nil, {message = "Disabled!"})
                end
            end
        end

        -- Retrigger all jokers if diff < 4
        if context.retrigger_joker_check and not context.blueprint then
            if card.ability.extra.transformTime == 0 and diff < 4 then
                if context.other_card ~= card then
                    return {
                        message = localize('k_again_ex'),
                        repetitions = 1,
                        card = card
                    }
                end
            end
        end

        -- Scoring effects
        if context.joker_main and not context.blueprint then
            if card.ability.extra.transformTime == 0 then
                if diff >= 4 and diff < 7 then
                    return {
                        message = localize{type='variable',key='a_chips',vars={card.ability.extra.bonusChips * G.GAME.round_resets.ante}},
                        chips = card.ability.extra.bonusChips * G.GAME.round_resets.ante,
                        colour = G.C.CHIPS
                    }
                elseif diff > 10 and diff <= 14 then
                    return {
                        message = localize{type='variable',key='a_xmult',vars={card.ability.extra.multScale}},
                        Xmult_mod = card.ability.extra.multScale
                    }
                end
            end
        end
	end
}