//Tent_logistic XOR

module l1(clk,reset,led,databus1,addressbus2,ce,we,lsb,msb,oe,led1);
//output[31:0] write_data,loop_logistic,logistic_result;
input clk,reset;
output [15:0]databus1;
output [17:0] addressbus2;
output ce,we,lsb,msb,oe;
output reg led,led1;
reg [1:0] byte_counter;
reg [5:0] state; 
reg [15:0] acc [2:1];
reg [31:0] logistic_result,a,r,write_data;
reg [15:0] accumlator;
reg sub_aclr,subclk_en,mult_clr,mulclk_en,count_clr,clk_en,count_enble,comp_aclr,comp_en,cnt_wr;
reg [31:0] sub_in1,sub_in2,x_n,r_n,loop_logistic,half1,c_in,mull_acc,sub_acc,total_count,addcount;
wire[31:0]  c1,c2,count;
wire comp_alb;
parameter 	file_setup=0,read1=1,load1=2,delay_loop1=3,filestart=4,set_comp=5,check_comp=6,
			read2=7,load2=8,delay_loop2=9,process2=10,wait_process2=11,check_com = 12,write=13,write_1=14,total_write=15, 
			process_complete=16,read=17,load=18,delay_loop=19,process=20,wait_process=21,xor_process=22; 
			
sub_fun u1 (.clock(clk),.aclr(sub_aclr),.clk_en(subclk_en),.dataa(sub_in1),.datab(sub_in2),.result(c1)); 
mult_fun u2(.clock(clk),.aclr(mult_clr),.clk_en(mulclk_en),.dataa(x_n),.datab(r_n),.result(c2));
counter1 u3 (.clock(clk),.aclr(count_clr),.clk_en(clk_en),.cnt_en(count_enble),.q(count));
comparator u6 (.aclr(comp_aclr),.alb(comp_alb),.clk_en(comp_en),.clock(clk),.dataa(c_in),.datab(half1));

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
				r = 32'h3fcccccd; //1.6
				loop_logistic=32'h3dcccccd;	
				led1=1'b0;
				addcount=0;
				logistic_result = 32'h3f19999a; //0.6
				state = filestart;
			end
			
filestart: 	begin
				c_in  = logistic_result;
				led=1'b1;
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
		    state=read;
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
		    state=read;
		    end
		    else
		    state=wait_process2;
		    end
		    
read:	begin
		sub_in1=32'h3f800000; //1
		sub_in2=loop_logistic; // xn	sub_in2=32'h3dcccccd	
		r_n=32'h40733333;     //u
		x_n=loop_logistic;     // xn 
		subclk_en=1'b0;
		sub_aclr=1'b1;		
		
		mult_clr=1'b1;
		mulclk_en=1'b0;	
		
		count_clr=1'b1;
		clk_en=1'b0;
		count_enble=1'b0;		
		cnt_wr =1'b1; 										
		state =load;
		end
load	:begin
		subclk_en=1'b1;
		sub_aclr=1'b0;
		mult_clr=1'b0;
		mulclk_en=1'b1;
		clk_en=1'b1;
		count_enble=1'b1;
		count_clr=1'b0;
		state=delay_loop;
		end
		
delay_loop:begin
			if(count>=10)
			begin
		    clk_en=1'b0;
		    count_enble=1'b0;
		    count_clr=1'b1;  
		    mull_acc=c1;
			sub_acc =c2; 
            state=process;
		    end
		    else
		    state=delay_loop;
		    end
		    
process:begin        
        r_n=mull_acc;     //u
		x_n=sub_acc;     // b 
		mulclk_en=1'b1;
        mult_clr=1'b0;
        clk_en=1'b1;
		count_enble=1'b1;
		count_clr=1'b0;
		state=wait_process;
        end

wait_process :begin  
        if(count>=10)
			begin
		    clk_en=1'b0;
		    count_enble=1'b0;
		    count_clr=1'b1;    
            loop_logistic=c2;
		    state=xor_process;
		    end
		    else
		    state=wait_process;
		    end
  
xor_process:	begin
					write_data = loop_logistic ^ logistic_result;
					byte_counter=0;  
					acc[1]=write_data[15:0]; 
					acc[2]=write_data[31:16];
					state=write;
				end		    
write:	begin		
		byte_counter = byte_counter+1;												
		if(byte_counter<=2)
		begin	
										addcount=addcount+1;			
										accumlator=acc[byte_counter]; //load first data
										cnt_wr =1'b0;
										state = write_1;				              				
										end	
									else
										begin							
										byte_counter=0;
										total_count=total_count+2;
        								cnt_wr=1'b1;
										led=1'b0;
										state=total_write;
										end
										end
									    
write_1:	begin	
								cnt_wr=1'b1;												            
								state=write;							
								end
								
total_write:begin
				if(total_count>=16'd1000)  // total number of byte write in ram
				begin	
				state=process_complete;        
				end
				else
				state=filestart;
				end
				
process_complete:begin
                led1=1'b1;
				state=process_complete;        
				end
				    
        
        endcase
      end
        
assign databus1 =  accumlator;			
assign addressbus2 = addcount;	         
assign lsb =1'b0;
assign msb  =1'b0;
assign ce = 1'b0; 
assign oe =  1'b1;
assign we = cnt_wr ? 1'b1 : 1'b0;

        endmodule
