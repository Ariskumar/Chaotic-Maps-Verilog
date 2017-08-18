module cubicmap( tx,clk,reset,test,ready1);
input clk,reset;
output tx,ready1;
output reg [9:0]test;

reg [7:0]state,state1;

reg [63:0]xn,temp1,temp2;
reg [4:0]my_count;
reg [63:0]u;
reg [63:0] to_out;

reg [63:0]opa;
reg [63:0]opb;
reg [2:0]fpu_op;
reg[1:0] rmode;
reg enable_fpu;
wire[63:0] fpout;
wire fpu_ready;
wire overflow;
wire underflow;
wire inexact;
wire exception;
wire invalid;



reg rst_fpu;
reg transmit;
wire is_transmitting;
reg [7:0]tx_byte;
reg uart_reset;
assign ready1=fpu_ready;

parameter	file_setup=8'd0,comp_setup=8'd1,comp_wait=8'd2,check_cond=8'd3,wait_sub=8'd4,wait_sub1=8'd5,result_load=8'd6,reset_1=8'd7,multi=8'd8,wait_multi=8'd9,wait_reset=8'd10, 
			ascii_setup=8'd11,ascii_wait=8'd12,th_compare=8'd13,comp_wait_2=8'd14,comp_setup_2=8'd15,wait_sub1_2=8'd16, check_cond_2=8'd17, wait_sub_2=8'd18, result_load_2=8'd19, reset_1_2=8'd20, multi_2=8'd21, wait_multi_2=8'd22, wait_reset_2=8'd23,
			ascii_setup_2=8'd24, ascii_wait_2=8'd25, th_compare_2=8'd26, uart_setup=8'd27, uart_transmit=8'd28, halt=8'd29, con_start=8'd30,uart_start=8'd31;


fpu_double u1( .clk(clk),.rst(rst_fpu),.enable(enable_fpu),.rmode(rmode),.fpu_op(fpu_op),.opa(opa),.opb(opb),.out(fpout),.ready( fpu_ready),.overflow(overflow),.underflow(underflow),	    
        .inexact(inexact), .exception(exception), .invalid(exception));		
uart u2(.clk(clk),.tx(tx),.transmit(transmit),.tx_byte(tx_byte),.is_transmitting(is_transmitting),.rst(1'b0));
	
		
always@(posedge clk)
if(reset)
state=file_setup;
else
begin
case (state)
file_setup:	begin		
				u 		=	64'h4004B851EB851EB8; //2.589999999999999857891452847
				xn 		=	64'h3FE870B3B839FEE6; //0.763757572000000051204438022
				rst_fpu=0;			
				fpu_op	=	1;	
				transmit=	0;	
				rmode		=	0;	
				enable_fpu=0;					
				state	= 	comp_setup;
			end
comp_setup:	begin
				rst_fpu=0;
			    	fpu_op	=	2;
				opa		=	xn; 
				opb		=	xn;  //0.5
				enable_fpu=1'b1;			
				state	=	comp_wait;
			end
			
comp_wait:	begin
				if(fpu_ready ==1'b1)
				begin
					temp1   = fpout; 
					enable_fpu=1'b0;
			    		rst_fpu	=1'b1;
					state 	= wait_sub; //halt; 				
				end
				else 
				begin								
					state	=	comp_wait; 	
				end			
			end
				
/*check_cond:	begin
				if(fpout[63]	==	1'b0)
				begin
					fpu_op	=	1; 	
					rst_fpu	=1'b1;			
					enable_fpu=0;
					opa		=	64'h3FF0000000000000; //1.0
					opb		=	xn;									
					state	= wait_sub;//	ready_clear; //u(1-xn)
				end				
				else 
				begin				
					rst_fpu=1'b1;
					enable_fpu=0;						
					state	=multi;//ready_clear;	
					end			
					
			end*/
			
		
			
wait_sub:	begin 			
			    enable_fpu=1'b1;
			    rst_fpu	=1'b0;
			    fpu_op	=	1;
			    opa		=	64'h3FF0000000000000; //1.0
				opb		=	temp1;
				state	=	wait_sub1;
				end
													
wait_sub1: begin
			    if(fpu_ready ==1'b1) 
			    begin	
				state 	= result_load; 		
				end				
				else 				
					state	=	wait_sub1; 
			end
result_load:begin
                temp1		=	fpout;
				enable_fpu	=	0;
				state		=	reset_1;
				//state 	= ready_clear; 					
				end
					
reset_1:begin
			rst_fpu=1'b1;
			state=multi;
			end				
multi:		begin
			    rst_fpu=1'b0;			    
				fpu_op	=	2; 				
				opa		=	u;
				opb		=	xn;				
				enable_fpu=1;								
				state	=	wait_multi;
			end
wait_multi:	begin				
			if(fpu_ready ==1'b1) 
			    begin	
				    temp2	=	fpout; 
				    state 	=	wait_reset; 					
				end
				else 							    			
					 state	=	wait_multi;					 
			end
			
			
			
			
wait_reset:	begin 	
					rst_fpu=1'b1;
					enable_fpu=1'b0;
					state = reset_1_2;
					//state=uart_start;
					
	end
	
	
	
//			
reset_1_2:begin
			rst_fpu=1'b1;
			state=multi_2;
			end				
multi_2:		begin
			    rst_fpu=1'b0;			    
				fpu_op	=	2; 				
				opa		=	temp1;
				opb		=	temp2;				
				enable_fpu=1;								
				state	=	wait_multi_2;
			end
wait_multi_2:	begin				
			if(fpu_ready ==1'b1) 
			    begin
					xn		=	fpout;
				    to_out	=	xn; 
				    state 	=	wait_reset_2; 					
				end
				else 							    			
					 state	=	wait_multi_2;					 
			end
wait_reset_2:	begin 	
					rst_fpu=1'b1;
					enable_fpu=1'b0;
					my_count = 0;
					//state = reset_1_2;
					state=uart_start;
					
	end
	
						
			
//
	
uart_start:	begin	
				if(my_count < 8)
				begin
				case (my_count)
					5'b00000:tx_byte	=	to_out[7:0];
					5'b00001:tx_byte	=	to_out[15:8];
					5'b00010:tx_byte	=	to_out[23:16];
					5'b00011:tx_byte	=	to_out[31:24];
					5'b00100:tx_byte	=	to_out[39:32];
					5'b00101:tx_byte	=	to_out[47:40];
					5'b00110:tx_byte	=	to_out[55:48];
					5'b00111:tx_byte	=	to_out[63:56];
					/*5'b01000:tx_byte	=	to_out[71:64];
					5'b01001:tx_byte	=	to_out[79:72];
					5'b01010:tx_byte	=	to_out[87:80];
					5'b01011:tx_byte	=	to_out[95:88];
					5'b01100:tx_byte	=	to_out[103:96];
					5'b01101:tx_byte	=	to_out[111:104];
					5'b01110:tx_byte	=	to_out[119:112];
					5'b01111:tx_byte	=	to_out[127:120];*/
				endcase
				my_count	=	my_count + 1;
				state		=	uart_setup;
				end
				else
				begin
					my_count	=	0;
					state		= 	comp_setup;
				end
			end
					
uart_setup:	begin
				
				transmit	=	1;				
				state		=	uart_transmit;
			end		
			
uart_transmit:begin
				if(is_transmitting==1'b0)
				begin
				    
					transmit	=	0;	
					tx_byte		=	0; 	
					rst_fpu		=	1'b1;											   								
					state		=	uart_start	;					
				end
				else
					state 		=	uart_transmit;
			end
			
halt:begin 
           // test=fpout[31:24];
			state 		=	halt;
end

	
			
endcase  
end		
endmodule 
