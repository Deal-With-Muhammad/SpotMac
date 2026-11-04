# SpotMac

Double-tap a key and your screen dims, leaving a spotlight around your cursor. It's made for demos and screen recordings, or for finding your pointer on a big display.

[Read the case study](https://www.dealwithmuhammad.com/work/spotmac)

## What it does

- Lives in the menu bar and shows the spotlight when you double-tap a modifier key
- Follows your cursor, then goes away on any key press or click
- Goes away on its own once the mouse stops moving, unless you turn that off
- Can launch at login
- Has no networking code

The spotlight shows on your main display.

## Settings

| Setting | Options | Default |
| --- | --- | --- |
| Trigger key | Left or right Control, Command, Shift or Option | Left Control |
| Double-tap window | 200 to 600 ms | 400 ms |
| Spotlight radius | 60 to 220 px | 110 px |
| Dim level | 30 to 85% | 55% |
| Soft edge | On or off | On |
| Ring | On or off | Off |
| Fade | On or off | On |
| Auto-dismiss | Off, or 200 to 1500 ms after the mouse stops | On, 500 ms |

## Permissions

Watching for the double-tap needs Accessibility permission. The app shows its status and links you to System Settings.

## Building it

Open `SpotMac.xcodeproj` in Xcode and run the SpotMac target. The project's deployment target is macOS 26.4, so lower it if you're building for an older Mac.

Built with Swift, SwiftUI and AppKit, with no third-party packages.
