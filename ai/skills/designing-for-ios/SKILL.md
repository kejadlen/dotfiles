---
name: designing-for-ios
description: Use when designing UI for iOS apps, reviewing iOS interface decisions, building SwiftUI views for iPhone, or advising on layout, navigation, typography, gestures, or accessibility for iOS. Covers Liquid Glass, Dynamic Type, safe areas, toolbars, tab bars, and ergonomic touch targets.
---

# Designing for iOS

Quick reference for iOS design based on the Apple Human Interface Guidelines. Consult the full HIG at developer.apple.com/design/human-interface-guidelines for detailed specifications and additional topics.

## Core Principles

iPhone is a medium-size, high-resolution display held in one or both hands at arm's length. Design for this context:

- **Focus on primary tasks.** Limit onscreen controls; make secondary actions discoverable with minimal interaction.
- **Adapt to context changes.** Support orientation, Dark Mode, Dynamic Type. Let people choose configurations.
- **Design for reach.** Place important controls in the middle or bottom of the display. Let people swipe to navigate back or act on list rows.
- **Integrate platform capabilities with permission.** Biometric auth, payments, location, gyroscope, camera -- enhance the experience without forcing data entry.

## Layout

### Safe Areas and Guides

Respect safe areas -- they avoid Dynamic Island, home indicator, sensor housing, and toolbars. Content backgrounds extend to screen edges; interactive content stays within safe areas.

### Key Rules

- Extend backgrounds full-bleed to display edges.
- Group related items; separate with spacing, shapes, or color.
- Place important content in reading order (top-leading).
- Support both portrait and landscape unless your app strictly requires one.
- Avoid full-width buttons -- respect system margins and screen curvature.
- Hide the status bar only in immersive experiences (games, media playback).

### Size Classes

| Orientation | Width | Height |
|---|---|---|
| Portrait | Compact | Regular |
| Landscape (standard) | Compact | Compact |
| Landscape (Plus/Max) | Regular | Compact |

Design layouts that adapt to size class changes. Use SwiftUI or Auto Layout.

### Device Dimensions (Common)

| Model Group | Points (portrait) | Scale |
|---|---|---|
| iPhone 16/17 Pro Max | 440x956 | @3x |
| iPhone 16/17 Pro, 17 | 402x874 | @3x |
| iPhone 16 Plus, 15 Plus | 430x932 | @3x |
| iPhone 16, 15 | 393x852 | @3x |
| iPhone 16e, 14 | 390x844 | @3x |

## Toolbars (Navigation)

As of iOS 26 / Liquid Glass, navigation bars are consolidated into **toolbars**. A toolbar provides title, navigation (back/forward), search, and action items.

### Structure

| Position | Content |
|---|---|
| Leading edge | Back button, view title, document menu |
| Center area | Common actions (customizable on iPad) |
| Trailing edge | Key actions, search, More menu, primary action (Done/Save) |

### iOS-Specific

- Prioritize only essential items -- space is limited. Use a More menu for additional actions.
- Use **large titles** -- they transition to standard size on scroll, helping orientation.
- Use standard Back (circle chevron symbol) and Close (X) buttons. Don't use text labels for these.
- Use SF Symbols without borders for action items.
- Use `.prominent` style for a single primary action (e.g., Done) on the trailing edge.
- Reduce custom toolbar backgrounds -- let Liquid Glass and scroll edge effects handle the content/control distinction.

## Tab Bars

Use tab bars for top-level navigation between app areas. Toolbars act on content within a view.

## Typography

### System Fonts

- SF Pro, the system sans-serif for iOS.
- New York (NY), a serif alternative.
- Both support variable font format with dynamic optical sizing.

### Default and Minimum Sizes

| Context | Default | Minimum |
|---|---|---|
| iOS/iPadOS | 17 pt | 11 pt |

### Key Text Styles (Large / Default Size)

| Style | Weight | Size | Leading |
|---|---|---|---|
| Large Title | Regular | 34 pt | 41 pt |
| Title 1 | Regular | 28 pt | 34 pt |
| Title 2 | Regular | 22 pt | 28 pt |
| Title 3 | Regular | 20 pt | 25 pt |
| Headline | Semibold | 17 pt | 22 pt |
| Body | Regular | 17 pt | 22 pt |
| Callout | Regular | 16 pt | 21 pt |
| Subhead | Regular | 15 pt | 20 pt |
| Footnote | Regular | 13 pt | 18 pt |
| Caption 1 | Regular | 12 pt | 16 pt |
| Caption 2 | Regular | 11 pt | 13 pt |

### Dynamic Type

- Always support Dynamic Type. Text scales across 7 standard sizes (xSmall-xxxLarge) plus 5 accessibility sizes (AX1-AX5).
- Adapt layout at large sizes: switch inline items to stacked layouts, reduce columns.
- Scale meaningful icons alongside text (SF Symbols do this automatically).
- Minimize truncation. Use `numberOfLines` for wrapping; avoid tight leading for 3+ lines.
- Maintain information hierarchy at all sizes -- keep primary elements at top.

### Best Practices

- Prefer Regular, Medium, Semibold, or Bold weights. Avoid Ultralight, Thin, Light.
- Minimize typeface count.
- Use built-in text styles for consistent hierarchy.
- Prioritize important content when responding to size changes -- not everything needs to grow equally.

## Gestures

### Standard Gestures

| Gesture | Action |
|---|---|
| Tap | Activate control, select item |
| Swipe | Reveal actions, dismiss views, scroll |
| Drag | Move an element |
| Touch and hold | Reveal context menu or additional controls |
| Double tap | Zoom in/out |
| Pinch | Zoom |
| Rotate | Rotate selected item |

### iOS-Specific

| Gesture | Action |
|---|---|
| Three-finger swipe left/right | Undo / Redo |
| Three-finger pinch in/out | Copy / Paste |
| Shake | Undo / Redo |

### Best Practices

- Use standard gestures with standard meanings. Don't repurpose tap or swipe for non-standard actions.
- Provide responsive, immediate feedback during gestures.
- Indicate when a gesture is unavailable (e.g., locked object, disabled button).
- Custom gestures must be discoverable, easy to perform, distinct from standard gestures, and never the only way to perform an action.
- Don't conflict with system edge gestures (swipe from bottom, top corners).

## Adaptability Checklist

When designing for iOS, verify:

- [ ] Layout respects safe areas (Dynamic Island, home indicator, rounded corners)
- [ ] Both orientations work (or experience gracefully locks to one)
- [ ] Dynamic Type supported across all text styles
- [ ] Dark Mode supported with appropriate colors and materials
- [ ] Controls reachable in one-handed use (middle/bottom of screen)
- [ ] Swipe-to-go-back works throughout navigation hierarchy
- [ ] Content extends full-bleed behind translucent bars
- [ ] Toolbar items use SF Symbols, not text labels (except Edit/Done)
- [ ] Large title used for primary navigation views
- [ ] No full-width buttons (respect system margins)
- [ ] Accessibility: VoiceOver labels, sufficient contrast, hit targets >= 44pt

## System Integration

Support these where relevant:

- **Widgets** -- glanceable info on Home Screen and Lock Screen
- **Home Screen quick actions** -- 3D Touch / long-press shortcuts on app icon
- **Spotlight** -- index app content for system search
- **Shortcuts / Siri** -- expose key actions as intents
- **Activity views** -- standard share sheet for sharing content
- **Live Activities** -- real-time updates on Lock Screen and Dynamic Island

## Common Mistakes

| Mistake | Fix |
|---|---|
| Text labels for Back button | Use standard circle chevron symbol |
| Bordered SF Symbols in toolbars | Use unbounded symbols; system provides hover/selection states |
| Custom toolbar backgrounds | Let Liquid Glass and scroll edge effects handle layering |
| Ignoring Dynamic Type | Use text styles; test at AX5 accessibility size |
| Controls only at top of screen | Place frequent actions at middle/bottom for reachability |
| Full-width buttons | Inset from edges; match screen curvature |
| Mixing too many toolbar item groups | Maximum 3 groups; keep it clean |
| Separate text and symbol buttons in same group | Insert fixed space between text-labeled and symbol buttons |
