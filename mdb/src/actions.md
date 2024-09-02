# PVox Actions

Actions are PVox's way of managing sound tables. PVox uses a simple global table in order to manage separate player's modules, and other forms of player sounds.

Globally, the PVox module table looks something like this.

```lua,no_run

['My Cool Module 1'] = {
    ['actions'] = {...},
    ['callouts'] = {...},
    ['footsteps'] = { [ 'default' ] = { ... } }
},

['My Cool Module 2'] = {
    ['actions'] = {...},
    ['callouts'] = {...},
    ['footsteps'] = { [ 'default' ] = { ... } }
},

```

The only required field for modules is the `actions` table. This contains the key value pairs of tables in which sounds can be ran from. Actions are usually string values with no spaces, in all lowercase (with underscores, therefore snake case), and they simply define all of the possible sound files associated with that specific action.

For example, the action `pickup_weapon` is called whenever a player picks up a weapon. This means that to add sounds that can be used with this, you'd put them in a table.

```lua,no_run
function pvox_setup_actions()
    return {
        ['actions'] = {
            ['pickup_weapon'] = {
                'my_sound_dir/pickup1_cool.wav',
                'my_sound_dir/pickup2_cool.wav',
                'my_sound_dir/pickup3_cool.wav',
                'my_sound_dir/pickup4_cool.wav',
            }
        }
    }
end
```

## Types

In PVox implementations, there has always been a consistent standard, linking.

When creating an implementation, instead of linking an action `string` key to a `table` value, you can link it to another `string` to instead use *THAT* action.

```lua,no_run
['actions'] = {
    ['pickup_weapon'] = "on_ready",
    ['on_ready'] = {
        'a.wav',
        'b.wav',
        'c.wav',
    }
}
```

And once run in PVox, those sound files will be called whenever a weapon is picked up, OR whenever `on_ready` is called.

<div class="warning">
As of 9/2/2024, the pickup_weapon action may not be working as expected with the (VManip) Manual Pickup addon installed. See <a href=https://github.com/kdgonz7/ImmPVox/issues/16>PVox Weapon Pickup Sound Bug (Issue No. 16)</a> for more information.
</div>

## Available Actions

While the actual defined amount of actions is unknown, as any action can be ran via `EmitAction`, and it is up to the defined action-table to create sounds for that string, there are some actions which are frequently emitted from the default PVox codebase.

Those include:

* `"death"` - called whenever a player dies.
* `"take_damage_in_vehicle"` - called when a player takes damage in a vehicle.
* `"take_damage"` - called when a player takes general damage
* `"damage_" + npc_class` - called when a player takes damage from `npc_class`. See [Localized Information](./local.md) for more info.
* `npc_class + "_killed"` - called when an NPC of `npc_class` is killed. See [Localized Information](./local.md) for more info.
* `"nice_shot"` - **(New in V9)** called when a friendly NPC gets a kill, and the player sees it. 
    * (may require the **EA** patch to be enabled. See [Extended Actions](./ea.md) for more information.)
* `"enemy_killed"` - when a general enemy/thing is killed.
* `"enemy_spotted"` - called when an enemy is spotted, or has been tagged.
    * They are therefore known by the current player, and other players around them.
* `"confirm_kill"` - when a kill is confirmed. These are separate voice lines and can be created via the `pvox_smart_confirm`.
* `"reload"` - when a player reloads their current weapon.
* `"no_ammo"` - called when a player tries to reload their current weapon, but they have no ammo.
* `"pickup_weapon"` - called when a player picks up a **weapon**
* `"on_ready"` - called when a player spawns in. However, as of v9, `pickup_weapon` has precedence over this action.
    * Use `pickup_weapon` instead, or copy/link `pickup_weapon` here.

### EBA (Extension-Based Actions)

Here are some extension-based actions, or actions which are called from modules, and aren't officially called by PVox itself.

* `inspect` - called when the inspect key is pressed. See [The Inspect Module] for more information.
