module sin1(clk,reset,a,b,c);
input clk,reset;
output reg [31:0] a;
output reg [31:0]b;
output reg [31:0]c;
reg [31:0]u;
reg [31:0]ip1;
reg [31:0]ip2;
reg [3:0] state; 
reg sine_reset,sineclk_en,count_clr,countclk_en,count_enable,multi_aclr,multi_en;
reg [31:0] data_in;
wire [31:0] result_out;
wire [31:0] multi_result;
wire [7:0] count_out;
parameter load_multi=1,wait_process=2,filestart=3,find_sine=4,delay_loop=5,load_multi1=6,delay=7;

testsine u1 (.aclr(sine_reset),.clk_en(sineclk_en),.clock(clk),.data(data_in),.result(result_out));
count2 u2(.aclr(count_clr),.clk_en(countclk_en),.clock(clk),.cnt_en(count_enable),.q(count_out));
multi1 u3(.clock(clk),.dataa(ip1),.datab(ip2),.aclr(multi_aclr),.clk_en(multi_en),.result(multi_result));

always@(posedge clk or posedge reset)
begin
if(reset)
state=filestart;
else
begin
case (state)
filestart:	begin
					u=32'h40351eb8; //2.83
					a=32'h3f5645a2; //0.837
					count_clr=1'b1;
					multi_aclr=1'b1;
					sine_reset=1'b1;
					state = load_multi;
				end
load_multi:	begin

		ip1 = 32'h40492492; //3.142857
		ip2 = a;
		multi_aclr = 1'b0;
		multi_en = 1'b1;
		count_clr=1'b0;
		countclk_en=1'b1;
		count_enable=1'b1;
		
		state=wait_process;
		end
		
wait_process :begin  
					if(count_out>=8'd8)
					begin
					b=multi_result;
					count_clr=1'b1;
					countclk_en=1'b0;
					count_enable=1'b0;
					multi_aclr = 1'b1;
					multi_en = 1'b0;		
					state=find_sine;
		    end
		    else
		    state=wait_process;
		    end
find_sine:	begin
					data_in = b;
					sine_reset = 1'b0;
					sineclk_en = 1'b1;
					count_clr=1'b0;
					countclk_en=1'b1;
					count_enable=1'b1;
					state = delay_loop;
				end
delay_loop:	begin
					if(count_out>=8'd40)
					begin
						c=result_out;
						count_clr=1'b1;
						countclk_en=1'b0;
						count_enable=1'b0;
						sine_reset = 1'b1;
						sineclk_en = 1'b0;		
						state=load_multi1;
					end
					else
						state=delay_loop;
			 end
load_multi1: 	begin
						ip1 = u;
						ip2 = c;
						multi_aclr = 1'b0;
						multi_en = 1'b1;
						count_clr=1'b0;
						countclk_en=1'b1;
						count_enable=1'b1;
						state = delay;
					end
delay:			begin
						if(count_out>=8'd8)
						begin
							a=multi_result;
							count_clr=1'b1;
							countclk_en=1'b0;
							count_enable=1'b0;
							multi_aclr = 1'b1;
							multi_en = 1'b0;		
							state=load_multi;
						end
						else
							state=delay;
						end
endcase
end
end
endmodule
