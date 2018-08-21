## What is it?

Laptop provisioner.

## Usage

For a new laptop run the bootstrap script to install minimum packages:

```/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/mjwalf/laptop-osx/master/bootstrap.rb)"```

Run ```laptop-osx``` to install all packages beyond the bootstrap minimum or to update state (bash alias stored in dotfiles repo)

Add/Remove packages from `ansible/roles/casks/defaults.yml` and from `ansible/roles/brew/defaults.yml` to add or remove packages

## Credits

- [Mark Walford](http://twitter.com/mjwalf)
- [Simon Thulbourn](http://twitter.com/sthulb)
