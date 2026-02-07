# Cookbook PhobOS

<p align="center">
    <img
        src="https://github.com/gaiaBuildSystem/.github/raw/main/profile/PhobOS3.png"
        height="140"
    />
</p>

PhobOS is the Debian based and [Torizon](https://torizon.io/) compatible Linux distribution that Gaia builds. The name is a reference to the Greek god, and brother of Deimos, Phobos.

PhobOS is compatible with the Torizon ecosystem. It uses OSTree to manage the system rootfs, Aktualizr to handle updates through Torizon OTA, Torizon remote access and comes with a Docker container runtime.

> Torizon™ is a registered trademark. Gaia project does not talk on behalf of Torizon or on behalf of any Toradex product.

## Supported Platforms

| Board                       | Gaia Machine Name   |
|-----------------------------|---------------------|
| Raspberry Pi 5B             | rpi5b               |
| Raspberry Pi 4B             | rpi4b               |
| Toradex SMARC iMX95         | smarc-imx95         |
| Toradex iMX95 EVK           | imx95-verdin-evk    |
| NXP iMX93 Freedom Board     | imx93-frdm          |
| Toradex Verdin iMX8M Plus   | imx8mp-verdin       |
| Toradex Luna SBC            | luna                |
| Synaptics Astra sl1680      | sl1680              |
| Synaptics Astra sl2619      | sl2619              |
| Generic x86_64              | intel               |
| QEMU x86_64                 | qemux86-64          |
| QEMU arm64                  | qemuarm64           |


## Building PhobOS

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/);
- [Gaia project Gaia Core](https://github.com/gaiaBuildSystem/gaia);
- One of the Machine specific BSP cookbooks:
    - [NXP Boards](https://github.com/gaiaBuildSystem/cookbook-nxp)
    - [Raspberry Pi Boards](https://github.com/gaiaBuildSystem/cookbook-rpi)
    - [Synaptics Astra Boards](https://github.com/gaiaBuildSystem/cookbook-synaptics)
    - [x86_64 Boards](https://github.com/gaiaBuildSystem/cookbook-intel)

### Build

Example of building PhobOS for Toradex iMX95 Verdin EVK using manifest:

1. Create the work directory:

```bash
mkdir workdir
cd workdir
```

2. Clone the Gaia core repo:

```bash
git clone https://github.com/gaiaBuildSystem/gaia.git
```

3. Clone manifest repo:

```bash
git clone https://github.com/gaiaBuildSystem/manifests.git
```

4. Copy the `manifest.json` file from the platform that you want to build for the root of the work directory:

```bash
cp manifests/cookbook-nxp/manifest.json .
```

5. Run the Gaia init script from the root of the work directory:

```bash
./gaia/scripts/init
```

At end of this script execution a dev shell will be opened inside the Gaia container.

6. Run the `bitcook` to build the image on the dev container shell:

> [!WARNING]
The `--buildPath` argument must be an absolute path.

```bash
./gaia/scripts/bitcook/gaia.ts --buildPath /home/<user>/workdir --distro ./cookbook-phobos/distro-phobos-imx95-verdin-evk.json --installHostDeps
```

This will generate the image on the `--buildPath` directory `./build-PhobOS/tmp/imx95-verdin-evk/deploy`

## Torizon OS Feature Comparison

Although systems have design and architectural differences the goal as the project grows is to add to PhobOS some level of feature parity. The table below shows the current status of each key feature:

✅ - Feature is available <br>
⚠️ - Work in progress <br>
⌛ - Feature possible but not planned yet <br>
❌ - Feature will never match <br>
ℹ️ - Community support

| Feature                            | Torizon OS | PhobOS |
| ---------------------------------- | ----------- | ------------------------ |
| OTA Update OS Image                | ✅          | ✅                       |
| OTA Update Container App           | ✅          | ✅                       |
| OTA Update Bootloader              | ✅          | ⌛                       |
| Native apt-get install¹            | ❌          | ✅                       |
| Device Monitoring                  | ✅          | ⌛                       |
| RAC Remote Access                  | ✅          | ✅                       |
| Prebuilt OS Image                  | ✅          | ⌛                       |
| QA Approved Releases               | ✅          | ⌛                       |
| Built with Yocto                   | ✅          | ❌                       |
| Image Customizing with Opus³       | ❌          | ✅                       |
| Image Customizing with TCB²        | ✅          | ❌                       |
| SBOM⁴                              | ✅          | ✅                       |
| Torizon VS Code Extension support⁵ | ✅          | ✅                       |



¹**Native apt-get install**: it is possible to install Debian packages without need of containerization, as the OS is Debian based. <br>
²**TCB**: Torizon Core Builder <br>
³**Opus**: PhobOS image customization tool <br>
⁴**SBOM**: Software Bill of Materials <br>
⁵**Torizon VS Code Extension support**: PhobOS supports the Torizon VS Code templates trought a different repository that need to be configured on the VS Code settings <br>
