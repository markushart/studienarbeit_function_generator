----------------------------------------------------------------------------------
-- Company: FH Bielefeld
-- Engineer: Markus Hartlage
-- 
-- Create Date: 01/20/2022 09:21:54 PM
-- Design Name: 
-- Module Name: DAC_Channel - Behavioral
-- Project Name: 
-- Target Devices: digilent Pmod DA2 DAC
-- Tool Versions: 
-- Description: 
-- this component instantiates one channel of digilent Pmod DA2 12-bit digital to
-- analog converter
--
-- generic:
-- -
-- inputs:
-- - CLK: the DAC clock
-- - CE: 0: component is activated
-- - DATA_in: a vector that holds the in-going 12bit value
-- - ~SYNC: SYNC must be pulled to low for at least 16 cycles for one transmission
--          to be successful. If SYNC goes high within a transfer of data, the
--          DAC Microchip will discard any sent bit
-- outputs:
-- - DATA_out: the serial Data that goes into the DAC
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


entity DAC_Channel is
  port (CLK      : in  std_logic;
        CE       : in  std_logic;
        DATA_in  : in  std_logic_vector (11 downto 0);
        SYNC     : in  std_logic;
        DATA_out : out std_logic);
end DAC_Channel;

architecture Behavioral of DAC_Channel is

  -- protocoll wants, that before data transmission, this Preamble is sent,
  -- where the first 2 bits (meaning bit 0 and 1) can hold any value and
  -- bit 2 and 3 must be 0
  constant PREAMBLE_v : std_logic_vector(3 downto 0) := "0000";

begin

  send : process(CLK, CE, DATA_in)
    variable bit_count      : integer range 0 to 15         := 0;
    -- variable DATA_in_buffer : std_logic_vector(15 downto 0) := PREAMBLE_v & DATA_in;
  begin
    if rising_edge(clk) and CE = '0' then  -- if not enabled do nothing
      if SYNC = '0' then
        if bit_count < 4 then
            DATA_out <= PREAMBLE_v(3 - bit_count);
        else
            DATA_out <= DATA_in(15 - bit_count);
        end if;
        
        if bit_count < 15 then
          bit_count := bit_count + 1;
        else
          bit_count := 0;
        end if;
      else
        -- reset bit_count if byte_transfer is interrupted
        bit_count := 1;
        -- DATA_out is permanently the MSB of preamble, so on the first rising edge
        -- of clock DATA_out is allready set
        DATA_out <= PREAMBLE_v(3);
      end if;
    end if;
  end process send;

end Behavioral;
