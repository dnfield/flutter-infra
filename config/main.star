#!/usr/bin/env lucicfg

# Constants shared by multiple definitions below
FLUTTER_REPO_URL = 'https://chromium.googlesource.com/external/github.com/flutter/flutter'
ENGINE_REPO_URL = 'https://chromium.googlesource.com/external/github.com/flutter/engine'

RECIPE_BUNDLE = 'infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build'

ENGINE_BUILDER_LINUX_HOST = 'Linux Host Engine'
ENGINE_BUILDER_LINUX_ANDROID_AOT = 'Linux Android AOT Engine'
ENGINE_BUILDER_LINUX_ANDROID_DEBUG = 'Linux Android Debug Engine'

ENGINE_BUILDER_MAC_HOST = 'Mac Host Engine'
ENGINE_BUILDER_MAC_ANDROID_AOT = 'Mac Android AOT Engine'
ENGINE_BUILDER_MAC_ANDROID_DEBUG = 'Mac Android Debug Engine'
ENGINE_BUILDER_MAC_IOS = 'Mac iOS Engine'

ENGINE_BUILDER_WINDOWS_HOST = 'Windows Host Engine'
ENGINE_BUILDER_WINDOWS_ANDROID_AOT = 'Windows Android AOT Engine'

FLUTTER_BUILDER_LINUX = 'Linux'
FLUTTER_BUILDER_LINUX_COVERAGE = 'Linux Coverage'
FLUTTER_BUILDER_WINDOWS = 'Windows'
FLUTTER_BUILDER_MAC = 'Mac'

FLUTTER_BUILDER_LINUX_PACKAGING = 'Linux Flutter Packaging'
FLUTTER_BUILDER_WINDOWS_PACKAGING = 'Windows Flutter Packaging'
FLUTTER_BUILDER_MAC_PACKAGING = 'Mac Flutter Packaging'


IOS_TOOLS_REPO_PREFIX = 'https://flutter-mirrors.googlesource.com/'

BUILDER_IDEVICEINSTALLER = 'ideviceinstaller'
BUILDER_LIBPLIST = 'libplist'
BUILDER_USBMUXD = 'usbmuxd'
BUILDER_OPENSSL = 'openssl'
BUILDER_LIBIMOBILEDEVICE = 'libimobiledevice'
BUILDER_IOS_DEPLOY = 'ios-deploy'

IOS_TOOLS_COLLECTION = [
  BUILDER_IDEVICEINSTALLER,
  BUILDER_LIBPLIST,
  BUILDER_USBMUXD,
  BUILDER_OPENSSL,
  BUILDER_LIBIMOBILEDEVICE,
  BUILDER_IOS_DEPLOY,
]

FLUTTER_RECIPE = luci.recipe(
  name = 'flutter/flutter',
  cipd_package = RECIPE_BUNDLE,
  cipd_version = 'refs/heads/master',
)

ENGINE_RECIPE = luci.recipe(
  name = 'flutter/engine',
  cipd_package = RECIPE_BUNDLE,
  cipd_version = 'refs/heads/master',
)

IOS_TOOLS_RECIPE = luci.recipe(
  name = 'flutter/ios-usb-dependencies',
  cipd_package = RECIPE_BUNDLE,
  cipd_version = 'refs/heads/master',
)

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

luci.console_view(
  name = 'engine',
  repo = ENGINE_REPO_URL,
  refs = ['refs/heads/master'],
  include_experimental_builds = True,
)

luci.console_view(
  name = 'framework',
  repo = FLUTTER_REPO_URL,
  refs = ['refs/heads/master'],
  include_experimental_builds = True,
)

luci.console_view(
  name = 'packaging',
  repo = FLUTTER_REPO_URL,
  refs = ['refs/heads/beta', 'refs/heads/dev', 'refs/heads/stable'],
  exclude_ref = 'refs/heads/master',
  include_experimental_builds = True,
)

def prodBuilder(name, *, os, recipe, properties={}, category, console_view_name, short_name, caches=None, cores='8', triggered_by = None):
  default_properties = {
    'mastername': 'client.flutter',
    'gradle_dist_url': 'https://services.gradle.org/distributions/gradle-4.10.2-all.zip',
    'goma_jobs': '200',
  }
  default_properties.update(properties)
  dimensions = {
    'pool': 'luci.flutter.prod',
    'cpu': 'x86-64',
    'os': os,
  }
  if cores != None:
    dimensions['cores'] = cores

  luci.builder(
    name = name,
    bucket = 'prod',
    executable = recipe,
    properties = default_properties,
    service_account = 'flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com',
    execution_timeout = 3 * time.hour,
    dimensions = dimensions,
    caches = caches,
    swarming_tags = ['vpython:native-python-wrapper'],
    build_numbers = True,
    triggered_by = triggered_by,
  )
  luci.console_view_entry(
    builder = 'prod/' + name,
    console_view = console_view_name,
    category = category,
    short_name = short_name,
  )

def getEngineProperties(build_host=False, build_android_debug=False, build_android_aot=False, build_android_vulkan=False,build_ios=False):
  return {
    'build_host': build_host,
    'build_android_debug': build_android_debug,
    'build_android_aot': build_android_aot,
    'build_android_vulkan': build_android_vulkan,
    'build_ios': build_ios,
  }

def prodEngineWindowsBuilder(name, *, short_name, properties):
  prodBuilder(
    name,
    recipe = ENGINE_RECIPE,
    os = 'Windows-10',
    category = 'Windows',
    console_view_name = 'engine',
    short_name = short_name,
    properties = properties,
    triggered_by = ['master-gitiles-trigger-engine'],
  )

def prodEngineMacBuilder(name, *, short_name, properties):
  # see https://chrome-infra-packages.appspot.com/p/infra_internal/ios/xcode/mac/+/
  default_properties = {
    '$depot_tools/osx_sdk': {
      'sdk_version': '10e125', # 10.2
    },
    'jazzy_version': '0.9.5',
  }
  default_properties.update(properties)

  prodBuilder(
    name,
    recipe = ENGINE_RECIPE,
    os = 'Mac-10.14',
    category = 'Mac',
    console_view_name = 'engine',
    short_name = short_name,
    caches = [swarming.cache(name = 'osx_sdk', path = 'osx_sdk')],
    properties = default_properties,
    cores = None,
    triggered_by = ['master-gitiles-trigger-engine'],
  )

def prodEngineLinuxBuilder(name, *, short_name, properties):
  prodBuilder(
    name,
    recipe = ENGINE_RECIPE,
    os = 'Ubuntu-16.04',
    category = 'Linux',
    console_view_name = 'engine',
    short_name = short_name,
    caches = [swarming.cache(name = 'flutter_openjdk_install', path = 'java')],
    properties = properties,
    triggered_by = ['master-gitiles-trigger-engine'],
  )

def prodFrameworkBuilder(name, *, os, properties={}, category, short_name, caches=None, cores = '8'):
  default_properties = {'shard': 'tests'}
  default_properties.update(properties)
  prodBuilder(
    name,
    recipe = FLUTTER_RECIPE,
    console_view_name = 'framework',
    os = os,
    properties = default_properties,
    category = category,
    short_name = short_name,
    caches = caches,
    cores = cores,
    triggered_by = ['master-gitiles-trigger-framework'],
  )

def prodPackagingBuilder(name, *, os, category, cores = '8', caches = []):
  prodBuilder(
    name,
    recipe=FLUTTER_RECIPE,
    console_view_name='packaging',
    os = os,
    category = category,
    short_name = 'pkg',
    cores = cores,
    caches = caches,
    triggered_by = ['gitiles-trigger-packaging']
  )

prodFrameworkBuilder(
  FLUTTER_BUILDER_LINUX,
  os = 'Ubuntu-16.04',
  category = 'Linux',
  short_name = 'frwk',
)

prodFrameworkBuilder(
  FLUTTER_BUILDER_LINUX_COVERAGE,
  os = 'Ubuntu-16.04',
  category = 'Linux',
  short_name = 'lcov',
  properties={
    'shard': 'coverage',
    'coveralls_lcov_version': '5.1.0',
  }
)

prodFrameworkBuilder(
  FLUTTER_BUILDER_MAC,
  os = 'Mac-10.14',
  category = 'Mac',
  short_name = 'frwk',
  properties = {
    'cocoapods_version': '1.6.0',
      # see https://chrome-infra-packages.appspot.com/p/infra_internal/ios/xcode/mac/+/
    '$depot_tools/osx_sdk': {
      'sdk_version': '10e125', # 10.2
    },
  },
  caches = [
    swarming.cache(name = 'osx_sdk', path = 'osx_sdk'),
    swarming.cache(name = 'flutter_cocoapods', path = 'cocoapods'),
  ],
  cores = None,
)

prodFrameworkBuilder(
  FLUTTER_BUILDER_WINDOWS,
  os = 'Windows-10',
  category = 'Windows',
  short_name = 'frwk',
  caches = [swarming.cache(name = 'flutter_openjdk_install', path = 'java')],
)

prodPackagingBuilder(
  FLUTTER_BUILDER_LINUX_PACKAGING,
  os = 'Ubuntu-16.04',
  category = 'Linux',
)

prodPackagingBuilder(
  FLUTTER_BUILDER_MAC_PACKAGING,
  os = 'Mac-10.14',
  category = 'Mac',
  cores = None,
  caches = [swarming.cache(name = 'osx_sdk', path = 'osx_sdk')],
)

prodPackagingBuilder(
  FLUTTER_BUILDER_WINDOWS_PACKAGING,
  os = 'Windows-10',
  category = 'Windows',
)

prodEngineLinuxBuilder(
  ENGINE_BUILDER_LINUX_HOST,
  short_name = 'host',
  properties = getEngineProperties(build_host = True),
)

prodEngineLinuxBuilder(
  ENGINE_BUILDER_LINUX_ANDROID_DEBUG,
  short_name = 'dbg',
  properties = getEngineProperties(build_android_debug = True, build_android_vulkan = True),
)

prodEngineLinuxBuilder(
  ENGINE_BUILDER_LINUX_ANDROID_AOT,
  short_name = 'aot',
  properties = getEngineProperties(build_android_aot = True),
)

prodEngineMacBuilder(
  ENGINE_BUILDER_MAC_HOST,
  short_name = 'host',
  properties = getEngineProperties(build_host = True),
)

prodEngineMacBuilder(
  ENGINE_BUILDER_MAC_ANDROID_AOT,
  short_name = 'aot',
  properties = getEngineProperties(build_android_aot = True),
)

prodEngineMacBuilder(
  ENGINE_BUILDER_MAC_ANDROID_DEBUG,
  short_name = 'dbg',
  properties = getEngineProperties(build_android_debug = True, build_android_vulkan = True),
)

prodEngineMacBuilder(
  ENGINE_BUILDER_MAC_IOS,
  short_name = 'ios',
  properties = getEngineProperties(build_ios = True),
)

prodEngineWindowsBuilder(
  ENGINE_BUILDER_WINDOWS_HOST,
  short_name = 'host',
  properties = getEngineProperties(build_host = True),
)

prodEngineWindowsBuilder(
  ENGINE_BUILDER_WINDOWS_ANDROID_AOT,
  short_name = 'aot',
  properties = getEngineProperties(build_android_aot = True),
)

luci.gitiles_poller(
  name = 'master-gitiles-trigger-engine',
  bucket = 'prod',
  repo = ENGINE_REPO_URL,
)

luci.gitiles_poller(
  name = 'gitiles-trigger-packaging',
  bucket = 'prod',
  repo = FLUTTER_REPO_URL,
  refs = ['refs/heads/dev', 'refs/heads/beta', 'refs/heads/stable'],
)

luci.gitiles_poller(
  name = 'master-gitiles-trigger-framework',
  bucket = 'prod',
  repo = FLUTTER_REPO_URL,
)

def generateIosToolsBuilders():
  for builder in IOS_TOOLS_COLLECTION:
    repo = IOS_TOOLS_REPO_PREFIX + builder
    luci.builder(
      name = builder,
      bucket = 'prod',
      executable = IOS_TOOLS_RECIPE,
      swarming_tags = ['vpython:native-python-wrapper'],
      dimensions = {
       'pool': 'luci.flutter.prod',
        'cpu': 'x86-64',
        'os': 'Mac-10.14',
      },
      properties = {
        'mastername': 'client.flutter',
        '$depot_tools/osx_sdk': {
          'sdk_version': '10e125',
        },
        'goma_jobs': '200',
        'package_name': builder + '-flutter',
      },
      execution_timeout = 3 * time.hour,
      caches = [swarming.cache(name = 'osx_sdk', path = 'osx_sdk')],
      build_numbers = True,
      service_account = 'flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com',
    )
    luci.gitiles_poller(
      name = 'gitiles-trigger-' + builder,
      bucket = 'prod',
      repo = repo,
      triggers = [builder],
    )
    luci.console_view(
      name = builder,
        repo = repo,
      refs = ['refs/heads/master'],
      include_experimental_builds = True,
    )

generateIosToolsBuilders()
