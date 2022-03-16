----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/11/2021 04:43:08 PM
-- Design Name: 
-- Module Name: GEN_ZIGZAG - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- ouputs a zigzag signal with generic bitwidth
-- generic:
-- -data_width: bitwidth of output vector
-- -clk_width: width of the internal clock that counts the cyc_ticks,
--             usually clk_width = cyc_ticks'length
-- inputs:
-- -clk: clock signal
-- -CE: chip enable, if '0' signal is enabled
-- -cyc_ticks: number of clock cycles, after which the cycle time is due
-- -high: the highest value y_out can reach
-- -low: the lowest value y_out can reach
-- outputs:
-- -y_out: output signal of width data_width
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;



entity GEN_ZIGZAG is
  generic(data_width          : natural := 8;
          clk_width           : natural := 24;
          clk_ticks_per_count : natural := 64);
  port (clk       : in  std_logic;
        CE        : in  std_logic;
        cyc_ticks : in  std_logic_vector(clk_width - 1 downto 0);
        HIGH      : in  std_logic_vector(data_width - 1 downto 0);
        LOW       : in  std_logic_vector(data_width - 1 downto 0);
        y_out     : out std_logic_vector(data_width - 1 downto 0));
end GEN_ZIGZAG;

architecture Behavioral of GEN_ZIGZAG is

  signal count   : std_logic_vector(clk_width - 1 downto 0) := (others => '0');
  signal ct_half : std_logic_vector(clk_width - 1 downto 0) := (others => '1');
  signal dir     : std_logic                                := '1';
  
  signal count_en : std_logic := '0';
  
  signal div_en : std_logic := '0';
  signal P  : unsigned(clk_width + data_width - 1 downto 0)         := (others => '0');
  signal CT : std_logic_vector(clk_width + data_width - 1 downto 0) := (others => '0');
  signal Q  : std_logic_vector(clk_width + data_width - 1 downto 0) := (others => '0');
  
  component GEN_COUNTER is
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

   -- divide the cyc_ticks by two
  ct_half <= '0' & cyc_ticks(clk_width - 1 downto 1);
  
  -- counter with max ticks half as count maximum
  counter : GEN_COUNTER
    generic map(data_width => clk_width,
                reset_on_underflow => '0',
                reset_on_overflow => '0'
                )
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
           SCLK_EN => COUNT_EN
           );
  
  
  --- in this section the count range is mapped to the range of amplitude ---
  -- (High - Low) * count is divided by ct_half, Remainder is ignored
  division : GEN_DIVISION
  generic map(dw => data_width + clk_width
              )
  port map(CLK => CLK,
           CE  => DIV_EN,
           N   => std_logic_vector(P),
           D   => CT,
           Q   => Q
           );

  -- count 64 ticks to enable the divison in the right frequency
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
          CT <= (data_width - 1 downto 0 => '0') & ct_half;
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

  --- process to toggle the count direction ---
  set_dir : process(CLK, CE)
    variable D : std_logic := '1';
  begin
    -- toggle the direction signal when zero or COUNTMAXHALF are reached
    if rising_edge(clk) and count_en = '0'then
      -- compare count to half of cyc_ticks
      if count >= ct_half - 1 then
        D := '0';
      elsif count < 1 then
        D := '1';
      end if;
    end if;

    DIR <= D;
  end process set_dir;  

end Behavioral;
