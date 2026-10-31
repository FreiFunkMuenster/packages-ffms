# gluon-advancedstats
respondd provider that announces whether the node owner agreed to the recording of advanced statistics.

The value is read from `gluon-advanced-config.@advstats[0].enabled` (default `0`) and published as
`nodeinfo.advanced-stats.store-stats` (boolean).

The option is set in the config mode by `gluon-config-mode-statistics`.
