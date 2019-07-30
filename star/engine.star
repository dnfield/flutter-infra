#!/usr/bin/env lucicfg

load('//prod_builder.star', 'prodBuilder')
load('//xcode.star', 'XCODE')

RECIPE_BUNDLE = 'infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build'

ENGINE_REPO_URL = 'https://chromium.googlesource.com/external/github.com/flutter/engine'

ENGINE_RECIPE = luci.recipe(
  name = 'flutter/engine',
  cipd_package = RECIPE_BUNDLE,
  cipd_version = 'refs/heads/master',
)

ENGINE_BUILDER_LINUX_HOST = 'Linux Host Engine'
ENGINE_BUILDER_LINUX_ANDROID_AOT = 'Linux Android AOT Engine'
ENGINE_BUILDER_LINUX_ANDROID_DEBUG = 'Linux Android Debug Engine'

ENGINE_BUILDER_MAC_HOST = 'Mac Host Engine'
ENGINE_BUILDER_MAC_ANDROID_AOT = 'Mac Android AOT Engine'
ENGINE_BUILDER_MAC_ANDROID_DEBUG = 'Mac Android Debug Engine'
ENGINE_BUILDER_MAC_IOS = 'Mac iOS Engine'

ENGINE_BUILDER_WINDOWS_HOST = 'Windows Host Engine'
ENGINE_BUILDER_WINDOWS_ANDROID_AOT = 'Windows Android AOT Engine'

luci.console_view(
  name = 'engine',
  repo = ENGINE_REPO_URL,
  refs = ['refs/heads/master'],
  include_experimental_builds = True,
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
  default_properties = {
    'jazzy_version': '0.9.5',
    '$depot_tools/osx_sdk': XCODE,
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
  ENGINE_BUILDER_MAC_ANDROID_DEBUG,
  short_name = 'dbg',
  properties = getEngineProperties(build_android_debug = True, build_android_vulkan = True),
)

prodEngineMacBuilder(
  ENGINE_BUILDER_MAC_ANDROID_AOT,
  short_name = 'aot',
  properties = getEngineProperties(build_android_aot = True),
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
