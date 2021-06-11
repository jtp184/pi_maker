# PiMaker

Easy bake for Raspberry Pi

## Installation

Add this line to your application's Gemfile:
```ruby
gem 'pi_maker', github: 'jtp184/pi_maker'
```

You can also download and install it globally with
```bash
git clone https://github.com/jtp184/pi_maker.git
cd pi_maker
rake install
```

## Hardware & Imaging

This gem was tested with various SD cards, on Mac and Linux operating systems, and with the Raspberry Pi 3+ and 4.

Software images can be downloaded from [raspberrypi.org](https://www.raspberrypi.org/software/operating-systems/) directly or through torrent. I reccomend the full desktop version for the preinstalled software tools, but pi_maker can write any `.img` file.

## Usage

### Documentation

All methods and classes are RDoc documented at https://jtp184.github.io/pi_maker/

### PiMaker

### Instructions

The `Instructions` class holds data for what should be installed or configured on the Pi.

```ruby
# Basic initialization with all options
instructions = PiMaker::Instructions.new(
  # Array of packages to install using apt-get install
  apt_packages: %w(neofetch kitty),
  # Array of gems to install to system using sudo gem install
  gems: %w(tty-config tty-prompt),
  # Hash, with keys of github repos to clone to ~/repos, values of an array of post-clone commands
  github_repos: {
    'jtp184/arch_dotfiles' => [
      'mkdir -p ~/.config',
      'cp -R ~/repos/arch_dotfiles/config ~/.config'
    ]
  },
  # Run any raw shell commands
  shell: ['touch ~/.hushlogin'],
  # Runs the raspi-config nongui version, allowing argument passing
  raspi_config: {
    'do_spi' => 0,
    'do_expand_rootfs' => nil
  },
  # Chunks of text to append to bashrc
  bashrc: ["export PIMAKER_ID=#{SecureRandom.uuid}"]
)

# Also available through block syntax using .define
further_instructions = PiMaker::Instructions.define do |i|
  i.apt_packages = %w[wget]
  i.gems =  Time.now.friday? ? %w[colorize] : %w[pastel]
end
```

### BootConfig

Altering options on the SD Card's [`config.txt`](https://www.raspberrypi.org/documentation/configuration/config-txt/) file is achieved with the `BootConfig` class, which can both read and write a config.

```ruby
# Enable SSH at boot
boot_config = PiMaker::BootConfig.new(ssh: true)

boot_config['pi4'] = {
  'dtparam=audio' => 'on',
  'max_framebuffers' => '2',
}

# You can also read an existing config
card_config = PiMaker::BootConfig.new(path: '/mnt/boot/config.txt')

card_config['all'] # => { 'dtoverlay' => 'vc4-fkms-v3d' }

card_config.to_s # => "[pi4]\ndtparam=audio=on..."
```

### WpaConfig

Wifi credentials can be entered using a `WpaConfig`, which carries a number of networks and can be written to the boot config to preset the wifi network before boot.

```ruby
wpa_config = PiMaker::WpaConfig.new(networks: { 'WorldOfWifi' => 'passw0rd' })

# Append new credentials to the config
wpa_config.append('WifiAtWork', 'b3tt3rp@assw0rd')

# Redacts passwords by default
wpa_config.to_h # => { country_code: 'US', networks: ['WorldOfWifi', 'WifiAtWork']}
# Override by passing true
wpa_config.to_h(true) # => { networks: { 'WorldOfWifi' => 'passw0rd, ... 

# Export proper format to a file
wpa_config.to_s # => "ctrl_interface=DIR=/var..."
```

### Recipe

Binding together initialization and configuration options is the `Recipe` class, which is used to define a particular named setup of pi

```ruby
PiMaker::Recipe.define do |r|
  # Set a hostname and password to be applied
  r.hostname = 'PiMaker-ExamplePi'
  r.password = SecureRandom.hex

  # Pass in currently defined wifi options, or new ones
  r.wifi_config_options = { networks: ['WorldOfWifi', { 'NewConnection' => 'B33SW@X' }] }

  # Pass a boot config constructor
  r.boot_config_options = { ssh: true, config: { 'all' => { 'dtparam=spi' => 'on' } } }

  # Handle initial configuration with an Instructions object
  r.initial_setup_options = {
    apt_packages: %w[imagemagick nodejs npm],
    bashrc: 'export NJS_ROOT=/home/pi/npm'
  }

  # Other optional named Instructions sets to execute
  r.additional_setup_options = {
    use_kitty: { apt_packages: %w[kitty] },
    add_tty_gems: { gem: %w[tty-prompt tty-cursor] }
  }
end
```

### Pantry

The `Pantry` is where `Recipe` objects are stored. The class has functionality for saving and loading collections to YAML files, handling encryption of files on disk, and locating and loading from a global and persistant pantry.

```ruby
# Checks for existing config file in current directory, home directory, and ~/.config/pi_maker
# Returns the directory a pantry was found in, or nil
PiMaker::Pantry.global_exists? # => '/home/pi'

# Can load the file that exists
PiMaker::Pantry.global # => #<PiMaker::Pantry...>

# And accept options for password
PiMaker::Pantry.global(password: 'SN3AKY')

# If the global pantry doesn't exist, the returned instance can create it by calling #write
PiMaker::Pantry.global.write
# You can also write with encryption, or to a specific path
PiMaker::Pantry.global.write(password: 'badpassword12345', path: './')
```

A Pantry carries recipes and wifi networks, which are accessible within the recipes without reiterating their passwords

```ruby
pantry = PiMaker::Pantry.global

# Networks within the pantry can be passed as string instead of as hash
pantry.wifi_networks # => { 'AccessPoint' => 'AP101' }

pantry.recipes.first.wpa_config.networks['AccessPoint'] # => 'AP101'
```

### FileEncrypter

The `FileEncrypter` handles converting plaintext to encrypted text, keeping credentials within recipes safe.

```ruby
PiMaker::FileEncrypter.encrypt('SuperSecretText', 'SecretPassword')
# => "PIMAKER:ENCRYPTED\n\x97c\xCC\xB8z\xCE7\xDCwY:\x01\"\xC2\xF2l\xC6\xC11F\x8Blh \xCA\x89#8\xB4\xF7\x12u"

# Various classes within the gem include exporting which optionally passes through the FileEncrypter

# Export to an encrypted file which decrypts to a yaml file
enc = PiMaker::Recipe.new.to_yaml('UtterlyUnhackable')

# Decrypt it by providing the original password
dec = PiMaker::Recipe.from_yaml(enc, 'UtterlyUnhackable') == enc # => true
```

### DiskManagement

The DiskManagement module houses functions surrounding reading the state of the filesystem and flashing of SD cards. The module itself is a shortcut for these functions, automatically picking a disk protocol and passing method calls to it.

```ruby
# Automatically decides based on OS
PiMaker::DiskManagement.protocol # => PiMaker::DiskManagement::MacOs

# Passes messages to protocol when applicable
PiMaker::DiskManagement.list_devices 
# => [/dev/disk2: /Volumes/boot | 2 partitions (63.8646 gigabytes)]
```

#### DiskProtocol

The Disk protocols read filesystem data from different operating systems, and handle formatting and writing to disks. The base class provides functionality common to both, and child classes provide duck typed methods to interact with the underlying system. The `Linux` disk protocol uses `lsblk` to get disk info and `mount` / `umount` to control them, while the `MacOs` disk protocol uses `diskutil` for all of its functions.

```ruby
protocol = PiMaker::DiskManagement.protocol

# Find an attached SD card, when one exists, based on OS defaults
protocol.sd_card_device # => /dev/disk2: /Volumes/boot | 2 partitions (63.8646 gigabytes)

# Many disk functions can be called directly if desired, but are better called on the resulting device
protocol.mounted?('/dev/disk2') # => true
protocol.mount_point_for('/dev/disk2') # => '/Volumes/boot'
```
#### StorageDevice

`StorageDevice` represents a connected disk. It wraps the data extracted from the `DiskProtocol`, and includes methods to query status and information, as well as initiating a `FlashingOperation` on itself.

```ruby
sd_card = PiMaker::DiskManagement.sd_card_device

sd_card.capacity # => 127259789970
sd_card.size # => "127.2597 gigabytes"
sd_card.mounted? # => true
sd_card.dev_path # => '/dev/disk2'

sd_card.unmount && sd_card.mounted? # => false

sd_card.write_image('~/Downloads/raspios.img') # => #<PiMaker::FlashingOperation>
```

#### FlashingOperation

Writing the OS image to the SD card is accomplished with the `FlashingOperation` class. It wraps an `IO.popen` call to `dd`, and reports when it completes

```ruby
# Initialize by itself and defer execution
flop = PiMaker::FlashingOperation.new(image_path: './raspios.img', disk: PiMaker::DiskManagement.sd_card_device.unmount)

# Begin the write like this
flop.call

# Check for completion
flop.finished? # => false
sleep 300 && flop.finished? # => true

# The preferred way is to call from the StorageDevice, which unmounts the disk, and instantiates and starts the operation
PiMaker::DiskManagement.sd_card_device.write_image('./raspios.img') # => #<PiMaker::FlashingOperation>
```

### NetworkIdentifier

The `NetworkIdentifier` will search for valid Raspberry Pis on the network, and return their ip addresses. This is useful for connecting to and running commands on the pi after initial flashing, before a hostname has been set.

```ruby
# Standard call method with no arguments, uses `arp` by default
PiMaker::NetworkIdentifier.call # => ['192.168.1.127']

# Also has a built in parser for using nmap with sudo
PiMaker::NetworkIdentifier.call(scan_with: :nmap)

# And you can pass your own program to call, and parse and filter with any callable object
PiMaker::NetworkIdentifier.call(
  scan_with: :my_program,
  parse_with: ->(out) { out.scan(/\d{3}\.\d{3}.\d.\d{3}/) }
  filter_with: ->(ips) { ips.select { |i| i[-1] == '7'} }
)
```

### CommandGroup

Translating a set of `Instructions` into the actual shell commands to execute them is handled by the `CommandGroup` class. 

```ruby
instructions = PiMaker::Pantry.global
                              .recipes
                              .first
                              .initial_setup

cmds = PiMaker::CommandGroup.new(instructions)

# Returns runnable versions of install directives
cmds.apt_packages # => 'sudo apt-get install -y imagemagick nodejs'
```
### RemoteRunner

Executing a `CommandGroup` on a pi over the network via SSH is done with the `RemoteRunner` class, which wraps `net/ssh` and `net/scp`.

```ruby
runner = PiMaker::RemoteRunner.new(
  # You can pass a username / password here, or use the default
  config: {
    username: 'pi',
    password: 'raspberry'
  },
  # Pass a command group to execute it
  command_group: cmds,
  # Upload files with from/to tuples or a hash
  upload_files: [['./settings.yml', '/home/pi/.config/settings.yml']],
  # Download files from a path the same way
  download_files: { '/home/pi/something.txt' => './' }
)
```

## CLI

Most of the CLI commands and subcommands can be run with the `--interactive` option to prompt for selection when needed.

### `pantry`

#### `init`
```
Usage
  pi_maker pantry init [PATH]

Options:
  -o, [--overwrite], [--no-overwrite]  # Overwrite existing pantry

Create a pantry folder
```

#### `encrypt`
```
Usage
  pi_maker pantry encrypt [PASSWORD]

Encrypt the pantry folder
```

#### `decrypt`
```
Usage
  pi_maker pantry decrypt [PASSWORD]

Decrypt the pantry folder
```

### `wifi`

#### `add`
```
Usage
  pi_maker wifi add [SSID] [PASSWD]

Adds a new wifi config to the persistant store
```

#### `delete`
```
Usage
  pi_maker wifi delete [SSID]

Deletes a stored network from persistance
```

#### `list`
```
Usage
  pi_maker wifi list

Options:
  -p, [--passwords], [--no-passwords]  # Whether to show passwords for networks

Show stored wifi configs

```

#### `supplicant`
```
Usage
  pi_maker wifi supplicant

Options:
  -s, [--save=SAVE]              # Where to save to, defaults to the sd card, or current directory
  -c, [--credentials=key:value]  # Set a single credential as the file contents

Write a wpa_supplicant.conf file to copy manually
```

### `recipe`

#### `add`
```
Usage
  pi_maker recipe add

Options:
  -n, [--hostname=HOSTNAME]              # Set the hostname
  -w, [--password=PASSWORD]              # Set the password
  -f, [--wifi-options=key:value]         # Set the wifi options
  -b, [--boot-options=key:value]         # Set the boot options
  -o, [--initial-setup=key:value]        # Set the initial setup options
  -e, [--export-format=EXPORT_FORMAT]    # Output as ruby or yaml
                                         # Default: yaml
  -p, [--pantry], [--no-pantry]          # Save this recipe to the pantry as well
                                         # Default: true
  -l, [--local-file], [--no-local-file]  # Whether to write out a local file with the contents
  -s, [--ssh], [--no-ssh]                # Enable ssh on boot
                                         # Default: true

Add a new recipe
```
#### `delete`
```
Usage
  pi_maker recipe delete [HOSTNAME]

Remove a recipe
```
#### `initial`
```
Usage
  pi_maker recipe initial

Options:
  -p, [--path=PATH]                # Save to a specific path
  -v, [--verbose], [--no-verbose]  # Whether to print command output
  -r, [--reboot], [--no-reboot]    # Reboot after running commands
  -l, [--login], [--no-login]      # Set the hostname and password
                                   # Default: true
  -c, [--credentials=key:value]    # Pass in login details directly
  -s, [--scan], [--no-scan]        # Use the network identifier to pick a pi
                                   # Default: true
  -w, [--scan-with=SCAN_WITH]      # Use a different program to scan with

Perform the initial setup commands from the recipe
```

#### `list`
```
Usage
  pi_maker recipe list

Show all recipes from a certain collection
```

#### `write_boot`
```
Usage
  pi_maker recipe write_boot

Options:
  -p, [--path=PATH]  # Save to a specific path

Write a recipe's boot config to the SD card
```

### `boot`

#### `config`
```
Usage
  pi_maker boot config

Options:
  -s, [--save=SAVE]         # Where to save to, defaults to the sd card, or current directory
  -v, [--values=key:value]  # Pass values to the config

Set values on the config file directly
```
#### `flash`
```
Usage
  pi_maker boot flash

Options:
  -m, [--image=IMAGE]    # An image file to write
  -d, [--device=DEVICE]  # The device to write to

Flash a card from an image
```

### `identify`
```
Usage
  pi_maker identify

Options:
  -r, [--range=RANGE]                      # Which ip range to target
                                           # Default: 192.168.1.0/24
  -p, [--program=PROGRAM]                  # What program to run with
                                           # Default: arp
  -o, [--output=OUTPUT]                    # What data to return, either [i]p, [h]ostname, or [b]oth
                                           # Default: i
  -i, [--interactive], [--no-interactive]  # Run with prompting
  -h, [--help], [--no-help]                # Display usage information

Find Raspberry Pi devices on the local network
```

### `remote`

#### `apply`
```
Usage
  pi_maker remote apply

Options:
  -v, [--verbose], [--no-verbose]    # Whether to print command output
  -c, [--config=key:value]           # Pass in a hash of config options
  -s, [--scan], [--no-scan]          # Perform a network scan to find hosts
  -k, [--connect-with=CONNECT_WITH]  # Whether to use [i]p_address or [h]ostname to connect
                                     # Default: i

Apply a recipe from the pantry
```

#### `connect`
```
Usage
  pi_maker remote connect

Options:
  -c, [--config=key:value]           # Pass in a hash of config options
  -s, [--scan], [--no-scan]          # Perform a network scan to find hosts
  -k, [--connect-with=CONNECT_WITH]  # Whether to use [i]p_address or [h]ostname to connect
                                     # Default: i

Connect to a pi over SSH
```

#### `upload`
```
Usage
  pi_maker remote upload

Options:
  -c, [--config=key:value]           # Pass in a hash of config options
  -s, [--scan], [--no-scan]          # Perform a network scan to find hosts
  -k, [--connect-with=CONNECT_WITH]  # Whether to use [i]p_address or [h]ostname to connect
                                     # Default: i

Transfer a local file to the remote
```

#### `download`
```
Usage
  pi_maker remote download

Options:
  -c, [--config=key:value]           # Pass in a hash of config options
  -s, [--scan], [--no-scan]          # Perform a network scan to find hosts
  -k, [--connect-with=CONNECT_WITH]  # Whether to use [i]p_address or [h]ostname to connect
                                     # Default: i

Copy a remote file
```