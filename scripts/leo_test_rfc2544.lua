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
local FRAME_LOSS=0.01;
local PORT_NUMBERS=4;

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

local tx0_prev=0;
local tx1_prev=0;
local tx2_prev=0;
local tx3_prev=0;
local rx0_prev=0;
local rx1_prev=0;
local rx2_prev=0;
local rx3_prev=0;

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
	local statTxRx_0, statTxRx_1, statTxRx_2, statTxRx_3;
	local num_tx0, num_tx1, num_tx2, num_tx3, total_tx=0;
	local num_rx0, num_rx1, num_rx2, num_rx3, total_rx=0;
	local num_dropped_0, num_dropped_1, num_dropped_2, num_dropped_3, total_dropped;
	local ret_loss;
	local msg;
	local statTxRx={};
	local numTx={};
	local numRx={};

	for port_count=0, PORT_NUMBERS-1, 1 do
		-- statTxRx = pktgen.portStats(port_count, "port")[tonumber(port_count)];
		table.insert(statTxRx, pktgen.portStats(port_count, "port")[tonumber(port_count)]);

		tx_prev[port_count+1] = tx_prev[port_count+1] or 0;
		table.insert(numTx, statTxRx[port_count+1].opackets-tx_prev[port_count+1]);
		total_tx = total_tx + numTx[port_count+1];
	
		rx_prev[port_count+1] = rx_prev[port_count+1] or 0;
		table.insert(numRx, statTxRx[port_count+1].ipackets-rx_prev[port_count+1]);
		total_rx = total_rx + numRx[port_count+1];
	end

	-- statTxRx_0 = pktgen.portStats(0, "port")[tonumber(0)];
	-- statTxRx_1 = pktgen.portStats(1, "port")[tonumber(1)];
	-- statTxRx_2 = pktgen.portStats(2, "port")[tonumber(2)];
	-- statTxRx_3 = pktgen.portStats(3, "port")[tonumber(3)];
	-- num_tx0 = statTxRx_0.opackets-tx0_prev;
	-- num_tx1 = statTxRx_1.opackets-tx1_prev;
	-- num_tx2 = statTxRx_2.opackets-tx2_prev;
	-- num_tx3 = statTxRx_3.opackets-tx3_prev;
	-- total_tx = num_tx0+num_tx1+num_tx2+num_tx3;

	-- num_rx0 = statTxRx_0.ipackets-rx0_prev;
	-- num_rx1 = statTxRx_1.ipackets-rx1_prev;
	-- num_rx2 = statTxRx_2.ipackets-rx2_prev;
	-- num_rx3 = statTxRx_3.ipackets-rx3_prev;
	-- total_rx = num_rx0+num_rx1+num_rx2+num_rx3;

	-- num_dropped_0 = num_tx1 - num_rx0;
	-- num_dropped_1 = num_tx0 - num_rx1;
	-- num_dropped_2 = num_tx3 - num_rx2;
	-- num_dropped_3 = num_tx2 - num_rx3;
	num_dropped_0 = numTx[2] - numRx[1];
	num_dropped_1 = numTx[1] - numRx[2];
	num_dropped_2 = numTx[4] - numRx[3];
	num_dropped_3 = numTx[3] - numRx[4];
	total_dropped = num_dropped_0+num_dropped_1+num_dropped_2+num_dropped_3;

	msg =        string.format("[P0]    Tx: %d Rx: %d Drop: %d\n", numTx[1], numRx[1], num_dropped_0);
	msg = msg .. string.format("[P1]    Tx: %d Rx: %d Drop: %d\n", numTx[2], numRx[2], num_dropped_1);
	msg = msg .. string.format("[P2]    Tx: %d Rx: %d Drop: %d\n", numTx[3], numRx[3], num_dropped_2);
	msg = msg .. string.format("[P3]    Tx: %d Rx: %d Drop: %d", numTx[4], numRx[4], num_dropped_3);
	-- msg =        string.format("[P0]    Tx: %d Rx: %d Drop: %d\n", num_tx0, num_rx0, num_dropped_0);
	-- msg = msg .. string.format("[P1]    Tx: %d Rx: %d Drop: %d\n", num_tx1, num_rx1, num_dropped_1);
	-- msg = msg .. string.format("[P2]    Tx: %d Rx: %d Drop: %d\n", num_tx2, num_rx2, num_dropped_2);
	-- msg = msg .. string.format("[P3]    Tx: %d Rx: %d Drop: %d", num_tx3, num_rx3, num_dropped_3);

	print(msg);
	file:write(msg.."\n");

	-- print("[PORT 0] Tx: " .. num_tx0 .. ". Rx: " .. num_rx0 .. ". Dropped: " .. num_dropped_0);
	-- print("[PORT 1] Tx: " .. num_tx1 .. ". Rx: " .. num_rx1 .. ". Dropped: " .. num_dropped_1);
	-- print("[PORT 2] Tx: " .. num_tx2 .. ". Rx: " .. num_rx2 .. ". Dropped: " .. num_dropped_2);
	-- print("[PORT 3] Tx: " .. num_tx3 .. ". Rx: " .. num_rx3 .. ". Dropped: " .. num_dropped_3);
	-- file:write("[PORT 0] Tx: " .. num_tx0 .. ". Rx: " .. num_rx0 .. ". Dropped: " .. num_dropped_0 .. "\n");
	-- file:write("[PORT 1] Tx: " .. num_tx1 .. ". Rx: " .. num_rx1 .. ". Dropped: " .. num_dropped_1 .. "\n");
	-- file:write("[PORT 2] Tx: " .. num_tx2 .. ". Rx: " .. num_rx2 .. ". Dropped: " .. num_dropped_2 .. "\n");
	-- file:write("[PORT 3] Tx: " .. num_tx3 .. ". Rx: " .. num_rx3 .. ". Dropped: " .. num_dropped_3 .. "\n");
	
	ret_loss = (total_dropped / total_tx) * 100; -- Percentage

	msg = string.format("[TOTAL] Tx: %d Rx: %d Drop: %d Frame loss: %0.5f %%", total_tx, total_rx, total_dropped, ret_loss);
	print(msg);
	file:write(msg.."\n");

	-- print("[ ALL  ] Tx: " .. num_tx .. ". Rx: " .. num_rx .. ". Dropped: " .. num_dropped .. ". Frame loss(%): " .. ret_loss);
	-- file:write("[ ALL  ] Tx: " .. num_tx .. ". Rx: " .. num_rx .. ". Dropped: " .. num_dropped .. ". Frame loss(%): " .. ret_loss .. "\n");
	pktgen.delay(5000);

	-- tx0_prev = statTxRx_0.opackets;
	-- tx1_prev = statTxRx_1.opackets;
	-- tx2_prev = statTxRx_2.opackets;
	-- tx3_prev = statTxRx_3.opackets;
	-- rx0_prev = statTxRx_0.ipackets;
	-- rx1_prev = statTxRx_1.ipackets;
	-- rx2_prev = statTxRx_2.ipackets;
	-- rx3_prev = statTxRx_3.ipackets;

	for port_count = 0, PORT_NUMBERS, 1 do
		tx_prev[port_count+1] = statTxRx[port_count+1].opackets;
		rx_prev[port_count+1] = statTxRx[port_count+1].ipackets;
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
	pktgen.delay(10000);
	pktgen.start("all");

	pktgen.delay(duration);
	pktgen.stop("all");

	pktgen.delay(10000);

	return getPortStats();

	-- statTxRx_0 = pktgen.portStats(0, "port")[tonumber(0)];
	-- statTxRx_1 = pktgen.portStats(1, "port")[tonumber(1)];
	-- statTxRx_2 = pktgen.portStats(2, "port")[tonumber(2)];
	-- statTxRx_3 = pktgen.portStats(3, "port")[tonumber(3)];

	-- num_tx0 = statTxRx_0.opackets-tx0_prev;
	-- num_tx1 = statTxRx_1.opackets-tx1_prev;
	-- num_tx2 = statTxRx_2.opackets-tx2_prev;
	-- num_tx3 = statTxRx_3.opackets-tx3_prev;
	-- num_tx = num_tx0+num_tx1+num_tx2+num_tx3;

	-- num_rx0 = statTxRx_0.ipackets-rx0_prev;
	-- num_rx1 = statTxRx_1.ipackets-rx1_prev;
	-- num_rx2 = statTxRx_2.ipackets-rx2_prev;
	-- num_rx3 = statTxRx_3.ipackets-rx3_prev;
	-- num_rx = num_rx0+num_rx1+num_rx2+num_rx3;

	-- num_dropped_0 = num_tx1 - num_rx0;
	-- num_dropped_1 = num_tx0 - num_rx1;
	-- num_dropped_2 = num_tx3 - num_rx2;
	-- num_dropped_3 = num_tx2 - num_rx3;
	-- num_dropped = num_dropped_0+num_dropped_1+num_dropped_2+num_dropped_3;
	

	-- print("[PORT 0] Tx: " .. num_tx0 .. ". Rx: " .. num_rx0 .. ". Dropped: " .. num_dropped_0);
	-- print("[PORT 1] Tx: " .. num_tx1 .. ". Rx: " .. num_rx1 .. ". Dropped: " .. num_dropped_1);
	-- print("[PORT 2] Tx: " .. num_tx2 .. ". Rx: " .. num_rx2 .. ". Dropped: " .. num_dropped_2);
	-- print("[PORT 3] Tx: " .. num_tx3 .. ". Rx: " .. num_rx3 .. ". Dropped: " .. num_dropped_3);

	-- file:write("[PORT 0] Tx: " .. num_tx0 .. ". Rx: " .. num_rx0 .. ". Dropped: " .. num_dropped_0 .. "\n");
	-- file:write("[PORT 1] Tx: " .. num_tx1 .. ". Rx: " .. num_rx1 .. ". Dropped: " .. num_dropped_1 .. "\n");
	-- file:write("[PORT 2] Tx: " .. num_tx2 .. ". Rx: " .. num_rx2 .. ". Dropped: " .. num_dropped_2 .. "\n");
	-- file:write("[PORT 3] Tx: " .. num_tx3 .. ". Rx: " .. num_rx3 .. ". Dropped: " .. num_dropped_3 .. "\n");
	
	-- ret_loss = (num_dropped / num_tx) * 100;

	-- print("[ ALL  ] Tx: " .. num_tx .. ". Rx: " .. num_rx .. ". Dropped: " .. num_dropped .. ". Frame loss(%): " .. ret_loss);
	-- file:write("[ ALL  ] Tx: " .. num_tx .. ". Rx: " .. num_rx .. ". Dropped: " .. num_dropped .. ". Frame loss(%): " .. ret_loss .. "\n");
	-- pktgen.delay(5000);

	-- tx0_prev = statTxRx_0.opackets;
	-- tx1_prev = statTxRx_1.opackets;
	-- tx2_prev = statTxRx_2.opackets;
	-- tx3_prev = statTxRx_3.opackets;
	-- rx0_prev = statTxRx_0.ipackets;
	-- rx1_prev = statTxRx_1.ipackets;
	-- rx2_prev = statTxRx_2.ipackets;
	-- rx3_prev = statTxRx_3.ipackets;

	-- return num_tx, num_rx, num_dropped, ret_loss;
end

local function runThroughputTest(pkt_size)
	local num_dropped, max_rate, min_rate, trial_rate;
	local total_tx, total_rx, total_dropped, ret_loss;
	local tx_pps, rx_pps, msg;

	max_rate = 100;
	min_rate = 1;
	trial_rate = initialRate;
	
	for count=1, 13, 1
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

	msg = string.format("tx-pps: %0.3f rx-pps: %0.3f\n", tx_pps, rx_pps);

	if ret_loss <= FRAME_LOSS
	then
		msg = msg .. string.format("Max rate for %d bytes is: %0.3f"
									, pkt_size, trial_rate);
		print(msg);
		file:write(msg.."\n\n");
		-- print("tx-pps: "..tx_pps.. " rx-pps: "..rx_pps);
		-- file:write("tx-pps: "..tx_pps.. " rx-pps: "..rx_pps .. "\n\n")
		-- print("Max rate for packet size "  .. pkt_size .. "B is: " .. trial_rate);
		-- file:write("Max rate for packet size "  .. pkt_size .. "B is: " .. trial_rate .. "\n\n");
	else
		msg = msg .. string.format("Max rate for %d bytes of %0.3f%% could not be \z
                                            connfirmed for %s seconds as required by rfc2544.\n\n"
                                            , pkt_size, trial_rate, confirmDuration);
		print(msg);
		file:write(msg.."\n\n");
		-- print("tx-pps: "..tx_pps.. " rx-pps: "..rx_pps);
		-- file:write("tx-pps: "..tx_pps.. " rx-pps: "..rx_pps .. "\n\n")
		-- print("Max rate for packet size " .. pkt_size .. " of " .. trial_rate .. "% could not be confirmed for 60 seconds as required by rfc2544.");
		-- file:write("Max rate for packet size " .. pkt_size .. " of " .. trial_rate .. "% could not be confirmed for 60 seconds as required by rfc2544." .. "\n\n");
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
		pktgen.delay(3000);
		runThroughputTest(size);
	end
	file:close();
end

main();
