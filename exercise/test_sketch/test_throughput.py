#mport random
from operator import itemgetter
import sys
import time
import math

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import CPULimitedHost
from mininet.link import TCLink
from mininet.node import OVSController, RemoteController

from mininet.util import dumpNodeConnections
from mininet.log import setLogLevel
from mininet.cli import CLI


class Lab3Topo(Topo):
    def build(self):
        self.addHost('h1')
        self.addHost('h2')
        #self.addHost('h3')
        #self.addHost('h4')
        #self.addHost('h5')

        self.addSwitch( 's1' )
        #self.addSwitch( 's2' )
        #self.addSwitch( 's3' )
        #self.addSwitch( 's4' )
        #self.addSwitch( 's5' )

        ###########    Network Topo   ################


        ##############################################
        #
        #                 h5
        #                 /
        #       h1      s5     h4
        #         \   /    \ /
        #           s1      s4
        #           |        |
        #           |        |
        #           |        |
        #           |        |
        #           |        |
        #          s2-------s3
        #         /           \
        #       h2             h3

        ###########   Switch - host link   #############
        self.addLink('s1', 'h1', bw=10, port1=1, port2=1)
        self.addLink('s1', 'h2', bw=10, port1=2, port2=1)




# How flow pattern are generated
'''
def generate_flow_request(flows):
    data = np.random.exponential(8, 10)
    time_stamp = []
    t = 0
    request = []
    requests_pair = []
    for flow in flows:
        init = random.randint(10, 30)
        data = np.random.exponential(init, 10)
        t = 0
        time_stamp = []
        for it in data:
            time_stamp.append(round(it))
            t += round(it)
            request.append({'flow': flow, 'arrival time':t})
            requests_pair.append([flow[0], flow[1], t])
    requests_pair = sorted(requests_pair, key=lambda requests_pair: requests_pair[2], reverse=False)
    return requests_pair
'''
if __name__ == "__main__":
    hosts = ['h1', 'h2']

    setLogLevel('info')

    topo = Lab3Topo()
    net = Mininet( topo=topo, link=TCLink )
    net.start()

    net.pingAll()
    time.sleep(10)
    h1, h2 = net.get('h1', 'h2')
    h2.cmd('iperf -s -u -i 1 > ./Experiment/interval/x_h2.txt &')

    for idx in range(10):
        time.sleep(2)

        cmd = 'iperf -c ' + h2.IP() + ' -u  -b 20m -t 30 -i 1 -p   &'
        h1.cmd(cmd)
        print idx,  "th flow arrival time is", time.ctime()
	idx += 1

    print '*******************************'
    print "Wait for flow test finished"
    print '*******************************'
    time.sleep(5)
    print "Flow test is finished\nYou can shotdown mininet and test your result now \n"

    CLI(net)
    net.stop()
