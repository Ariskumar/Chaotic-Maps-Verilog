module sin1(clk,reset,a,loop_logistic,write_data);
input clk,reset;
output reg [31:0] a;
output reg [31:0] loop_logistic;
output reg [31:0] write_data;
reg [31:0] b,c,u,ip1,ip2,sub_in1,sub_in2,mull_acc,sub_acc,data_in;
reg [3:0] state; 
reg led,sine_reset,sineclk_en,count_clr,countclk_en,count_enable,sub_aclr,subclk_en,multi_aclr,multi_en;
wire [31:0] result_out;
wire [31:0] multi_result,c1;
wire [7:0] count_out;
parameter 	load_multi=1,wait_process=2,filestart=3,find_sine=4,delay_loop=5,load_multi1=6,delay=7,
				read1=8,load1=9,delay_loop1=10,process1=11,wait_process1=12,xor_process=13;

sub_fun u4 (.clock(clk),.aclr(sub_aclr),.clk_en(subclk_en),.dataa(sub_in1),.datab(sub_in2),.result(c1));
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
					loop_logistic=32'h3dcccccd;
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
		led=1'b0;	
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
							state=read1;
						end
						else
							state=delay;
						end
read1:	begin
		sub_in1=32'h3f800000; //1
		sub_in2=loop_logistic; // xn	sub_in2=32'h3dcccccd	
		ip1=32'h40733333;     //u
		ip2=loop_logistic;     // xn 
		subclk_en=1'b0;
		sub_aclr=1'b1;		
		
		multi_aclr=1'b1;
		multi_en=1'b0;	
		
		count_clr=1'b1;
		countclk_en=1'b0;
		count_enable=1'b0;		
		
		 										
		state =load1;
		end
load1	:begin
		subclk_en=1'b1;
		sub_aclr=1'b0;
		multi_aclr=1'b0;
		multi_en=1'b1;
		countclk_en=1'b1;
		count_enable=1'b1;
		count_clr=1'b0;
		state=delay_loop1;
		end
		
delay_loop1:begin
			if(count_out>=10)
			begin
		    countclk_en=1'b0;
		    count_enable=1'b0;
		    count_clr=1'b1;  
		    mull_acc=c1;
			sub_acc =multi_result; 
            state=process1;
		    end
		    else
		    state=delay_loop1;
		    end
		    
process1:begin        
        ip1=mull_acc;     //u
		ip2=sub_acc;     // b 
		multi_en=1'b1;
        multi_aclr=1'b0;
        countclk_en=1'b1;
		count_enable=1'b1;
		count_clr=1'b0;
		state=wait_process1;
        end

wait_process1 :begin  
        if(count_out>=10)
			begin
		    countclk_en=1'b0;
		    count_enable=1'b0;
		    count_clr=1'b1;    
            loop_logistic=multi_result;
		    state=xor_process;
		    end
		    else
		    state=wait_process1;
		    end
xor_process:begin
						write_data = loop_logistic ^ a;
						state = load_multi;
						led=1'b1;	
				end
  
endcase
end
end
endmodule


