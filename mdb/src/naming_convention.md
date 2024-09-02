# The PVox Naming Convention

PVox modules can have any name they desire, whether it be lowercase, uppercase, or even all symbols. This is because all modules are simply keys in a dictionary, you can simply add a new module using `ImplementModule`, and specify its name.

```lua,no_run
-- e.g. module
if ! PVox then return end

PVox:ImplementModule('My Module', function() return { ... } end)
```

<div class="warning">
There's a couple limits to the naming convention when it comes to creating modules, especially procedural modules. When creating a module, if you use the procedural method (via <i>return true</i>), you will notice you have to adhere to Operating System limits.

You can not use uppercase names and lowercase ones interchangeably, due to Windows' filesystem being case insensitive, while Unix-like Operating Systems have a more strict ruling over the case of files and folders.

Therefore, making a procedural module, and calling it `A`, then making its action table in the `pvox/` directory, as `a` instead of `A`, will cause issues when your addon is ran on Unix-like devices. This is not a PVox-specific problem, and should be handled and thought of directly by the caller. See the warnings on [file.Find](https://wiki.facepunch.com/gmod/file.Find) and [file.Read](https://wiki.facepunch.com/gmod/file.Read) for more information. 

These restrictions do *NOT* exist on traditional modules.
</div>

## What About Normal?

When creating a normal module, as opposed to a procedural one where all the files are listed via actual code, a majority of these restrictions are lifted. You can use multiple of PVox's [Generator Functions]() in order to create these sound tables, or write them out manually.

```lua,no_run
-- ...

PVox:ImplementModule('My Module', function(_)
    return {
        ['actions'] = {
            ['pickup_weapon'] = ...
        }
    }
end)
```
