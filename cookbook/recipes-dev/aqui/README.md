# aqui Recipe

This directory contains a Gaia cookbook recipe for `aqui`, a small UDP broadcast beacon. It announces the device on the local network so you can find its IP address without a serial console or access to the router DHCP table.

"Aqui" is Portuguese for "here".

## How It Works

The `aqui` script runs as a systemd service. Every `AQUI_INTERVAL` seconds it uses `socat` to send one UDP datagram to the broadcast address `255.255.255.255` on port `AQUI_PORT`. The payload is a single line of plain text, without a trailing newline:

```
aqui <hostname> <ip addresses>
```

For example:

```
aqui qemux86-64 172.17.0.5
```

Only the IPv4 addresses of interfaces backed by a device are listed: Ethernet, Wi-Fi, USB and virtio network cards, which have a `/sys/class/net/<iface>/device` link. Virtual interfaces like `lo`, `docker0`, `br-*` and `veth*` are skipped, so the Docker bridge addresses are not reported. The addresses are read with `ifconfig`, so only the primary IPv4 address of each interface is listed.

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
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("", 9999))
while True:
    data, addr = s.recvfrom(1024)
    print(addr[0], data.decode(), flush=True)
'
```

```
172.17.0.5 aqui qemux86-64 172.17.0.5
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
