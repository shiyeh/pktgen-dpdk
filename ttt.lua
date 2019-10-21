package.path = package.path ..";?.lua;test/?.lua;app/?.lua;"

-- require "Pktgen";
function pktgen_config()

    pktgen.screen("on");

    pktgen.set_ipaddr("0", "src", "192.168.89.101/24");
    pktgen.set_ipaddr("0", "dst", "192.168.89.102");
    -- pktgen.set_mac("0", "FA:16:3E:26:E9:E6");
    pktgen.set("all", "sport", 1000);
    pktgen.set("all", "dport", 1000);
    pktgen.set("all", "size", 64);
    pktgen.set("all", "rate", 100);
    pktgen.set_type("all", "ipv4");
    pktgen.set_proto("all", "udp");

    pktgen.src_ip("0", "start", "192.168.89.101");
    pktgen.src_ip("0", "inc", "0.0.0.0");
    pktgen.src_ip("0", "min", "192.168.89.101");
    pktgen.src_ip("0", "max", "192.168.89.101");
    pktgen.dst_ip("0", "start", "192.168.89.102");
    pktgen.dst_ip("0", "inc", "0.0.0.0");
    pktgen.dst_ip("0", "min", "192.168.89.102");
    pktgen.dst_ip("0", "max", "192.168.89.102");

    pktgen.dst_mac("0", "start", "FA:16:3E:26:E9:E6");

    pktgen.src_port("all", "start", 1000);
    pktgen.src_port("all", "inc", 1);
    pktgen.src_port("all", "min", 1000);
    pktgen.src_port("all", "max", 1099);
    pktgen.dst_port("all", "start", 1000);
    pktgen.dst_port("all", "inc", 1);
    pktgen.dst_port("all", "min", 1000);
    pktgen.dst_port("all", "max", 1100);

    pktgen.pkt_size("all", "start", 64);
    pktgen.pkt_size("all", "inc",0);
    pktgen.pkt_size("all", "min", 64);
    pktgen.pkt_size("all", "max", 64);
    pktgen.ip_proto("all", "udp");
    pktgen.set_range("all", "on");

    pktgen.start("all");
    pktgen.sleep(20)
    pktgen.stop("all");
    pktgen.sleep(20)

    prints("opackets", pktgen.portStats("all", "port")[0].opackets);
    prints("oerrors", pktgen.portStats("all", "port")[0].oerrors);

end

pktgen_config()
