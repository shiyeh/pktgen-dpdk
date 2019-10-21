package.path = package.path ..";?.lua;test/?.lua;app/?.lua;"

require "Pktgen"

pktgen.ports_per_page(2);
-- pktgen.icmp_echo("all", "on");
-- pktgen.send_arp("all", "g");
pktgen.set_mac("0","src", "aabb:8899:3344");
pktgen.set_mac("1", "dst","ccdd:5566:3344");
-- pktgen.mac_from_arp("on");

pktgen.set_ipaddr("0", "dst", "1.1.1.241");
pktgen.set_ipaddr("0", "src", "2.1.1.242/24");
pktgen.set_ipaddr("1", "dst", "10.10.2.2");
pktgen.set_ipaddr("1", "src", "10.10.2.2/24");
-- pktgen.set_proto("all", "udp");
-- pktgen.set_type("all", "ipv6");
