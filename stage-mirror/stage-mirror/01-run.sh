#!/bin/bash -e

# Create app folder
mkdir -p "${ROOTFS_DIR}/home/mirror/magic-mirror"

# Create the HTML app directly from the script to save steps
cat << 'EOF' > "${ROOTFS_DIR}/home/mirror/magic-mirror/index.html"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { margin: 0; background: #000; overflow: hidden; color: #e8c96a; font-family: serif; }
        #mirror-container { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; }
        #face-svg { height: 65vh; animation: float 4s ease-in-out infinite; }
        @keyframes float { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-20px); } }
        #bubble { position: absolute; top: 10%; background: #2a1a00; border: 3px solid #8a6800; padding: 20px; border-radius: 20px; opacity: 0; transition: opacity 0.5s; }
        #input-wrap { position: absolute; bottom: 5%; width: 60%; display: flex; background: #1a1a1a; border: 2px solid #8a6800; border-radius: 50px; padding: 10px; }
        input { background: transparent; border: none; color: #e8c96a; flex-grow: 1; outline: none; }
    </style>
</head>
<body>
    <div id="mirror-container">
        <div id="bubble">❧ <span id="txt"></span> ❧</div>
        <svg id="face-svg" viewBox="0 0 200 250">
            <ellipse cx="100" cy="120" rx="60" ry="90" fill="#c9a86c" />
            <circle cx="75" cy="110" r="5" fill="#0a2800" />
            <circle cx="125" cy="110" r="5" fill="#0a2800" />
            <path id="mouth" d="M80,170 Q100,180 120,170" stroke="#8b2020" stroke-width="4" fill="none" />
        </svg>
        <div id="input-wrap"><input type="text" placeholder="speak thy question..."></div>
    </div>
    <script>
        // Simple quip logic for boot
        setTimeout(() => {
            document.getElementById('txt').innerText = "I have awakened.";
            document.getElementById('bubble').style.opacity = 1;
        }, 3000);
    </script>
</body>
</html>
EOF

# Force X11 (Disable Wayland)
on_chroot << EOF
sed -i 's/#wayland_enabled=false/wayland_enabled=false/' /etc/lightdm/lightdm.conf
EOF

# Setup Autostart
mkdir -p "${ROOTFS_DIR}/home/mirror/.config/autostart"
cat << EOF > "${ROOTFS_DIR}/home/mirror/.config/autostart/magic-mirror.desktop"
[Desktop Entry]
Type=Application
Exec=/home/mirror/start-mirror.sh
EOF

# Create the startup bash script
cat << 'EOF' > "${ROOTFS_DIR}/home/mirror/start-mirror.sh"
#!/bin/bash
sleep 10
xrandr --output HDMI-1 --rotate left 2>/dev/null || xrandr --output HDMI-A-1 --rotate left
xset s off -dpms
unclutter -idle 0 -root &
chromium --kiosk --no-first-run --start-fullscreen file:///home/mirror/magic-mirror/index.html
EOF
chmod +x "${ROOTFS_DIR}/home/mirror/start-mirror.sh"

# Permissions and Autologin
on_chroot << EOF
useradd -m -p $(openssl passwd -1 mirror) mirror
usermod -aG audio,video,input mirror
EOF

cat << EOF > "${ROOTFS_DIR}/etc/lightdm/lightdm.conf.d/01-mirror.conf"
[Seat:*]
autologin-user=mirror
autologin-user-timeout=0
EOF
