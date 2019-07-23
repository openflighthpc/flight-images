# Flight Images

Flight Images provides scripts for building and booting diskless clients from squashed OS images.

## Installation

A script is provided to setup the diskless host, which:
- Sets up TFTP/PXE
- Configures HTTP
- Sets up the internal PXE network
- Downloads the scripts for building images

(Note: the script presumes the interface eth0 is connected to the internal network for PXE boot)

To run the host setup script:
```bash
curl https://raw.githubusercontent.com/openflighthpc/flight-images/master/host_setup.sh |/bin/bash
```

## Operation

The following scripts are available in the repository:
- `newimage.sh NAME`: Generates a new CentOS installation within directory `/var/www/netboot/NAME`.
- `liveosimage.sh NAME`: Create a squashed os image from `/var/www/netboot/NAME`.

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
