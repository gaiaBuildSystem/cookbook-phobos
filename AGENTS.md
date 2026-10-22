# Cookbook PhobOS

Cookbook PhobOS has the recipes needed for building the PhobOS Torizon operating system.

PhobOS is the Debian based and Toradex Torizon compatible Linux distribution that Gaia builds. The name is a reference to the Greek god, and brother of Deimos, Phobos.

## Building PhobOS

For building PhobOS follow the instructions provided in the official Gaia documentation.

## Push OSTree to Torizon

The PhobOS build generates an OSTree repository and commit that represents the current state of the system. This commit can then be pushed to the Torizon cloud for deployment to devices and fleets.

To push the OSTree commit to Torizon you need an account and the `credentials.zip` file provided by Torizon.

Once you have the credentials, you can use the `ostree` recipe to automatically push the commit to the Torizon cloud. By default it's disabled, to enable it  copy the `credentials.zip` file to the `cookbook-phobos/cookbook/recipes-update/ostree/credentials` directory and set the environment variable before the build command:

```bash
OSTREE_GARAGE_PUSH=true ./gaia/bitcook --buildPath /your/workdir --distro ./cookbook-phobos/distro-phobos-qemux86-64.json  --installHostDeps --noCache --overrideEnv
```

Attention to the need of the `--overrideEnv` argument which will override the environment variable set at recipe metadata level.
