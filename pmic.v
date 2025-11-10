`timescale 1ns / 1ps
 
// Engineer: Zaheer Ahmad
// Description: PMIC Design

module pmic (clk, reset,pwr_up,pwr_dn,error,ldo_en,trigger,seg,Anode_Activate);

    input wire clk, reset, pwr_up, pwr_dn, error;
    input wire [4:0] trigger;
    
    output reg [6:0] ldo_en;
    output reg [6:0] seg;
    output reg [3:0] Anode_Activate;
    
    reg [6:0] sig_ldo_en;
    reg [4:0] counter;
    reg [26:0] clock_count;
    reg irq;
    reg [1:0] sel;
    
    wire one_second_enable;
    reg [7:0] displayed_number;
    reg [3:0] LED_BCD;
    reg [19:0] refresh_counter;
    
    parameter [1:0]	
		    s0       = 2'b00,
        	power_up = 2'b01,
        	active   = 2'b10,
        	power_dn = 2'b11;
    
    reg [1:0] current_state;
    reg [1:0] next_state;
    reg reset_count;
    wire [6:0] temp;

    always @ (posedge clk)
    begin
        if(~reset) begin 
            current_state <= s0;
            ldo_en <= 7'd0;
        end
        else begin
            current_state <= next_state;
            ldo_en <= sig_ldo_en;
        end
            
    end  
    assign temp = (ldo_en << 1);

    always @ (*)
        begin
            sig_ldo_en = ldo_en;
            next_state = current_state;
            case(current_state)
                s0:         begin
                            reset_count = 1'b0;
                            sig_ldo_en = 7'd0;
                            if (pwr_up) begin 
                                next_state = power_up; 
                                
                            end
                            else begin 
                                next_state = s0;
                            end
                end
                power_up:   begin
                            reset_count = 1'b1;
                            if (error) begin 
                                next_state = s0; 
                            end
                            
                            else begin 
                                if (counter == 5'd10) begin
                                    next_state = active; 
                                    reset_count = 0;		
                                end
                                else begin
                                    if (irq) begin
                                        sig_ldo_en[6:1] = temp[6:1] ;
                                        sig_ldo_en[0] = 1'b1; 
                                    end
                                    next_state = power_up;
                                end
                            end
                end
                active:     begin 
                                reset_count = 1'b1;
                                sig_ldo_en = ldo_en;
                            if(error) begin 
                                    next_state = s0; 
                            end
                            
                            else begin 
                                if (counter > 5'd9) begin
                                    if (pwr_dn || (counter == trigger)) begin
                                        next_state = power_dn; 
                                        reset_count = 1'b0;		
                                    end
                                    else begin 
                                        //counter <= counter + 1; 
                                        next_state = active;
                                    end
                                end
                                else
                                    next_state = active;
                            end
                end       
                power_dn:   begin
                            reset_count = 1'b1;
                            if (error) begin 
                                    next_state = s0; 
                            end
                            
                            else begin
                                if (counter == 5'd10) begin
                                    next_state = s0; 
                                end
                                else begin 
                                    if (irq) begin
                                        sig_ldo_en = (ldo_en << 1);
                                    end
                                    else
                                        sig_ldo_en = ldo_en;
                                    next_state = power_dn;		
                                end
                            end
                end
            endcase
            
         end

    always @ (posedge clk)
    begin
        if(~reset_count)
        begin
            counter <= 5'd0;
            clock_count <= 27'd0;
        end
        else 
            begin
                clock_count <= clock_count + 27'd1;
                irq <= 1'b0;
            if (clock_count == 27'd99999999)
            begin
                irq <= 1'b1;
                counter <= counter + 5'd1;
                clock_count <= 27'd0;    
            end
        
        end
    end
    
    assign one_second_enable = (clock_count == 27'd99999999)?1:0;
        
        always @(posedge clk)
            begin
                if(~reset)
                    displayed_number <= 0;
                else if(one_second_enable == 1)
                    displayed_number <= displayed_number + 1;
            end 
            
        always @(posedge clk)
            begin 
                    if(~reset) begin
                        refresh_counter <= 0;
                        sel <= 2'b00;
                      end
                    else    begin
                            refresh_counter <= refresh_counter + 1;
                            
                            if (refresh_counter == 20'd500000) begin
                                refresh_counter <= 20'd0;
                                if(sel == 2'b10)
                                    sel <= 2'b00;
                                else
                                    sel <= sel + 1;
                            end
                    end
                     
            end        
        
        always @( sel or current_state or displayed_number or reset)
            begin
                if (~reset) begin
                    Anode_Activate = 4'b0100;
                    LED_BCD = 'd0;
                end
                else begin 
                    case(sel)
                        2'b00:      begin
                                        Anode_Activate = 4'b1110; 
                                        // activate LED4 and Deactivate LED2, LED3, LED1
                                        LED_BCD = ((displayed_number % 1000)%100)%10;
                                        // the fourth digit of the 16-bit number   
                                    end
                        2'b01:      begin
                                        Anode_Activate = 4'b1101; 
                                        // activate LED3 and Deactivate LED2, LED1, LED4
                                        LED_BCD = ((displayed_number % 1000)%100)/10;
                                        // the third digit of the 16-bit number
                                    end
                        2'b10:      begin
                                        Anode_Activate = 4'b0111;
                                        case(current_state)
                                                s0:         begin
                                                                LED_BCD = 4'b0000;
                                                        end
                                                power_up:   begin
                                                                LED_BCD = 4'b0001;
                                                        end
                                                active:     begin
                                                                LED_BCD = 4'b0010;
                                                        end
                                                power_dn:     begin
                                                                LED_BCD = 4'b0011;
                                                        end
                                                 default:
                                                        LED_BCD = 'd0;
                                            endcase
                                   end
                        default: begin
                                        Anode_Activate = 4'b0100;
                                        LED_BCD = 'd0;
                                        end
           endcase
           end
        end

       always @(*)
                begin
                    case(LED_BCD)
                    4'b0000: seg = 7'b0000001; // "0"     
                    4'b0001: seg = 7'b1001111; // "1" 
                    4'b0010: seg = 7'b0010010; // "2" 
                    4'b0011: seg = 7'b0000110; // "3" 
                    4'b0100: seg = 7'b1001100; // "4" 
                    4'b0101: seg = 7'b0100100; // "5" 
                    4'b0110: seg = 7'b0100000; // "6" 
                    4'b0111: seg = 7'b0001111; // "7" 
                    4'b1000: seg = 7'b0000000; // "8"     
                    4'b1001: seg = 7'b0000100; // "9" 
                    default: seg = 7'b0000001; // "0"
                    endcase
                end         

endmodule
