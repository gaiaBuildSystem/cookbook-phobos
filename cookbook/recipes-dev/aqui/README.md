# aqui Recipe

This directory contains a Gaia cookbook recipe for `aqui`, a small UDP broadcast beacon. It announces the device on the local network so you can find its IP address without a serial console or access to the router DHCP table.

"Aqui" is Portuguese for "here".

## How It Works

The `aqui` script runs as a systemd service. Every `AQUI_INTERVAL` seconds it uses `socat` to send one UDP datagram to the broadcast address `255.255.255.255` on port `AQUI_PORT`. The payload is a single line without a trailing newline, starting with the hardcoded `aqui ` prefix followed by a **compact JSON** object:

```
aqui {"hostname":"qemux86-64","ip":["192.168.1.10"],"model":"Standard PC (Q35 + ICH9, 2009)"}
```

The first word `aqui` lets listeners identify the message type. Splitting on the first whitespace leaves the remainder as a single-line JSON object that can be parsed directly with any standard JSON parser:

- **`hostname`** — the system hostname, from the `hostname` command
- **`ip`** — an array of IPv4 addresses of physical network interfaces: Ethernet, Wi-Fi, USB and virtio network cards, which have a `/sys/class/net/<iface>/device` link. Virtual interfaces like `lo`, `docker0`, `br-*` and `veth*` are skipped. Omitted entirely if no interface has a usable address
- **`model`** — the device model from the DMI data, read with the `fastfetch` Host module: the product name plus version when set, e.g. `PhobOS Emulator (0.0)`, falling back to the product family. Omitted if `fastfetch` is unavailable or the DMI data is not set by the O.E.M.

The service starts after `network-online.target`. If the network is not ready yet, the send errors are ignored and the script tries again on the next interval. If the script dies, systemd restarts it after 5 seconds.

## Files

| File | Installed to | Description |
|------|--------------|-------------|
| `files/aqui` | `/usr/bin/aqui` | The beacon script |
| `systemd/aqui.service` | `/etc/systemd/system/aqui.service` | The systemd unit, enabled at build time |
| `deploy.xsh` | - | Copies the files to the image rootfs and enables the service |

The recipe depends on the `socat` and `net-tools` Debian packages, which are added to the image through `targetDeps`.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `AQUI_PORT` | `9999` | UDP port the beacon is sent to |
| `AQUI_INTERVAL` | `5` | Seconds between beacons |

The defaults are set in `systemd/aqui.service`. To change them for an image, edit the `Environment=` lines of the unit. To change them on a running device, use a drop-in:

```bash
systemctl edit aqui.service
```

```ini
[Service]
Environment=AQUI_INTERVAL=10
```

## Adding or Removing It From an Image

Gaia picks up every recipe found in the `searchForRecipesOn` paths of the distro JSON. The PhobOS distros search `cookbook`, so `aqui` is included by default. To leave it out of an image, add it to `excludeRecipes`:

```json
"excludeRecipes": [
    "aqui"
]
```

## Checking the Beacon

### On the Device

Check that the service is running:

```bash
systemctl status aqui
journalctl -u aqui
```

The beacon is also delivered to the device itself, so you can listen for it locally:

```bash
socat -u UDP-RECVFROM:9999,reuseaddr,fork SYSTEM:'cat; echo'
```

### From Another Machine on the Same Network

Use one of the options below. Replace `9999` if you changed `AQUI_PORT`.

With `socat`, printing one beacon per line:

```bash
socat -u UDP-RECVFROM:9999,reuseaddr,fork SYSTEM:'cat; echo'
```

> [!NOTE]
> A plain `socat -u UDP-RECV:9999 -` also works, but because the beacon has no trailing newline all the messages are printed on the same line.

With Python, also printing the address the beacon came from:

```bash
python3 -c '
import socket, json
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("", 9999))
while True:
    data, addr = s.recvfrom(1024)
    msg = data.decode().strip()
    if msg.startswith("aqui "):
        # strip the "aqui " prefix and parse the JSON payload
        try:
            info = json.loads(msg[len("aqui "):])
            hostname = info.get("hostname", "unknown")
            ips = info.get("ip", [])
            model = info.get("model", "")
            print(f"Host: {hostname}")
            if ips:
                print("IPs: " + ", ".join(ips))
            if model:
                print(f"Model: {model}")
        except json.JSONDecodeError as e:
            print(f"Invalid JSON: {e}")
    else:
        print("Unknown message format:", repr(msg))
'
```

Output example:

```
Host: qemux86-64
IPs: 192.168.1.10
Model: Standard PC (Q35 + ICH9, 2009)
```

With `tcpdump`, without opening a socket:

```bash
sudo tcpdump -n -A -i any udp port 9999
```

### Troubleshooting

If nothing arrives:

- Make sure the listener is on the same layer 2 network (same subnet / VLAN) as the device. Routers do not forward broadcasts to other networks.
- Check that the host firewall allows incoming UDP on the beacon port.
- On WSL2 or inside a VM with NAT networking, broadcasts from the physical network may not reach the guest. Listen on the host, or use bridged networking.
- On the device, check `systemctl status aqui` and that `socat` and `ifconfig` are installed.
- If the beacon arrives without any address, the device has no IPv4 address on a physical interface yet, only on virtual ones.
- If the beacon arrives without a model, `fastfetch` is not installed on the device or the DMI product name and family are not set by the O.E.M.
