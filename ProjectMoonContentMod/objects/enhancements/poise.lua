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

SMODS.Enhancement {
    key = "poise",
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 5, y = 2},
    config = { counter = 0, baseChance = 1, maxChance = 10, maxChanceShiomi = 2, extra = {xmult = 2}},
    loc_vars = function(self, info_queue, card)
        
        local new_numerator, new_denominator = SMODS.get_probability_vars(card, card.ability.counter, card.ability.maxChance, 'poise')
        local new_numeratorShiomi, new_denominatorShiomi = SMODS.get_probability_vars(card, card.ability.baseChance, card.ability.maxChanceShiomi, 'shiomi')
        return {vars = { card.ability.extra.xmult, card.ability.counter, new_numerator, new_denominator, new_numeratorShiomi, new_denominatorShiomi } }
    end,
    calculate = function(self, card, context)
        ensure_ability(card)

        local tremorCounting = 0

        for i = 1, #G.play.cards do
            if SMODS.has_enhancement(G.play.cards[i], 'm_pmcmod_tremor') then
                tremorCounting = tremorCounting + 1
            end
        end

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
                    card.ability.counter = card.ability.counter + (3 * (1 + tremorCounting))
                else
                    card.ability.counter = card.ability.counter + (2 * (1 + tremorCounting))
                end
            else
                card.ability.counter = card.ability.counter + (1 * (1 + tremorCounting))
            end

            if SMODS.pseudorandom_probability(card, 'poise', card.ability.counter, card.ability.maxChance, 'poise') then
                ret.xmult = card.ability.extra.xmult
                card.poise_trigger = true
                -- halve on a trigger rather than dropping back to 1
                card.ability.counter = math.max(1, math.floor(card.ability.counter / 2))

                G.E_MANAGER:add_event(Event {
                func = function()
                    play_sound('pmcmod_poiseTrigger', 0.9, 0.9)
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
          ref_table = card.ability,
          ref_value = "counter",
          text = "?"
        }
        return true
      end
    }))
    end,
}