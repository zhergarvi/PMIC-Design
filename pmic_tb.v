`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2021 03:02:05 PM
// Design Name: 
// Module Name: pmic_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//`include "./../rtl/PMIC_Code.v"

//`timescale 1ns/1ps

module pmic_tb;

    // localparam T=1000000;
    
    reg clk, reset, pwr_up, pwr_dn, error;
    reg [4:0] trigger;
//    reg [6:0] ldo_en;
    
    pmic dut (
    .clk(clk),
    .reset(reset),
    .pwr_up(pwr_up),
    .pwr_dn(pwr_dn),
    .error(error),
//    .ldo_en(ldo_en),
    .trigger(trigger));

    initial begin 
	clk=0;
	forever #5 clk=~clk;
	//#500 $finish;
	end

/*    initial begin
        reset = 1'b1;
    end

    initial begin
	$dumpfile("wave.vcd");
	$dumpvars();
    end
*/
    
   initial begin
        //#1000000;
	    reset = 1'b0;
	    error = 1'b0;
        pwr_up = 1'b0;
	    pwr_dn  = 1'b0;
        trigger = 5'd0;
//        sel = 2'b00;

//	repeat(30000)@(posedge clk);
//        trigger = 5'd31;
//    repeat(20000)@(posedge clk);
//        trigger = 5'd0;
    repeat(100000)@(posedge clk);
	    reset = 1'b1;	
        pwr_up = 1'b1;
        trigger = 5'd11;            // time at which active state should trigger

    repeat(2)@(posedge clk);
        pwr_up = 1'b0;
        
    repeat(1500000000)@(posedge clk);
        pwr_dn = 1'b1;
        
    repeat(200000000)@(posedge clk);
//        error = 1'b1;
//        reset = 1'b0;
//        pwr_dn = 1'b0;
//    repeat(2)@(posedge clk);
//        error = 1'b0;
//    repeat(2)@(posedge clk);
        // pwr_dn = 1'b0;
//        #10000000;

//	repeat(20)@(posedge clk);
	#4000; //$finish;
    end

endmodule

