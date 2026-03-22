This is a guide walking through how to get C64 Ultimate Toolbox working with your Ultimate 64 or your Commodore 64 Ultimate.

---

## Requirements

* A **Commodore 64 Ultimate** (C64U) or **Ultimate 64** connected to your local network via **Ethernet**
* A Mac running **macOS 14.6** or later, connected to the same local network (Ethernet or Wi-Fi)
* Both devices must be on the **same local network**
* **Toolbox Mode** requires firmware **3.11+** with REST API enabled

> **Note:** The C64U must use its Ethernet port for streaming. Wi-Fi on the C64U does not support the data stream feature. Your Mac can connect via Wi-Fi, but Ethernet on both sides is recommended for the most stable connection.

## Connection Modes

C64 Ultimate Toolbox offers two ways to connect:

* **Viewer Mode** — Passively listens for video and audio streams. You manually start the streams on the C64U. No API connection needed.
* **Toolbox Mode** — Connects to the C64U's REST API to automatically start streams, load files, control the machine, and forward keyboard input.

---

## Viewer Mode Setup

### 1. Connect Your C64U to the Network

The C64U must be connected to your local network via its **Ethernet port**. Video and audio streaming is not available over Wi-Fi — it requires the wired LAN connection.

Connect an Ethernet cable from the port on the back-left of the C64U to your router. Most routers assign an IP address automatically via DHCP.

To confirm the connection:

1. Open the C64U Menu by pressing the **Multi Function Switch** upward.
2. Navigate to **"Wired Network Setup"** using the **W** and **S** keys, then press **RETURN**.
3. Confirm that **"Use DHCP"** is **"Enabled"**.
4. Confirm that **"Active IP address"** shows a valid IP address (not `0.0.0.0`).

### 2. Find Your Mac's IP Address

You'll need your Mac's local IP address to tell the C64U where to send the streams.

1. Open **System Settings** on your Mac.
2. Go to **Network** (or **Wi-Fi** / **Ethernet** depending on your connection).
3. Note your Mac's IP address (e.g. `192.168.1.76`).

### 3. Start the Data Streams

On your Commodore 64 Ultimate (or Ultimate 64, etc):

1. Bring up your **Ultimate Menu** (multi-function up or C= + RESTORE).
2. Hit **F1** to bring up the sub-menu.
3. Go to **Streams**.
4. Select **VIC Stream**.
5. Put in your Mac's IP address and port (e.g. `192.168.1.76:11000`) and press **RETURN**.
6. Repeat this process from step 1, but select **Audio Stream**.
7. Put in your Mac's IP address and the port (e.g. `192.168.1.76:11001`) and press **RETURN**.

### 4. Connect in Viewer Mode

1. Launch **C64 Ultimate Toolbox** on your Mac.
2. Under **Viewer Mode**, your Mac's local IP address is displayed for reference.
3. Verify the **Video Port** is **11000** and **Audio Port** is **11001** (these must match the ports configured on the C64U).
4. Click **Listen**.
5. You should see the C64U's screen appear within a moment.

Your recent Viewer Mode sessions are saved for quick reconnection.

---

## Toolbox Mode Setup

Toolbox Mode gives you full control of your C64U from your Mac — automatic stream setup, device info, file loading, machine control, and keyboard forwarding.

### 1. Enable Network Services on the C64U

On your Commodore 64 Ultimate:

1. Bring up your **Ultimate Menu** (multi-function up or C= + RESTORE).
2. Navigate to **"Network Services"** and press **RETURN**.
3. Enable **"FTP File Service"** — set it to **"Enabled"**.
4. Enable **"Web Remote Control Service"** — set it to **"Enabled"**.
5. If you have set a network password, note it down — you'll need it to connect.

### 2. Find Your C64U's IP Address

1. In the Ultimate Menu, navigate to **"Wired Network Setup"**.
2. Note the **"Active IP address"** (e.g. `192.168.1.24`).

### 3. Connect in Toolbox Mode

1. Launch **C64 Ultimate Toolbox** on your Mac.
2. Under **Toolbox Mode**, enter your C64U's **IP Address**.
3. If your C64U has a network password configured, enter it in the **Password** field. Check **Save Password** if you'd like it remembered.
4. Click **Connect**.
5. The app will verify the connection, fetch device info, and automatically start the video and audio streams.

Your recent Toolbox Mode connections are saved for quick reconnection.

---

## Using the App

### Controls Overlay

When connected, click anywhere on the video to open the controls overlay. The available controls depend on your connection mode:

**Both modes:**
* **Audio** — Adjust volume and stereo balance
* **CRT Filter** — Open the CRT effects editor

**Toolbox Mode only:**
* **Start/Stop Streams** — Manually start or stop the video and audio streams
* **Run File** — Load a SID, PRG, or CRT file from your Mac onto the C64U
* **Menu** — Press the Ultimate menu button
* **Reset** — Reset the C64 (with confirmation)
* **Reboot** — Reboot the device; streams automatically restart when it comes back online (with confirmation)
* **Power Off** — Power off the device and return to the home screen (with confirmation)
* **Keyboard** — Toggle keyboard forwarding (see below)

Click outside the overlay or press **Escape** to dismiss it.

### Keyboard Forwarding (Toolbox Mode)

When enabled, your Mac keyboard input is forwarded to the C64 in real time. This works with BASIC and programs that read input through the KERNAL (text adventures, etc.). It does not work in the Ultimate menu or with most games that read the keyboard hardware directly.

An on-screen key strip appears at the bottom of the window with C64-specific keys:
* **F1–F8** function keys
* **RUN/STOP**, **HOME**, **CLR**, **INST**, **DEL**
* **Cursor keys** (up, down, left, right)
* **MENU** button (opens Ultimate menu)
* Special characters: **£**, **↑**, **←**
* **SH+RET** (shifted RETURN)

A blue **KB** indicator appears in the status bar when keyboard forwarding is active.

### Audio Controls

| Action | Shortcut |
|----|-----|
| Volume Up | **Cmd+Up Arrow** |
| Volume Down | **Cmd+Down Arrow** |
| Mute/Unmute | **Shift+Cmd+M** |

You can also adjust volume and stereo balance from the Audio screen in the controls overlay.

### Window Size

The CRT shader renders at your window size — just resize the window to your preferred resolution. The display always maintains the correct aspect ratio.

### CRT Effect Presets

C64 Ultimate Toolbox includes 8 built-in presets that simulate the look of classic CRT monitors:

* **Clean** — No effects, pure pixel output
* **Home CRT** — Subtle scanlines, bloom, shadow mask, curvature, and vignette
* **P3 Amber** — Amber monochrome monitor with afterglow
* **P1 Green** — Classic green phosphor monitor
* **Crisp** — Minimal scanlines, very clean
* **Warm Glow** — Soft bloom and persistent afterglow
* **Old TV** — Heavy scanlines, slot mask, strong curvature and vignette
* **Arcade** — Arcade cabinet look with aperture grille mask

Select a preset from the **Preset** menu in the menu bar. A checkmark indicates the active preset, and an asterisk indicates a modified built-in preset.

### Customizing CRT Effects

Open the CRT Filter screen from the controls overlay (click the video, then tap **CRT Filter**). All changes are applied in real time — the background dims away so you can see your adjustments live.

**Available parameters:**

* **Scanlines** — Intensity and width
* **Bloom & Blur** — Blur radius, bloom intensity, and bloom radius
* **Tint** — None, Amber, Green, or Monochrome, with adjustable strength
* **Phosphor Mask** — Aperture Grille, Shadow Mask, or Slot Mask, with adjustable intensity
* **Screen Shape** — Curvature (barrel distortion) and vignette (corner darkening)
* **Afterglow** — Phosphor persistence strength and decay speed

You can save your customized settings as a new preset using the **Save As...** button, or from **Preset > Save As New Preset** in the menu bar. To revert a modified built-in preset, use **Reset** or **Preset > Reset to Default**.

### Screenshots

Press **Shift+Cmd+S** or use **Capture > Take Screenshot** to save the current frame as a PNG file. CRT effects are included in the screenshot. The screenshot resolution matches your current window size.

### Video Recording

Press **Shift+Cmd+R** or use **Capture > Start Recording** to begin recording. The recording includes both video (with CRT effects applied) and audio. Press the same shortcut again to stop recording. Recordings are saved as MOV files with H.264 video. The window cannot be resized during recording.

### Disconnecting

Press **Cmd+D** or use the **Stream > Disconnect** menu item to disconnect. In Toolbox Mode, the app will automatically stop the streams on the C64U before disconnecting.

---

## Troubleshooting

**No video appears (Viewer Mode):**

* Make sure you have started the **VIC Stream** in the Ultimate Menu, pointed at your Mac's IP address.
* Make sure the C64U is connected via **Ethernet** (not Wi-Fi). Streaming is only available over the wired LAN connection.
* Make sure both devices are on the same local network.
* Check that the Video Port matches the port configured on the C64U (default: **11000**).

**No video appears (Toolbox Mode):**

* Make sure **Web Remote Control Service** is enabled in the C64U's Network Services menu.
* Verify the IP address is correct and the C64U is reachable on the network.
* If the device has a network password, make sure you've entered it correctly.
* Try clicking **Start Streams** in the controls overlay to manually restart the streams.

**"Incorrect password" error:**

* Check your network password in the C64U's Network Services settings.
* Passwords are case-sensitive.

**No audio:**

* In Viewer Mode, make sure you have started the **Audio Stream** in the Ultimate Menu, pointed at your Mac's IP address.
* Make sure the volume is turned up and not muted (**Shift+Cmd+M** to toggle mute).
* Check the stereo balance in the Audio controls — it may be shifted to one channel.

**Choppy video or dropped frames:**

* Use an Ethernet connection on your Mac as well for the most stable stream.
* Check the FPS counter in the bottom-right corner of the window. PAL runs at 50 FPS and NTSC at 60 FPS.

**Keyboard forwarding not working:**

* Keyboard forwarding only works with programs that read input through the KERNAL (BASIC, text editors, etc.). Most games and the Ultimate menu read the keyboard hardware directly and will not respond.
* Make sure the keyboard is enabled — look for the blue **KB** indicator in the status bar.