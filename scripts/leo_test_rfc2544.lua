-- RFC2544 Throughput Test
-- as defined by https://www.ietf.org/rfc/rfc2544.txt
--  SPDX-License-Identifier: BSD-3-Clause

package.path = package.path ..";?.lua;test/?.lua;app/?.lua;../?.lua"

require "Pktgen";

-- define packet sizes to test
--local pkt_sizes		= { 128,256,512 };
local pkt_sizes		= { 64, 128, 256, 512, 1024, 1280, 1518 };

-- Time in seconds to transmit for
local duration		= 30000;
local confirmDuration	= 60000;
local pauseTime		= 8000;
local FRAME_LOSS=0.01;  -- Percentage
local PORT_NUMBERS=4;
local trial_round=12; --Times

-- define the ports in use
local sendport		= "0";
local recvport		= "1";

-- ip addresses to use
local dstip		= "90.90.90.90";
local srcip		= "1.1.1.1";
local netmask		= "/24";

local initialRate	= 50 ;

local tx_prev={};
local rx_prev={};
local total_tx=0;
local total_rx=0;

local function setupTraffic()
	--pktgen.set_ipaddr(sendport, "dst", dstip);
	--pktgen.set_ipaddr(sendport, "src", srcip..netmask);

	--pktgen.set_ipaddr(recvport, "dst", srcip);
	--pktgen.set_ipaddr(recvport, "src", dstip..netmask);

	-- Leo added --
--	pktgen.set_ipaddr("0", "dst", "3.1.1.242");
	pktgen.set_ipaddr("0", "dst", "2.1.1.242");
	pktgen.set_ipaddr("0", "src", "1.1.1.241/24");
	pktgen.set_ipaddr("1", "dst", "1.1.1.241");
	pktgen.set_ipaddr("1", "src", "2.1.1.242/24");

	--	pktgen.set_ipaddr("2", "dst", "1.1.1.241");
	pktgen.set_ipaddr("2", "dst", "4.1.1.244");
	pktgen.set_ipaddr("2", "src", "3.1.1.243/24");
	pktgen.set_ipaddr("3", "dst", "3.1.1.243");
	pktgen.set_ipaddr("3", "src", "4.1.1.244/24");
	pktgen.set_mac("0", "dst", "00a0:c900:6466");
	pktgen.set_mac("1", "dst", "3412:7856:6566");
	pktgen.set_mac("2", "dst", "00a0:c900:6666");
	pktgen.set_mac("3", "dst", "3412:7856:6766");

	--pktgen.set_proto(sendport..","..recvport, "udp");
	-- set Pktgen to send continuous stream of traffic
	pktgen.set("all", "count", 0);
end

local function getPortStats()
	-- Get and modify all port stats manually by using simple math.
	local num_dropped_0, num_dropped_1, num_dropped_2, num_dropped_3, total_dropped;
	local ret_loss;
	local msg;
	local statTxRx={};
	local numTx={};
	local numRx={};

	for port_count=0, PORT_NUMBERS-1, 1 do
		table.insert(statTxRx, pktgen.portStats(port_count, "port")[tonumber(port_count)]);

		tx_prev[port_count+1] = tx_prev[port_count+1] or 0;
		table.insert(numTx, statTxRx[port_count+1].opackets-tx_prev[port_count+1]);
		total_tx = total_tx + numTx[port_count+1];
	
		rx_prev[port_count+1] = rx_prev[port_count+1] or 0;
		table.insert(numRx, statTxRx[port_count+1].ipackets-rx_prev[port_count+1]);
		total_rx = total_rx + numRx[port_count+1];
	end

	num_dropped_0 = numTx[2] - numRx[1]; -- Port1 tx - Port0 rx
	num_dropped_1 = numTx[1] - numRx[2]; -- Port0 tx - Port1 rx
	num_dropped_2 = numTx[4] - numRx[3]; -- Port3 tx - Port2 rx
	num_dropped_3 = numTx[3] - numRx[4]; -- Port2 tx - Port3 rx
	total_dropped = num_dropped_0+num_dropped_1+num_dropped_2+num_dropped_3;

	msg =        string.format("[P0]    Tx: %d Rx: %d Drop: %d\n", numTx[1], numRx[1], num_dropped_0);
	msg = msg .. string.format("[P1]    Tx: %d Rx: %d Drop: %d\n", numTx[2], numRx[2], num_dropped_1);
	msg = msg .. string.format("[P2]    Tx: %d Rx: %d Drop: %d\n", numTx[3], numRx[3], num_dropped_2);
	msg = msg .. string.format("[P3]    Tx: %d Rx: %d Drop: %d", numTx[4], numRx[4], num_dropped_3);

	print(msg);
	file:write(msg.."\n");

	ret_loss = (total_dropped / total_tx) * 100; -- Percentage

	msg = string.format("[TOTAL] Tx: %d Rx: %d Drop: %d Frame loss: %0.5f %%", total_tx, total_rx, total_dropped, ret_loss);
	print(msg);
	file:write(msg.."\n");

	pktgen.delay(pauseTime);

	for port_count = 1, PORT_NUMBERS, 1 do
		tx_prev[port_count] = statTxRx[port_count].opackets;
		rx_prev[port_count] = statTxRx[port_count].ipackets;
	end

	return total_tx, total_rx, total_dropped, ret_loss;
end

local function runTrial(pkt_size, rate, duration, count)
	local msg;

	pktgen.clr();
	pktgen.set("all", "rate", rate);
	pktgen.set("all", "size", pkt_size);

	msg = string.format("Running trial #%s, Rate: %0.3f%%, Packet Size: %d bytes, Duration: %d (mS).", count, rate, pkt_size, duration);
	-- print("Running trial #" .. count .. ". Rate: " .. rate .. " %. Packet Size: " .. pkt_size .. ". Duration (mS):" .. duration);
	-- file:write("Running trial #" .. count .. ". Rate: " .. rate .. " %. Packet Size: " .. pkt_size .. ". Duration (mS):" .. duration .. "\n");
	print(msg);
	file:write(msg.."\n");
	pktgen.delay(pauseTime);
	pktgen.start("all");

	pktgen.delay(duration);
	pktgen.stop("all");

	pktgen.delay(pauseTime);

	return getPortStats();

end

local function runThroughputTest(pkt_size)
	local max_rate, min_rate, trial_rate;
	local total_tx, total_rx, total_dropped, ret_loss;
	local tx_pps, rx_pps, msg;

	max_rate = 100;
	min_rate = 1;
	trial_rate = initialRate;
	
	for count=1, trial_round, 1
	do
		total_tx, total_rx, total_dropped, ret_loss = runTrial(pkt_size, trial_rate, duration, count);
		if ret_loss <= FRAME_LOSS
		then
			min_rate = trial_rate;
		else
			max_rate = trial_rate;
		end
		trial_rate = min_rate + ((max_rate - min_rate)/2);
	end

	-- Ensure we test confirmation run with the last succesfull zero-drop rate
	if trial_rate >=99.95
	then
		trial_rate = 100;
	else
		trial_rate = min_rate;
	end

	-- confirm throughput rate for at least 60 seconds
	total_tx, total_rx, total_dropped, ret_loss = runTrial(pkt_size, trial_rate, confirmDuration, "Confirmation");

	tx_pps = total_tx / 4 / (confirmDuration/1000);
	rx_pps = total_rx / 4 / (confirmDuration/1000);

	msg = string.format("[AVG-PPS] tx-pps: %0.3f rx-pps: %0.3f\n", tx_pps, rx_pps);

	if ret_loss <= FRAME_LOSS
	then
		msg = msg .. string.format("Max rate for %d bytes is: %0.3f"
									, pkt_size, trial_rate);
		print(msg);
		file:write(msg.."\n\n");
	else
		msg = msg .. string.format("Max rate for %d bytes of %0.3f%% could not be \z
									connfirmed for %s seconds as required by rfc2544."
									, pkt_size, trial_rate, confirmDuration/1000 );
		print(msg);
		file:write(msg.."\n\n");
	end
end

function main()
	file = io.open("RFC2544_tput_results.txt", "w");
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
