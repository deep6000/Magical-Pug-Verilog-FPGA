module key_debouncer(clk, button, button_state, pressed, released);
  
  // Inputs
  input clk;
  input button;
  
  // Outputs
  output button_state;
  output pressed;
  output released;

  reg button_state;
  
  // Internal Registers and Wires
  reg sync_0;
  reg sync_1;  
  reg state_changed;
  reg [15:0] counter;
  
  // Synchronize button input
  always @(posedge clk)
    begin
      sync_0 <= ~button;
      sync_1 <= sync_0;
    end
  
  // Determine if state changed
  always @(posedge clk)
    begin
      if (button_state == sync_1)
        begin
          state_changed = 0;
        end
      else
        begin
          state_changed = 1;
        end
    end
  
  // Determine Button States
  always @(posedge clk)
    begin
      if (state_changed == 0) 
        begin
          counter <= 0;
        end
      else
        begin
          // Increase count
          counter <= counter + 1;
          
          // If counter is full, button state has changed
          if (counter == 16'hFFFF) 
            begin
              // Toggle button state
              button_state <= ~button_state;
            end
        end
    end
  
  assign pressed = (state_changed & (counter == 16'hFFFF) & (~button_state));
  assign released = (state_changed & (counter == 16'hFFFF) & (button_state));
  
endmodule 