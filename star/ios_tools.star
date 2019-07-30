#!/usr/bin/env lucicfg

RECIPE_BUNDLE = 'infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build'

IOS_TOOLS_REPO_PREFIX = 'https://flutter-mirrors.googlesource.com/'

BUILDER_IDEVICEINSTALLER = 'ideviceinstaller'
BUILDER_LIBPLIST = 'libplist'
BUILDER_USBMUXD = 'usbmuxd'
BUILDER_OPENSSL = 'openssl'
BUILDER_LIBIMOBILEDEVICE = 'libimobiledevice'
BUILDER_IOS_DEPLOY = 'ios-deploy'

IOS_TOOLS_COLLECTION = (
  (BUILDER_IDEVICEINSTALLER, 'idev'),
  (BUILDER_LIBPLIST, 'plist'),
  (BUILDER_USBMUXD, 'usbmd'),
  (BUILDER_OPENSSL, 'ssl'),
  (BUILDER_LIBIMOBILEDEVICE, 'libi'),
  (BUILDER_IOS_DEPLOY, 'deploy'),
)

def generateIosToolsBuilders():
  for item in IOS_TOOLS_COLLECTION:
    builder = item[0]
    short_name = item[1]
    repo = IOS_TOOLS_REPO_PREFIX + builder
    luci.builder(
      name = builder,
      bucket = 'prod',
      executable = luci.recipe(
        name = 'flutter/ios-usb-dependencies',
        cipd_package = RECIPE_BUNDLE,
        cipd_version = 'refs/heads/master',
      ),
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
      entries = [
        luci.console_view_entry(
          builder = builder,
          category = 'Mac',
          short_name = short_name,
        ),
      ]
    )
