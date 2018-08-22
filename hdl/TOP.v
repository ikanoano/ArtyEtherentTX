
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

wire          nibble_clk;
wire[3:0]     nibble;
wire          nibble_user_data;
wire          nibble_valid;
wire[3:0]     with_usr;
wire          with_usr_valid;
ethernet_test et (
  CLK100MHZ,
  switches,

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



endmodule

`default_nettype wire
