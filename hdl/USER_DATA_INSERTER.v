
`default_nettype none
`timescale 1 ps / 1 ps

module USER_DATA_INSERTER (
  input   wire          clk,

  input   wire[3:0]     nibble,
  input   wire          nibble_user_data,
  input   wire          nibble_valid,
  output  reg [3:0]     with_usr,
  output  reg           with_usr_valid
);

reg [3-1:0]   state = 0;
always @(posedge clk) begin
  state <=
    !nibble_user_data ? 0 :
    state < 4         ? state + 1:
                        state;
end

reg [16-1:0]  cnt = 0;
always @(posedge clk) begin
  with_usr_valid  <= nibble_valid;
  casex ({nibble_user_data, state})
    4'b0xxx:  with_usr <= nibble;
    4'b1000:  with_usr <= cnt[4*3+:4];
    4'b1001:  with_usr <= cnt[4*2+:4];
    4'b1010:  with_usr <= cnt[4*1+:4];
    4'b1011:  with_usr <= cnt[4*0+:4];
    default:  with_usr <= nibble;
  endcase

  if({with_usr_valid, nibble_valid}==2'b10) cnt <= cnt+1;
end


endmodule

`default_nettype wire
