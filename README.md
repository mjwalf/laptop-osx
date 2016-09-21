
# Laptop OS X

| Title   | URL                                  |
|:--------|:-------------------------------------|
| Website | https://github.com/mjwalf/laptop-osx |
| Source  | https://github.com/mjwalf/laptop-osx |

Laptop provisioning

## What is it?

A way for me to provision OS X machines to my requirements (probably a MacBook Pro)

## Usage

First

```/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/mjwalf/laptop-osx/master/bootstrap.rb)"```

After

*command to install all configured packages and options*

Beyond

*command to update packages and state*

## Issues

- Sometimes Homebrew fails to update. Run ```rm -rf /usr/local/Homebrew/.git```

## Planned Development

- Add Ubuntu Equivalent
- Prompt for appleid to run mas install

## Communication

- If you **need help**, try **Googling** your problem.
- If you want to **ask a general question**, raise an issue
- If you **find a bug**, open an issue and try to **fix it yourself**.
- If you **want a new feature**, try to **add it yourself** after talking it through.

## Contributing

If you want to add functionality to this project, pull requests are welcome.

- Create a branch based off master and do all of your changes with in it.
- If you have to pause to add a 'and' anywhere in the title, it should be two pull requests.
- Make commits of logical units and describe them properly
- Check for unnecessary whitespace with git diff --check before committing.
- If possible, submit tests to your patch / new feature so it can be tested easily.
- Assure nothing is broken by running all the test
- Please ensure that it complies with coding standards.
- Branches **WILL** be **rebased** into master.

**Please raise any issues with this project as a GitHub issue.**

## Credits

- [Mark Walford](http://twitter.com/mjwalf)
- [Simon Thulbourn](http://twitter.com/sthulb)
