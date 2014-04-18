def FlagsForFile(filename, **kwargs):
  final_flags = [
    '-Wall',
    '-I', '.',
    '-I', '/usr/local/include',
    '-fobjc-arc'
  ]
  return {
    'flags': final_flags,
    'do_cache': True
  }

