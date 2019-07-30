#!/usr/bin/env lucicfg

load('//prod_builder.star', 'prodBuilder')
load('//xcode.star', 'XCODE')

RECIPE_BUNDLE = 'infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build'
FLUTTER_REPO_URL = 'https://chromium.googlesource.com/external/github.com/flutter/flutter'

FLUTTER_BUILDER_LINUX = 'Linux'
FLUTTER_BUILDER_LINUX_COVERAGE = 'Linux Coverage'
FLUTTER_BUILDER_WINDOWS = 'Windows'
FLUTTER_BUILDER_MAC = 'Mac'

FLUTTER_RECIPE = luci.recipe(
  name = 'flutter/flutter',
  cipd_package = RECIPE_BUNDLE,
  cipd_version = 'refs/heads/master',
)

luci.console_view(
  name = 'framework',
  repo = FLUTTER_REPO_URL,
  refs = ['refs/heads/master'],
  include_experimental_builds = True,
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
    '$depot_tools/osx_sdk': XCODE,
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

luci.gitiles_poller(
  name = 'master-gitiles-trigger-framework',
  bucket = 'prod',
  repo = FLUTTER_REPO_URL,
)
