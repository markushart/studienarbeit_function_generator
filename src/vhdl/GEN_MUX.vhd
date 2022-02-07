----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.11.2021 17:15:35
-- Design Name: 
-- Module Name: GEN_DEMUX - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- Multiplexer for 4 inputs with generic width
-- generic:
-- -data_width: width of input and output std_logic_vectors
-- inputs:
-- -d_in0 to d_in3: inputs that get muxed to output depending on 
--                  decimal value of sel (sel = 1: d_in1 => d_out)
-- -sel: selection signal that selects the input that 
--       is muxed to output
-- outputs:
-- -d_out: output signal
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GEN_MUX is
    generic(data_width : natural := 4);
    Port (sel   : in  STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
          d_in0 : in STD_LOGIC_VECTOR(data_width - 1 downto 0);
          d_in1 : in STD_LOGIC_VECTOR(data_width - 1 downto 0);
          d_in2 : in STD_LOGIC_VECTOR(data_width - 1 downto 0);
          d_in3 : in STD_LOGIC_VECTOR(data_width - 1 downto 0);
          d_out  : out  STD_LOGIC_VECTOR(data_width - 1 downto 0));
end GEN_MUX;

architecture Behavioral of GEN_MUX is

constant zero_vec : std_logic_vector(data_width - 1 downto 0) := (others =>'0');

begin
    
    -- multiplex the signals to output depending on value of select
    with sel select
    d_out <= d_in0 when "00",
             d_in1 when "01",
             d_in2 when "10",
             d_in3 when "11",
             d_in0 when others;
    
end Behavioral;
