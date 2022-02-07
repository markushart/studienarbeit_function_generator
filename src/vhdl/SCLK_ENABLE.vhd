----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/26/2022 03:51:20 PM
-- Design Name: 
-- Module Name: SCLK_ENABLE - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SCLK_ENABLE is
    Port ( CLK     : in  STD_LOGIC;
           CE      : in  STD_LOGIC;
           -- asynchornous reset
           R       : in  STD_LOGIC;
           -- signal is dividable by 2**16 bit
           DIVIDER : in  natural range 0 to 65535;
           SCLK_EN : out STD_LOGIC);
end SCLK_ENABLE;

architecture Behavioral of SCLK_ENABLE is
  
  -- marks when the nth SCLK_EN is '0'
  signal CLK_en   : std_logic                     := '1';

begin

    count : process(CLK, CE)
    variable count : natural range 0 to 65535;
    begin
        if R = '0' then -- restart the count process
            count := DIVIDER;
        else
            if falling_edge(CLK) and CE = '0' then
              if count = 1 or count = 0 then
                -- DIVIDER is only changed when count has finished last cycle
                -- count can be 0 if DIVIDER = 0
                count := DIVIDER;
                CLK_EN <= '0';
              else               -- count down
                count := count - 1;
                CLK_EN <= '1';
              end if;
            end if;
        end if;
    end process count;

    SCLK_EN <= CLK_EN or CE;

end Behavioral;
