----------------------------------------------------------------------------------
-- Company: FH Bielefeld
-- Engineer: Markus Hartlage
-- 
-- Create Date: 02/02/2022 03:52:03 PM
-- Design Name: 
-- Module Name: GEN_DIVISION - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- this component can divide two unsigned integers N and D with the width dw
-- it needs one cycle per bit till the right result is displayed
-- algorithm can be found on https://en.wikipedia.org/wiki/Division_algorithm
-- in section "Integer division (unsigned) with remainder"
-- generic:
-- -dw: bit width of the integers that are divided, e.g. 32 for 4 byte division
-- inputs:
-- - CLK: the clock signal
-- - CE: 0: component enabled, 1: not enabled
-- - N: numerator of the fraction that is calculated
-- - D: denumerator of the fraction that is calculated
-- outputs:
-- - Q: the Quotient of the division result
-- - R: the Remainder of the division result
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
use ieee.std_logic_unsigned.all;

entity GEN_DIVISION is
    generic( dw : natural := 36);
    Port ( CLK : in  STD_LOGIC;
           CE  : in  STD_LOGIC;
           N   : in  STD_LOGIC_VECTOR (dw - 1 downto 0);
           D   : in  STD_LOGIC_VECTOR (dw - 1 downto 0);
           Q   : out STD_LOGIC_VECTOR(dw - 1 downto 0);
           R   : out STD_LOGIC_VECTOR(dw - 1 downto 0));
end GEN_DIVISION;

architecture Behavioral of GEN_DIVISION is

begin

    divide : process(CLK, CE)
        variable i   : natural range 0 to dw - 1 := 0;
        variable Q_v : STD_LOGIC_VECTOR(dw - 1 downto 0) := (others => '0');
        variable R_v : STD_LOGIC_VECTOR(dw - 1 downto 0) := (others => '0');
    begin
        if rising_edge(CLK) and CE = '0' then
            if D /= 0 then
                -- shift R 1 bit to left and append i'th bit of N
                R_v := R_v(dw - 2 downto 0) & N(i);
                if R_v >= D then -- if Remainder is bigger than Denumerator
                    R_v    := R_v - D;
                    Q_v(i) := '1';
                end if;
                if i = 0 then
                    i   := dw - 1;
                    -- output Q and R to the outside world
                    Q   <= Q_v;
                    R   <= R_v;
                    -- set Q and R to zero to begin new division
                    Q_v := (others => '0');
                    R_v := (others => '0');
                else
                    -- count down 
                    i := i - 1;
                end if;
             end if;
        end if;
    end process divide;

end Behavioral;
