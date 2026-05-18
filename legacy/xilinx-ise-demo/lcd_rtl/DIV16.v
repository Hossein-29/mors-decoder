module div16(clk,rst,clk_16);
input clk,rst;
output clk_16;

reg[3:0] count;

always @(posedge clk or negedge rst)
begin
  if (!rst)
    count <= 'b0;
  else
    count <= count +1; 
end

assign clk_16 = count[3];

endmodule

