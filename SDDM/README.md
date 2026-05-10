# SDDM Display Manager

> **Install path:** `/usr/share/sddm/themes/` (requires root)

SDDM login screen configuration.

## Setup

Copy theme files to the SDDM themes directory:

```bash
sudo cp -r <theme-folder> /usr/share/sddm/themes/<theme-name>
```

Then configure `/etc/sddm.conf`:

```ini
[Theme]
Current=<theme-name>
```
