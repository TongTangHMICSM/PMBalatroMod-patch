sendDebugMessage("Launching Project Moon Content Mod!", "ProjectMoonContentMod")

ProjectMoonMod = {}

PMCMOD = SMODS.current_mod

-------------------------------------------------------------------------------
-- Shared Charge pool (the Charge edition)
--
-- Steamodded 26.1002.0 never calls an Edition's `calculate`: the only call site is
-- commented out in src/overrides.lua, and Card:calculate_edition has no callers.
-- So the Charge edition cannot drive itself. A hidden manager card in the dummy
-- joker area (objects/jokers/other.lua, key 'chargeManager') feeds and spends this
-- pool instead.
-------------------------------------------------------------------------------

function PMCMOD.get_charge()
    return (G.GAME and G.GAME.pmcmod_charge_pool) or 0
end

function PMCMOD.add_charge(amount)
    if not G.GAME then return end
    G.GAME.pmcmod_charge_pool = math.max(0, (G.GAME.pmcmod_charge_pool or 0) + (amount or 1))
end

-- Charges gained per trigger: 2 while Tiph B (robotEnoch) is in play
function PMCMOD.charge_gain()
    local jokers = (G.jokers and G.jokers.cards) or {}
    for i = 1, #jokers do
        local key = jokers[i].config and jokers[i].config.center and jokers[i].config.center.key
        if key == 'j_pmcmod_robotEnoch' then return 2 end
    end
    return 1
end

-- Only a Keypage holding the Charge edition may spend the pool
function PMCMOD.has_charge_keypage()
    local jokers = (G.jokers and G.jokers.cards) or {}
    for i = 1, #jokers do
        if jokers[i].edition and jokers[i].edition.key == 'e_pmcmod_charge' then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Prescripts and the Index
-- ---------------------------------------------------------------------------
-- Prescripts last PRESCRIPT_SCENES Scenes, then resolve: Grace of the City if the page's objective
-- was met, Karmic Consequence if it was not. Both are run-wide counters (shared across every
-- prescript). Grace also makes Index Keypages more likely to be offered - see PMCMOD.index_weight.
-- The old money swing ($15 on fulfilment, wipe on failure) left the prescripts and now happens only
-- while Voice of the City is held.
PMCMOD.PRESCRIPT_SCENES = 3

-- The Index Keypages that drive the prescript cycle. angelica is deliberately absent: she carries
-- the Index pool as her only pool, so dropping it would leave her with nowhere to come from.
PMCMOD.INDEX_POOL_MEMBERS = {
    'esther', 'gloria', 'hubert', 'rien', 'sora',
}

function PMCMOD.grace()
    return (G.GAME and G.GAME.pmcmod_grace) or 0
end

function PMCMOD.karma()
    return (G.GAME and G.GAME.pmcmod_karma) or 0
end

-- ---------------------------------------------------------------------------
-- Nurse father / apprentice pairs
-- ---------------------------------------------------------------------------
-- Four pairs, each a father and the apprentice that belongs at his right hand:
--   {shiomiYoru, ren}  {rien, sora}  {matthias, kira}  {valencina, lucio}
-- A pair is "linked" only while the apprentice sits EXACTLY to the right of the father. The trigger
-- count is shared between the two cards (one number per pair, identified by the father's key) rather
-- than duplicated on each side.
PMCMOD.PAIRS = {
    shiomiYoru = 'ren',
    rien = 'sora',
    matthias = 'kira',
    valencina = 'lucio',
}

-- SMODS card keys carry the j_pmcmod_ prefix; PMCMOD.PAIRS is written with bare names.
function PMCMOD.bare_key(key)
    if type(key) ~= 'string' then return nil end
    return (key:gsub('^j_pmcmod_', ''))
end

function PMCMOD.pair_father_of(key)
    key = PMCMOD.bare_key(key)
    if not key then return nil end
    if PMCMOD.PAIRS[key] then return key end
    for father, apprentice in pairs(PMCMOD.PAIRS) do
        if apprentice == key then return father end
    end
    return nil
end

function PMCMOD.pair_linked(card)
    local center = card and card.config and card.config.center
    local key = PMCMOD.bare_key(center and center.key)
    local father = PMCMOD.pair_father_of(key)
    if not father then return false end
    local apprentice = PMCMOD.PAIRS[father]
    local jokers = (G.jokers and G.jokers.cards) or {}

    for i = 1, #jokers do
        if jokers[i] == card then
            if key == father then
                local right = jokers[i + 1]
                return (right and PMCMOD.bare_key(right.config.center.key) == apprentice) and true or false
            end
            local left = jokers[i - 1]
            return (left and PMCMOD.bare_key(left.config.center.key) == father) and true or false
        end
    end
    return false
end

-- The shared count lives in G.GAME, so a card's tooltip has no way to know it changed. Mirroring
-- the value onto both cards of the pair (ability.extra.pairCount) gives the UI something to notice.
function PMCMOD.pair_mirror(father, value)
    local jokers = (G.jokers and G.jokers.cards) or {}
    local apprentice = PMCMOD.PAIRS[father]
    for i = 1, #jokers do
        local key = PMCMOD.bare_key(jokers[i].config and jokers[i].config.center and jokers[i].config.center.key)
        if (key == father or key == apprentice) and jokers[i].ability
            and type(jokers[i].ability.extra) == 'table' then
            jokers[i].ability.extra.pairCount = value
        end
    end
end

-- For tooltips only: the shared count plus whether the pair is actually linked right now, so the
-- player can see why it is or is not rising.
function PMCMOD.pair_trigger_display(card)
    local marker = PMCMOD.pair_linked(card) and localize('pmcmod_pairLinked') or localize('pmcmod_pairUnlinked')
    return PMCMOD.pair_triggers(card) .. " (" .. marker .. ")"
end

function PMCMOD.pair_triggers(card)
    local father = PMCMOD.pair_father_of(card and card.config and card.config.center and card.config.center.key)
    if not father or not G.GAME then return 0 end
    G.GAME.pmcmod_pair_triggers = G.GAME.pmcmod_pair_triggers or {}
    return G.GAME.pmcmod_pair_triggers[father] or 0
end

function PMCMOD.set_pair_trigger(card, n)
    local father = PMCMOD.pair_father_of(card and card.config and card.config.center and card.config.center.key)
    if not father or not G.GAME then return end
    G.GAME.pmcmod_pair_triggers = G.GAME.pmcmod_pair_triggers or {}
    G.GAME.pmcmod_pair_triggers[father] = n or 0
    PMCMOD.pair_mirror(father, n or 0)
end

function PMCMOD.add_pair_trigger(card, n)
    local father = PMCMOD.pair_father_of(card and card.config and card.config.center and card.config.center.key)
    if not father or not G.GAME then return end
    G.GAME.pmcmod_pair_triggers = G.GAME.pmcmod_pair_triggers or {}
    G.GAME.pmcmod_pair_triggers[father] = (G.GAME.pmcmod_pair_triggers[father] or 0) + (n or 1)
    PMCMOD.pair_mirror(father, G.GAME.pmcmod_pair_triggers[father])
end

-- What Sora reads: the City's favour net of its consequences. Negative when Karma outweighs Grace.
function PMCMOD.sora_grace()
    return PMCMOD.grace() - PMCMOD.karma()
end

function PMCMOD.voice_of_the_city_in_play()
    local jokers = (G.jokers and G.jokers.cards) or {}
    for i = 1, #jokers do
        local c = jokers[i].config and jokers[i].config.center
        if c and c.key == 'j_pmcmod_voiceOfTheCity' then return true end
    end
    return false
end

-- aspects are the _alt variants - they do not count as Index members
function PMCMOD.is_aspect(key)
    return type(key) == 'string' and key:sub(-4) == '_alt'
end

function PMCMOD.index_member_in_play()
    local jokers = (G.jokers and G.jokers.cards) or {}
    for i = 1, #jokers do
        local center = jokers[i].config and jokers[i].config.center
        if center and center.pools and center.pools.Index and not PMCMOD.is_aspect(center.key) then
            return true
        end
    end
    return false
end

function PMCMOD.prescript_in_play()
    local jokers = (G.jokers and G.jokers.cards) or {}
    for i = 1, #jokers do
        local center = jokers[i].config and jokers[i].config.center
        if center and type(center.key) == 'string' and center.key:sub(1, 18) == 'j_pmcmod_prescript' then
            return true
        end
    end
    return false
end

function PMCMOD.is_prescript_key(key)
    return type(key) == 'string' and key:sub(1, 18) == 'j_pmcmod_prescript'
end

-- Scenes survived. Prescripts call this from their end_of_round branch and resolve when it is true.
-- Tripping it marks the card resolved so the immediate path below cannot pay out a second time.
function PMCMOD.prescript_expired(card)
    if not (card and card.ability and card.ability.extra) then return false end
    if card.ability.extra.prescriptResolved then return false end
    card.ability.extra.scenesAlive = (card.ability.extra.scenesAlive or 0) + 1
    if card.ability.extra.scenesAlive >= PMCMOD.PRESCRIPT_SCENES then
        card.ability.extra.prescriptResolved = true
        return true
    end
    return false
end

-- The moment a prescript's outcome is known - fulfilled, or blown - it is destroyed. The other exit
-- is the end of its third Scene, which the page's own end_of_round branch handles.
-- Announces how a prescript ended, where it dissolves.
function PMCMOD.prescript_verdict(card, fulfilled)
    card_eval_status_text(card, 'extra', nil, nil, nil, {
        message = localize(fulfilled and 'pmcmod_prescriptFulfilled' or 'pmcmod_prescriptFailed'),
        colour = fulfilled and G.C.BLUE or G.C.RED,
    })
end

function PMCMOD.resolve_prescript(card)
    if not (card and card.ability and card.ability.extra) then return end
    local ex = card.ability.extra
    if ex.prescriptResolved then return end
    ex.prescriptResolved = true

    local fulfilled = ex.prescriptFullfilled == true and ex.prescriptFailed ~= true
    card.prescriptFullfilled = fulfilled          -- Rien reads this as the page is destroyed

    local n = tostring(card.config.center.key):match('prescript(%d+)')
    if n and G.GAME.pool_flags then G.GAME.pool_flags['prescript' .. n .. 'Extinct'] = true end

    if fulfilled then PMCMOD.grant_grace() else PMCMOD.grant_karma() end
    PMCMOD.prescript_verdict(card, fulfilled)

    if not card.getting_sliced then
        card.getting_sliced = true
        local target = card
        G.E_MANAGER:add_event(Event({func = function()
            play_sound('tarot1', 0.9, 0.9)
            target:juice_up(0.8, 0.8)
            target:start_dissolve({G.C.RED}, nil, 1.6)
        return true end }))
    end
end

function PMCMOD.grant_grace()
    if not G.GAME then return end
    G.GAME.pmcmod_grace = (G.GAME.pmcmod_grace or 0) + 1
    -- the Index pays out only while its Voice is listening
    if PMCMOD.voice_of_the_city_in_play() then ease_dollars(15) end
end

function PMCMOD.grant_karma()
    if not G.GAME then return end
    G.GAME.pmcmod_karma = (G.GAME.pmcmod_karma or 0) + 1
    if PMCMOD.voice_of_the_city_in_play() then ease_dollars(-G.GAME.dollars, true) end
end

-- Grace makes Index Keypages more likely: x2 each, capped by PMCMOD.bonus_weight like everything
-- else. Aspects (_alt) are their own cards and get no bonus - they are not Index members.
function PMCMOD.index_weight(weight, key)
    if PMCMOD.is_aspect(key) then return weight end
    return PMCMOD.bonus_weight(weight, PMCMOD.grace())
end

-- Spawns the next prescript at the start of a Scene while an Index member is on the team and none
-- is out. Driven from the Card:calculate_joker wrapper on setting_blind, once per Scene.
function PMCMOD.prescript_driver()
    if not (G.GAME and G.jokers) then return end
    local rr = G.GAME.round_resets or {}
    local sceneKey = (rr.ante or 0) * 10000 + (G.GAME.round or 0)
    if G.GAME.pmcmod_prescript_sceneKey == sceneKey then return end
    G.GAME.pmcmod_prescript_sceneKey = sceneKey

    -- an Index Keypage, or the Voice of the City itself: the Voice speaks for the Index even
    -- when no member of it is on the team
    if not (PMCMOD.index_member_in_play() or PMCMOD.voice_of_the_city_in_play()) then return end
    if PMCMOD.prescript_in_play() then return end

    -- A fresh draw each time. This used a Shuffle with the fixed seed 'pmcmod_prescripts', so
    -- every run issued exactly the same order; the seed now mixes in the Scene and a spawn counter.
    local list = {
        "j_pmcmod_prescript1", "j_pmcmod_prescript2", "j_pmcmod_prescript3",
        "j_pmcmod_prescript4", "j_pmcmod_prescript5", "j_pmcmod_prescript6",
        "j_pmcmod_prescript7", "j_pmcmod_prescript8", "j_pmcmod_prescript9",
        "j_pmcmod_prescript10", "j_pmcmod_prescript11",
    }
    G.GAME.pmcmod_prescript_count = (G.GAME.pmcmod_prescript_count or 0) + 1
    local seed = 'pmcmod_prescript_' .. (rr.ante or 0) .. '_' .. (G.GAME.round or 0) .. '_' .. G.GAME.pmcmod_prescript_count

    local spawned = SMODS.add_card({
        key = pseudorandom_element(list, seed),
        stickers = { "eternal" },
        force_stickers = true,
    })
    PMCMOD.claim_slot(spawned)
end

-- What a Burn Card pays: 0.001% of the Encounter (0.00001), grown by the Laevateinn's
-- remaining counters. No ceiling: Tremor is meant to be able to run away with it.
function PMCMOD.burn_chips()
    local encounter = (G.GAME and G.GAME.blind and G.GAME.blind.chips) or 0
    return encounter * 0.00001 * PMCMOD.laevateinn_scale()
end

-- Credit Card is the one thing that lets the purse go negative, in vanilla and here.
function PMCMOD.credit_card_in_play()
    return #SMODS.find_card('j_credit_card') > 0
end

-- How much stronger Burn Cards are for what is left of the Laevateinn: x10 per counter below
-- three, so x1 at a full three and x1000 at none. No Matthias means no change at all.
function PMCMOD.laevateinn_scale()
    local found = SMODS.find_card('j_pmcmod_matthias')
    if not found or #found == 0 then return 1 end
    local extra = found[1].ability and found[1].ability.extra
    if type(extra) ~= 'table' or type(extra.laevateinn) ~= 'number' then return 1 end
    return 10 ^ math.max(0, 3 - extra.laevateinn)
end

-- ---------------------------------------------------------------------------
-- Index Keypages lost to a prescript
-- ---------------------------------------------------------------------------
-- prescript2 picks a Keypage and asks for it to be sold (its `selectedJoker`). If that card is an
-- Index member, it is queued here and re-issued at the next shop with a random Edition.
--
-- The absorbed values survive; only volatile state is dropped, so Sora comes back in her first form
-- with everything she stole still on her.
PMCMOD.INDEX_RETURN_VOLATILE = {
    'locked', 'dryReceptions', 'lastReception', 'doubleReception',
    'chargeHand', 'chargeSpendHand', 'chargeTriggers', 'currentPosition', 'pairCount',
}

function PMCMOD.queue_index_return(sold)
    if not (sold and sold.config and sold.config.center) then return end
    local center = sold.config.center
    if not (center.pools and center.pools.Index) then return end
    local key = center.key

    -- was this exact Keypage demanded by a prescript on the board?
    local demanded = false
    local jokers = (G.jokers and G.jokers.cards) or {}
    for i = 1, #jokers do
        local extra = jokers[i].ability and jokers[i].ability.extra
        -- extra is a plain number on some jokers (config = {extra = 1, ...})
        if type(extra) == 'table' and extra.selectedJoker == key then
            demanded = true
            break
        end
    end
    if not demanded then return end

    local keep = {}
    if type(sold.ability.extra) == 'table' then
        for k, v in pairs(sold.ability.extra) do keep[k] = v end
    end
    for _, k in ipairs(PMCMOD.INDEX_RETURN_VOLATILE) do keep[k] = nil end

    G.GAME.pmcmod_index_return = G.GAME.pmcmod_index_return or {}
    G.GAME.pmcmod_index_return[#G.GAME.pmcmod_index_return + 1] = { key = key, stats = keep }
end

function PMCMOD.index_return_tick()
    local queued = G.GAME and G.GAME.pmcmod_index_return
    if not queued or #queued == 0 then return end
    local rr = G.GAME.round_resets or {}
    local shopKey = (rr.ante or 0) * 10000 + (G.GAME.round or 0)
    if G.GAME.pmcmod_index_return_shopKey == shopKey then return end
    G.GAME.pmcmod_index_return_shopKey = shopKey

    for _, entry in ipairs(queued) do
        local edition = SMODS.poll_object({
            type = 'Edition', guaranteed = true,
            seed = 'pmcmod_index_return' .. shopKey .. tostring(entry.key),
        })
        local added = SMODS.add_card({ key = entry.key, edition = edition })
        PMCMOD.claim_slot(added)
        if added and added.ability and added.ability.extra then
            for k, v in pairs(entry.stats or {}) do added.ability.extra[k] = v end
        end
    end
    G.GAME.pmcmod_index_return = {}
end

-- Rudolph's four effects are all "while Rudolph is on the team", so they need to be visible to
-- events that happen outside his own calculate: other cards triggering, and anything being sold.
function PMCMOD.rudolph_in_play()
    local jokers = (G.jokers and G.jokers.cards) or {}
    for i = 1, #jokers do
        local c = jokers[i]
        if c.config and c.config.center and c.config.center.key == 'j_pmcmod_rudolph' then
            return true
        end
    end
    return false
end

-- Selling anything (Keypage or consumable) feeds the Charge pool with its sell value.
function PMCMOD.install_sell_reporter()
    if PMCMOD._sell_reporter or not (G and G.FUNCS and G.FUNCS.sell_card) then return end
    local original = G.FUNCS.sell_card
    PMCMOD._sell_reporter = original
    G.FUNCS.sell_card = function(e)
        local sold = e and e.config and e.config.ref_table
        local value = (sold and sold.sell_cost) or 0
        original(e)
        if value > 0 and PMCMOD.rudolph_in_play() then
            PMCMOD.add_charge(value)
        end
        -- a prescript-demanded Index Keypage comes back next shop
        PMCMOD.queue_index_return(sold)
    end
end

-- How many Tremor cards are in the deck. Tremor passively amplifies the other enhancements, and
-- several of them scale their effect by this count.
function PMCMOD.tremor_count()
    local n = 0
    for _, c in ipairs(G.playing_cards or {}) do
        if SMODS.has_enhancement(c, 'm_pmcmod_tremor') then n = n + 1 end
    end
    return n
end

-- A small Use button drawn on a Keypage, shown only while its Blade is charged. Created from the
-- card's update, removed when the charge is spent, so there is never more than one.
function PMCMOD.update_use_button(card, charged, handler)
    if charged and not card.children.pmcmod_use then
        card.children.pmcmod_use = UIBox{
            definition = { n = G.UIT.ROOT, config = { align = 'cm', colour = G.C.CLEAR }, nodes = {
                { n = G.UIT.C, config = { align = 'cm', padding = 0.06, r = 0.2, colour = G.C.BLUE,
                    button = handler, hover = true, shadow = true }, nodes = {
                    { n = G.UIT.T, config = { text = localize('pmcmod_use'), scale = 0.5,
                        colour = G.C.WHITE, shadow = true } },
                } },
            } },
            config = { align = 'bm', offset = { x = 0, y = 0.1 }, parent = card },
        }
    elseif not charged and card.children.pmcmod_use then
        card.children.pmcmod_use:remove()
        card.children.pmcmod_use = nil
    end
end

-- Yoru: 50 Blade halves what this encounter asks for.
G.FUNCS.pmcmod_yoru_blade = function(e)
    local found = SMODS.find_card('j_pmcmod_shiomiYoru')
    local card = found and found[1]
    if not (card and card.ability and card.ability.extra) then return end
    local ex = card.ability.extra
    -- only during an encounter
    if not (G.GAME.blind and G.GAME.blind.chips and G.GAME.blind.in_blind) then return end
    if (ex.blade or 0) < 50 then return end
    ex.blade = ex.blade - 50
    G.GAME.blind.chips = math.max(1, math.floor(G.GAME.blind.chips / 2))
    card_eval_status_text(card, 'extra', nil, nil, nil, {
        message = localize('pmcmod_yoruUsed'), colour = G.C.RED,
    })
end

-- Ren: 20 Blade buys one more hand this encounter.
G.FUNCS.pmcmod_ren_blade = function(e)
    local found = SMODS.find_card('j_pmcmod_ren')
    local card = found and found[1]
    if not (card and card.ability and card.ability.extra) then return end
    local ex = card.ability.extra
    -- only during an encounter
    if not (G.GAME.blind and G.GAME.blind.in_blind) then return end
    if (ex.blade or 0) < 20 then return end
    ex.blade = ex.blade - 20
    -- round_resets.hands is only read when a round starts, and ease_hands_played consumes a hand
    -- rather than granting one, so the live counter is raised directly
    G.GAME.current_round.hands_left = (G.GAME.current_round.hands_left or 0) + 1
    card_eval_status_text(card, 'extra', nil, nil, nil, {
        message = localize('pmcmod_renUsed'), colour = G.C.BLUE,
    })
end

-- Mr. Bones' save, for Valencina: once per run she survives a lost encounter. The engine decides
-- that in G.FUNCS.evaluate_round rather than in a joker's calculate, so the score is topped up to the
-- requirement just before the original runs. Strictly stronger than Mr. Bones: the encounter is
-- credited rather than merely survived.
function PMCMOD.install_death_saver()
    if PMCMOD._death_saver or not (G and G.FUNCS and G.FUNCS.evaluate_round) then return end
    local original = G.FUNCS.evaluate_round
    PMCMOD._death_saver = original
    G.FUNCS.evaluate_round = function(...)
        local blind = G.GAME and G.GAME.blind
        if G.GAME and blind and blind.chips and G.GAME.chips
            and to_big(G.GAME.chips) < to_big(blind.chips) then
            local found = SMODS.find_card('j_pmcmod_valencina')
            if found and #found > 0 then
                local extra = found[1].ability and found[1].ability.extra
                if type(extra) == 'table' and not extra.bonesUsed then
                    extra.bonesUsed = true
                    G.GAME.chips = blind.chips
                    card_eval_status_text(found[1], 'extra', nil, nil, nil, {
                        message = localize('pmcmod_valencinaSave'), colour = G.C.RED,
                    })
                end
            end
        end
        return original(...)
    end
end

-- context.discard fires once per discarded card, so a card cannot tell how big the discard was.
-- Recording the size here lets Valencina apply Trading Card's rule to a one-card discard.
-- Spectral packs draw from the shop as often as Buffoon packs of the same tier. The mod defines no
-- booster of its own, so these are the base game's: weight 0.3 against Buffoon's 0.6.
function PMCMOD.match_spectral_weights()
    if not (G and G.P_CENTERS) then return end
    for _, tier in ipairs({ 'normal', 'jumbo', 'mega' }) do
        for i = 1, 4 do
            local spec = G.P_CENTERS['p_spectral_' .. tier .. '_' .. i]
            local buff = G.P_CENTERS['p_buffoon_' .. tier .. '_' .. i]
            if spec and buff and buff.weight then
                spec.weight = buff.weight
            end
        end
    end
end

-- Every destroyed playing card, counted once, whatever destroyed it. Lucio's XMult reads this; the
-- counter Valencina used to keep herself was removed so her own destroys are not double counted.
function PMCMOD.install_destroy_counter()
    if PMCMOD._destroy_counter or not (SMODS and SMODS.destroy_cards) then return end
    local original = SMODS.destroy_cards
    PMCMOD._destroy_counter = original
    SMODS.destroy_cards = function(cards, ...)
        local list = cards
        if list and not list[1] and list.ability then list = { list } end
        local n = 0
        for _, c in ipairs(list or {}) do
            if c and c.playing_card then n = n + 1 end
        end
        if n > 0 and G.GAME then
            G.GAME.pmcmod_cards_destroyed = (G.GAME.pmcmod_cards_destroyed or 0) + n
        end
        return original(cards, ...)
    end
end

-- Tremor adds to a Gold Card's round-end money. The cash-out pass (state_events.lua:221) pays
-- effects[ii].h_dollars, and those come from this per-card getter, so the getter is wrapped additively
-- and the vanilla payout still happens exactly once. If the method is named differently in this build
-- the installer does nothing.
function PMCMOD.install_gold_tremor()
PMCMOD.install_destroy_counter()
    if PMCMOD._gold_tremor or not (Card and Card.get_end_of_round_effect) then return end
    local original = Card.get_end_of_round_effect
    PMCMOD._gold_tremor = original
    function Card:get_end_of_round_effect(context)
        local ret = original(self, context)
        if type(ret) == 'table' and ret.h_dollars and self.ability
            and self.ability.name == 'Gold Card' then
            local tremor = PMCMOD.tremor_count()
            if tremor > 0 then ret.h_dollars = ret.h_dollars + tremor end
        end
        return ret
    end
end

-- Tremor raises a Lucky Card's odds. Card:get_chip_mult is a small pure getter (card.lua:984) and
-- the whole Lucky roll is inside it, so it is replaced rather than patched around; every other card
-- delegates to the original.
function PMCMOD.install_lucky_tremor()
    if PMCMOD._lucky_tremor or not (Card and Card.get_chip_mult) then return end
    local original = Card.get_chip_mult
    PMCMOD._lucky_tremor = original
    function Card:get_chip_mult()
        local tremor = 0
        if self.ability and self.ability.effect == "Lucky Card" and not self.debuff
            and self.ability.set ~= 'Joker' then
            tremor = PMCMOD.tremor_count()
        end
        if tremor <= 0 then return original(self) end
        local normal = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1
        if pseudorandom('lucky_mult') < normal * (1 / 5 + 0.2 * tremor) then
            self.lucky_trigger = true
            return self.ability.mult
        end
        return 0
    end
end

function PMCMOD.install_discard_reporter()
    if PMCMOD._discard_reporter or not (G and G.FUNCS and G.FUNCS.discard_cards_from_highlighted) then
        return
    end
    local original = G.FUNCS.discard_cards_from_highlighted
    PMCMOD._discard_reporter = original
    G.FUNCS.discard_cards_from_highlighted = function(e, hook)
        -- measured the way the game itself measures it (state_events.lua:389), including the
        -- discard's own card_limit clamp
        local highlighted = ((G.hand or {}).highlighted) or {}
        local limit = (G.discard and G.discard.config and G.discard.config.card_limit) or 99
        local play = (G.play and #G.play.cards) or 0
        G.GAME.pmcmod_discardSize = math.min(#highlighted, limit - play)
        G.GAME.pmcmod_discardId = (G.GAME.pmcmod_discardId or 0) + 1
        return original(e, hook)
    end
end

-- Shop weight helper for get_weight(). A rarity draws its members in proportion to their
-- weight (10 by default), so a multiple makes a joker more likely to be offered. Every joker
-- starts at x1 - equal with its rarity peers - and only rises when its condition is met.
-- The multiple is capped (PMCMOD.MAX_SHOP_WEIGHT_MULT) because these exponents count
-- deck-wide cards: uncapped, a 10-pallid deck gave queequeg 2^11 = x2048 and the shop became
-- that one joker. Raise or lower the cap to taste; it is the only knob.
PMCMOD.MAX_SHOP_WEIGHT_MULT = 8
function PMCMOD.bonus_weight(weight, exponent)
    return (weight or 10) * math.min(2 ^ math.max(0, exponent or 0), PMCMOD.MAX_SHOP_WEIGHT_MULT)
end

-- Sin seals can appear on a scored card that does not have a seal yet, when the card carries
-- the matching enhancement. The seal is permanent once it lands, and it takes effect from the
-- card's next scoring: SMODS.score_card evaluates the card's own effects before the jokers
-- (src/utils.lua:2244 vs 2251), so a seal granted during the joker pass cannot fire the same hand.
-- Odds use G.GAME.probabilities.normal like the rest of the mod, so Oops! All 6s helps.
PMCMOD.SIN_SEAL_GRANTS = {
    m_pmcmod_bleed   = { seal = 'pmcmod_sinLust',     odds = 10 },
    m_pmcmod_poise   = { seal = 'pmcmod_sinPride',    odds = 10 },
    m_pmcmod_tremor  = { seal = 'pmcmod_sinSloth',    odds = 10 },
    m_pmcmod_rupture = { seal = 'pmcmod_sinGluttony', odds = 10 },
    m_pmcmod_burn    = { seal = 'pmcmod_sinWrath',    odds = 10 },
    m_pmcmod_sinking = { seal = 'pmcmod_sinGloom',    odds = 10 },
}
PMCMOD.SIN_ENVY_ODDS = 60

function PMCMOD.try_sin_seal(card)
    if not card or card.seal or card.debuff then return false end
    local prob = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal) or 1

    for enhancement, grant in pairs(PMCMOD.SIN_SEAL_GRANTS) do
        if SMODS.has_enhancement(card, enhancement) then
            if pseudorandom('pmcmod_sinseal_' .. grant.seal) < prob / grant.odds then
                card:set_seal(grant.seal, nil, true)
                return grant.seal
            end
            return false
        end
    end

    -- Envy: a plain card, while an edition is on the card itself or on any Keypage
    if card.config and card.config.center and card.config.center.key == 'c_base' then
        local edition_in_play = card.edition ~= nil
        if not edition_in_play and G.jokers then
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i].edition then
                    edition_in_play = true
                    break
                end
            end
        end
        if edition_in_play and pseudorandom('pmcmod_sinseal_envy') < prob / PMCMOD.SIN_ENVY_ODDS then
            card:set_seal('pmcmod_sinEnvy', nil, true)
            return 'pmcmod_sinEnvy'
        end
    end
    return false
end

-- aCertainSinclair counts how often the Keypage on its left triggers. SMODS exposes that through
-- context.post_trigger, but that only fires when the neighbour's calculate RETURNS an effect - so a
-- keypage that works by changing state (Ren granting Poise, for instance) is invisible to it - and
-- only if the mod's "post_trigger" optional feature was picked up.
-- This reports the same thing directly, without the flag: after any joker returns an effect for a
-- real context, every joker is offered a pmcmod_trigger context carrying that joker in other_card.
-- Summoned keypages that should not cost a joker slot but must not be Negative either (several
-- keypages scale off Negative cards). The game's slot check adds +1 to the limit for a Negative
-- card (button_callbacks.lua:2396), so granting +1 here is the same thing without the edition.
-- The flag lives on the card and travels with the save; the credit is returned when it leaves play.
-- SMODS computes the joker area's slots itself: CardArea:handle_card_limit()
-- (src/utils.lua:3936) sums card.ability.card_limit over the area as extra_slots, adds the base, and
-- the counter draws display_slots; it is called from CardArea:update() via card_limit.toml:168-182,
-- and card_limit.toml:152-166 even deletes vanilla's Negative limit tweak. Editing
-- G.jokers.config.card_limit by hand is therefore overwritten on the next area update - the native
-- way to grant a slot is card.ability.card_limit on the card, which also travels with the save.
function PMCMOD.claim_slot(card)
    if not card or not card.ability or card.ability.pmcmod_free_slot then return end
    card.ability.pmcmod_free_slot = true
    card.ability.card_limit = (card.ability.card_limit or 0) + 1
    if G.jokers and G.jokers.handle_card_limit then G.jokers:handle_card_limit() end
end

function PMCMOD.release_slot(card)
    if not card or not card.ability or not card.ability.pmcmod_free_slot then return end
    card.ability.pmcmod_free_slot = nil
    card.ability.card_limit = math.max(0, (card.ability.card_limit or 1) - 1)
    if G.jokers and G.jokers.handle_card_limit then G.jokers:handle_card_limit() end
end

PMCMOD.TRIGGER_CONTEXT = 'pmcmod_trigger'

-- The broadcast costs one extra context evaluation per trigger, so it only runs while a Sinclair is
-- on the board.
function PMCMOD.sinclair_in_play()
    local jokers = G.jokers and G.jokers.cards
    if not jokers then return false end
    for i = 1, #jokers do
        local c = jokers[i]
        if c.config and c.config.center and c.config.center.key == 'j_pmcmod_aCertainSinclair' then
            return true
        end
    end
    return false
end

function PMCMOD.install_trigger_reporter()
    if PMCMOD._trigger_reporter then return end
    local original = Card and Card.calculate_joker
    if not original then return end
    PMCMOD._trigger_reporter = original

    function Card:calculate_joker(context)
        local ret = original(self, context)
        -- the prescript cycle is driven here: this wrapper is the only place that sees
        -- ending_shop without needing a specific Keypage on the team
        if context and context.setting_blind then
            PMCMOD.prescript_driver()
        end
        if context and context.ending_shop then
            PMCMOD.index_return_tick()
        end
        -- a prescript whose outcome is already known is destroyed right away
        if context and not context.blueprint and self.ability and self.ability.set == 'Joker'
            and self.config and self.config.center and PMCMOD.is_prescript_key(self.config.center.key)
            and self.ability.extra and not self.ability.extra.prescriptResolved
            and (self.ability.extra.prescriptFullfilled == true or self.ability.extra.prescriptFailed == true) then
            PMCMOD.resolve_prescript(self)
        end
        -- Rudolph: a Keypage holding Charge gains $1 of sell value every time it triggers.
        if ret and self.ability and self.ability.set == 'Joker' and not self.debuff
            and self.edition and self.edition.key == 'e_pmcmod_charge'
            and context and not context.blueprint and PMCMOD.rudolph_in_play() then
            self.ability.extra_value = (self.ability.extra_value or 0) + 1
            self:set_cost()
        end
        if ret and self.ability and self.ability.set == 'Joker' and not self.debuff
            and context and not context.pmcmod_trigger and not context.blueprint
            and SMODS.can_context_post_trigger(context) and PMCMOD.sinclair_in_play() then
            SMODS.calculate_context({
                pmcmod_trigger = true,
                other_card = self,
                other_context = context,
            })
        end
        return ret
    end
end
PMCMOD.install_trigger_reporter()
PMCMOD.install_sell_reporter()
PMCMOD.install_discard_reporter()
PMCMOD.install_death_saver()
PMCMOD.install_lucky_tremor()
PMCMOD.install_gold_tremor()
PMCMOD.match_spectral_weights()

SMODS.current_mod.optional_features = function()
    return {
        retrigger_joker = true,
		post_trigger = true,
        object_weights = true
    }
end

PMCMOD.config_tab = function()
    return {n=G.UIT.ROOT, config = {align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={
        create_toggle({label = "Enable Adaptative Scaling", ref_table = PMCMOD.config, ref_value = "enable_adaptative_scaling"}),
    }}
end

-------------------
-- Loading files --
-------------------

if (SMODS.Mods['JokerDisplay'] or {}).can_load or false then SMODS.load_file("objects/joker_display_definitions.lua")() end
SMODS.load_file("objects/jokers.lua")()


local organizedJokerList = {
    'oswald',
    'esther',
    'gloria',
    'hubert',
    'kim',
    'angelica',
    'puppeteer',
    'nikolai',
    'maxim',
    'rudolph',
    'kalo',
    'katriel',
    'denis',
    'boris',
    'angelaLoR',
    'yisang',
    'donQuixote',
    'ryoshu',
    'hongLu',
    'heathcliff',
    'ishmael',
    'angela',
    'michelle',
    'elijah',
    'giovanni',
    'gabriel',
    'daniel',
    'kali',
    'benjamin',
    'garion',
    'lisa',
    'enoch',
    'hermann',
    'gubo',
    'jiaHuan',
    'aseah',
    'panther',
    'lion',
    'wolf',
    'hopkins',
    'aya',
    'yuri',
    'demian',
    'rim',
    'sanson',
    'effie',
    'saude',
    'aida',
    'sonya',
    'siegfried',
    'kromer',
    'guido',
    'papaBongy',
    'dongrang',
    'dongbaek',
    'samjo',
    'shrenne',
    'alfonso',
    'marile',
    'ran',
    'niko',
    'ahab',
    'queequeg',
    'starbuck',
    'stubb',
    'pip',
    'pilot',
    'smee',
    'ricardo',
    'catherine',
    'everyCatherine',
    'nelly',
    'erlking',
    'hindley',
    'linton',
    'josephine',
    'olga',
    'rain',
    'mika',
    'moses',
    'ezra',
    'santata',
    'crayon',
    'domino',
    'dadQuixote',
    'sancho',
    'dulcinea',
    'barber',
    'priest',
    'bari',
    'cesara',
    'alessio',
    'jiaXichun',
    'hugo',
    'camille',
    'paula',
    'romero',
    'hanul',
    'caiman',
    'aengDu',
    'jun',
    'herbert',
    'mai',
    'bumble',
    'timeRipper',
    'casetti',
    'sasha',
    'hohenheim',
    'alyssa',
    'marton',
    'johann',
    'qingTao',
    'shanSan',
    'werner',
    'jumsoon',
    'garnet',
    'catt',
    'jiaMu',
    'jiaQiu',
    'linDaiyu',
    'xueBaochai',
    'xianren',
    'ladyWang',
    'jiaZheng',
    'jiaYuanchun',
    'jiaHuanChild',
    'xuePan',
    'wangZhao',
    'wangDawei',
    'wangQingshan',
    'wangRen',
    'shiYihua',
    'shiHuazhen',
    'shiSijing',
    'kongSihui',
    'kongYoujin',
    'xiren',
    'wei',
    'zigong',
    'zilu',
    'nightDrifter',
    'leiHeng',
    'valencina',
    'rien',
    'matthias',
    'callisto',
    'shiomiYoru',
    'lucio',
    'sora',
    'kira',
    'albina',
    'ren',
    'ravi',
    'jamila',
    'aCertainSinclair',
    'araya',
    'emile',
    'rufo',
    'alan',
    'vermillionCross',
    'indigoElder',
    'yellowHarpoon',
    'sephirahHod',
    'sephirahMalkuth',
    'sephirahNetzach',
    'sephirahYesod',
    'sephirahChesed',
    'sephirahGebura',
    'sephirahHokma',
    'sephirahBinah',
    'sephirahTiphereth',
    'robotHod',
    'robotMalkuth',
    'robotNetzach',
    'robotYesod',
    'robotChesed',
    'robotGebura',
    'robotHokma',
    'robotBinah',
    'robotTiph',
    'robotEnoch',
    'silence',
    'shylook',
    'queenOfHatred',
    'chickens',
    'puppets',
    'other',
    'generics',
    'voiceOfTheCity',
    'prescripts',
    'childrenOfTheGalaxy',
    'laetitia',
    'censored',
}

local organizedChallengeList = {
    'bloodfiend',
    'colours',
    'index',
    'luck',
    'money',
    'pequod',
    'poise',
    'vengence',
    'wuthering',
}

local organizedDeckList = {
    'thumb',
    'index',
    'middle',
    'ring',
    'serpent',
    'shy',
    'silent',
    'galaxy',
    'gift',
    'love',
    'censored',
}

local organizedEnhancementList = {
--    'ammo',
    'bleed',
    'burn',
    'rupture',
    'sinking',
    'poise',
    'tremor',
    'pallid',
    'painted',
}

local organizedEditionList = {
    'charge'
}

local organizedSealList = {
    'markOfCain',
    'pebble',
    'gift',
    'sinEnvy',
    'sinPride',
    'sinGloom',
    'sinGluttony',
    'sinSloth',
    'sinLust',
    'sinWrath'
}

local organizedSleevesList = {
    'thumb',
    'index',
    'middle',
    'ring',
    'serpent',
    'shy',
    'silence',
    'galaxy',
    'gift',
    'love',
    'censored',
}

local organizedSpectralList = {
    'banquet',
    'waltz',
    'barbed',
    'binds',
    'bygone',
    'ticking',
    'hunt',
    'outcast',
    'unloving',
    'witness',
    'manifest',
    'conceptIncinerator',

}

local organizedPartnerList = {
    'angela',
    'roland',
    'netzach',
    'dante'
}

for i=1, #organizedJokerList do
    assert(SMODS.load_file("objects/jokers/" .. organizedJokerList[i] .. ".lua"))()
end

for i=1, #organizedChallengeList do
    assert(SMODS.load_file("objects/challenges/" .. organizedChallengeList[i] .. ".lua"))()
end

for i=1, #organizedDeckList do
    assert(SMODS.load_file("objects/backs/" .. organizedDeckList[i] .. ".lua"))()
end

for i=1, #organizedEnhancementList do
    assert(SMODS.load_file("objects/enhancements/" .. organizedEnhancementList[i] .. ".lua"))()
end

for i=1, #organizedEditionList do
    assert(SMODS.load_file("objects/editions/" .. organizedEditionList[i] .. ".lua"))()
end

for i=1, #organizedSealList do
    assert(SMODS.load_file("objects/seals/" .. organizedSealList[i] .. ".lua"))()
end

for i=1, #organizedSpectralList do
    assert(SMODS.load_file("objects/spectrals/" .. organizedSpectralList[i] .. ".lua"))()
end

if (SMODS.Mods['partner'] or {}).can_load or false then

    for i=1, #organizedPartnerList do

        SMODS.Atlas {
            key = 'projectMoonPartnersDante',
            path = "modCompat/projectMoonPartnersDante.png",
            px = 46,
            py = 58,
        }

        SMODS.Atlas {
            key = 'projectMoonPartnersNetz',
            path = "modCompat/projectMoonPartnersNetz.png",
            px = 46,
            py = 58,
        }

        SMODS.Atlas {
            key = 'projectMoonPartnersRoland',
            path = "modCompat/projectMoonPartnersRoland.png",
            px = 46,
            py = 58,
        }

        SMODS.Atlas {
            key = 'projectMoonPartnersAngela',
            path = "modCompat/projectMoonPartnersAngela.png",
            px = 46,
            py = 58,
        }

        assert(SMODS.load_file("objects/partners/" .. organizedPartnerList[i] .. ".lua"))()
    end

end

if (SMODS.Mods['CardSleeves'] or {}).can_load or false then

    SMODS.Atlas {
        key = 'projectMoonSleeves',
        path = "modCompat/projectMoonSleeves.png",
        px = 73,
        py = 95,
    }

    for i=1, #organizedSleevesList do

        assert(SMODS.load_file("objects/sleeves/" .. organizedSleevesList[i] .. ".lua"))()

    end

end

---------------------
-- Preparing atlas --
---------------------
---


SMODS.Atlas {key = "ModdedProjectMoon",	path = "newProjectMoonJokers.png",	px = 71, py = 95}
SMODS.Atlas {key = "ModdedProjectMoon2",	path = "newProjectMoonJokers2.png",	px = 71, py = 95}
SMODS.Atlas {key = "ModdedProjectMoonTrue",	path = "newProjectMoonTrueJokers.png",	px = 71, py = 95}
SMODS.Atlas {key = "ModdedProjectMoonSpectrals",	path = "newProjectMoonSpectrals.png",	px = 71, py = 95}
SMODS.Atlas {key = "ModdedProjectMoonEditions",	path = "newProjectMoonEditions.png",	px = 71, py = 95}
SMODS.Atlas {key = "modicon",	path = "icon.png",	px = 32, py = 32}

SMODS.Shader{key = 'charge', path = 'charge.fs'}
----------------------------
-- Talisman Compatibility --
----------------------------

to_big = to_big or function(x)
    return x
end


-- Config Options --

--SMODS.current_mod.config_tab = function()
--    return {n=G.UIT.ROOT, config = {align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={
--        create_toggle({label = localize("k_unlock_all"), ref_table = ProjectMoonMod.config, ref_value = "temporary_unlock_all"}),
--    }}
--end


-------------------

SMODS.Sound{
	key = 'gubo_aim',
	path = 'gubo_aim.ogg',
	pitch = 0.7,
	volume = 0.6,
}


SMODS.Sound{
	key = 'gubo_shoot',
	path = 'gubo_shoot.ogg',
	pitch = 0.7,
	volume = 0.6,
}

SMODS.Sound{
	key = 'poiseTrigger',
	path = 'poiseTrigger.ogg',
	pitch = 0.7,
	volume = 0.6,
}

SMODS.Sound{
	key = 'kromerWhistle',
	path = 'kromerWhistle.ogg',
	pitch = 0.7,
	volume = 0.6,
}

SMODS.Sound{
	key = 'heathcliffGood',
	path = 'heathcliffGood.ogg',
	pitch = 1.0,
	volume = 0.7,
}

SMODS.Sound{
	key = 'heathcliffBad',
	path = 'heathcliffBad.ogg',
	pitch = 1.0,
	volume = 0.7,
}


if (SMODS.Mods['qol_bundle'] or {}).can_load or false then

SMODS.Tarot:take_ownership('c_wheel_of_fortune', 
  {
	config = {
            extra = QOL_BUNDLE.config.wheel_of_fortune_value or 4
        },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds,
            'pmcmod_wheel_of_fortune')
        return { vars = { numerator, denominator } }
    end,
    use = function(self, card, area, copier)
        if SMODS.pseudorandom_probability(card, 'pmcmod_wheel_of_fortune', 1, card.ability.extra.odds) then
            local editionless_jokers = SMODS.Edition:get_edition_cards(G.jokers, true)

            local eligible_card = pseudorandom_element(editionless_jokers, 'pmcmod_wheel_of_fortune')
            local edition = SMODS.poll_edition { key = "pmcmod_wheel_of_fortune", guaranteed = true, no_negative = true, options = { 'e_polychrome', 'e_holo', 'e_foil' } }
            eligible_card:set_edition(edition, true)
            check_for_unlock({ type = 'have_edition' })
			G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        func = function()
                            play_sound('pmcmod_heathcliffGood', 1.0, 0.7)
                            return true
                        end
                    }))
        else
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    attention_text({
                        text = localize('k_nope_ex'),
                        scale = 1.3,
                        hold = 1.4,
                        major = card,
                        backdrop_colour = G.C.SECONDARY_SET.Tarot,
                        align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK or G.STATE == G.STATES.SMODS_BOOSTER_OPENED) and
                            'tm' or 'cm',
                        offset = { x = 0, y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK or G.STATE == G.STATES.SMODS_BOOSTER_OPENED) and -0.2 or 0 },
                        silent = true
                    })
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.06 * G.SETTINGS.GAMESPEED,
                        blockable = false,
                        blocking = false,
                        func = function()
                            play_sound('pmcmod_heathcliffBad', 1.0, 0.7)
                            return true
                        end
                    }))
                    play_sound('tarot2', 1, 0.4)
                    card:juice_up(0.3, 0.5)
                    return true
                end
            }))
        end
    end,
  }, true)

else

    SMODS.Tarot:take_ownership('c_wheel_of_fortune', 
  {
	config = { extra = { odds = 4 } },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds,
            'pmcmod_wheel_of_fortune')
        return { vars = { numerator, denominator } }
    end,
    use = function(self, card, area, copier)
        if SMODS.pseudorandom_probability(card, 'pmcmod_wheel_of_fortune', 1, card.ability.extra.odds) then
            local editionless_jokers = SMODS.Edition:get_edition_cards(G.jokers, true)

            local eligible_card = pseudorandom_element(editionless_jokers, 'pmcmod_wheel_of_fortune')
            local edition = SMODS.poll_edition { key = "pmcmod_wheel_of_fortune", guaranteed = true, no_negative = true, options = { 'e_polychrome', 'e_holo', 'e_foil' } }
            eligible_card:set_edition(edition, true)
            check_for_unlock({ type = 'have_edition' })
			G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        func = function()
                            play_sound('pmcmod_heathcliffGood', 1.0, 0.7)
                            return true
                        end
                    }))
        else
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    attention_text({
                        text = localize('k_nope_ex'),
                        scale = 1.3,
                        hold = 1.4,
                        major = card,
                        backdrop_colour = G.C.SECONDARY_SET.Tarot,
                        align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK or G.STATE == G.STATES.SMODS_BOOSTER_OPENED) and
                            'tm' or 'cm',
                        offset = { x = 0, y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK or G.STATE == G.STATES.SMODS_BOOSTER_OPENED) and -0.2 or 0 },
                        silent = true
                    })
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.06 * G.SETTINGS.GAMESPEED,
                        blockable = false,
                        blocking = false,
                        func = function()
                            play_sound('pmcmod_heathcliffBad', 1.0, 0.7)
                            return true
                        end
                    }))
                    play_sound('tarot2', 1, 0.4)
                    card:juice_up(0.3, 0.5)
                    return true
                end
            }))
        end
    end,
  }, true)

end

------------------
-- Object Types --
------------------

--Sinners


-- K Corp
SMODS.ObjectType({
	key = "Sinners",
	default = "j_ring_master",
	cards = {
		["j_ring_master"] = true, 	--Gregor
		["j_bootstraps"] = true, 	--Rodya
		["j_idol"] = true, 			--Sinclair
		["j_constellation"] = true, --Yi Sang
		["j_midas_mask"] = true, 	--Ishamel
		["j_hit_the_road"] = true, 	--Heathcliff
		["j_seeing_double"] = true, --Don Quixote
		["j_diet_cola"] = true, 	--Hong Lu
		["j_flower_pot"] = true, 	--Ryoshu
		["j_baron"] = true, 		--Meursault
		["j_hanging_chad"] = true, 	--Outis
		["j_oops"] = true, 			--Faust
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
		self:inject_card(G.P_CENTERS.j_ring_master)
		self:inject_card(G.P_CENTERS.j_bootstraps)
		self:inject_card(G.P_CENTERS.j_idol)
		self:inject_card(G.P_CENTERS.j_constellation)
		self:inject_card(G.P_CENTERS.j_midas_mask)
		self:inject_card(G.P_CENTERS.j_hit_the_road)
		self:inject_card(G.P_CENTERS.j_seeing_double)
		self:inject_card(G.P_CENTERS.j_diet_cola)
		self:inject_card(G.P_CENTERS.j_flower_pot)
		self:inject_card(G.P_CENTERS.j_baron)
		self:inject_card(G.P_CENTERS.j_hanging_chad)
		self:inject_card(G.P_CENTERS.j_oops)
	end,
})

-- Thumb
SMODS.ObjectType({
	key = "Thumb",
	default = "j_greedy_joker",
	cards = {
		["j_greedy_joker"] = true, 	--Aspect of Kalo
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
		self:inject_card(G.P_CENTERS.j_greedy_joker)
	end,
})

-- Heretics
SMODS.ObjectType({
	key = "Heretics",
	default = "j_four_fingers",
	cards = {
 		["j_four_fingers"] = true, 	--Gamma
 		["j_mime"] = true,			--Eilleen
		["j_banner"] = true,		--Dalloc
		["j_8_ball"] = true,		--Arnold
		["j_fibonacci"] = true,		--Consta
		["j_scholar"] = true,		--Mo
		["j_egg"] = true,			--Mi
		["j_splash"] = true,		--Beta
		["j_blue_joker"] = true,	--Alloc
		["j_ride_the_bus"] = true,	--Manager Dante
		["j_square_joker"] = true,	--Jin
		["j_seance"] = true,		--Jae-heon
		["j_riff_raff"] = true,		--Angela
		["j_shortcut"] = true,		--Alpha
		["j_hologram"] = true,		--Luda
		["j_rocket"] = true,		--Nemo
		["j_fortune_teller"] = true,--Wang
		["j_smiley_face"] = true,	--Taein
		["j_troubadour"] = true,	--Gloria
		["j_certificate"] = true,	--Allen
		["j_onyx_agate"] = true,	--The Puppeteer
		["j_glass_joker"] = true,	--Distorted Yan
		["j_brainstorm"] = true,	--Baral
		["j_joker"] = true,			--Oswald
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
		self:inject_card(G.P_CENTERS.j_four_fingers)
		self:inject_card(G.P_CENTERS.j_mime)
		self:inject_card(G.P_CENTERS.j_banner)
		self:inject_card(G.P_CENTERS.j_8_ball)
		self:inject_card(G.P_CENTERS.j_fibonacci)
		self:inject_card(G.P_CENTERS.j_scholar)
		self:inject_card(G.P_CENTERS.j_egg)
		self:inject_card(G.P_CENTERS.j_splash)
		self:inject_card(G.P_CENTERS.j_blue_joker)
		self:inject_card(G.P_CENTERS.j_ride_the_bus)
		self:inject_card(G.P_CENTERS.j_square)
		self:inject_card(G.P_CENTERS.j_seance)
		self:inject_card(G.P_CENTERS.j_riff_raff)
		self:inject_card(G.P_CENTERS.j_shortcut)
		self:inject_card(G.P_CENTERS.j_hologram)
		self:inject_card(G.P_CENTERS.j_rocket)
		self:inject_card(G.P_CENTERS.j_fortune_teller)
		self:inject_card(G.P_CENTERS.j_smiley)
		self:inject_card(G.P_CENTERS.j_troubadour)
		self:inject_card(G.P_CENTERS.j_certificate)
		self:inject_card(G.P_CENTERS.j_onyx_agate)
		self:inject_card(G.P_CENTERS.j_glass)
		self:inject_card(G.P_CENTERS.j_brainstorm)
		self:inject_card(G.P_CENTERS.j_mystic_summit)
	end,
})

--Demian's Group
SMODS.ObjectType({
	key = "DemiansGroup",
	default = "j_pmcmod_demian",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

--Hell's Kitchen
SMODS.ObjectType({
	key = "HellsKitchen",
	default = "j_pmcmod_chickenA",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- Bloodfiend
SMODS.ObjectType({
	key = "Bloodfiends",
	default = "j_seeing_double",
	cards = {
		["j_seeing_double"] = true, --Don Quixote
		["j_bloodstone"] = true, --Blood-red Night
		["j_vampire"] = true --Elena
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
		self:inject_card(G.P_CENTERS.j_seeing_double)
	end,
})

-- New League of Nine
SMODS.ObjectType({
	key = "NewLeagueOfNine",
	default = "j_pmcmod_sonya",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- N Corp
SMODS.ObjectType({
	key = "NCorp",
	default = "j_pmcmod_kromer",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})



-- K Corp
SMODS.ObjectType({
	key = "KCorp",
	default = "j_pmcmod_dongrang",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- Puppets
SMODS.ObjectType({
	key = "Puppets",
	default = "j_pmcmod_puppetA",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

--Aspects
SMODS.ObjectType({
	key = "Aspects",
	default = "j_joker",
	cards = {
		["j_joker"] = true,
		["j_riff_raff"] = true,
		["j_greedy_joker"] = true,
		["j_lusty_joker"] = true,
		["j_wrathful_joker"] = true,
		["j_gluttenous_joker"] = true,
		["j_turtle_bean"] = true,
		["j_troubadour"] = true,
		["j_juggler"] = true,
		["j_half"] = true,
		["j_onyx_agate"] = true,
		["j_abstract"] = true,
		["j_swashbuckler"] = true,
		["j_bull"] = true,
		["j_constellation"] = true,
		["j_midas_mask"] = true,
		["j_hit_the_road"] = true,
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

--Aspects
SMODS.ObjectType({
	key = "TrueVersion",
	default = "j_pmcmod_oswald",
	cards = {
		["j_pmcmod_oswald"] = true,
		["j_pmcmod_angelaLoR"] = true,
		["j_pmcmod_kalo"] = true,
		["j_pmcmod_katriel"] = true,
		["j_pmcmod_denis"] = true,
		["j_pmcmod_boris"] = true,
		["j_pmcmod_esther"] = true,
		["j_pmcmod_gloria"] = true,
		["j_pmcmod_hubert"] = true,
		["j_pmcmod_angelica"] = true,
		["j_pmcmod_puppeteer"] = true,
		["j_pmcmod_nikolai"] = true,
		["j_pmcmod_rudolph"] = true,
		["j_pmcmod_maxim"] = true,
		["j_pmcmod_yisang"] = true,
		["j_pmcmod_ishmael"] = true,
		["j_pmcmod_heathcliff"] = true,
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)

	end,
})

-- R Corp
SMODS.ObjectType({
	key = "RCorp",
	default = "j_pmcmod_maxim",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- Ring
SMODS.ObjectType({
	key = "Ring",
	default = "j_pmcmod_albina",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- Index
SMODS.ObjectType({
	key = "Index",
	default = "j_pmcmod_angelica",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- Middle
SMODS.ObjectType({
	key = "Middle",
	default = "j_pmcmod_kira",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- Pinky
SMODS.ObjectType({
	key = "Pinky",
	default = "j_pmcmod_ren",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- L Corp
SMODS.ObjectType({
	key = "LCorp",
	default = "j_pmcmod_jamila",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- Limbus Company
SMODS.ObjectType({
	key = "Limbus",
	default = "j_pmcmod_ravi",
	cards = {
 	},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

-- QUIPS --

SMODS.JimboQuip({
    key = 'roland',
    extra = {
        center = 'j_stencil',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_stencil')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

SMODS.JimboQuip({
    key = 'malkuth',
    extra = {
        center = 'j_sock_and_buskin',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_sock_and_buskin')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

SMODS.JimboQuip({
    key = 'yesod',
    extra = {
        center = 'j_smeared',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_smeared')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

SMODS.JimboQuip({
    key = 'hod',
    extra = {
        center = 'j_pareidolia',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_pareidolia')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

SMODS.JimboQuip({
    key = 'netzach',
    extra = {
        center = 'j_satellite',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_satellite')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

SMODS.JimboQuip({
    key = 'tiph',
    extra = {
        center = 'j_shoot_the_moon',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_shoot_the_moon')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

SMODS.JimboQuip({
    key = 'gebura',
    extra = {
        center = 'j_stuntman',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_stuntman')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

SMODS.JimboQuip({
    key = 'chesed',
    extra = {
        center = 'j_castle',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_castle')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

SMODS.JimboQuip({
    key = 'hokma',
    extra = {
        center = 'j_cartomancer',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_cartomancer')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

SMODS.JimboQuip({
    key = 'binah',
    extra = {
        center = 'j_astronomer',
    },
    filter = function(self, type)
        if next(SMODS.find_card('j_astronomer')) then
            if type == 'win' then
                self.extra.text_key = self.key..'_win'
                return true, { weight = 100 }
            elseif type == 'loss' then
                self.extra.text_key = self.key..'_loss'
                return true, { weight = 100 }
            end
        end
    end
})

-- DUMMY CARD AREA

local game_start_run_ref = Game.start_run
function Game:start_run(args)
    self.pmcmod_dummy_joker_area = CardArea(
        0,
        0,
        self.CARD_W * 1.9,
        self.CARD_H * 0.95,
        {
            card_limit = 999,
            type = 'joker',
            highlight_limit = 1,
        }
    )
	self.pmcmod_dummy_joker_area.states.visible = false
    ProjectMoonMod.dummyJoker = G.pmcmod_dummy_joker_area

    game_start_run_ref(self, args)
end

local game_start_run_ref = Game.start_run
function Game:start_run(args)
    self.pmcmod_garnet_joker_area = CardArea(
        0,
        0,
        self.CARD_W * 1.9,
        self.CARD_H * 0.95,
        {
            card_limit = 999,
            type = 'joker',
            highlight_limit = 1,
        }
    )
	self.pmcmod_garnet_joker_area.states.visible = false
    ProjectMoonMod.garnetJoker = G.pmcmod_garnet_joker_area

    game_start_run_ref(self, args)
end

local card_set_cost_voucher = Card.set_cost
function Card:set_cost()
    card_set_cost_voucher(self)
    if next(SMODS.find_card("j_pmcmod_santata")) then
        if (self.ability.set == 'Voucher') then self.cost = 0 end
    end
end

SMODS.DrawStep {
    key = "censoring",
    order = 11,
    func = function(card, layer)
        if (layer == 'card' or layer == 'both') and card.sprite_facing == 'front' then
            local censoredPresent = false
            local pinnocchioPresent = false

            if G.GAME and G.GAME.blind then
                if G.jokers then
                    for i=1, #G.jokers.cards do
                        if G.jokers.cards[i].config.center.key == "j_pmcmod_censored" then
                            censoredPresent = true
                            break
                        end

                        if G.jokers.cards[i].config.center.key == "j_pmcmod_pinnocchio" then
                            pinnocchioPresent = true
                            break
                        end
                    end
                end
                if censoredPresent == true and card.ability.set == 'Joker' and not (card.children.center.sprite_pos.x == 2 and card.children.center.sprite_pos.y == 1 and card.children.center.atlas == G.ASSET_ATLAS["pmcmod_ModdedProjectMoonEditions"]) then
                --card.children.center = Sprite(card.T.x, card.T.y, card.T.w, card.T.h, G.ASSET_ATLAS["pmcmod_ModdedProjectMoon2"], {x = 0, y = 0})
                        card.children.center.atlas = G.ASSET_ATLAS["pmcmod_ModdedProjectMoonEditions"]
                        card.children.center:set_sprite_pos({x = 2, y = 1})
						if card.children.floating_sprite then
							card.children.floating_sprite.atlas = G.ASSET_ATLAS["pmcmod_ModdedProjectMoonEditions"]
							card.children.floating_sprite:set_sprite_pos({x = 2, y = 1})
						end
                end
            end
        end
    end
}
-- CHARGE MANAGER
-- Hidden helper card that drives the shared Charge pool (helpers near the top of this
-- file). It lives in the dummy joker area, which this mod's Lovely patch adds to the
-- joker evaluation lists, so it receives the same contexts a normal Keypage does.
local game_start_run_ref = Game.start_run
function Game:start_run(args)
    game_start_run_ref(self, args)

    local area = ProjectMoonMod.dummyJoker
    if not area then return end

    for _, c in ipairs(area.cards) do
        if c.config.center.key == 'j_pmcmod_chargeManager' then return end
    end
    SMODS.add_card({ key = 'j_pmcmod_chargeManager', area = area })
end
