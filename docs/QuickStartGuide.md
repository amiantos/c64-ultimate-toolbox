This is a guide walking through how to get C64 Ultimate Toolbox working with your Ultimate 64 or your Commodore 64 Ultimate.

---

## Requirements

* A **Commodore 64 Ultimate** (C64U) or **Ultimate 64** connected to your local network via **Ethernet**
* A Mac running **macOS 26** or later, connected to the same local network (Ethernet or Wi-Fi)
* Both devices must be on the **same local network**
* **Toolbox Mode** requires **FTP File Service** and **Web Remote Control Service** enabled on the device

> **Note:** The C64U must use its Ethernet port for streaming. Wi-Fi on the C64U does not support the data stream feature. Your Mac can connect via Wi-Fi, but Ethernet on both sides is recommended for the most stable connection.

## Connection Modes

C64 Ultimate Toolbox offers two ways to connect:

* **Viewer Mode** — Passively listens for video and audio streams. You manually start the streams on the C64U. No API connection needed.
* **Toolbox Mode** — Connects to the C64U's REST API and FTP server for automatic stream setup, file browsing and transfer, device control, and keyboard forwarding.

---

## Toolbox Mode Setup

Toolbox Mode gives you full control of your C64U from your Mac — automatic stream setup, file management, BASIC scratchpad, device control, and keyboard forwarding.

### 1. Enable Network Services on the C64U

On your Commodore 64 Ultimate:

1. Bring up your **Ultimate Menu** (multi-function up or C= + RESTORE).
2. Navigate to **"Network Services"** and press **RETURN**.
3. Enable **"FTP File Service"** — set it to **"Enabled"**.
4. Enable **"Web Remote Control Service"** — set it to **"Enabled"**.
5. If you have set a network password, note it down — you'll need it to connect.

### 2. Connect in Toolbox Mode

1. Launch **C64 Ultimate Toolbox** on your Mac.
2. Under **Toolbox Mode**, the app automatically scans your network for Ultimate devices every 5 seconds.
3. Your device should appear under **Discovered Devices** with its product name, hostname, and IP address.
   - A lock icon (🔒) indicates the device requires a password.
   - A warning (⚠️ FTP disabled) means the FTP File Service needs to be enabled.
4. Click your device to connect. If it requires a password, you'll be prompted — check **Save Password** to remember it.
5. The app will verify the connection, fetch device info, and automatically start the video and audio streams.

If your device doesn't appear automatically, use **Manual Connect** by entering the IP address and clicking **Connect**.

> **Tip:** To find your C64U's IP address manually, open the Ultimate Menu, navigate to **"Wired Network Setup"**, and check the **"Active IP address"**.

---

## Viewer Mode Setup

### 1. Connect Your C64U to the Network

The C64U must be connected to your local network via its **Ethernet port**. Video and audio streaming is not available over Wi-Fi — it requires the wired LAN connection.

Connect an Ethernet cable from the port on the back-left of the C64U to your router. Most routers assign an IP address automatically via DHCP.

### 2. Start the Data Streams

On your Commodore 64 Ultimate (or Ultimate 64, etc):

1. Bring up your **Ultimate Menu** (multi-function up or C= + RESTORE).
2. Hit **F1** to bring up the sub-menu.
3. Go to **Streams**.
4. Select **VIC Stream**.
5. Put in your Mac's IP address and port (e.g. `192.168.1.76:11000`) and press **RETURN**.
6. Repeat this process from step 1, but select **Audio Stream**.
7. Put in your Mac's IP address and the port (e.g. `192.168.1.76:11001`) and press **RETURN**.

### 3. Connect in Viewer Mode

1. Launch **C64 Ultimate Toolbox** on your Mac.
2. Switch to **Viewer Mode** using the tab at the top.
3. Your Mac's local IP address is displayed in the help text for reference.
4. Verify the **Video Port** is **11000** and **Audio Port** is **11001** (these must match the ports configured on the C64U).
5. Click **Listen**.
6. You should see the C64U's screen appear within a moment.

Your recent Viewer Mode sessions are saved for quick reconnection.

---

## Troubleshooting

**Device not appearing in Discovered Devices:**

* Make sure the C64U is connected via **Ethernet** and on the same local network as your Mac.
* Make sure **Web Remote Control Service** is enabled in Network Services.
* If macOS prompts for local network access permission, approve it — the next scan will find your device.
* Try using Manual Connect with the device's IP address.

**Lock icon (🔒) on discovered device:**

* The device has a network password set. Click it and enter the password when prompted.

**"⚠️ FTP disabled" on discovered device:**

* Enable **FTP File Service** in the C64U's Network Services menu.

**"Unable to start streams" error:**

* The C64U must be connected via **Ethernet** for streaming. Wi-Fi does not support data streams.

**No video appears (Viewer Mode):**

* Make sure you have started the **VIC Stream** in the Ultimate Menu, pointed at your Mac's IP address.
* Make sure both devices are on the same local network.
* Check that the Video Port matches the port configured on the C64U (default: **11000**).

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

**File manager not connecting:**

* Make sure **FTP File Service** is enabled on the device.
* If the device has a password, the file manager uses it automatically — make sure you connected with the correct password.
