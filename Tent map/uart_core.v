module uart_core(uart_clk,reset1,txd,random_write,write_complete,random_sequance);
input uart_clk,reset1,random_write;
input [31:0] random_sequance;
output reg txd,write_complete;
reg div_clk;
reg [3:0] a[7:0];
reg [7:0] uart_reg,state,random_count;
 reg [3:0] count;
integer baud_clk;
reg send,trans_done;
parameter wait_st=1,uart_trans=2,uart_done=3,total_transfer=5,next_line=6,uart_trans1=7;

//..................................... baudrate generator

always@(posedge uart_clk)
begin
if(baud_clk>=24000000/9600)
begin
baud_clk=0;
div_clk=1'b1;
end
else
begin
div_clk=1'b0;
baud_clk=baud_clk+1;
end
end

//..........................................adc data read and conversion

always@(posedge div_clk)
	begin
	if(reset1)
	   begin
		state=wait_st;
		end
     else
	  begin
		  case(state)
wait_st:if(random_write)
			begin
			
			a[7][3:0]=random_sequance[3:0];
			a[6][3:0]=random_sequance[7:4];
			a[5][3:0]=random_sequance[11:8];
			a[4][3:0]=random_sequance[15:12];
			a[3][3:0]=random_sequance[19:16];
			a[2][3:0]=random_sequance[23:20];
			a[1][3:0]=random_sequance[27:24];
			a[0][3:0]=random_sequance[31:28];
		    write_complete=1'b0;
			random_count=0;
			state=uart_trans;
			end
		  else 
			begin
			state=wait_st;
			end
uart_trans:begin
			if(a[random_count]<=9)
			 begin
			 uart_reg[7:4]=4'b0011;
			 uart_reg[3:0]=a[random_count];
			 send=1'b1;
			 state=uart_done;                     
        	 end
			 else if (a[random_count]==4'ha)
			 begin
			 uart_reg[7:4]=4'b0110;
			 uart_reg[3:0]=1; 							
		     send=1'b1;
			 state=uart_done;                     
       	     end
       	     else if (a[random_count]==4'hb)
			 begin
			 uart_reg[7:4]=4'b0110;
			 uart_reg[3:0]=2; 							
		     send=1'b1;
			 state=uart_done;                     
       	     end
       	     else if (a[random_count]==4'hc)
			 begin
			 uart_reg[7:4]=4'b0110;
			 uart_reg[3:0]=3; 							
		     send=1'b1;
			 state=uart_done;                     
       	     end
       	     else if (a[random_count]==4'hd)
			 begin
			 uart_reg[7:4]=4'b0110;
			 uart_reg[3:0]=4; 							
		     send=1'b1;
			 state=uart_done;                     
       	     end
       	     else if (a[random_count]==4'he)
			 begin
			 uart_reg[7:4]=4'b0110;
			 uart_reg[3:0]=5; 							
		     send=1'b1;
			 state=uart_done;                     
       	     end
       	     else 
       	     begin
			 uart_reg[7:4]=4'b0110;
			 uart_reg[3:0]=6; 							
		     send=1'b1;
			 state=uart_done;                     
       	     end
       	     end
       	            	     			       
uart_done:begin
			  if(trans_done)  
			  begin
              send=1'b0;
			  state=total_transfer;
           end
           else
           state=uart_done;
           end
total_transfer:begin
	       if(random_count>=7)
		   begin
		   random_count=0;
       	   send=1'b0;
       	   state=next_line;
			end
	 else
		  begin
			 random_count=random_count+1;
			 state=uart_trans;
			 end
			 end
			 
next_line:begin
			 uart_reg[7:0]=8'h20;
			 send=1'b1;
			 state=uart_trans1;
			 end
uart_trans1:begin
			if(trans_done)  
			begin
              send=1'b0;
              write_complete=1'b1;			 
		      state=wait_st;
           end
           else
           state=uart_trans1;
           end			 
       	     
			 
          endcase
				end
				end
			
always@(posedge div_clk)
begin
if(send)
begin
if(count<11)
count=count+1;
else
count=0;
end
else
count=0;
end


// bitwise transmision block

always@(posedge div_clk)
begin
if(send)
begin
case(count)
			   1:begin
				  trans_done=1'b0;
				  txd<=1'b0;
				  end
				2:txd<=uart_reg[0];
				3:txd<=uart_reg[1];
				4:txd<=uart_reg[2];
				5:txd<=uart_reg[3];
				6:txd<=uart_reg[4];
				7:txd<=uart_reg[5];
				8:txd<=uart_reg[6];
				9:txd<=uart_reg[7];
			    10:begin					
					txd<=1'b1;
					trans_done=1'b1;					
					end 
				11:trans_done=1'b0;     
                endcase
                end
else
                txd=1'b1;
                end
                
                
endmodule 
