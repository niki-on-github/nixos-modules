# ALVR

- https://github.com/NixOS/nixpkgs/pull/308097
- https://github.com/alvr-org/ALVR/wiki/Linux-Troubleshooting#steamvr

## Setup

1. Install Steam VR
2. `sudo setcap CAP_SYS_NICE+ep ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher`
3. In `Steam : Library` Search for SteamVR. Right click `Properties`. Insert Lauch Options: `QT_QPA_PLATFORM=xcb ~/.local/share/Steam/steamapps/common/SteamVR/bin/vrmonitor.sh %command%`
