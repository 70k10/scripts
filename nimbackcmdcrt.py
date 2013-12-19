import os
import re
import socket

environments = [u'prm',u'trm',u'trn',u'prd',u'sit',u'uat']

#lswpar -N -c
#name:interface:address:mask_prefix:broadcast
#wpar:en0:10.0.0.2:255.255.255.0:10.0.0.255

#lswpar > lswparout
lswparout = open("./lswparout", 'r')

host=lswparout.readline().rstrip('\n')

lswpar = []
for i in lswparout:
    lswpar.append(re.split(u':', i))

findenv = lambda x: [ a for a in environments if x.find(a) != -1 ]

lswparfiltered = [(wpar[0],wpar[1],socket.gethostbyaddr(wpar[2])[0],findenv(socket.gethostbyaddr(wpar[2])[0])[0]) for wpar in lswpar if wpar[2].startswith('10.')]

nimaddout = open("./nimaddout", 'w')

#nim -o define -t wpar -a mgmt_profile1="serverhost wpar" -a if1="find_net wparhostname 0" envwpar
for wpar in lswparfiltered:
    wparname = wpar[0] if wpar[0].find(wpar[3]) != -1 else ''.join([wpar[3], wpar[0]])
    print(''.join(['nim -o define -t wpar -a mgmt_profile1=\"', host, ' ', wpar[0], '\" -a if1=\"find_net ', wpar[2], ' 0\" ', wparname]))
