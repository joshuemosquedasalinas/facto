# Desktop Pet Cat

A macOS desktop companion — an animated cat that lives in a small floating window and roams freely around your screen.

## What it does

Shadow renders a sprite-animated cat in a transparent, borderless window that moves across your display. The cat behaves autonomously, cycling through locomotion, rest, and aerial states driven by a probabilistic behavior engine. When near screen edges, it will grab walls, climb upward, or descend — and it stays aware of screen bounds at all times.

## Behaviors

- Locomotion — walk, run, sneak, dash
- Rest — idle, sit, lie down, sleep, crouch
- Aerial — hop, wall grab, wall climb, sky climb, sky descent
- Reactions — attack, fright
- Meows — occasional speech bubbles appear beside the cat

## Cat variants

Five color options selectable from the right-click context menu:

┌────────┬──────┐
│  Name  │ Code │
├────────┼──────┤
│ Brown  │ 01   │
├────────┼──────┤
│ Tuxedo │ 02   │
├────────┼──────┤
│ Orange │ 03   │
├────────┼──────┤
│ Grey   │ 04   │
├────────┼──────┤
│ Black  │ 05   │
└────────┴──────┘

## Usage

Right-click the cat to:
- Toggle Hover mode (window stays above all others)
- Switch between cat variants

Hover your cursor over the window to reveal the cat's name label.

## Requirements

- macOS 13 or later
- Xcode 15+

## Build

Open shadow.xcodeproj in Xcode and run the shadow scheme. No external dependencies.
