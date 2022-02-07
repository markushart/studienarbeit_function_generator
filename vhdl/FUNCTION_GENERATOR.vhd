----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/22/2021 07:33:46 PM
-- Design Name: 
-- Module Name: FUNCTION_GENERATOR_TB - Behavioral
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
use IEEE.STD_LOGIC_1164.all;

entity FUNCTION_GENERATOR_TB is
--  Port ( );
end FUNCTION_GENERATOR_TB;

architecture Behavioral of FUNCTION_GENERATOR_TB is

  constant T_tb : time := 10ns;

  component FUNCTION_GENERATOR is
  port (CLK100MHZ : in  std_logic;
        RsRx      : in  std_logic;
        RsTx      : out std_logic;
        LED       : out std_logic_vector(11 downto 0);
        JA        : out std_logic_vector(3 downto 0)
        );
  end component FUNCTION_GENERATOR;

  signal data_stream    : std_logic_vector(81 downto 0) := 
  "11" 
  -- data stream has to be read bytewise from right to left
  -- current instruction: set_cyc_ticks (x"01") to x"000008"
  -- "01" to send start and stop bit
  & x"80" & "01" 
  & x"00" & "01" 
  & x"00" & "01" 
  & x"01" & "01"
  
  -- & x"0C" & "01"  -- 
  
  & x"40" & "01" 
  & x"00" & "01" 
  & x"00" & "01" 
  & x"04" & "01";
  
  signal clk_tb         : std_logic := '0';
  signal RX_tb          : std_logic := '1';
  signal TX_tb          : std_logic := '0';
  signal digital_out_tb : std_logic_vector(11 downto 0) := "000000000000";
  signal JA_tb : std_logic_vector(3 downto 0) := "0000";

begin

  uut : FUNCTION_GENERATOR
    port map(clk100MHZ => clk_tb,
             RsRx      => RX_tb,
             RsTx      => TX_tb,
             LED       => digital_out_tb,
             JA        => JA_tb);

  stim : process
  begin
    for i in 0 to 120000 loop
      for j in 0 to 868 loop
         clk_TB       <= '0';
         wait for T_tb/2;
         clk_TB       <= '1';
         wait for T_tb/2;
      end loop;
      RX_TB <= data_stream(0);
      data_stream <= '1' & data_stream(data_stream'length - 1 downto 1);
    end loop;
    wait;
  end process stim;

end Behavioral;
