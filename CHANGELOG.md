# Changelog

This project follows [Semantic Versioning 2.0.0](http://semver.org/).

## <a name="unreleased"></a>Unreleased 

## <a name="v0.2.0"></a>[v0.2.0](https://github.com/eXolnet/redmine-code-audit/tree/v0.2.0) (2015-08-19)
[Full Changelog](https://github.com/eXolnet/redmine-code-audit/compare/v0.1.0...v0.2.0)

### Added
* [#1] Add the created_on date of each commit to the comment title
* [#2] Send an email notification when new comments have been posted
* [#14] Initial vagrant development VM
* [#16]: Send an email when a new audit request is made
* [#17] Add status to audits
* [#21] Allow users to reply to inline comments
* [#24] Add link to committer user page
* [#28] Add sorting capabilities to the audit list
* [#29] In the detailed changes section, add links to the file history and view
* [#34] Audit auditors backend
* [#50] Add support for redmine 3

### Fixed
* [#10] Apply textile transform to the details text
* [#26] In the update audit page, current auditors are not checked
* [#31] Internal Error when trying to create an audit without filling the form
* [#35] No validation is done on audit creation
* [#41] Class patch are not correctly applied
* [#51] Adding inline comments is not working anymore
* [#52] An internal error is generated when an audit with no general comment is submitted
* [#53] Comments for the same line are not added in order they were created
* [#56] An internal error is generated when view the audits page on Redmine 3
* [#59] Link on the audit number in the audits page points to the issues#show route
* [#62] The revision isn't keep on audit creation when there's an error
* [#70] The plugin is unable to reinitialize itself when touching the code

## <a name="v0.1.0"></a>[v0.1.0](https://github.com/eXolnet/redmine-code-audit/tree/v0.1.0) (2015-02-12)

Initial release