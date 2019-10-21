-- RFC2544 Throughput Test
-- as defined by https://www.ietf.org/rfc/rfc2544.txt
--  SPDX-License-Identifier: BSD-3-Clause

package.path = package.path ..";?.lua;test/?.lua;app/?.lua;../?.lua"

require "Pktgen";

-- define packet sizes to test
local pkt_sizes		= { 64, 1518, 1280, 512, 128 };
-- local pkt_sizes		= { 64, 128, 256, 512, 1024, 1280, 1518 };

-- Time in seconds to transmit for
local duration		= 10000;
local confirmDuration	= 60000;
local pauseTime		= 8000;

-- define the ports in use
local sendport		= "0";
local recvport		= "1";

-- ip addresses to use
local dstip		= "90.90.90.90";
local srcip		= "1.1.1.1";
local netmask		= "/24";

local initialRate	= 50 ;

local tx_prev = 0;
local rx_prev = 0;

local function setupTraffic()
	pktgen.set_ipaddr(sendport, "dst", dstip);
	pktgen.set_ipaddr(sendport, "src", srcip..netmask);

	pktgen.set_ipaddr(recvport, "dst", srcip);
	pktgen.set_ipaddr(recvport, "src", dstip..netmask);

	pktgen.set_proto(sendport..","..recvport, "udp");
	-- set Pktgen to send continuous stream of traffic
	pktgen.set(sendport, "count", 0);
end

local function runTrial(pkt_size, rate, duration, count)
	local num_tx, num_rx, num_dropped;

	pktgen.clr();
	pktgen.set("all", "rate", rate);
	pktgen.set("all", "size", pkt_size);

	pktgen.start("all");
	-- pktgen.start("all");
	print("Running trial " .. count .. ". Rate: " .. rate .. " %. Packet Size: " .. pkt_size .. ". Duration (mS):" .. duration);
	file:write("Running trial " .. count .. ". Rate: " .. rate .. " %. Packet Size: " .. pkt_size .. ". Duration (mS):" .. duration .. "\n");
	pktgen.delay(duration);
	pktgen.stop("all");

	pktgen.delay(5000);

	-- statTx = pktgen.portStats(sendport, "port")[tonumber(sendport)];
	-- statRx = pktgen.portStats(recvport, "port")[tonumber(recvport)];
	statTxRx_0 = pktgen.portStats(0, "port")[tonumber(0)];
	statTxRx_1 = pktgen.portStats(1, "port")[tonumber(1)];

	-- statRx_0 = pktgen.portStats(0, "port")[tonumber(0)];
	-- statRx_1 = pktgen.portStats(1, "port")[tonumber(1)];
	-- statRx_2 = pktgen.portStats(2, "port")[tonumber(2)];
	-- statRx_3 = pktgen.portStats(3, "port")[tonumber(3)];

	num_tx = statTxRx_0.opackets + statTxRx_1.opackets;
	num_rx = statTxRx_0.ipackets + statTxRx_1.ipackets;

	-- num_tx = statTx.opackets - tx_prev;
	-- num_rx = statRx.ipackets - rx_prev;
	-- num_dropped = num_tx - num_rx;
	num_dropped_0 = statTxRx_0.opackets - statTxRx_0.ipackets;
	num_dropped_1 = statTxRx_1.opackets - statTxRx_1.ipackets;
	num_dropped = num_dropped_0+num_dropped_1;

	print("[PORT 0] Tx: " .. statTxRx_0.opackets .. ". Rx: " .. statTxRx_0.ipackets .. ". Dropped: " .. num_dropped_0);
	print("[PORT 1] Tx: " .. statTxRx_1.opackets .. ". Rx: " .. statTxRx_1.ipackets .. ". Dropped: " .. num_dropped_1);

	file:write("[PORT 0] Tx: " .. statTxRx_0.opackets .. ". Rx: " .. statTxRx_0.ipackets .. ". Dropped: " .. num_dropped_0 .. "\n");
	file:write("[PORT 1] Tx: " .. statTxRx_1.opackets .. ". Rx: " .. statTxRx_1.ipackets .. ". Dropped: " .. num_dropped_1 .. "\n");
	pktgen.delay(3000);

	tx_prev = num_tx;
	rx_prev = num_rx;

	return num_dropped;
end

local function runThroughputTest(pkt_size)
	local num_dropped, max_rate, min_rate, trial_rate;

	max_rate = 100;
	min_rate = 1;
	trial_rate = initialRate;
	for count=1, 10, 1
	do
		num_dropped = runTrial(pkt_size, trial_rate, duration, count);
		if num_dropped <= 0
		then
			min_rate = trial_rate;
		else
			max_rate = trial_rate;
		end
		trial_rate = min_rate + ((max_rate - min_rate)/2);
	end

	-- Ensure we test confirmation run with the last succesfull zero-drop rate
	if trial_rate >=99.9
	then
		trial_rate = 100;
	else
		trial_rate = min_rate;
	end

	-- confirm throughput rate for at least 60 seconds
	num_dropped = runTrial(pkt_size, trial_rate, confirmDuration, "Confirmation");
	if num_dropped <= 0
	then
		print("Max rate for packet size "  .. pkt_size .. "B is: " .. trial_rate);
		file:write("Max rate for packet size "  .. pkt_size .. "B is: " .. trial_rate .. "\n\n");
	else
		print("Max rate of " .. trial_rate .. "% could not be confirmed for 60 seconds as required by rfc2544.");
		file:write("Max rate of " .. trial_rate .. "% could not be confirmed for 60 seconds as required by rfc2544." .. "\n\n");
	end
end

function main()
	file = io.open("RFC2544_throughput_results.txt", "w");
	print("Setting traffic, please wait...");
	pktgen.delay(3000);
	setupTraffic();
	pktgen.delay(3000);

	for _,size in pairs(pkt_sizes)
	do
		runThroughputTest(size);
	end
	file:close();
end

main();
