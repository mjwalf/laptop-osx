## What is it?

Ruby script and ansible playbook for setting up new laptop and maintaining brew packages and dotfiles for Apple dev laptop.

## Bootstraping Instructions

For a new laptop run the bootstrap script:

```/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/mjwalf/laptop-osx/master/bootstrap.rb)"```

This will add `~/Developer/src/...../` folder which holds the playbook.

Add the bash function to dotfiles repo

```
function laptop-osx () {
  if [ "$1" = "" ]; then
    ansible-playbook '/Users/'$(whoami)'/Developer/config/src/github.com/mjwalf/laptop-osx/ansible/playbook.yml' -e install_user="$(whoami)" -i '/Users/'$(whoami)'/Developer/config/src/github.com/mjwalf/laptop-osx/ansible/hosts' -K
  else
    ansible-playbook '/Users/'$(whoami)'/Developer/config/src/github.com/mjwalf/laptop-osx/ansible/playbook.yml' -e install_user="$(whoami)" -i '/Users/'$(whoami)'/Developer/config/src/github.com/mjwalf/laptop-osx/ansible/hosts' -K --tags="$1"
  fi
}
```

Add/Remove packages from `ansible/roles/casks/defaults.yml` and from `ansible/roles/brew/defaults.yml` to add or remove packages

Run `laptop-osx` or `laptop-osx [tag_name]` to update or add new packages added above.


## Credits

- [mjwalf](http://twitter.com/mjwalf)
- [sthulb](http://twitter.com/sthulb-attic/laptop-osx) (original concept)
- [lafarer](https://github.com/lafarer/ansible-role-osx-defaults) (macos defaults)
