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
-- Demultiplexer for 4 inputs with generic width
-- generic:
-- -data_width: data width of inputs and outputs
-- inputs:
-- -d_in: input signal
-- -sel: selection signal
-- outputs:
-- -d_out0 to d_out3: outputs that get muxed to output depending on 
--                    decimal value of sel (sel = 1: d_out1 => d_in)
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use work.array_of_std_logic_vectors.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GEN_DEMUX is
    generic(data_width : natural := 4);
    Port (sel   : in  STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
          d_in  : in  STD_LOGIC_VECTOR(data_width - 1 downto 0);
          d_out0 : out STD_LOGIC_VECTOR(data_width - 1 downto 0);
          d_out1 : out STD_LOGIC_VECTOR(data_width - 1 downto 0);
          d_out2 : out STD_LOGIC_VECTOR(data_width - 1 downto 0);
          d_out3 : out STD_LOGIC_VECTOR(data_width - 1 downto 0));
end GEN_DEMUX;

architecture Behavioral of GEN_DEMUX is

constant zero_vec : std_logic_vector(data_width - 1 downto 0) := (others =>'0');

begin
    
    d_out0 <= d_in when sel = "00" else zero_vec;
    d_out1 <= d_in when sel = "01" else zero_vec;
    d_out2 <= d_in when sel = "10" else zero_vec;
    d_out3 <= d_in when sel = "11" else zero_vec;
    
end Behavioral;
