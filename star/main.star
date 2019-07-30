#!/usr/bin/env lucicfg

load('//ios_tools.star', 'generateIosToolsBuilders')
load('//prod_builder.star', 'prodBuilder')
exec('//engine.star')
exec('//flutter.star')
exec('//packaging.star')

luci.project(
  name = 'flutter',

  buildbucket = 'cr-buildbucket.appspot.com',
  logdog = 'luci-logdog.appspot.com',
  milo = 'luci-milo.appspot.com',
  scheduler = 'luci-scheduler.appspot.com',
  swarming = 'chromium-swarm.appspot.com',

  acls = [
    acl.entry(
      roles = [
        acl.BUILDBUCKET_READER,
        acl.LOGDOG_READER,
        acl.PROJECT_CONFIGS_READER,
        acl.SCHEDULER_READER,
      ],
      groups = 'all',
    ),
    acl.entry(
      roles = [
        acl.BUILDBUCKET_TRIGGERER,
        acl.SCHEDULER_OWNER,
      ],
      groups = 'project-flutter-prod-schedulers'
    ),
    acl.entry(
      roles = [
        acl.BUILDBUCKET_TRIGGERER,
      ],
      users = 'luci-scheduler@appspot.gserviceaccount.com',
    ),
    acl.entry(
      roles = [
        acl.BUILDBUCKET_OWNER,
      ],
      groups = 'project-flutter-admins'
    ),
    acl.entry(
      roles = [
        acl.LOGDOG_WRITER,
      ],
      groups = 'luci-logdog-chromium-writers',
    ),
  ],
)

luci.logdog(
  gs_bucket = 'chromium-luci-logdog',
)

luci.milo(
  logo = 'https://storage.googleapis.com/chrome-infra-public/logo/flutter-logo.svg',
  favicon = 'https://storage.googleapis.com/flutter_infra/favicon.ico',
)

luci.bucket(
  name = 'prod',
)

generateIosToolsBuilders()
