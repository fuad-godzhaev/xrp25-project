# XR Project Setup Guide

This guide explains how to reuse the XR setup for all your projects without recreating the camera and hands every time.

## Quick Start

### Method 1: Use the XR Player Prefab (Easiest)

1. Create a new scene in Godot
2. Add a Node3D as the root
3. Add these essential nodes:
   - Add a child node: `start_xr` (Node) with script `res://examples/bge/start_xr.gd`
   - Add a child node: `WorldEnvironment` with an Environment resource
   - Add a child node: `DirectionalLight3D` for lighting
4. **Instance the XR Player**: Right-click root → "Instantiate Child Scene" → select `res://xr_player.tscn`
5. Add your project-specific content as additional children

**Result**: You now have a fully functional XR scene with hands and camera!

### Method 2: Use the Complete Base Scene

1. Create a new scene
2. Right-click → "Instantiate Child Scene" → select `res://xr_base_scene.tscn`
3. Add your content under the "Content" node or as siblings

### Method 3: Instance room_with_hands

1. Create a new scene
2. Right-click → "Instantiate Child Scene" → select `res://examples/room/room_with_hands.tscn`
3. Add your project-specific content

## What Each File Does

- **`xr_player.tscn`**: Just the XROrigin with camera and hands (drop into any scene)
- **`xr_base_scene.tscn`**: Complete scene template with lighting and environment
- **`room_with_hands.tscn`**: Full example with additional features

## Example: Loading music_toys into room_with_hands

1. Open `room_with_hands.tscn`
2. Right-click on the root node
3. "Instantiate Child Scene" → select `res://examples/xr_sequencer/music_toys.tscn`
4. In the Scene tree, expand the music_toys instance
5. Delete the duplicate `XROrigin` node (since room_with_hands already has one)
6. Position the sequencer nodes where you want them

## Best Practices

- **Don't duplicate XROrigin**: Only have ONE XROrigin per scene
- **Use the Content node**: Add your objects under a dedicated "Content" node for organization
- **Instance, don't copy**: Use "Instantiate Child Scene" to maintain updates from the base scene
- **Save as templates**: Create your own scene templates for different project types

## Common Nodes You'll Need

Every XR scene needs:
1. `start_xr` node (script) - Initializes XR
2. `XROrigin3D` - The XR camera and controller root
3. `XRCamera3D` - The player's viewpoint
4. Left and right hand controllers with hand models
5. `WorldEnvironment` - For lighting and environment settings

All of these are included in `xr_player.tscn` and `xr_base_scene.tscn`!
