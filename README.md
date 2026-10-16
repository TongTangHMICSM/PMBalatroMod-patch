# PMBalatroMod
Please refer to the original https://github.com/CountKiro/PMBalatroMod
this is just a fork due to some aspect i want to fix

# Installing 
Due to mod structure change a bit for convenient in development, you can git clone the mods or download the whole code as to put it into mods folder as PMBalatroMod-patch-master

# Table of Change
- Add sin seal (based on what the description in the code said and my interpretation)
- Add sin texture in 2x (texture come from upscaling the 1x one with lazy and simple algorithm so it look a bit pixelated)
- Fix/Add magical girl
- Change Mod structure
- Fix XiChun display
- Fix Niko code
- Fix Indigo Elder code
- Improve Alan logic
- Improve Garnet logic
- Flowing time nerf *Questionable
- Fix kongsihui
- Fix Ahab's X Mult to match its description (gains X0.05 per scored Pallid card, no longer a static deck-count formula)
- Rework Matthias' unseal: when the price outruns the purse the buy is refused and the seal takes one counter per hand in order - the first seal destroys every card in the scored hand for $20, the second a random non-Eternal Keypage (if any), the third Kira and bans her (if she is in play)
- Fix Burn Card payout to be a true 0.001% of the Encounter (was 0.1%, so at the Laevateinn's x1000 every Burn card hit the 9999 cap on ordinary blinds)

# Fixes

Engine and framework
- Charge Keypages never fed the pool. The hidden manager card lives in the dummy joker area, and the base game dispatches hand-level contexts straight over its own card lists, so it only ever received the per-scored-card context: its joker_main branch was dead code.
- Slot-free summons were impossible by hand. Editing `G.jokers.config.card_limit` is overwritten every frame by SMODS's `handle_card_limit`, which recomputes the limit from the cards themselves - the slot credit now lives on `card.ability.card_limit`, where SMODS actually reads it.
- The room gate on papaBongy blocked its own spawns: `SMODS.add_to_deck` enforces no limit at all, and Negative cards still count in `#G.jokers.cards`.
- Singleton compared rank and colour instead of rank and suit - the suit was computed and then never used.
- All gameplay `math.random` rolls are seeded, so results stay reproducible from the run seed.
- Three localisation keys were referenced by code but never written, so those popups would have shown their own key names.

Crashes
- Sora's stat display used `#10#`-`#13#` placeholders. The description parser only understands `#1#`-`#9#`, and it runs while tooltips are built at load, so the mod failed to start.
- Sora's payoff still multiplied by `multiplier`, a variable removed several edits earlier when the Rien double became a real repetition. Lua treats the missing name as a nil global, so it only threw mid-hand.
- Three reads of `ability.extra` assumed a table. Five jokers write `config = {extra = 0.5, ...}` with a plain number (kromer, michelle, sephirahHod, siegfried, wolf), so indexing it threw.

Keypages and effects
- Ahab's X Mult was a static `1 + 0.05` per Pallid card in the deck, contradicting the description's "gains X Mult every time a Pallid card is scored". He now gains X0.05 for each scored Pallid card (saved on the card) and pays out the running total, and `loc_vars` shows the stored value instead of recomputing from the deck.
- aCertainSinclair counted only left neighbours that returned an effect, and it wrote into the live context other Keypages read - it now counts any left neighbour's trigger and works on a copy.
- Ren reports a trigger when it gives Poise.
- Lei Heng can no longer destroy an Eternal Keypage; a protected neighbour turns that toss into a retrigger.
- Sephirah Chesed and Ishmael read X-Chips from the wrong config level, and debuffs now die with the card that applied them.
- Erasure removes Eternal Keypages again, but the deck starters (shylook, silence, censored, laetitia, voiceOfTheCity, queenOfHatred, childrenOfTheGalaxy) are protected.
- Manifest unlocks a still-locked True Version instead of showing "Locked" and burning the Spectral; 18 of its 21 targets start locked. Seeded and challenge runs still refuse unlocks.
- Two texture pack badge keys that were referenced but never defined, and a stray brace in pt_BR.
- Silent Deck's change had to be applied to `objects/backs/silent.lua`: the loader only reads `objects/backs/`, so `objects/decks/` is a dead duplicate of all 11 decks.
- Matthias: the long-first-hand penalty fired on every 4+ card hand regardless of the purse, and the broke penalty only destroyed the triggering card while the rest of the unburnt hand kept buying with the $20 it had just paid out. The buy is now refused outright whenever the price outruns the purse, the hand stops, and the seal takes one counter per hand in a fixed order: the first wipes every card in the scored hand, the second a random non-Eternal Keypage (if one exists), the third Kira and bans her (if she is in play).
- Burn Cards paid 0.1% of the Encounter instead of the described 0.001%. At the Laevateinn's x1000 that is the whole blind, so every Burn card maxed out the 9999 chip cap. The payout multiplier is now a true 0.001% (1% of the Encounter at x1000).

Pairs
- Every pair lookup missed. `card.config.center.key` is `j_pmcmod_ren` while the pair table uses bare keys, so no apprentice ever found its father.
- The Scene lock left a stale `<flag> = false` reset in each card's `context.before`, wiping the flag `setting_blind` had just set. This killed every pair bonus, including Kira's trigger count.
- Sora's charge bonus lingered across hands: only the spend was guarded, so an old spend kept adding triggers for the rest of the run.
- Sora transformed after one Scene. Her counter was evaluated outside any context, and keying on the Scene number let a single Scene advance it more than once.
- Rien's X-Chips was a flat amount rather than a multiplier, and Sinclair's popup asked the variable dictionary for a key that only holds vanilla entries, which returns the string "ERROR".
- Kira dying to her own trigger count now bans her from the pool and spends a Laevateinn counter, the same as Matthias's branch.

# Balanced Changes

Shop pool
- Weight is equal inside each rarity again. The 29 jokers that scaled their own weight now start at x1 like their peers and only rise while their condition holds, capped at x8 (`PMCMOD.MAX_SHOP_WEIGHT_MULT`). Uncapped, a 10-pallid deck put queequeg at x2048 and one joker owned its rarity.
- Every pool a joker declares now resolves: added the 7 missing ObjectTypes (RCorp, Ring, Index, Middle, Pinky, LCorp, Limbus), fixed the Sinner/Puppet/R Corp declarations, the six ObjectType defaults written in a key form that can never resolve, and a card key in TrueVersion that does not exist.
- The 57 summon/transform-only jokers are documented instead of relying on placeholder pool flags that nothing ever set.
- Grace of the City scales the shop weight of the Index Keypages (x2 per point, capped x8). Aspects are excluded: they are their own cards, not Index members.

Charge
- One shared pool: +1 per scored Page, +1 per hand for each Keypage holding it (Tiph B doubles the gain), and a Keypage spends 5 to score a played card twice, leftovers carrying over.
- Charge edition weight 3 -> 17, and Maxim and Rudolph only enter the shop pool while a Keypage holding Charge is on the team.
- Maxim reworked onto the shared pool: scored Face cards add 5 Charge, scored number cards spend 1 Charge to trigger twice, +2 Chips per dollar held, and $1 per 10 Charge at the end of the Scene.
- Rudolph reworked (his calculate was empty, so he did nothing): Charge cards trigger once more, a Charge Keypage gains $1 sell value each time it triggers, he gains Mult equal to the other Keypages' total sell value, and selling anything feeds its sell value into the pool.
- Nikolai: R Corp Keypages give x1.5 Mult each while he is held (compounding - three is x3.375), on top of his catalogue Mult, and he no longer catalogues aspects.

Index and Prescripts
- Prescripts are driven by Index membership: one is issued at the start of a Scene whenever none is active, each lasts 3 Scenes, and resolving grants Grace of the City (fulfilled) or Karmic Consequence (failed) - two run-wide counters. The old $15 / wipe-money swing moved to Voice of the City, which only pays it out while it is held. Voice of the City alone is enough to keep the cycle going.
- Each prescript page shows how many Scenes it has left, and announces Fulfilled or Failed when it resolves.
- Garnet and Angelica left the Index pool (Garnet keeps Thumb, Middle, Ring, Pinky and Bloodfiends; Angelica is pool-less, like the 94 other Keypages that carry an empty pools table and still spawn).
- Esther, Gloria and Hubert now scale on net Grace (Grace less Karma), all three on a scored Singleton: Esther gives x(1 + 0.1 per point) Chips, Gloria gives $(1 + 0.1 per point) - never below 0 - and Hubert has a 1.2 per point in 4 chance to retrigger it. Each grants +1 hand size once net Grace reaches 5.
- A prescript-demanded Index Keypage returns in the next shop with a random Edition. Sora keeps everything she absorbed but comes back in her first form.

The four pairs
- Each nurse-father pair shares one trigger counter, and the formation is read at the start of the Scene and held for it, so rearranging mid-Scene cannot toggle it. Every pair tooltip shows the count and whether the pair is linked.
- Sora steals an Edition from any Keypage at the start of a Scene and absorbs it: Foil +50 Chips, Holo +10 Mult, Poly x1.5 Mult, Charge a stack, Negative worn with +20 Chips. Charge stacks scale what she feeds the pool, and each lets 5 Charge buy her keypage another trigger. Three Receptions without stealing and she transforms, keeping every absorbed value.
- Her second form scales on net Grace: Chips and Mult by 1 + 0.1 per point, and XMult raised to the power 1 + 0.5 per point. With Rien exactly to her left she takes his Edition first and triggers twice for the rest of the Reception.
- Rien pays Grace of the City and Karmic Consequence: +15 Mult per Grace, X(1 + 0.2 per Grace) Chips, X0.9 per Karma, and -50 Chips per Karma. Destroying him clears Karma.
- Kira pays $4 per scored Burn Card, counts one trigger per hand rather than per card, and dies after 3 hands.

Matthias, Burn and the sin seals
- Matthias carries 3 Laevateinn counters and -1 Hand. On the first hand of a Scene, each unburnt card gains Burn for the going price, which starts at $2 and rises by $1 per purchase. Nothing is spent while short - the buy only happens at or above the price, the purse never goes below $0 unless Credit Card is held, and Kira exactly to his right waives the price entirely and stops it climbing.
- Once the price outruns the purse, the buy is refused and the seal takes a counter instead, once per hand, in a fixed order: the first seal destroys every card in the scored hand for $20, the second a random non-Eternal Keypage (Kira excluded, and only if one exists), and the third Kira, banning her from the pool (only if she is in play). Going broke stops the buying for the rest of the hand.
- With no counters left nothing is bought: every scored card rolls 1 in 5 to gain Burn, and a hit on a card that already burns destroys it.
- Burn Cards have no use limit and pay chips - 0.001% of the Encounter Score, multiplied by x10 for every Laevateinn counter spent, capped at 9999.
- The Wrath seal is now purely Burn-driven: 1.2 per Sloth seal in 10 to become a Burn Card, and in 20 to spread Burn to a card that lacks it. Its old perma Chips, Mult and Money gains are gone.
- Sloth passively enchants every other sin seal; its description says just that.

Other
- Silent Deck gives +1 hand and +1 discard instead of +2/+2, and Kong Sihui pays $5 instead of $2.
- Alan's text is shorter and its edition handling is safer, and Jumsoon's flip was corrected.
- Bongys and Prescripts are summoned without consuming a joker slot, and a Bongy always spawns one of each of the four.
- Tooltips were compacted where they ran off screen: Matthias (15 lines to 8), Sloth (9 to 4), Rien and Sora.
