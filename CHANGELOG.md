## [Unreleased]

## [0.5.0] - 2024-08-22

- introduce ability to view resolved errors and delete them ([@acoffman](https://github.com/fractaledmind/solid_errors/pull/56))
- loosen Rails dependency constraints to allow for Rails 8 ([@dorianmariecom](https://github.com/fractaledmind/solid_errors/pull/58))
- update README.md with rails error reporting example ([@stillhart](https://github.com/fractaledmind/solid_errors/pull/57))

## [0.4.3] - 2024-06-21

- fix `SolidErrors.send_emails?` that always returns true ([@defkode](https://github.com/fractaledmind/solid_errors/pull/46))
- Highlight source line ([@Bhacaz](https://github.com/fractaledmind/solid_errors/pull/47))
- Lastest occurences first ([@Bhacaz](https://github.com/fractaledmind/solid_errors/pull/48))
- Fix partial not being found with different inflector [@emilioeduardob](https://github.com/fractaledmind/solid_errors/pull/50)

## [0.4.2] - 2024-04-10

- Fix bug in error page when using Postgres ([@mintuhouse](https://github.com/fractaledmind/solid_errors/pull/43))

## [0.4.1] - 2024-04-09

- Ensure only first occurence is open on error page ([@fractaledmind](https://github.com/fractaledmind/solid_errors/pull/42))

## [0.4.0] - 2024-04-09

- Add email notifications ([@fractaledmind](https://github.com/fractaledmind/solid_errors/pull/3))
- Add `fingerprint` column to `SolidErrors::Error` model ([@fractaledmind](https://github.com/fractaledmind/solid_errors/pull/10))
  - read more about the upgrade process in the [UPGRADE.md](./UPGRADE.md) file
- Paginate error occurrences ([@fractaledmind](https://github.com/fractaledmind/solid_errors/pull/39))
- Ensure footer sticks to bottom of page ([@fractaledmind](https://github.com/fractaledmind/solid_errors/pull/40))
- Fix `errors/index` view ([@dorianmariecom](https://github.com/fractaledmind/solid_errors/pull/25))
- Fix `occurrences/_occurrence` partial ([@fractaledmind](https://github.com/fractaledmind/solid_errors/pull/28))
- Add documentation on ejecting views ([@dorianmariecom](https://github.com/fractaledmind/solid_errors/pull/30))
- Only declare necessary Rails sub-systems as dependencies ([@everton](https://github.com/fractaledmind/solid_errors/pull/35))
- Force :en locale inside ErrorsController to avoid missing translations ([@everton](https://github.com/fractaledmind/solid_errors/pull/36))
- Avoid triggering N+1 on index page ([luizkowalski](https://github.com/fractaledmind/solid_errors/pull/38))

## [0.3.5] - 2024-02-06

- Fix issue with `gsub!` on a frozen string ([@joelmoss](https://github.com/fractaledmind/solid_errors/pull/9))

## [0.3.4] - 2024-01-29

- Ensure that setting username/password with Ruby triggers the basic authentication

## [0.3.3] - 2024-01-28

- Properly fix the setup issues
- Add the needed locale file

## [0.3.2] - 2024-01-28

- Fix belongs_to reference in Occurrence model

## [0.3.1] - 2024-01-28

- Fix incorrect table reference name and long index name in the migration template

## [0.3.0] - 2024-01-28

- Proper release with full coherent functionality and documentation

## [0.2.0] - 2024-01-14

- Initial release

## [0.1.0] - 2024-01-14

- Reserve gem name
