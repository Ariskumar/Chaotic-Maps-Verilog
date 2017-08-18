module sin1(clk,reset,a,logistic_result,loop_logistic,write_data,led);
input clk,reset;
output reg [31:0] a;
output reg [31:0] loop_logistic;
output reg led;
reg [31:0]b;
reg [31:0]c;
reg [31:0] mull_acc,sub_acc,r,u;
reg [31:0]ip1;
reg [31:0]ip2;
reg [7:0] state; 
reg 	sine_reset,sineclk_en,sub_aclr,subclk_en,count_clr,countclk_en,count_enable,multi_aclr,
		multi_en,comp_aclr,comp_en;
output reg [31:0] logistic_result,write_data;
reg [31:0] sub_in1,sub_in2,half1,c_in,data_in;
wire [31:0] result_out;
wire [31:0] multi_result,c1;
wire [7:0] count_out;
wire comp_alb;
parameter 	load_multi=1,wait_process=2,filestart=3,find_sine=4,delay_loop=5,load_multi1=6,delay=7,
				load2=8,delay_loop2=9,process2=10,wait_process2=11,check_com = 12, 
				read1=13,load1=14,delay_loop1=15,set_comp=16,read2=17,check_comp=18,xor_process=19,
				read3=20,load3=21,delay_loop3=22,process3=23,wait_process3=24,xor_process3=25;

testsine u1 (.aclr(sine_reset),.clk_en(sineclk_en),.clock(clk),.data(data_in),.result(result_out));
count2 u2(.aclr(count_clr),.clk_en(countclk_en),.clock(clk),.cnt_en(count_enable),.q(count_out));
multi1 u3(.clock(clk),.dataa(ip1),.datab(ip2),.aclr(multi_aclr),.clk_en(multi_en),.result(multi_result));
sub_fun u4 (.clock(clk),.aclr(sub_aclr),.clk_en(subclk_en),.dataa(sub_in1),.datab(sub_in2),.result(c1)); 
comparator u5 (.aclr(comp_aclr),.alb(comp_alb),.clk_en(comp_en),.clock(clk),.dataa(c_in),.datab(half1));

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
					half1 = 32'h3f000000; //0.5
					r = 32'h3fcccccd; //1.6
					logistic_result = 32'h3f19999a; //0.6
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
							c_in  = logistic_result;	
							comp_aclr = 1'b1;
							comp_en   = 1'b0;
							state = set_comp;
						 //state=load_multi;
						end
						else
							state=delay;
						end
set_comp:	begin
				comp_aclr = 1'b0;
				comp_en   = 1'b1;
				state = check_com;
			end
check_com:	state = check_comp;
check_comp:	begin
				if(comp_alb == 1'b1)
					state = read1;//u*x_n
				else
					state = read2;//u*(1-x_n)
			end
				
read1:	begin
		ip1=r;
		ip2=logistic_result;		
		multi_aclr=1'b1;
		count_clr=1'b1;
		multi_en=1'b0;	
		countclk_en=1'b0;
		count_enable=1'b0;	
		state =load1;
		end
load1	:begin
		multi_aclr=1'b0;
		multi_en=1'b1;
		//div_start=1'b1;
		countclk_en=1'b1;
		count_enable=1'b1;
		count_clr=1'b0;
		state=delay_loop1;
		end
		
delay_loop1:begin
			if(count_out>=10)
			begin
		    //div_start=1'b0;
		    countclk_en=1'b0;
		    count_enable=1'b0;
		    count_clr=1'b1; 
		    logistic_result=multi_result;  
		    state=xor_process;
		    end
		    else
		    state=delay_loop1;
		    end
        
read2:	begin
		sub_in1=32'h3f800000; //1.0
		sub_in2=logistic_result;
		subclk_en=1'b0;
		sub_aclr=1'b1;
		count_clr=1'b1;
		multi_aclr=1'b1;	
		countclk_en=1'b0;
		count_enable=1'b0;		
		multi_en=1'b0;	
		state =load2;
		end
load2	:begin
		subclk_en=1'b1;
		sub_aclr=1'b0;
		//div_start=1'b1;
		countclk_en=1'b1;
		count_enable=1'b1;
		count_clr=1'b0;
		state=delay_loop2;
		end
		
delay_loop2:begin
			if(count_out>=10)
			begin
		    //div_start=1'b0;
		    countclk_en=1'b0;
		    count_enable=1'b0;
		    count_clr=1'b1;        
		    state=process2;
		    end
		    else
		    state=delay_loop2;
		    end
		    
process2:begin        
			ip1=c1;
			ip2=r;        
			multi_en=1'b1;
			multi_aclr=1'b0;
			countclk_en=1'b1;
			count_enable=1'b1;
			count_clr=1'b0;
			state=wait_process2;
        end

wait_process2 :begin  
        if(count_out>=10)
			begin
		    countclk_en=1'b0;
		    count_enable=1'b0;
		    count_clr=1'b1;    
		    logistic_result=multi_result;
		    state=xor_process;
		    end
		    else
		    state=wait_process2;
		    end	
xor_process:	begin
						write_data = logistic_result ^ a;
						state = read3;
					end
read3:	begin
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
		
		 										
		state =load3;
		end
load3	:begin
		subclk_en=1'b1;
		sub_aclr=1'b0;
		multi_aclr=1'b0;
		multi_en=1'b1;
		countclk_en=1'b1;
		count_enable=1'b1;
		count_clr=1'b0;
		state=delay_loop3;
		end
		
delay_loop3:begin
			if(count_out>=10)
			begin
		    countclk_en=1'b0;
		    count_enable=1'b0;
		    count_clr=1'b1;  
		    mull_acc=c1;
			sub_acc =multi_result; 
            state=process3;
		    end
		    else
		    state=delay_loop3;
		    end
		    
process3:begin        
        ip1=mull_acc;     //u
		ip2=sub_acc;     // b 
		multi_en=1'b1;
        multi_aclr=1'b0;
        countclk_en=1'b1;
		count_enable=1'b1;
		count_clr=1'b0;
		state=wait_process3;
        end

wait_process3 :begin  
        if(count_out>=10)
			begin
		    countclk_en=1'b0;
		    count_enable=1'b0;
		    count_clr=1'b1;    
            loop_logistic=multi_result;
		    state=xor_process3;
		    end
		    else
		    state=wait_process3;
		    end
xor_process3:begin
						write_data = loop_logistic ^ write_data;
						state = load_multi;
						led=1'b1;	
				end

					
endcase
end
end
endmodule






