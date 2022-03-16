----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.11.2021 12:17:49
-- Design Name: 
-- Module Name: GEN_COUNTER - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- Counter with generic maximum size, goes to 0 on overflow
-- generic:
-- -data_width: data width of counter output signal that decides
--              what the maximum value of the counter can be
-- inputs:
-- -clk: the clock signal, count is changed on rising edge
-- -clk_en: if 0 clock pauses, if 1 clock counts
-- -R: low active asynchronous reset
-- -D: direction in which to count (1: up, 0: down)
-- -max_ticks: when count > max_ticks the counter is reset
-- -inc: increment by which the count is raised on each
--       clock cycle
-- outputs:
-- -o_count: the output count
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GEN_COUNTER is
    generic(data_width         : natural   := 32;
            reset_on_overflow  : std_logic := '1';
            reset_on_underflow : std_logic := '1');
    port (CLK       : in  std_logic;
          CE        : in  std_logic;
          R         : in  std_logic;
          D         : in  std_logic;
          max_ticks : in  std_logic_vector(data_width - 1 downto 0);
          inc       : in  std_logic_vector(data_width - 1 downto 0);
          o_count   : out std_logic_vector(data_width - 1 downto 0));
end GEN_COUNTER;

architecture Behavioral of GEN_COUNTER is
    
    constant ZERO : std_logic_vector(data_width - 1 downto 0) := (others => '0');
    
begin
    
    count_p : process(R, CLK, CE)
    variable count : std_logic_vector(data_width - 1 downto 0) := (others => '0');
    begin
    if R = '0' then
        count := ZERO;
    elsif rising_edge(CLK) and CE = '0' then
        if D = '1' then
            -- check for overflow
            if (count > max_ticks - inc) then
                if reset_on_overflow = '1' then
                    count := ZERO;
                end if;
            else
                count := count + inc;
            end if;
        elsif D = '0'then
            -- check for underflow
            if (count < inc) then
                if reset_on_underflow = '1' then
                    count := max_ticks;
                end if;
            else
                count := count - inc;
            end if;
        end if;
    end if;
    o_count <= count;
    end process count_p;

end Behavioral;
