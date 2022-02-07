----------------------------------------------------------------------------------
-- Company: FH Bielefeld
-- Engineer: Markus Hartlage
-- 
-- Create Date: 17.11.2021 17:20:30
-- Design Name: 
-- Module Name: GEN_RAMP - Behavioral
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
-- -CE: chip enable signal, if '0' signal is enabled
-- -dir: high means that value increases: /|/|
--       low means that value decreases: |\|\
-- -cyc_ticks: number of clock cycles, after which the cycle time is due
-- -high: maximum value the ramp can reach
-- -low: minimum value the ramp can reach
-- outputs:
-- -y_out: output signal of width data_width
--
-- set y_out to high when x_in >= thresh else y_out is gone be low.
-- one can define the signal-range by setting data_width to the desired bitwidth
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


entity GEN_RAMP is
  generic(data_width : natural         := 8;
          clk_width  : natural         := 24;
          clk_ticks_per_count :natural := 64);
  port (clk       : in  std_logic;
        CE        : in  std_logic;
        DIR       : in  std_logic;
        cyc_ticks : in  std_logic_vector (clk_width - 1 downto 0);   
        HIGH      : in  std_logic_vector (data_width - 1 downto 0);
        LOW       : in  std_logic_vector (data_width - 1 downto 0);
        y_out     : out std_logic_vector (data_width - 1 downto 0));
end GEN_RAMP;

architecture Behavioral of GEN_RAMP is

  signal count  : std_logic_vector(clk_width - 1 downto 0) := (others => '0');
  
  signal count_en : std_logic := '0';
  
  signal div_en : std_logic := '0';
  signal P  : unsigned(clk_width + data_width - 1 downto 0)         := (others => '0');
  signal CT : std_logic_vector(clk_width + data_width - 1 downto 0) := (others => '0');
  signal Q  : std_logic_vector(clk_width + data_width - 1 downto 0) := (others => '0');
  
  component GEN_COUNTER is
    generic(data_width : natural := 32);
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
          R       : in  STD_LOGIC;
          DIVIDER : in natural;
          SCLK_EN : out std_logic);
  end component SCLK_ENABLE;

  component GEN_DIVISION is
      generic( dw : natural := 36);
      Port ( CLK : in  STD_LOGIC;
             CE  : in  STD_LOGIC;
             N   : in  STD_LOGIC_VECTOR (dw - 1 downto 0);
             D   : in  STD_LOGIC_VECTOR (dw - 1 downto 0);
             Q   : out STD_LOGIC_VECTOR(dw - 1 downto 0);
             R   : out STD_LOGIC_VECTOR(dw - 1 downto 0));
  end component GEN_DIVISION;

begin

  counter : GEN_COUNTER
    generic map(data_width => clk_width)
    port map(
      clk       => clk,
      CE        => count_en,
      R         => '1',
      D         => DIR,
      max_ticks => cyc_ticks,
      inc       => (clk_width - 1 downto 1 => '0') & '1',
      o_count   => count
      );
  
  -- enables the counter when a divison is ready
  count_enable : SCLK_ENABLE
  port map(CLK     => CLK,
           CE      => CE,
           R       => '1',
           DIVIDER => clk_ticks_per_count,
           SCLK_EN => count_en
           );
  
  --- in this section the count range is mapped to the range of amplitude ---
  -- the (High - Low) * count is divided by cyc_ticks, Remainder is ignored
  -- Output occures on the next cycle
  division : GEN_DIVISION
  generic map(dw => data_width + clk_width
              )
  port map(CLK => CLK,
           CE  => DIV_EN,
           N   => std_logic_vector(P),
           D   => CT,
           Q   => Q
           );

  -- the division takes one clock cycle for each bit so it hast to
  -- be enabled for data_width + clk_width ticks since this is the 
  -- width of P which is divided, this process does this by pulling 
  -- div_en low for data_width + clk_width ticks
  process(CLK, CE)
    variable tick_count : natural range 0 to clk_ticks_per_count := 0;
  begin
    if rising_edge(CLK) and CE = '0' then
      if tick_count = clk_ticks_per_count - 1 then
        tick_count := 0;
        div_en <= '0';
      else
        if tick_count < data_width + clk_width - 1 then 
          -- product of amplitude and current count
          P <= unsigned(HIGH - LOW) * unsigned(count);
          -- expand the vector to width of GEN_DIVISION
          CT <= (data_width - 1 downto 0 => '0') & cyc_ticks;
          -- assign the relevant part of the divison, which is 
          -- the scaled Amplitude and add LOW
          y_out <= Q(data_width - 1 downto 0) + LOW;
        else
          -- disable the division and do subsequent calculation steps
          div_en <= '1'; 
        end if;
        tick_count := tick_count + 1;
      end if;
    end if;
  end process;

end Behavioral;
