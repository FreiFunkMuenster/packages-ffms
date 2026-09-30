# gluon-config-mode-statistics
Adds a checkbox "Track advanced statistics" to the config mode wizard.

The setting is stored in `gluon-advanced-config.@advstats[0].enabled` and announced via respondd
by `gluon-advancedstats`, which is pulled in as dependency.
