# Flight Images

Flight Images provides scripts for building and booting diskless clients from squashed OS images.

## Installation

A script is provided to setup the diskless host, which:
- Sets up TFTP/PXE
- Configures HTTP
- Sets up the internal PXE network
- Downloads the scripts for building images

(Note: the script presumes the interface eth0 is connected to the internal network for PXE boot)

Set up the host by curling the script as the root user:
```bash
curl https://raw.githubusercontent.com/openflighthpc/flight-images/master/host_setup.sh |/bin/bash
```

There are some customisation options to the host setup script which can be overridden at installation time:
- `INTEFACE`: Default `eth0`, the interface to configure IP settings for and use for DHCP/TFTP/HTTP/NFS.
- `IP`: Default `10.10.0.1`
- `NETMASK`: Default `255.255.0.0`
- `NETWORK`: Default `10.10.0.0`
- `DHCPRANGE`: Default `10.10.200.10 10.10.200.200`
- `EXTERNALINTERFACE`: Default eth1, the interface which external/internet facing network is connected to. Used for DNS/external forwarding for clients.
- `IMAGEBASE`: Default `/export/images`, this is the directory where images will be created and shared over HTTP and NFS.
- `EXPORT`: Default `/images`, the alias for `$IMAGEBASE` that will be used in HTTP and NFS configuration.

To override any of the above settings, append them before the bash call during host setup:
```bash
curl https://raw.githubusercontent.com/openflighthpc/flight-images/master/host_setup.sh |IP=192.168.0.1 NETMASK=255.255.255.0 NETWORK=192.168.0.0 IMAGEBASE=/export/ /bin/bash
```

## Operation

The following scripts are available in the repository:
- `newimage.sh NAME`: Generates a new CentOS installation within directory `/var/www/netboot/NAME`.
- `liveosimage.sh NAME`: Create a squashed os image from `/var/www/netboot/NAME`.

### New Image

Create a new image as follows:
```
cd /root/flight-images
bash newimage.sh diskless-example
```

This will print out a TFTP entry that can be added to `/var/lib/tftpboot/pxelinux.cfg/default` (or a node-specific file) to provide an NFS root for clients.

### Live OS Image

Wrap up an image into an img file as follows:
```
cd /root/flight-images
bash liveosimage.sh diskless-example
```

This will print out a TFTP entry that can be added to `/var/lib/tftpboot/pxelinux.cfg/default` (or a node-specific file) to serve the image to clients over HTTP or NFS.

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Images is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
