
paths = open('multipaths.out', 'r')
iosched = open('chiosched.sh', 'w')

XIV=1
for path in paths:
    if path.find('XIV') != -1:
        print(path)
        XIV=1
    elif path.find('2145') != -1:
        XIV=0
    if XIV == 1:
        print(path)
        drive = path.split(' ')
        if len(drive) > 2:
            if drive[3].startswith('sd'):
                print(drive[3])
                print(''.join(['echo \'noop\' > /sys/block/', drive[3], '/queue/scheduler']), file=iosched)
paths.close()
iosched.close()
