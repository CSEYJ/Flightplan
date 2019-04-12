#!/usr/bin/env python2

# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import os
import sys
if 'BMV2_REPO' in os.environ:
    newpath  = os.path.join(os.environ['BMV2_REPO'], 'tools')
    print("Appending {} to pythonpath".format(newpath))
    sys.path.append(newpath)
else:
    print("WARNING: BMV2_REPO variable not found")
    print("Unless behavioral-model/tools has been added to the path explicitly, "
          "this test will likely fail")

from mininet.net import Mininet
from mininet.topo import Topo
from mininet.log import setLogLevel, info
from mininet.cli import CLI

from flightplan_p4_mininet import P4Switch, P4Host, send_commands

from collections import defaultdict
import argparse
import yaml
from time import sleep

parser = argparse.ArgumentParser(description="Flightplan Mininet Layout")
parser.add_argument('config', help="Path to topological configuration yaml file")
parser.add_argument('--pcap-dump', help="Path to directory to dump pcap files into",
                    type=str, required=False, default=None)
parser.add_argument('--verbose', help='Turn on console logging',
                    action='store_true')
parser.add_argument('--log', help='Log to this directory',
                    type=str, required=False, default=None)
parser.add_argument('--cli', help='Run CLI',
                    action='store_true')
parser.add_argument('--bmv2-exe', help='Path to bmv2 executable',
                    type=str, required=False, default=None)
parser.add_argument('--replay', help='Provide a pcap file to be sent through from h1 to h2',
                    type=str, action='store', required=False, default=False)
parser.add_argument('--host-prog', help='Run a program on a host. Syntax = "hostname:program to run"',
                    type=str, action='append', required=False, default=[])
parser.add_argument('--time', help='Time to run mininet for',
                    type=int, required=False, default=1)
# Modified below in main execution
# (sorry for the global)
global cfg_file

def cfgpath(path):
    cfg_dir = os.path.dirname(os.path.realpath(cfg_file))
    return os.path.join(cfg_dir, path)

class FPTopo(Topo):

    def __init__(self, host_spec, switch_spec, sw_path, log, verbose):
        Topo.__init__(self)

        self.all_links = {}
        max_link_port = defaultdict(int)

        self.log_dir = log
        self.host_spec = host_spec
        self.switch_spec = switch_spec
        self.all_nodes = {}
        base_thrift = 9090

        switch_items = sorted(switch_spec.items(), key=lambda x: x[0])

        for i, (sw_name, sw_opts) in enumerate(switch_items):
            if log:
                console_log = os.path.join(log, sw_name+'.log')
            else:
                console_log = None

            switch = self.addSwitch(sw_name,
                                    sw_path = sw_path,
                                    json_path = cfgpath(sw_opts['cfg']),
                                    thrift_port = base_thrift + i,
                                    log_console = console_log,
                                    verbose = verbose)

            self.all_nodes[sw_name] = dict(
                    node=switch,
                    port=base_thrift+i)

            for link_name, link_num  in sw_opts.get('links', {}).items():
                self.all_links[(sw_name, link_name)] = link_num
                max_link_port[sw_name] = max(max_link_port[sw_name], link_num+1)

            print("SWITCH: %s" % self.all_nodes[sw_name])

        for i, (host_name, host_ops) in enumerate(sorted(host_spec.items())):
            self.all_nodes[host_name] = dict(
                    node = (self.addHost(host_name,
                                         ip = '10.0.{}.1/24'.format(i),
                                         mac = '00:04:00:00:00:{:02x}'.format(i))),
                    ip = '10.0.{}.1'.format(i),
                    mac = '00:04:00:00:00:{:02x}'.format(i),
            )
            print("HOST: %s" % self.all_nodes[host_name])

            for link_name, link_num in host_ops.get('links', {}):
                self.all_links[(host_name, link_name)] = link_num
                max_link_port[host_name] = max(max_link_port[host_name], link_num+1)

        created_links = defaultdict(set)
        for (name1, name2), port1 in self.all_links.items():

            # Already added in the other direction
            if name1 in created_links[name2]:
                continue

            if (name2, name1) not in self.all_links:
                self.all_links[(name2, name1)] = max_link_port[name2]
                max_link_port[name2] += 1

            self.addLink(name1, name2,
                         port1 = port1,
                         port2 = self.all_links[(name2, name1)])
            created_links[name1].add(name2)
            created_links[name2].add(name1)

    def init(self, net):

        for h in net.hosts:
            h.cmd("sysctl -w net.ipv6.conf.all.disable_ipv6=1")
            h.cmd("sysctl -w net.ipv6.conf.default.disable_ipv6=1")
            h.cmd("sysctl -w net.ipv6.conf.lo.disable_ipv6=1")

        for s in net.switches:
            s.cmd("sysctl -w net.ipv6.conf.all.disable_ipv6=1")
            s.cmd("sysctl -w net.ipv6.conf.default.disable_ipv6=1")
            s.cmd("sysctl -w net.ipv6.conf.lo.disable_ipv6=1")

        for node1 in self.host_spec:
            #for node2 in self.host_spec:
                #if node1 == node2:
                #    continue
            h1 = net.get(node1)
            h1.cmd('ip route add default dev eth0 via ' + self.all_nodes[node1]['ip'])
            #h1.setDefaultRoute('dev eth0 via ' + self.all_nodes[node1]['ip'])

        for node in self.host_spec:
            n = net.get(node)
            n.describe()

    def start_tcp_dump(self, net, directory, name1, name2):
        if_num = self.all_links[(name1, name2)]
        if name1.startswith('h'):
            iface = 'eth{}'.format(if_num)
        else:
            iface = '{}-eth{}'.format(name1, if_num)

        fname = os.path.join(directory, '{}_to_{}.pcap'.format(name1, name2))
        net.get(name1).cmd('tcpdump -i {} -Q out -w {}&'.format(iface, fname))

        fname = os.path.join(directory, '{}_from_{}.pcap'.format(name1, name2))
        net.get(name1).cmd('tcpdump -i {} -Q in -w {}&'.format(iface, fname))

    def start_tcp_dumps(self, net, directory):
        for name1, name2 in self.all_links:
            self.start_tcp_dump(net, directory, name1, name2)

    def stop_tcp_dumps(self, net):
        print("Stopping tcpdump on hosts")
        for host in self.host_spec:
            net.get(host).cmd('pkill tcpdump')
        for switch in self.switch_spec:
            net.get(switch).cmd('pkill tcpdump')


    def do_switch_replay(self, net):
        for sw1_name, sw_opts in self.switch_spec.items():
            for sw2_name, filename in sw_opts.get('replay',{}).items():
                num = self.all_links[(sw1_name, sw2_name)]
                print("Replaying {} from {} on {}-eth{} to {}".format(filename, sw1_name, sw1_name, num, sw2_name))
                net.get(sw1_name).cmd(
                        'tcpreplay -i {}-eth{} {}'.format(sw1_name, num, cfgpath(filename))
                )
                sleep(1)

    def do_commands(self, net):
        for sw_name, sw_opts in self.switch_spec.items():
            if 'cmds' in sw_opts:
                for cmd_file in sw_opts['cmds']:
                    commands = open(cfgpath(cmd_file)).readlines()
                    send_commands(self.all_nodes[sw_name]['port'], cfgpath(sw_opts['cfg']), commands)

    def run_host_programs(self, net, extras):
        for name, spec in self.host_spec.items():
            if 'program' in spec:
                print("Running {} on {}".format(spec['program'], name))
                net.get(name).cmd('{} > {}/{}_prog.log 2>&1 &'.format(spec['program'], self.log_dir, name))

        for extra_prog in extras:
            try:
                name, program = extra_prog.split(':')
            except:
                print("Programs provided from cli must be of form 'h1:program to run'")
                raise
            print("Running {} on {}".format(program, name))
            net.get(name).cmd('{} > {}/{}_prog.log 2>&1 &'.format(program, self.log_dir, name))

    def do_host_replay(self, net, host, towards, file):
        print("Replaying {} on {}.eth0".format(file, host))
        net.get(host).cmd(
                'tcpreplay -p 100 -i eth0 {}'.format(file)
        )

def main():
    global cfg_file
    args = parser.parse_args()

    if args.bmv2_exe is None:
        bmv2_exe = os.path.join(os.environ['BMV2_REPO'], 'targets', 'booster_switch', 'simple_switch')
    else:
        bmv2_exe = args.bmv2_exe

    cfg_file = args.config

    with open(args.config) as f:
        cfg = yaml.load(f)

    topo = FPTopo(cfg['hosts'], cfg['switches'],
                  bmv2_exe, args.log, args.verbose)

    print("Starting mininet")
    net = Mininet(topo=topo, host=P4Host, switch=P4Switch, controller=None)

    net.start()

    topo.init(net)

    net.staticArp()


    if args.pcap_dump:
        sleep(1)
        topo.start_tcp_dumps(net, args.pcap_dump)


    sleep(1)

    topo.do_switch_replay(net)

    sleep(1)

    topo.do_commands(net)

    topo.run_host_programs(net, args.host_prog)

    if args.replay:
        replay_args = args.replay.split(":")
        replay_arg1 = replay_args[0].split('-')
        if len(replay_args) != 2 or len(replay_arg1) != 2:
            raise Exception("args.replay must have form Host-Switch:File")
        topo.do_host_replay(net, replay_arg1[0], replay_arg1[1], replay_args[1])
        sleep(1)

    sleep(args.time)

    if args.cli:
        CLI(net)

    if args.pcap_dump:
        topo.stop_tcp_dumps(net)
    print("Stoping mininet")

if __name__ == '__main__':
    setLogLevel('debug')
    main()


