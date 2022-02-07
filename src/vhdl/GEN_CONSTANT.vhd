----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/22/2021 08:47:44 PM
-- Design Name: 
-- Module Name: GEN_CONSTANT - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- a dummy component for output of a constant value
-- generic:
--   -data_width: the width of the output signal
-- inputs:
--    -high: the signal that returns the output
--    -CE: chip enable, if CE is low, the constant value output will be 0
-- outputs:
--   - y_out: the signal that puts out a constant value
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GEN_CONSTANT is
  generic(data_width : natural := 12);
  port (high  : in  std_logic_vector(data_width - 1 downto 0);
        CE    : in  std_logic;
        y_out : out std_logic_vector(data_width -1 downto 0)
        );
end GEN_CONSTANT;

architecture Behavioral of GEN_CONSTANT is
  -- constant that pulls all bits to 0
  constant ZERO : std_logic_vector(data_width -1 downto 0) := (others => '0');

begin

  y_out <= high when CE = '0' else ZERO;

end Behavioral;
