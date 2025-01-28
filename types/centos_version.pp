type Pxe::Centos_version = Variant[
  Enum[
    '9-stream',
    '10-stream'
  ],
  # added support for versions like 9-20240226.1 or 8-20240325.0
  Pattern[/^(9|10)-202[4-9](0[1-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[01])(\.[0-9])?$/],
]
