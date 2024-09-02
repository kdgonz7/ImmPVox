# PVox Call-out API

PVox has a call-out API that is designed to be easy to use and supports a multitude of sounds, similar to [PVox Actions](./actions.md).

To add call-outs to your VOX pack, the method is the same.

<div class="warning">
PVOX, as of v9, does <b>NOT</b> support adding a 'callouts' directory. This is because of insecurity and potential vulnerabilities for server owners. If you would like this as an optional feature, you can open an issue on it <a href="https://github.com/kdgonz7/ImmPVox/issues">here.</a>
</div>

## Accessing Call-outs (v9 ONLY)

To access one of your pack's defined call outs, you can use the `+pvox_open_callout` command, and bind that to a key like so:

```
bind x +pvox_open_callout
```
