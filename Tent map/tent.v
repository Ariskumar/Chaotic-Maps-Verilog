module l1(clk,reset,reset1,led,txd1);
input clk,reset,reset1;
output reg led;
output txd1;
reg [4:0] byte_counter,state; 
reg [15:0] acc [2:1];
reg [31:0] logistic_result;
reg [31:0] a,r,uart_databus;
reg [15:0] accumlator;
reg sub_aclr,subclk_en,mult_clr,mulclk_en,count_clr,clk_en,count_enble,comp_aclr,comp_en,cnt_wr;
reg [31:0] sub_in1,sub_in2,sub_result,x_n,r_n,loop_logistic,half1,c_in,total_count,addcount;
wire[31:0]  c1,c2,count;
wire comp_alb,uart_eoc;
reg uart_soc;
parameter 	file_setup=0,read1=1,load1=2,delay_loop1=3,filestart=4,set_comp=5,check_comp=6,
			read2=7,load2=8,delay_loop2=9,process2=10,wait_process2=11,check_com = 12,write=13,write_1=14,total_write=15, 
			process_complete=16; 
			
sub_fun u1 (.clock(clk),.aclr(sub_aclr),.clk_en(subclk_en),.dataa(sub_in1),.datab(sub_in2),.result(c1)); 
mult_fun u2(.clock(clk),.aclr(mult_clr),.clk_en(mulclk_en),.dataa(x_n),.datab(r_n),.result(c2));
counter1 u3 (.clock(clk),.aclr(count_clr),.clk_en(clk_en),.cnt_en(count_enble),.q(count));
comparator u6 (.aclr(comp_aclr),.alb(comp_alb),.clk_en(comp_en),.clock(clk),.dataa(c_in),.datab(half1));
uart_core u4(.uart_clk(clk),.reset1(reset1),.random_write(uart_soc),.write_complete(uart_eoc),.random_sequance(uart_databus),.txd(txd1));

//reg[31:0]  count;
always@(posedge clk)
if(reset)
state=file_setup;
else
begin
case (state)
file_setup:	begin
				half1 = 32'h3f000000; //0.5
				a = 32'h3f800000; //1.0
				r = 32'h3ff624dd; //1.923
				addcount=0;
				logistic_result = 32'h3ea56042; //0.323
				state = filestart;
			end
			
filestart: 	begin
				c_in  = logistic_result;	
				led=1'b0;
				comp_aclr = 1'b1;
				comp_en   = 1'b0;
				state = set_comp;
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
		r_n=r;
		x_n=logistic_result;		
		mult_clr=1'b1;
		count_clr=1'b1;
		mulclk_en=1'b0;	
		clk_en=1'b0;
		count_enble=1'b0;	
		state =load1;
		end
load1	:begin
		mult_clr=1'b0;
		mulclk_en=1'b1;
		//div_start=1'b1;
		clk_en=1'b1;
		count_enble=1'b1;
		count_clr=1'b0;
		state=delay_loop1;
		end
		
delay_loop1:begin
			if(count>=10)
			begin
		    //div_start=1'b0;
		    clk_en=1'b0;
		    count_enble=1'b0;
		    count_clr=1'b1; 
		    logistic_result=c2;
            loop_logistic=c2; 
            byte_counter=0;  
            acc[1]=loop_logistic[15:0]; // 754 standard split into 16/16 for store the ram
			acc[2]=loop_logistic[31:16];    
		    state=write;
		    end
		    else
		    state=delay_loop1;
		    end
        
read2:	begin
		sub_in1=a;
		sub_in2=logistic_result;
		subclk_en=1'b0;
		sub_aclr=1'b1;
		count_clr=1'b1;
		mult_clr=1'b1;	
		clk_en=1'b0;
		count_enble=1'b0;		
		mulclk_en=1'b0;	
		state =load2;
		end
load2	:begin
		subclk_en=1'b1;
		sub_aclr=1'b0;
		//div_start=1'b1;
		clk_en=1'b1;
		count_enble=1'b1;
		count_clr=1'b0;
		state=delay_loop2;
		end
		
delay_loop2:begin
			if(count>=10)
			begin
		    //div_start=1'b0;
		    clk_en=1'b0;
		    count_enble=1'b0;
		    count_clr=1'b1;        
		    state=process2;
		    end
		    else
		    state=delay_loop2;
		    end
		    
process2:begin        
        x_n=c1;
        r_n=r;        
        mulclk_en=1'b1;
        mult_clr=1'b0;
        clk_en=1'b1;
		count_enble=1'b1;
		count_clr=1'b0;
		state=wait_process2;
        end

wait_process2 :begin  
        if(count>=10)
			begin
		    //div_start=1'b0
		    clk_en=1'b0;
		    count_enble=1'b0;
		    count_clr=1'b1;    
		    logistic_result=c2;
		    loop_logistic=c2;
		    byte_counter=0;
		    //acc[1]=loop_logistic[15:0]; // 754 standard split into 16/16 for store the ram
			//acc[2]=loop_logistic[31:16];
		    state=write;
		    end
		    else
		    state=wait_process2;
		    end
		    
write:begin 
          uart_databus=loop_logistic;
          uart_soc=1'b1;
          state=write_1;
          end
					    
write_1:	begin	
				 if(uart_eoc)
				 begin
				 uart_soc=1'b0;				 
				 state=filestart;
				 end
				 else
				 state=write_1;
				 end
				
total_write:begin
				if(total_count==8'd100)  // total number of byte write in ram
				begin
				uart_soc=1'b0;				 	
				state=process_complete;        
				end
				else
				begin
				led=1'b1;
        		total_count=total_count+1;
				state=filestart;
				end
				end
process_complete:begin
                uart_soc=1'b0;
                led=1'b1;
				state=process_complete;        
				end
         endcase
      end
endmodule

