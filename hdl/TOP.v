
`default_nettype none
`timescale 1 ps / 1 ps

module TOP (
  input   wire          CLK100MHZ,
  input   wire[4-1:0]   switches,
  inout   wire          eth_mdio,
  output  wire          eth_mdc,
  output  wire          eth_rstn,
  output  wire[4-1:0]   eth_tx_d,
  output  wire          eth_tx_en,
  input   wire          eth_tx_clk,
  input   wire[4-1:0]   eth_rx_d,
  input   wire          eth_rx_err,
  input   wire          eth_rx_dv,
  input   wire          eth_rx_clk,
  input   wire          eth_col,
  input   wire          eth_crs,
  output  wire          eth_ref_clk
);

reg           start_sending;
wire          nibble_clk;
wire[3:0]     nibble;
wire          nibble_user_data;
wire          nibble_valid;
wire[3:0]     with_usr;
wire          with_usr_valid;
ethernet_test et (
  CLK100MHZ,

  eth_mdio,
  eth_mdc,
  eth_rstn,
  eth_tx_d,
  eth_tx_en,
  eth_tx_clk,
  eth_rx_d,
  eth_rx_err,
  eth_rx_dv,
  eth_rx_clk,
  eth_col,
  eth_crs,
  eth_ref_clk,

  start_sending,
  nibble_clk,
  nibble,
  nibble_user_data,
  nibble_valid,
  with_usr,
  with_usr_valid
);

USER_DATA_INSERTER udi (
  nibble_clk,

  nibble,
  nibble_user_data,
  nibble_valid,
  with_usr,
  with_usr_valid
);


//
// Scheduling when packets are sent
//
reg[25-1:0] count=0, max_count=0;
always @(posedge nibble_clk) begin
  case(switches)
    4'b0000: max_count <= 24999999;  // 1 packet per second
    4'b0001: max_count <= 12499999;  // 2 packet per second
    4'b0010: max_count <=  2499999;  // 10 packets per second 
    4'b0011: max_count <=  1249999;  // 20 packet per second
    4'b0100: max_count <=   499999;  // 50 packets per second 
    4'b0101: max_count <=   249999;  // 100 packets per second
    4'b0110: max_count <=   124999;  // 200 packets per second 
    4'b0111: max_count <=    49999;  // 500 packets per second 
    4'b1000: max_count <=    24999;  // 1000 packets per second 
    4'b1001: max_count <=    12499;  // 2000 packets per second 
    4'b1010: max_count <=     4999;  // 5000 packets per second 
    4'b1011: max_count <=     2499;  // 10,000 packests per second 
    4'b1100: max_count <=      999;  // 20,000 packets per second
    4'b1101: max_count <=      499;  // 50,000 packets per second 
    4'b1110: max_count <=      249;  // 100,000 packets per second
    default: max_count <=        0;  // as fast as possible 152,439 packets
  endcase

  count         <= count==max_count ? 0 : count+1;
  start_sending <= count==max_count;
end



endmodule

`default_nettype wire
