# Redmine Code Audit

[![Github Release](https://img.shields.io/github/release/eXolnet/redmine-code-audit.svg)](./releases)
[![Software License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square)](LICENSE.md)
[![Build Status](https://travis-ci.org/eXolnet/redmine-code-audit.svg)](https://travis-ci.org/eXolnet/redmine-code-audit)
[![Github All Releases](https://img.shields.io/github/downloads/eXolnet/redmine-code-audit/total.svg)]()

Code Audit is a Redmine plugin that allows users to post audits on commits in repositories linked to projects.

## Compatibility

This plugin version is compatible only with Redmine 3.0 and later.

## Installation

1. Download the .ZIP archive, extract files and copy the plugin directory into `#{REDMINE_ROOT}/plugins`.

2. Make a backup of your database, then run the following command to update it:

    ```
    bundle exec rake redmine:plugins:migrate RAILS_ENV=production 
    ```

3. Restart Redmine.

4. Login and enable the "Audit" module on projects you want to use it.

## Security

If you discover any security related issues, please email security@exolnet.com instead of using the issue tracker.

## Credits

- [Alexandre D'Eschambeault](https://github.com/xel1045)
- [Tom Rochette](https://github.com/roctom)
- [All Contributors](../../contributors)

## License

This code is licensed under the [MIT license](http://choosealicense.com/licenses/mit/). 
Please see the [license file](LICENSE) for more information.