module logistic(clk,reset,led,count,logistic_result,led1,databus1,addressbus2,ce,we,lsb,msb,oe);
output [7:0] count;
input clk,reset;
output [15:0]databus1;
output [17:0] addressbus2;
output ce,we,lsb,msb,oe;
output reg led;
reg [3:0]byte_counter, state; 
output led1;
output reg [31:0] logistic_result;
reg [15:0] acc [2:1];
reg sub_aclr,subclk_en,mult_clr,mulclk_en,count_clr,clk_en,count_enble,cnt_wr;
reg [31:0] sub_in1,sub_in2,sub_result,x_n,r_n,loop_logistic,mull_acc,sub_acc,total_count,addcount;
reg [15:0] accumlator;
wire[31:0]  c1,c2;
wire [7:0] count;
parameter read=1,load=2,delay_loop=3,process=4,wait_process=5,loop=6,write=7,write_1=8,total_write=9, 
process_complete=10;
sub_fun u1 (.clock(clk),.aclr(sub_aclr),.clk_en(subclk_en),.dataa(sub_in1),.datab(sub_in2),.result(c1));
mult_fun u2(.clock(clk),.aclr(mult_clr),.clk_en(mulclk_en),.dataa(x_n),.datab(r_n),.result(c2));
counter1 u3 (.clock(clk),.aclr(count_clr),.clk_en(clk_en),.cnt_en(count_enble),.q(count));
always@(posedge clk)
if(reset)
state=read;
else
begin
case (state)
read:	begin
		sub_in1=32'h3f800000; //1
		sub_in2=32'h3dcccccd; // xn
		addcount=0;			
		r_n=32'h40733333;     //u = 3.8
		x_n=32'h3dcccccd;     // xn = .1
		subclk_en=1'b0;
		sub_aclr=1'b1;		
		
		mult_clr=1'b1;
		mulclk_en=1'b0;	
		
		count_clr=1'b1;
		clk_en=1'b0;
		count_enble=1'b0;		
		
		led=1'b0;	
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
		    logistic_result=c2;
            loop_logistic=c2;
		    state=loop;
		    end
		    else
		    state=wait_process;
		    end
        
loop:begin
        sub_in1=32'h3f800000;
		sub_in2=loop_logistic;
		r_n=32'h40733333;	
		x_n=loop_logistic;	
		
		acc[1]=loop_logistic[15:0]; // 754 standard split into 16/16 for store the ram
		acc[2]=loop_logistic[31:16];
		
		sub_aclr=1'b1;		
		subclk_en=1'b0;
		
		mult_clr=1'b1;
		mulclk_en=1'b0;	
		
		count_enble=1'b0;		
		count_clr=1'b1;
		clk_en=1'b0;
		byte_counter=0;
		state=write;
		end
		// tent map:
		
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
										state=total_write;
										end
										end
									    
write_1:	begin	
								cnt_wr=1'b1;												            
								state=write;							
								end
								
total_write:begin
				if(total_count>=16'hc800)  // total number of byte write in ram
				begin	
				state=process_complete;        
				end
				else
				state=load;
				end
				
process_complete:begin
                led=1'b1;
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
		  