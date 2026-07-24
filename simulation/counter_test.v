module counter_test;
reg clk, rst;
wire [7:0] count;

counter counter1(clk,rst, count);

always #5 clk=~clk;

initial 
 begin
  clk=0;
  rst=0;#10;
  rst=1;
  #260
  $finish; // let's stop the simulation here.
 end
always @*
 $monitor("Count Value is %d", count);
endmodule
