# winrm-brute
A brute-force tool against WinRM service.

THIS TOOL IS FOR LEGAL PURPOSES ONLY!

## Introduction
This tool will try to connect to a
given target using the credentials provided and run a single command to check
if it was successful.

The brute-force attack is intended to test the security of systems in scenarios
like penetration testing. Don't use it against system you are not authorized to.

## Installation
First, clone the git repository:

`git clone https://github.com/mchoji/winrm-brute`

The easiest way to get started is using [Bundler].

### Bundler
After cloning the repository, just run:
```shell
cd winrm-brute
bundle config path vendor/bundle
bundle install
```

## How to Use
To check the available options, just call the program without arguments or with
`-h`.
```shell
$bundle exec ./winrm-brute.rb
Usage: winrm-brute.rb [options] HOST
    -u USER                          A specific username to authenticate as
    -U USERFILE                      File containing usernames, one per line
    -p PASSWORD                      A specific password to authenticate with
    -P PASSWORDFILE                  File containing passwords, one per line
    -t TIMEOUT                       Timeout for each attempt, in seconds (default: 1)
    -q, --quiet                      Do not write all login attempts
        --port=PORT                  The target TCP port (default: 5985)
        --uri=URI                    The URI of the WinRM service (default: /wsman)
    -h, --help                       Show this message

```

To start brute-forcing using usernames and passwords contained in files, you
can run:
```shell
$bundle exec ./winrm-brute.rb -U users.txt -P passwords.txt 10.0.0.1
```

## Dependencies
The only dependency is [WinRM] Ruby gem.

## Supported Authentication Methods
Currently, the only authentication method supported by **winrm-brute** is the
**negotiate** protocol. However, [WinRM] gem supports methods like SSL and
Kerberos, so this tool should be easily extended to support those as well.

## WinRM Service
Windows Remote Management (WinRM) is a Windows service that allows a user to
run commands remotely. See the [official
documentation](https://docs.microsoft.com/en-us/windows/win32/winrm/portal) for
more information.

## Authors
M. Choji - [@mchoji](https://github.com/mchoji)

## License
**winrm-brute** is licensed under the Apache License, Version 2.0. See
[LICENSE](LICENSE) for more information.

[Bundler]: https://bundler.io/
[WinRM]: https://github.com/WinRb/WinRM
