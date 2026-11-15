# Sounds to find / make (Stanley)

Ticked ones are in the game. Drop new files in `sound/` and Gavin hooks them up. Each line says **what** and **when it plays**.

## Player
- [x] Footsteps: `Footsteps.mp3`, loops while walking (one track for inside and outside for now)
- [ ] Footsteps, metal: walking inside the facility
- [ ] Hurt: a Listener touches you
- [ ] Death: health hits 0
- [x] Eat: `Food.mp3`, starts the 1 second crumble (cut if you switch away mid-bite)
- [x] Sprint footsteps: same track played 1.35x faster
- [ ] Out of breath: stamina runs dry

## Sonar
- [x] Gun fire: `SonarGSpot.mp3`, every shot
- [ ] Echo ping: the wave front reaches a wall/rock and it lights up
- [ ] Echo return: the bounce-back arc reaches the player (pitch by object size?)
- [ ] Fade-out: wave reaches max range

## Items
- [x] Pickup food / fuel: `CollectPts.mp3`
- [ ] Pickup fuel (own sound)
- [x] Pickup shard: `MagicShard.mp3`, **big and satisfying**
- [ ] Backpack full: you can't pick something up

## Facility
- [ ] Enter hum: walking through the door
- [x] Interior ambient hum: `InterriorAmbience.mp3`, loops while on the factory floor
- [x] Hopper: `Crunch.mp3` loops while fuel crumbles in
- [x] Sun Core deposit: `Shard.mp3` when shards go into the sun
- [ ] Sun ignite stages: the sun gets brighter

## Listeners
- [ ] Idle clicks / breathing
- [x] Alert: `Monstruo.mp3`, a Listener growls (from its position) the moment it starts hunting you
- [ ] Attack: contact damage
- [ ] Hit by sonar
- [x] Death: `Keith Ave.ogg` (converted from `Keith Ave.m4a`), plays from where it died; the boss uses it too
- [ ] Spawn sting: more of them arrive after a shard pickup

## Boss
- [ ] Countdown tick: the 60s timer after shard 5
- [ ] Final 10 seconds warning
- [ ] Spawn roar
- [ ] Hit, death
- [ ] Final shard drop

## Start rolls
- [ ] Slot spin loop + tick
- [ ] Bad result
- [ ] Good result
- [ ] **JACKPOT fanfare**

## Game
- [x] Stage-up sting: `Next Level.mp3`, at shards 2 and 4
- [ ] Low fuel alarm
- [ ] Low health heartbeat
- [ ] Time's up
- [ ] Lose
- [ ] Win: the sun rises

## Music / ambient
- [x] Dark outdoor ambience: `OutsideAmbience.mp3`, loops outside (0.5s crossfade at the door)
- [ ] Stage 3 tension track
- [ ] Ending track
