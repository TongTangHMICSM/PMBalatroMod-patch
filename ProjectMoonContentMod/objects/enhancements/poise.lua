-- Cards made before this config existed carry an older ability table: no counter, no maxChance,
-- and x_mult instead of extra.xmult. Arithmetic on the missing counter throws, and SMODS swallows it,
-- so the whole enhancement silently did nothing.
local function ensure_ability(card)
    local a = card.ability
    if type(a.counter) ~= 'number' then a.counter = 0 end
    if type(a.maxChance) ~= 'number' then a.maxChance = 10 end
    if type(a.baseChance) ~= 'number' then a.baseChance = 1 end
    if type(a.maxChanceShiomi) ~= 'number' then a.maxChanceShiomi = 2 end
    if type(a.extra) ~= 'table' then a.extra = { xmult = 2 } end
    if type(a.extra.xmult) ~= 'number' then
        a.extra.xmult = (type(a.x_mult) == 'number' and a.x_mult > 1) and a.x_mult or 2
    end
end

-- One stack for the whole board, not one per card.
local function shared(delta)
    if not G.GAME then return 0 end
    G.GAME.pmcmod_poise_stack = G.GAME.pmcmod_poise_stack or 0
    if delta then
        G.GAME.pmcmod_poise_stack = math.max(0, G.GAME.pmcmod_poise_stack + delta)
    end
    return G.GAME.pmcmod_poise_stack
end

SMODS.Enhancement {
    key = "poise",
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 5, y = 2},
    config = { counter = 0, baseChance = 1, maxChance = 10, maxChanceShiomi = 2, extra = {xmult = 2}},
    loc_vars = function(self, info_queue, card)
        
        local stack = shared(0)
        local new_numerator, new_denominator = SMODS.get_probability_vars(card, stack, math.max(1, (card.ability.maxChance or 10) - 0.1 * PMCMOD.tremor_count()), 'poise')
        local new_numeratorShiomi, new_denominatorShiomi = SMODS.get_probability_vars(card, card.ability.baseChance, card.ability.maxChanceShiomi, 'shiomi')
        return {vars = { (card.ability.extra and card.ability.extra.xmult) or 2, stack, new_numerator, new_denominator, new_numeratorShiomi, new_denominatorShiomi } }
    end,
    calculate = function(self, card, context)
        ensure_ability(card)

        -- Tremor reads the deck, not the hand: it amplifies while simply sitting there
        local tremorCounting = PMCMOD.tremor_count()

        if context.main_scoring and context.cardarea == G.play then
            local ret = {}
            local shiomiPresent = false
            local renPresent = false

            for i=1, #G.jokers.cards do

                if G.jokers.cards[i].config.center.key == "j_pmcmod_shiomiYoru" then
                    shiomiPresent = true
                    break
                end

                if G.jokers.cards[i].config.center.key == "j_pmcmod_ren" then
                    renPresent = true
                    break
                end

            end

            if shiomiPresent then
                if renPresent then
                    shared(3 * (1 + tremorCounting))
                else
                    shared(2 * (1 + tremorCounting))
                end
            else
                shared(1 * (1 + tremorCounting))
            end

            ensure_ability(card)
            -- Tremor narrows the denominator: X in (10 - 0.1 per Tremor card)
            local denominator = math.max(1,
                (card.ability.maxChance or 10) - 0.1 * tremorCounting)
            if SMODS.pseudorandom_probability(card, 'poise', shared(0),
                denominator, 'poise') then
                ret.xmult = (card.ability.extra and card.ability.extra.xmult) or 2
                card.poise_trigger = true
                -- halve the shared stack on a trigger rather than resetting it
                if G.GAME then
                    G.GAME.pmcmod_poise_stack = math.max(1, math.floor(shared(0) / 2))
                end

                -- played here rather than from a queued event: the mod's other sounds are all
                -- triggered inline, and a sound queued mid-scoring can be dropped
                play_sound('pmcmod_poiseTrigger', 1.0, 0.9)
                G.E_MANAGER:add_event(Event {
                func = function()
                    card.poise_trigger = false
                    return true
                end
            })

            end
            
            return ret

        end

        
    end,
    update = function(self, card, dt)
        ensure_ability(card)
        
    end,
    set_sprites = function(self, card, front)
    G.E_MANAGER:add_event(Event({
      blockable = false,
      func = function()
        card.canvas_text = SMODS.CanvasSprite {
          canvasW = 71, canvasH = 95,
          text_offset = { x = 9, y = 86 },
          text_colour = G.C.UI.TEXT_DARK,
          text_width = 15,
          text_height = 10,
          ref_table = G.GAME,
          ref_value = "pmcmod_poise_stack",
          text = "?"
        }
        return true
      end
    }))
    end,
}