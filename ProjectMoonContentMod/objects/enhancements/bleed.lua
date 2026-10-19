SMODS.Enhancement {
    key = "bleed",
    atlas = "ModdedProjectMoonEditions",
    pos = { x = 2, y = 2},
    config = { },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = {set = "Other", key = "effect_perma"}
        return { vars = { 1 + PMCMOD.tremor_count() }}
    end,
    calculate = function(self, card, context)

        if context.main_scoring and context.cardarea == G.play then

            -- Tremor reads the deck, not the hand: it amplifies while simply sitting there
            local tremorCounting = PMCMOD.tremor_count()

        --if context.individual and context.cardarea == G.play and SMODS.has_enhancement(context.other_card, 'm_pmcmod_bleed') then
            -- ability.mult is what Card:get_chip_mult reads, so the gain actually scores.
            -- perma_mult is never applied to a playing card, but it is the counter other Keypages
            -- consume (donQuixote turns it into chips, araya/hongLu/wangDawei add to it), so Bleed
            -- feeds both.
            -- A Bleed card pays for itself only: +1 for its own score, +1 more per Tremor
            local gain = 1 + tremorCounting
            card.ability.mult = (card.ability.mult or 0) + gain
            card.ability.perma_mult = (card.ability.perma_mult or 0) + gain

            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.MULT
            }
        end
    end,
    update = function(self, card, dt)
        
    end,
    set_sprites = function(self, card, front)
    G.E_MANAGER:add_event(Event({
      blockable = false,
      func = function()
        card.canvas_text = SMODS.CanvasSprite {
          canvasW = 71, canvasH = 95,
          text_offset = { x = 10, y = 86 },
          text_colour = HEX('ded5d3'),
          text_width = 15,
          text_height = 10,
          ref_table = card.ability,
          ref_value = "mult",
          text = "?"
        }
        return true
      end
    }))
    end,
}