cmd_port_config.o = gcc -Wp,-MD,./.port_config.o.d.tmp  -m64 -pthread  -march=native -DRTE_MACHINE_CPUFLAG_SSE -DRTE_MACHINE_CPUFLAG_SSE2 -DRTE_MACHINE_CPUFLAG_SSE3 -DRTE_MACHINE_CPUFLAG_SSSE3 -DRTE_MACHINE_CPUFLAG_SSE4_1 -DRTE_MACHINE_CPUFLAG_SSE4_2 -DRTE_MACHINE_CPUFLAG_AES -DRTE_MACHINE_CPUFLAG_PCLMULQDQ -DRTE_MACHINE_CPUFLAG_AVX -DRTE_MACHINE_CPUFLAG_RDRAND -DRTE_MACHINE_CPUFLAG_FSGSBASE -DRTE_MACHINE_CPUFLAG_F16C -DRTE_MACHINE_CPUFLAG_AVX2  -I/home/leo/pktgen-dpdk/lib/common/x86_64-native-linuxapp-gcc/include -I/home/leo/dpdk-stable-18.11.2//x86_64-native-linuxapp-gcc/include -include /home/leo/dpdk-stable-18.11.2//x86_64-native-linuxapp-gcc/include/rte_config.h -D_GNU_SOURCE -O3 -g -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations -Wold-style-definition -Wpointer-arith -Wcast-align -Wnested-externs -Wcast-qual -Wformat-nonliteral -Wformat-security -Wundef -Wwrite-strings -Wdeprecated -Wimplicit-fallthrough=2 -Wno-format-truncation -Wno-address-of-packed-member -I/home/leo/pktgen-dpdk/lib/common -D_GNU_SOURCE -DALLOW_EXPERIMENTAL_API    -o port_config.o -c /home/leo/pktgen-dpdk/lib/common/port_config.c 
