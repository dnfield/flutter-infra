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
