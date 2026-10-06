-- The Charge edition has no `calculate` on purpose: Steamodded 26.1002.0 never calls
-- an Edition's calculate (the only call site is commented out in src/overrides.lua,
-- and Card:calculate_edition has no callers). Its shared charge pool is driven by the
-- hidden `chargeManager` joker in objects/jokers/other.lua - see PMCMOD.get_charge,
-- PMCMOD.add_charge and PMCMOD.charge_gain in ProjectMoonContentMod.lua.
SMODS.Edition {
    key = 'charge',
    shader = 'pmcmod_charge',
    config = {},
    in_shop = true,
    weight = 3,
    extra_cost = 5,
    sound = { sound = "negative", per = 1.5, vol = 0.4 },
    loc_vars = function(self, info_queue, card)
        return { vars = { PMCMOD.get_charge and PMCMOD.get_charge() or 0 } }
    end,
    get_weight = function(self)
        return self.weight
    end,
}
