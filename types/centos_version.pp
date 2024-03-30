type Pxe::Centos_version = Variant[
  Enum[
    '7',
    '8',
    '7.9.2009',
    '8-stream',
    '9-stream',
  ],
  # added support for versions like 9-20240226.1 or 8-20240325.0
  Pattern[/^[89]-202[3-9](0[1-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[01])(\.[0-9])?$/],
]
