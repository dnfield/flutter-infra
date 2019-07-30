#!/usr/bin/env lucicfg

load('//prod_builder.star', 'prodBuilder')

RECIPE_BUNDLE = 'infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build'
FLUTTER_REPO_URL = 'https://chromium.googlesource.com/external/github.com/flutter/flutter'

FLUTTER_BUILDER_LINUX_PACKAGING = 'Linux Flutter Packaging'
FLUTTER_BUILDER_WINDOWS_PACKAGING = 'Windows Flutter Packaging'
FLUTTER_BUILDER_MAC_PACKAGING = 'Mac Flutter Packaging'

luci.console_view(
  name = 'packaging',
  repo = FLUTTER_REPO_URL,
  refs = ['refs/heads/beta', 'refs/heads/dev', 'refs/heads/stable'],
  exclude_ref = 'refs/heads/master',
  include_experimental_builds = True,
)

FLUTTER_RECIPE = luci.recipe(
  name = 'flutter/flutter',
  cipd_package = RECIPE_BUNDLE,
  cipd_version = 'refs/heads/master',
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

luci.gitiles_poller(
  name = 'gitiles-trigger-packaging',
  bucket = 'prod',
  repo = FLUTTER_REPO_URL,
  refs = ['refs/heads/dev', 'refs/heads/beta', 'refs/heads/stable'],
)
