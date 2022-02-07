----------------------------------------------------------------------------------
-- Company: FH Bielefeld
-- Engineer: Markus Hartlage
-- 
-- Create Date: 01/26/2022 10:57:30 AM
-- Design Name: 
-- Module Name: DIGITAL_ANALOG_CONVERTER - Behavioral
-- Project Name: 
-- Target Devices: digilent Pmod DA2 DAC
-- Tool Versions: 
--- Description: 
--  this component instantiates the digilent Pmod DA2 12-bit digital to
--  analog converter
--
-- generic:
-- -
-- inputs:
-- - CLK: the DAC-FPGA-Component clock, clock for the microchip is derived
--        from this clock signal
-- - CE: 0: Chip-enabled
-- - DATA_in_A: a vector that holds the current 12-Bit value for the
--              DAC-channel A
-- - DATA_in_B: a vector that holds the current 12-Bit value for the
--              DAC-channel B
-- outputs:
-- outputs:
-- - JA: the four PMOD pins used to drive the Digilent Pmod DA2
--      - JA0: ~SYNC: Synchronization bit that works like a chip enable for DAC
--      - JA1: DINA: Channel A of DAC, currently used for data-output
--      - JA2: DINB: Channel B of DAC, currently pulled high and not used
--      - JA3: SCLK: SCLK of DAC
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


entity DIGITAL_ANALOG_CONVERTER is
  generic(clk_ticks_per_bit : natural := 4
          );
  port (CLK       : in  std_logic;
        CE        : in  std_logic;
        DATA_in_A : in  std_logic_vector(11 downto 0);
        DATA_in_B : in  std_logic_vector(11 downto 0);
        JA        : out std_logic_vector(3 downto 0)
        );
end DIGITAL_ANALOG_CONVERTER;

architecture Behavioral of DIGITAL_ANALOG_CONVERTER is

  component SCLK_ENABLE is
    port (CLK     : in  std_logic;
          CE      : in  std_logic;
          R       : in  std_logic;
          DIVIDER : in  natural range 0 to 65535;
          SCLK_EN : out std_logic);
  end component SCLK_ENABLE;

  component DAC_Channel is
    port (CLK      : in  std_logic;
          CE       : in  std_logic;
          DATA_in  : in  std_logic_vector (11 downto 0);
          SYNC     : in  std_logic;
          DATA_out : out std_logic);
  end component DAC_Channel;
  
  -- JA signals
  signal SYNC       : std_logic := '1';
  signal SCLK       : std_logic := '0';
  
  signal DINA, DINB : std_logic := '0';
  
  -- signals for clock management
  signal channel_EN : std_logic := '1';
  signal sclk_EN    : std_logic := '0';
  
  -- signals for SYNC management
  signal in_buffer_A : std_logic_vector(11 downto 0) := (others => '1');
  signal in_buffer_B : std_logic_vector(11 downto 0) := (others => '1');

begin

  ------JA[3]--JA[2]--JA[1]--JA[0]
  JA <= SCLK & DINB & DINA & SYNC;
  
---------------------------------------------------------------------------
-- clock management
---------------------------------------------------------------------------

  -- creates enable signal for SCLK
  sc_en : SCLK_ENABLE
  port map(CLK     => CLK,
           CE      => CE,
           R       => '1',
           DIVIDER => clk_ticks_per_bit / 2,
           SCLK_EN => sclk_EN
           );
           
  -- create DAC_SCLK from the sclk_EN and clk signal
  toggle_sclk : process(CLK, CE)
  begin
    if rising_edge(CLK) and sclk_EN = '0' then
      if SCLK = '1' then
        SCLK <= '0';
      else
        SCLK <= '1';
      end if;
    end if;
  end process toggle_sclk;  
  
  -- creates enable signal for channels, that work on the bit-transfer frequency
  ch_en : SCLK_ENABLE
    port map(CLK     => CLK,
             CE      => CE,
             R       => '1',
             DIVIDER => clk_ticks_per_bit,
             SCLK_EN => channel_EN
             );

  --------------------------------------------------------------------------
  -- SYNC management
  --------------------------------------------------------------------------

  -- detect if ingoing data has changed
  check_and_sync : process(CLK, CE)
    variable bit_count  : natural range 0 to 15 := 7;
  begin 
    if rising_edge(CLK) and channel_EN = '0' then

      case bit_count is
      when 15 =>
        if ((DATA_in_A /= in_buffer_A)  or (DATA_in_B /= in_buffer_B)) then
          -- if data from cycle before has changed, 
          -- change data and pull down SYNC
          in_buffer_A <= DATA_in_A;
          in_buffer_B <= DATA_in_B;
          SYNC        <= '0';
          
          bit_count := 0;
        else
          SYNC <= '1';
        end if;
      
      when others =>
        bit_count := bit_count + 1;
      
      end case;
    end if;
  end process check_and_sync;
  
  --------------------------------------------------------------------------
  -- channel instantiation
  --------------------------------------------------------------------------

  channelA : DAC_Channel
    port map(CLK      => CLK,
             CE       => channel_EN,
             DATA_in  => in_buffer_A,
             SYNC     => SYNC,
             DATA_out => DINA
             );

  channelB : DAC_Channel
    port map(CLK      => CLK,
             CE       => channel_EN,
             DATA_in  => in_buffer_B,
             SYNC     => SYNC,
             DATA_out => DINB
             );

end Behavioral;
