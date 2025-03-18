# Cookbook PhobOS

<p align="center">
    <img
        src="https://github.com/gaiaBuildSystem/.github/raw/main/profile/PhobOS1.png"
        height="112"
    />
</p>

PhobOS is the Debian based and Toradex Torizon compatible Linux distribution that Gaia builds. The name is a reference to the Greek god, and brother of Deimos, Phobos.

PhobOS is compatible with the Toradex Torizon ecosystem. It uses OSTree to manage the system rootfs, Aktualizr to handle updates through Torizon OTA and comes with a Docker container runtime.

> Torizon™ is a registered trademark of Toradex Group AG. Gaia project does not talk on behalf of Toradex or on behalf of any Toradex product.

## Building PhobOS

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/);
- [Gaia project Gaia Core](https://github.com/gaiaBuildSystem/gaia);

<p align="center">
    <img
        src="https://github.com/gaiaBuildSystem/.github/raw/main/profile/GaiaBuildSystemLogoDebCircle.png"
        alt="This is a Gaia Project based cookbook"
        width="170"
    />
</p>

- One of the Machine specific BSP cookbooks:
    - [NXP Boards](https://github.com/gaiaBuildSystem/cookbook-nxp)
    - [Raspberry Pi Boards](https://github.com/gaiaBuildSystem/cookbook-rpi)

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

| Feature                           | Torizon OS | PhobOS iMX95 Verdin EVK | PhobOS Raspberry Pi 5B |
| --------------------------------- | ---------- | ----------------------- | ---------------------- |
| OTA Update OS Image               | ✅          | ✅                       | ✅                      |
| OTA Update Container App          | ✅          | ✅                       | ✅                      |
| OTA Update Bootloader             | ✅          | ⌛                       | ⌛                      |
| Debian package development*       | ❌          | ✅                       | ✅                      |
| Device Monitoring                 | ✅          | ⌛                       | ⌛                      |
| RAC Remote Access                 | ✅          | ⌛                       | ⌛                      |
| Free Technical Support            | ✅          | ℹ️                      | ℹ️                     |
| Prebuilt OS Image                 | ✅          | ⌛                       | ⌛                      |
| QA Approved Releases              | ✅          | ⌛                       | ⌛                      |
| Built with Yocto                  | ✅          | ❌                       | ❌                      |
| Image Customizing with TCB**      | ✅          | ❌                       | ❌                      |
| SBOM***                           | ✅          | ⌛                       | ⌛                      |
| Torizon VS Code Extension support | ✅          | ⌛                       | ⌛                      |



***Debian package development**: it is possible to install Debian packages without need of containerization, as the OS is Debian based. <br>
****TCB**: Torizon Core Builder <br>
*****SBOM**: Software Bill of Materials <br>
