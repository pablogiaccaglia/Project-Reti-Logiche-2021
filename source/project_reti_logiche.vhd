library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

---------------------- PIXEL COUNT MODULE ----------------------
entity pixel_count is
    port(
        i_clk               : in std_logic;
        i_rst               : in std_logic;
        i_data              : in std_logic_vector(7 downto 0);
        rows_load           : in std_logic;
        columns_load        : in std_logic;
        total_pixels        : out std_logic_vector(15 downto 0);
        o_end               : out std_logic;
        idle                : out std_logic
     );
end pixel_count;        


architecture Behavioral of pixel_count is
signal columns_reg              : std_logic_vector(7 downto 0);    
signal rows_reg                 : std_logic_vector(7 downto 0);      
signal start_count              : std_logic;

begin
   
     starting_address_handler : process(i_clk, i_rst)
      begin
        if (i_rst = '1') then
            total_pixels        <= (others => '0');
            o_end               <= '0';
            idle                <= '0';
         
        elsif rising_edge(i_clk) then
        
                if (start_count  = '1') then
                    if columns_reg = "00000000"  or rows_reg = "00000000" then
                        idle <= '1';
                    else 
                        total_pixels <= columns_reg*rows_reg;
                        
                        o_end       <= '1';  
                        idle        <= '0';
                     end if; 
                else
                    idle <= '0';    
                    o_end <= '0';
            end if;
         end if;
      end process;
                  
      columns_rows_reg_handler : process(i_clk, i_rst) 
      begin 
        if (i_rst = '1') then
            columns_reg <= (others => '0');
            rows_reg    <= (others => '0');
            start_count <= '0';
                         
        elsif rising_edge(i_clk)then
            if (columns_load = '1') then
                columns_reg <= i_data;
                start_count <= '0';
            elsif rows_load = '1' and start_count = '0' then
                rows_reg <= i_data;
                columns_reg <= columns_reg;
                start_count <= '1';
                           
            else
                 columns_reg <= columns_reg;
                 rows_reg <= rows_reg;
                 start_count <= start_count;
            end if;
        end if;
      end process;         
         
end Behavioral;

---------------------- MAX_MIN_PIXEL MODULE ----------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity max_min_pixel is
    port (         
        i_clk       : in std_logic;
        i_rst       : in std_logic;
        i_data      : in std_logic_vector(7 downto 0);
        max_min_load: in std_logic;       
        total_pixels: in std_logic_vector(15 downto 0);
        rc_loader   : in std_logic;
        max_px      : out std_logic_vector(7 downto 0);
        min_px      : out std_logic_vector(7 downto 0);
        o_end       : out std_logic
        );
end max_min_pixel;

architecture Behavioral of max_min_pixel is
signal max_reg          : std_logic_vector(7 downto 0);
signal min_reg          : std_logic_vector(7 downto 0);
signal counter          : std_logic_vector(15 downto 0);
signal max_done         : std_logic;
signal min_done         : std_logic;
signal end_operation    : std_logic;

begin
   
     max_reg_handler: process(i_clk, i_rst, end_operation)
     
        begin 
            if (i_rst = '1') then
              max_reg <= (others => '0');
              max_done <= '0';
            elsif rising_edge(i_clk) and end_operation = '0' then 
                
                if (max_min_load = '1') then   
                    if(i_data > max_reg) then
                        max_reg  <= i_data;
                    else
                        max_reg  <= max_reg;
                    end if;
                    max_done <= '1';
                else    
                    max_reg  <= max_reg; 
                    max_done <= '0';   
                 end if;      
            end if;          
         end process;
     
   
     
     
     min_reg_handler: process(i_clk, i_rst, end_operation) --AGGIUNTO end_operation
     
        begin 
            if (i_rst = '1') then
              min_reg  <= (others => '1');
              min_done <= '0';
            elsif rising_edge(i_clk) and end_operation = '0' then 
                
                if (max_min_load = '1') then
                    if(i_data < min_reg) then  
                        min_reg <= i_data;
                    else
                        min_reg <= min_reg;    
                    end if; 
                    min_done <= '1';    
                else
                    min_reg  <=  min_reg;  
                    min_done <= '0';    
                 end if;
                
            end if;          
         end process;
         
     o_address_handler : process(i_clk, i_rst, max_done, min_done)
     
        begin
            if (i_rst = '1') then
                counter       <= (others => '1');
                o_end         <= '0';
                max_px        <= (others => '0');
                min_px        <= (others => '1');
                end_operation <= '0';
            
            elsif rising_edge(i_clk) and (i_rst = '0') then
            
                if (rc_loader = '1') then
                    counter         <= total_pixels;
                
                 elsif (counter = "0000000000000000") then   
                    max_px          <= max_reg;
                    min_px          <= min_reg;
                    end_operation   <= '1';
                    o_end           <= '1';
                   
                elsif (max_done = '1') and (min_done = '1') then
                   
                    counter         <= counter - "0000000000000001";
                    
                else
                    counter         <= counter;
                    end_operation   <= end_operation;
                    max_px          <= max_reg;
                    min_px          <= min_reg;              
                end if;
            end if;
        end process;  

end Behavioral;
---------------------- SHIFT LEVEL MODULE ------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


entity shift_level_module is
    port ( 
    i_clk           : in std_logic;
    i_rst           : in std_logic;
    max_px          : in std_logic_vector(7 downto 0);
    min_px          : in std_logic_vector(7 downto 0);
    shift_level     : out std_logic_vector(7 downto 0)
    );
end shift_level_module;

architecture Behavioral of shift_level_module is

begin
    shift_level_handler: process(i_clk, i_rst)
         variable delta_value   : integer;
         variable shift         : integer;
         
         begin 
             if (i_rst = '1') then
                shift_level  <= (others => '0');            
             end if;   
               
            if rising_edge(i_clk) and (i_rst = '0') then
                  
                   delta_value := to_integer(unsigned((max_px - min_px)));
                    -- LUT 
                    if (delta_value = 0) then
                        shift := 8;
                    elsif (delta_value > 0) and (delta_value < 3) then
                        shift := 7; 
                    elsif (delta_value > 2) and (delta_value < 7) then
                        shift := 6;      
                    elsif (delta_value > 6) and (delta_value < 15) then
                        shift := 5;             
                    elsif (delta_value > 14) and (delta_value < 31) then
                        shift := 4;    
                    elsif (delta_value > 30) and (delta_value < 63) then
                        shift := 3; 
                    elsif (delta_value > 62) and (delta_value < 127) then
                        shift := 2;
                    elsif (delta_value > 126) and (delta_value < 255) then
                        shift := 1;
                    elsif (delta_value = 255) then
                        shift := 0;  
                    end if; 
                    
                    shift_level <= std_logic_vector(to_unsigned(shift, 8));
                
                end if;
                         
         end process;  
        
end Behavioral;

---------------------- NEW PIXEL MODULE --------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;    -- Needed for shifts

entity new_pixel_module is
    port ( 
    i_clk               : in std_logic;
    i_rst               : in std_logic;
    i_data              : in std_logic_vector(7 downto 0);
    start_new_px        : in std_logic;
    current_address     : in std_logic_vector(15 downto 0);
    total_pixels        : in std_logic_vector(15 downto 0);
    shift_level         : in std_logic_vector(7 downto 0);
    min_px              : in std_logic_vector(7 downto 0);
    o_data              : out std_logic_vector(7 downto 0);
    o_end               : out std_logic
    );
end new_pixel_module;

architecture Behavioral of new_pixel_module is
begin  

     next_px_handler : process(i_clk, i_rst)
        variable temp   : std_logic_vector(15 downto 0);
        variable shift  : integer;
        variable new_px : std_logic_vector(7 downto 0);
        variable input  : std_logic_vector(15 downto 0);
        begin 
             if (i_rst = '1') then
                o_data <= (others => '0');
             end if;   
                
            
            if rising_edge(i_clk) and (i_rst = '0')then 
                        -- Right Shift 
                       
                             temp   := std_logic_vector(shift_left(unsigned(( "00000000" & i_data) - min_px),(to_integer(unsigned(shift_level)))));
                             
                             if((temp) > "0000000011111111") then 
                                o_data <= (others => '1');
                             else    
                                o_data <= temp(7 downto 0);  
                              end if; 
                                                   
             end if;          
         end process;   
              
                
      write_address_handler : process(i_clk, i_rst)
          begin
            if (i_rst = '1') then
                o_end <= '0';
                
             elsif rising_edge(i_clk) then   
             if start_new_px = '1' then
                    if current_address = (total_pixels + total_pixels + "0000000000000010") then
                        o_end <= '1';
                    else
                        o_end <= '0';  
                    end if;  
               end if;      
             end if;
          end process;   
end Behavioral;
---------------------- MAIN MODULE -------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port(
        i_clk           : in std_logic;
        i_rst           : in std_logic;
        i_start         : in std_logic;
        i_data          : in std_logic_vector(7 downto 0);
        o_address       : out std_logic_vector(15 downto 0);
        o_done          : out std_logic;
        o_en            : out std_logic;
        o_we            : out std_logic;
        o_data          : out std_logic_vector(7 downto 0)
    );    
end project_reti_logiche;

architecture Behavioral of project_reti_logiche iS
type state is (S_IDLE, PRE_FETCH, FETCH_COLUMNS, FETCH_ROWS, PIXELS_COUNT, CALC_MAX_MIN, NEXT_PX_COMP, CALC_SHIFT,FETCH_PX_COMP, CALC_NEW_PX, PREPARE_OUT, WRITE_OUT, S_DONE);
signal next_state, current_state :      state;
signal end_px_count                     :std_logic := '0';
signal end_max_min                      :std_logic := '0';
signal end_new_px                       :std_logic := '0';
signal rows_load                        :std_logic := '0';
signal total_pixels_load                :std_logic := '0';
signal columns_load                     :std_logic := '0';
signal max_min_load                     :std_logic := '0';
signal shift_load                       :std_logic := '0';
signal start_new_px                     :std_logic := '0';
signal idle                             :std_logic := '0';
signal o_en_next                        :std_logic := '0';
signal o_done_next                      :std_logic := '0';
signal o_we_next                        :std_logic := '0';
signal reset_modules                    :std_logic := '0';
signal shift_level                      :std_logic_vector(7 downto 0)  := (others =>'0');
signal total_pixels                     :std_logic_vector(15 downto 0) := (others =>'0');
signal min_px                           :std_logic_vector(7 downto 0)  := (others =>'0');
signal next_address                     :std_logic_vector(15 downto 0) := (others =>'0');
signal max_px                           :std_logic_vector(7 downto 0)  := (others =>'0');
signal o_address_next                   :std_logic_vector(15 downto 0) := (others =>'0');
signal o_data_next                      :std_logic_vector(7 downto 0)  := (others =>'0');
signal o_next                           :std_logic_vector(15 downto 0) := (others =>'0');
signal temp_reg                         :std_logic_vector(15 downto 0) := (others =>'0');

component pixel_count is 
    port(
        i_clk                           : in std_logic;
        i_rst                           : in std_logic;
        i_data                          : in std_logic_vector(7 downto 0);
        rows_load                       : in std_logic;
        columns_load                    : in std_logic;
        total_pixels                    : out std_logic_vector(15 downto 0);
        o_end                           : out std_logic;
        idle                            : out std_logic
     );
end component;  

component max_min_pixel is
    port(         
        i_clk                           : in std_logic;
        i_rst                           : in std_logic;
        i_data                          : in std_logic_vector(7 downto 0);
        max_min_load                    : in std_logic;
        total_pixels                    : in std_logic_vector(15 downto 0);
        rc_loader                       : in std_logic;
        max_px                          : out std_logic_vector(7 downto 0);
        min_px                          : out std_logic_vector(7 downto 0);
        o_end                           : out std_logic
        );
end component;        

component shift_level_module is
    port ( 
        i_clk                           : in std_logic;
        i_rst                           : in std_logic;
        max_px                          : in std_logic_vector(7 downto 0);
        min_px                          : in std_logic_vector(7 downto 0);
        shift_level                     : out std_logic_vector(7 downto 0)
        );
end component;       

component new_pixel_module is   
    port ( 
    i_clk                               : in std_logic;
    i_rst                               : in std_logic;
    i_data                              : in std_logic_vector(7 downto 0);
    start_new_px                        : in std_logic;
    current_address                     : in std_logic_vector(15 downto 0);
    total_pixels                        : in std_logic_vector(15 downto 0);
    shift_level                         : in std_logic_vector(7 downto 0);
    min_px                              : in std_logic_vector(7 downto 0);
    o_data                              : out std_logic_vector(7 downto 0);
    o_end                               : out std_logic
    );
end component;

begin
    PIXELCOUNT : pixel_count port map(
                
                i_clk,
                reset_modules, 
                i_data,
                rows_load,
                columns_load,
                total_pixels,
                end_px_count,
                idle
    );
    
    MAX_MIN_PX : max_min_pixel port map(       
                i_clk,
                reset_modules,
                i_data,
                max_min_load,
                total_pixels,
                total_pixels_load,
                max_px,
                min_px,
                end_max_min
   );
    
    SHIFTLEVEL : shift_level_module port map(
                i_clk,
                reset_modules,
                max_px,
                min_px,
                shift_level
    );
    
    NEW_PX : new_pixel_module port map(
                i_clk,
                reset_modules,
                i_data,
                start_new_px,
                next_address,
                total_pixels,
                shift_level,
                min_px,
                o_data_next,
                end_new_px
    );
    
    STATE_OUTPUT : process(i_clk,i_rst)
     -- The sequential process which asserts outputs and saves values for the state
    begin 
   
            if (i_rst = '1')  then
               -- Asyncronously reset the machine
                current_state                   <= S_IDLE;
                o_address                       <= (others => '0');
                o_next                          <= (others => '0');
                o_en                            <= '0';
                o_we                            <= '0';
                o_data                          <= (others => '0');
                temp_reg                        <= (others => '0');
            elsif rising_edge(i_clk)then
                -- Assign values to current state
                current_state                   <= next_state;
                temp_reg                        <= o_address_next;
                o_next                          <= next_address;
                -- Assert outputs
                o_address                       <= o_address_next;
                o_en                            <= o_en_next;
                o_we                            <= o_we_next;
                o_data                          <= o_data_next;   
                o_done                          <= o_done_next; 
            end if;
     end process;        
         
    
    LAMBDA : process(current_state, i_start, end_px_count,idle,end_max_min,end_new_px) --AGGIUNTO IDLE
    -- machine transition function which computes the next state from the current state and the current input
    begin
      --  next_state <= current_state;
        case current_state is 
    
            when S_IDLE =>
                if i_start = '0'  then
                        next_state <= current_state;
                    else 
                        next_state <= PRE_FETCH;
                    end if; 
                    
            when PRE_FETCH =>
                next_state <= FETCH_COLUMNS;
                    
                                          
            when FETCH_COLUMNS =>
                  next_state <= FETCH_ROWS;        
                  
            when FETCH_ROWS =>
                 next_state <= PIXELS_COUNT;                                              
                           
            when PIXELS_COUNT =>
                if idle = '1' then
                     next_state <= S_DONE;
                elsif end_px_count = '0' then
                    next_state <= current_state;         
                else
                    next_state <= CALC_MAX_MIN;
                end if; 
                
         
            when CALC_MAX_MIN =>
                if end_max_min = '0' then
                    next_state <=  NEXT_PX_COMP;
                else
                    next_state <= CALC_SHIFT;
                end if;    
                
            when NEXT_PX_COMP =>
                 if end_max_min = '0' then
                     next_state <= CALC_MAX_MIN;
                 else
                     next_state <= CALC_SHIFT;
                 end if;      
                
            when CALC_SHIFT =>
                next_state <= FETCH_PX_COMP;
                
            when FETCH_PX_COMP =>
                if end_new_px = '0' then
                    next_state <= CALC_NEW_PX; 
                else
                    next_state <= S_DONE;   
                end if;    
                 
            when CALC_NEW_PX =>   
                 next_state <= PREPARE_OUT;
           
           when PREPARE_OUT =>
                next_state <= WRITE_OUT;
                           
            when WRITE_OUT =>  
                next_state <= FETCH_PX_COMP;  
                 
            when S_DONE =>
                if i_start = '1' then
                    next_state <= current_state;
                else
                    next_state <= S_IDLE;
                end if;
            end case;    
     end process;

     DELTA : process(current_state, next_address, temp_reg, total_pixels, o_next)
     -- Moore machine output function combinatorial process of  which computes the next output from the current state
     begin
          -- Signal assignments to avoid inferred latches
                o_done_next             <= '0';
                o_address_next          <= (others => '0');
                next_address            <= "0000000000000010";
                o_en_next               <= '0';
                o_we_next               <= '0';
                rows_load               <= '0';
                columns_load            <= '0';
                total_pixels_load       <= '0';
                start_new_px            <= '0'; 
                shift_load              <= '0'; --non serve più computare lo shift
                max_min_load            <= '0';
                reset_modules           <= '0';
          
          case current_state is 
          
        when S_IDLE =>        
              o_en_next                 <= '1';  
              
              
        when PRE_FETCH =>
              reset_modules             <= '1';
              
         when FETCH_COLUMNS =>
                      o_en_next                 <= '1'; 
                      o_address_next            <= "0000000000000001";      
                                    
         when FETCH_ROWS => 
                       columns_load              <= '1'; 
                       o_en_next                 <= '1';  
                       o_address_next            <= "0000000000000001";      
                       
              --inizio calcolo righe*colonne
         when PIXELS_COUNT =>         
               rows_load                 <= '1'; 
               o_address_next            <= "0000000000000010"; 
               total_pixels_load         <= '1';  
               o_en_next                 <= '1';        
                   
          when CALC_MAX_MIN =>  --- salvo risultato del confronto in  max_reg e min_reg, decremento
              
              max_min_load              <= '1';   
              o_address_next            <= next_address;       
              next_address              <=  temp_reg;          
              o_en_next                 <= '1';             
           
           when NEXT_PX_COMP =>   ---chiedo dato, disponibile poi in CALC_MAX_MIN  
              o_address_next            <= temp_reg + "0000000000000001";
              next_address              <= temp_reg + "0000000000000001";
      
           when  CALC_SHIFT  =>-- calcolo shift_level e salvo nel registro dedicato
       
              o_address_next            <=  "0000000000000010"; 
              next_address              <= "0000000000000010"  + total_pixels;
              o_en_next                 <= '1';
          
           when FETCH_PX_COMP =>      --chiedo indirizzo per leggere pixel i
              o_en_next                 <= '1';   
              o_address_next            <= o_next;  
              next_address              <= temp_reg;
            
            
           when CALC_NEW_PX =>   --calcolo new_px e preparo la scrittura 
              o_address_next            <= temp_reg;
              next_address              <= o_next;
              start_new_px              <= '1';

          when PREPARE_OUT => 
              o_en_next                 <= '1';
              o_we_next                 <= '1';
              o_address_next            <= temp_reg;
              next_address              <= o_next;
           
                             
           when WRITE_OUT =>
              o_en_next                 <= '1';
              o_address_next            <= o_next + "0000000000000001";
              next_address              <= temp_reg + "0000000000000001" ;

           when S_DONE =>
              o_done_next                    <= '1'; 
              
              
        end case; 
    end process;    
              
end Behavioral;

