----------------------------------------------------------------------------------
-- Company: FH Bielefeld
-- Engineer: Markus Hartlage
-- 
-- Create Date: 17.11.2021 17:20:30
-- Design Name: 
-- Module Name: SQUARE_SIGNAL - Behavioral
-- Project Name: function_generator 
-- Target Devices: Basys3 Board
-- Tool Versions: 
-- Description: 
-- Outputs a Square Signal that alternates between high and low signal
-- depending on threshhold thresh
-- generic:
-- -data_width: bitwidth of output signal
-- inputs:
-- -clk: clock signal
-- -CE: chip enable signal, if 0: signal is enabled
-- -high: the high signal to which output is set
-- -low:  the low signal to which output is set
-- -cyc_ticks: number of clock cycles, after which the cycle time is due
-- -thresh: threshhold, this determines the duty cycle of output signal
-- outputs:
-- -y_out: output signal of width data_width
--
-- set y_out to high when x_in >= thresh else y_out is gone be low.
-- one can define the signal-range by setting data_width to the desired bitwidth
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


entity SQUARE_SIGNAL is
  generic(data_width : natural         := 8;
          clk_width  : natural         := 24;
          clk_ticks_per_count :natural := 64);
  port (clk       : in  std_logic;
        CE        : in  std_logic;
        cyc_ticks : in  std_logic_vector (clk_width - 1 downto 0);
        thresh    : in  std_logic_vector (clk_width - 1 downto 0);
        high      : in  std_logic_vector (data_width - 1 downto 0);
        low       : in  std_logic_vector (data_width - 1 downto 0);
        y_out     : out std_logic_vector (data_width - 1 downto 0));
end SQUARE_SIGNAL;

architecture Behavioral of SQUARE_SIGNAL is
    
  --
  signal count  : std_logic_vector(clk_width - 1 downto 0) := (others => '0');
  --
  signal count_EN : std_logic := '1';
  
  component GEN_COUNTER is
    generic(data_width         : natural := 32;
            reset_on_overflow  : std_logic := '1';
            reset_on_underflow : std_logic := '1');
    port (CLK       : in  std_logic;
          CE        : in  std_logic;
          R         : in  std_logic;
          D         : in  std_logic;
          max_ticks : in  std_logic_vector(data_width - 1 downto 0);
          inc       : in  std_logic_vector(data_width - 1 downto 0);
          o_count   : out std_logic_vector(data_width - 1 downto 0));
  end component GEN_COUNTER;
  
  component SCLK_ENABLE is
    port (CLK     : in  std_logic;
          CE      : in  std_logic;
          R       : in  std_logic;
          DIVIDER : in  natural range 0 to 65535;
          SCLK_EN : out std_logic);
  end component SCLK_ENABLE;

begin

  -- count clk enable
  count_enable : SCLK_ENABLE
    port map(CLK     => CLK,
             CE      => CE,
             R       => '1',
             DIVIDER => clk_ticks_per_count,
             SCLK_EN => count_EN
             );

  -- 
  counter : GEN_COUNTER
    generic map(data_width => clk_width)
    port map(
      clk       => clk,
      CE        => count_EN,
      R         => '1',
      D         => '1',
      max_ticks => cyc_ticks,
      inc       => ((clk_width - 1 downto 1 => '0') & '1'),
      o_count   => count
      );

  -- compare count to thresh and set output
  y_out <= low when count > thresh else high;

end Behavioral;
