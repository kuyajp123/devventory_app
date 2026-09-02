# Flutter Development Setup & Run Guide

This document covers how to set up and run the **Devventory Go** Flutter app using:

1. Android Emulator
2. Physical Android device via USB cable
3. Physical Android device via Wireless Debugging

## Project Information

| Item | Value |
|---|---|
| App name | Devventory Go |
| Flutter project | `devventory_app` |
| Project path | `C:\Users\Paul\Projects\devventory_app` |
| Android package | `com.devventory.devventory_app` |
| Flutter | `3.47.2` |
| Dart | `3.13.2` |
| Android SDK | `C:\Users\Paul\AppData\Local\Android\Sdk` |

---

# 1. Prerequisites

Make sure the following are installed:

- Flutter SDK
- Android Studio
- Android SDK
- Android SDK Command-Line Tools
- Android SDK Platform
- Android SDK Build Tools
- Android Emulator
- Android device with USB debugging support

Verify Flutter:

```powershell
flutter --version
```

Verify connected devices:

```powershell
flutter devices
```

Expected output can contain devices such as:

```text
Redmi Note 8 Pro
sdk gphone... (emulator)
Windows
Chrome
Edge
```

---

# 2. Project Location

Open PowerShell and navigate to the project:

```powershell
cd C:\Users\Paul\Projects\devventory_app
```

All Flutter commands in this guide assume you are inside this directory.

---

# 3. Run Devventory Go on the Android Emulator

## 3.1 Start the Emulator

Open **Android Studio** and start an Android Virtual Device (AVD).

Alternatively, you can start the emulator from the command line if you know its AVD name.

After the emulator has fully booted, verify that Flutter detects it:

```powershell
flutter devices
```

Example:

```text
sdk gphone16k x86 64 (mobile) • emulator-5554 • android-x64 • Android 15
```

The important part is the device ID:

```text
emulator-5554
```

## 3.2 Run the App

Run:

```powershell
flutter run -d emulator-5554
```

Or, if the emulator is the only available device:

```powershell
flutter run
```

Flutter will build and install the debug APK on the emulator.

## 3.3 During Development

Once the app is running:

- Press `r` to perform a hot reload
- Press `R` to perform a hot restart
- Press `q` to stop the Flutter run session

Example:

```text
r
```

is useful after changing Dart/UI code because it updates the running app without rebuilding everything.

---

# 4. Run Devventory Go on a Physical Android Device Using USB

USB debugging is useful for the first device setup and is generally the simplest physical-device connection.

## 4.1 Enable Developer Options

On the Android phone:

1. Open **Settings**
2. Go to **About phone**
3. Find **MIUI version / Build number** depending on the Android/MIUI version
4. Tap it multiple times until Developer Options are enabled

Then open:

**Settings → Additional settings → Developer options**

Enable:

**USB debugging**

## 4.2 Connect the Phone

Connect the phone to the PC using a USB cable.

The phone may display:

```text
Allow USB debugging?
```

Choose:

**Allow**

You can optionally select:

**Always allow from this computer**

## 4.3 Verify the Device

Run:

```powershell
flutter devices
```

Example:

```text
Redmi Note 8 Pro (mobile) • 6p6drghinfhaqs5x • android-arm64 • Android 11
```

The device ID in this setup is:

```text
6p6drghinfhaqs5x
```

You can also verify through ADB:

```powershell
adb devices
```

Expected:

```text
List of devices attached
6p6drghinfhaqs5x    device
```

## 4.4 Run the App on the Phone

Run:

```powershell
flutter run -d 6p6drghinfhaqs5x
```

Flutter will build, install, and launch Devventory Go on the physical device.

---

# 5. Run Devventory Go on a Physical Device Wirelessly

Wireless debugging allows development without keeping the USB cable connected.

The phone and PC must be connected to the **same Wi-Fi network**.

## 5.1 Enable Wireless Debugging

On the Android phone:

**Settings → Additional settings → Developer options → Wireless debugging**

Turn:

**Wireless debugging → ON**

## 5.2 Pair the Phone with the PC

On the phone, select:

**Pair device with pairing code**

The phone will show an address similar to:

```text
192.168.100.5:43917
```

It will also display a pairing code, for example:

```text
518412
```

The IP address and port shown here are the **pairing address**.

Run on the PC:

```powershell
adb pair 192.168.100.5:43917
```

Enter the pairing code shown on the phone.

Successful pairing looks similar to:

```text
Successfully paired to 192.168.100.5:43917
```

> The pairing port is not necessarily the same port used for the actual wireless connection.

---

# 6. Connect to the Phone Wirelessly

After pairing, return to:

**Developer options → Wireless debugging**

Look for:

**IP address & Port**

It may show something like:

```text
192.168.100.5:37123
```

Use this address with:

```powershell
adb connect 192.168.100.5:37123
```

Expected result:

```text
connected to 192.168.100.5:37123
```

## 6.1 Verify the Wireless Connection

Run:

```powershell
adb devices
```

You should see:

```text
List of devices attached
192.168.100.5:37123    device
```

Then check Flutter:

```powershell
flutter devices
```

The phone should now appear as an Android device.

## 6.2 Unplug the USB Cable

Once the wireless connection is working, the USB cable can be disconnected.

The phone should remain available through ADB over Wi-Fi.

## 6.3 Run the Flutter App Wirelessly

Use the device ID shown by `flutter devices`.

For example:

```powershell
flutter run -d 192.168.100.5:37123
```

Flutter will build and deploy Devventory Go to the physical phone over Wi-Fi.

---

# 7. Understanding `-d`

The `-d` option means **device**.

It tells Flutter exactly which device should run the application.

Syntax:

```powershell
flutter run -d <device-id>
```

Examples:

### Emulator

```powershell
flutter run -d emulator-5554
```

### USB-connected phone

```powershell
flutter run -d 6p6drghinfhaqs5x
```

### Wireless phone

```powershell
flutter run -d 192.168.100.5:37123
```

If multiple devices are connected, using `-d` is recommended so Flutter knows exactly where to deploy the app.

---

# 8. Useful Commands

## Check Flutter Installation

```powershell
flutter --version
```

## Check Flutter Environment

```powershell
flutter doctor
```

The Android toolchain may show an **Android license status unknown** warning with newer Android CLI tooling. If the app can successfully build, install, and run, this warning does not necessarily block development.

## List Flutter Devices

```powershell
flutter devices
```

## List ADB Devices

```powershell
adb devices
```

## Restart ADB

If ADB behaves unexpectedly:

```powershell
adb kill-server
adb start-server
```

Then check:

```powershell
adb devices
```

## Pair Wireless Device

```powershell
adb pair <IP>:<PAIRING_PORT>
```

Example:

```powershell
adb pair 192.168.100.5:43917
```

## Connect Wireless Device

```powershell
adb connect <IP>:<PORT>
```

Example:

```powershell
adb connect 192.168.100.5:37123
```

## Run Flutter

```powershell
flutter run -d <device-id>
```

## Stop Running Flutter App

While `flutter run` is active:

```text
q
```

---

# 9. Troubleshooting

## Flutter Cannot Find the Phone

Run:

```powershell
flutter devices
```

Then:

```powershell
adb devices
```

If using USB:

- Check that USB debugging is enabled.
- Unlock the phone.
- Accept the USB debugging authorization prompt.
- Try another USB cable/USB port.

If using wireless:

- Make sure the phone and PC are on the same Wi-Fi network.
- Make sure Wireless debugging is enabled.
- Run `adb connect` again.
- Check `adb devices`.

---

## Wireless Pairing Fails

If this produces an error:

```powershell
adb pair <IP>:<PORT>
```

Try:

```powershell
adb kill-server
adb start-server
```

Then:

1. Turn Wireless debugging off.
2. Turn it back on.
3. Open **Pair device with pairing code** again.
4. Use the newly displayed IP, port, and pairing code.

The pairing port can change when wireless debugging is restarted.

---

## `adb` Is Not Recognized

If PowerShell says:

```text
adb : The term 'adb' is not recognized...
```

Use the Android SDK's full ADB path:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

For pairing:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" pair <IP>:<PORT>
```

For connecting:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" connect <IP>:<PORT>
```

---

# 10. Recommended Daily Development Workflow

## Emulator

```powershell
cd C:\Users\Paul\Projects\devventory_app
flutter devices
flutter run -d emulator-5554
```

## Physical Device — USB

Connect the phone:

```powershell
flutter devices
flutter run -d 6p6drghinfhaqs5x
```

## Physical Device — Wireless

If the device has already been paired:

```powershell
adb connect <IP>:<PORT>
flutter devices
flutter run -d <wireless-device-id>
```

For example:

```powershell
adb connect 192.168.100.5:37123
flutter run -d 192.168.100.5:37123
```

---

# 11. Quick Reference

| Target | Check | Run |
|---|---|---|
| Android Emulator | `flutter devices` | `flutter run -d emulator-5554` |
| Android Phone via USB | `flutter devices` | `flutter run -d 6p6drghinfhaqs5x` |
| Android Phone via Wi-Fi | `adb devices` / `flutter devices` | `flutter run -d <IP>:<PORT>` |

---

# 12. Important Notes

### USB vs Wireless

**USB**
- Easiest to set up
- Reliable
- Does not depend on Wi-Fi
- Good for initial device setup

**Wireless**
- No USB cable required after pairing
- Phone and PC must be on the same network
- Connection can be less stable on poor Wi-Fi
- Useful for normal day-to-day mobile development

### Pairing vs Connecting

These are two separate steps:

```text
adb pair
    ↓
Establish trust between PC and phone
    ↓
adb connect
    ↓
Create the actual wireless ADB connection
    ↓
flutter run
```

The port used by `adb pair` may be different from the port used by `adb connect`.

---

# 13. Current Devventory Go Setup

The current project has been successfully tested on:

- Android Emulator
- Redmi Note 8 Pro through USB
- Redmi Note 8 Pro through Wireless Debugging

The Android application package is:

```text
com.devventory.devventory_app
```

The product/display name is:

```text
Devventory Go
```

The Flutter project directory is:

```text
C:\Users\Paul\Projects\devventory_app
```
