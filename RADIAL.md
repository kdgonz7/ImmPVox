# PVOX Radial Callout Menu

This client-side script provides a visually appealing and interactive radial menu allowing players to select and activate voice callouts defined in their currently active PVOX module.

## Overview

When activated (typically by holding down a key), a circular menu appears centered on the player's screen. Callout options, plus a "Cancel" option, are arranged around a central hub. Players can select an option using their mouse or scroll wheel and then trigger the selected callout by releasing the activation key.

## Appearance & Visuals

* **Activation & Animation:**
    * The menu smoothly fades in and expands outwards from the center when activated.
    * It contracts and fades out when deactivated.
    * Animations use linear interpolation (`Lerp`) based on `FrameTime` for smoothness across different frame rates.
* **Layout:**
    * Always centered on the screen (`ScrW() / 2`, `ScrH() / 2`).
    * Consists of a central circle displaying "PVOX".
    * An outer ring defines the main radius of the menu.
    * Callout options are presented as smaller circles evenly spaced around the outer ring.
    * Lines connect the central circle to each option circle.
* **Styling & Effects:**
    * Uses predefined colors (`MenuColors` table) for background, rings, text, selection, and hover states.
    * The menu background has a semi-transparent, blurred effect (`draw.BlurredCircle`) to enhance readability over the game world.
    * Text uses custom fonts: `PVox-Normal-HUD-Font` for the center title and selection indicator, `PVox-Radial-HUD-Font` for the callout option text. (These fonts must be defined elsewhere, e.g., via `surface.CreateFont`).
    * The "Cancel" option is visually marked with a "✕" symbol.
* **Selection & Hover Indication:**
    * **Hover:** Moving the mouse cursor over an option circle makes it slightly larger and changes its background color (`MenuColors.Hover`).
    * **Selection:** The currently selected option is noticeably larger, uses the highlight color (`MenuColors.Selected`), and has a subtle outer glow effect. A separate pointer ("▶") also rotates around the outside of the menu to point directly at the selected option.

## Interaction & Controls

* **Activation:** The menu is displayed as long as the `+pvox_open_callout` console command is active (typically bound to a key press).
* **Mouse Control:**
    * When the menu is open, the mouse cursor becomes visible and usable (`gui.EnableScreenClicker(true)`).
    * Moving the mouse over an option highlights it.
    * Left-clicking (`MOUSE_LEFT`) on a highlighted option instantly selects it. A standard UI click sound (`ui/buttonclick.wav`) plays if the selection changes via click.
* **Scroll Wheel Control:**
    * Pressing the key bound to `invnext` (usually Mouse Wheel Down) cycles the selection forward through the options.
    * Pressing the key bound to `invprev` (usually Mouse Wheel Up) cycles the selection backward.
    * Selection wraps around (selecting next on the last item goes to the first, and vice-versa).
* **Triggering a Callout:**
    * Releasing the key bound to `+pvox_open_callout` (which executes `-pvox_open_callout`) finalizes the selection.
    * If the selected option is **not** "Cancel", its name is sent to the server via the `PVOX_Callout` network message, triggering the corresponding voice line.
    * The mouse cursor is hidden again (`gui.EnableScreenClicker(false)`).
    * The menu animates closed.

## How It Works

1.  **Initialization:** When `+pvox_open_callout` is activated:
    * Sets `PVoxCalloutMenuOpen` to `true`.
    * Enables the mouse cursor.
    * Clears and rebuilds the `Options` table:
        * Gets the local player's current PVOX module using `PVox:GetPlayerModule(LocalPlayer())`.
        * Retrieves the `callouts` table from the module.
        * Gets the keys (callout names) from the `callouts` table.
        * Sorts the keys alphabetically.
        * Adds a "Cancel" entry to the end of the list.
    * Sets the initial `Selected` item to be the "Cancel" option.
2.  **Drawing (`HUDPaint`):**
    * Checks if the player is alive and if the menu should be visible (`PVoxCalloutMenuAlpha > 0`).
    * Calculates animation states (`OpenAnimation`, `PVoxCalloutMenuAlpha`).
    * Draws the blurred background, central circle, outer ring, and connecting lines, applying animations and alpha.
    * Determines the mouse position and calculates the angle and distance relative to the menu center.
    * Checks if the mouse is within the interactive area and calculates which item is being hovered (`HoverItem`) based on the mouse angle.
    * Draws each option circle and its text, applying scaling and color changes for hover and selection states.
    * Draws the selection indicator ("▶") pointing at the currently selected item.
3.  **Input Handling:**
    * `PlayerBindPress`: Listens for `invnext` and `invprev` binds while the menu is open to update the `Selected` index.
    * `Think`: Listens for `MOUSE_LEFT` clicks while the menu is open. If a click occurs while `HoverItem` is valid, it sets `Selected` to match `HoverItem`.
4.  **Deactivation (`-pvox_open_callout`):**
    * Sets `PVoxCalloutMenuOpen` to `false` (starting the closing animation).
    * Hides the mouse cursor.
    * Checks the name of the currently `Selected` option in the `Options` table.
    * If the selected option is valid and **not** "Cancel", it sends the option name to the server using `net.Start("PVOX_Callout")`.
    * Resets internal state (`Selected = 1`, `Options = {}`).

## Usage & Keybinding

This radial menu is designed to be bound to a key. You hold the key to open the menu, select your desired callout using the mouse or scroll wheel, and then release the key to activate the callout.

**Example Keybind:**

To bind the menu to the `C` key, open your console (`~`) and type:

```lua
bind c +pvox_open_callout
```