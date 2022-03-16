----------------------------------------------------------------------------------
-- Company: FH Bielefeld
-- Engineer: Markus Hartlage
-- 
-- Create Date: 12/15/2021 01:22:10 PM
-- Design Name: 
-- Module Name: FUNCTION_GENERATOR - Behavioral
-- Project Name: Function-Generator
-- Target Devices: Basys3 Board, digilent Pmod DA2
-- Tool Versions: Vivado 2018.3
-- Description: 
-- this component runs a function generator that can run 4 different waveforms
-- and can be configured by a simple UART Interface
--
-- generic:
-- -
-- inputs:
-- - CLK100MHZ: the system clock
-- - RsRx, RsTx: UART input and output wire
-- outputs:
-- - LED: currently the LEDS on Basys3 are enabled to show digital output values
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

entity FUNCTION_GENERATOR is
  port (CLK100MHZ : in  std_logic;
        RsRx      : in  std_logic;
        RsTx      : out std_logic;
        LED       : out std_logic_vector(11 downto 0);
        JA        : out std_logic_vector(3 downto 0)
        );
end FUNCTION_GENERATOR;

architecture Behavioral of FUNCTION_GENERATOR is
  -- the data_width of the signal that finally will be outputted through DAC
  constant data_width : natural := 12;
  constant clk_width  : natural := 24;

  -- clock for digital to analog converter, runs on 25MHz
  -- DAC clock frequency will be 100mhz / DAC_div because
  -- component creates internal SCLK on JA[3]
  constant DAC_div  : natural :=  4;
  constant func_div : natural := 68;

  -- constants that define the waveforms that one can configure
  constant CONST_WF  : natural := 0;
  constant SQUARE_WF : natural := 1;
  constant ZIGZAG_WF : natural := 2;
  constant RAMP_WF   : natural := 3;

  -- the configuration constants for initialization
  constant CONST_CYC_TICKS : natural   := 2048; -- 100e6 / FUNC_div;
  constant CONST_HIGH      : natural   := 4095;
  constant CONST_LOW       : natural   := 0;
  constant CONST_DUTYCYCLE : natural   := 128;
  -- constant CONST_THRESH    : natural   := CONST_CYC_TICKS * CONST_DUTYCYCLE / 255;
  constant CONST_DIR       : std_logic := '0';
  constant CONST_WAVEFORM  : natural   := ZIGZAG_WF;

  component CONFIG_INTERFACE is
    generic (data_width : natural := 12;
             clk_width  : natural := 24;

             cyc_ticks_default : natural              := 255;
             dutycycle_default : natural              := 128;
             high_default      : natural              := 4095;
             low_default       : natural              := 0;
             waveform_default  : natural range 0 to 3 := 1;
             direction_default : std_logic            := '1';

             baud_clk_ticks : natural := 868
             );
    port (CLK : in std_logic;
          CE  : in std_logic;

          RX : in  std_logic;
          TX : out std_logic;

          cyc_ticks : out std_logic_vector(clk_width - 1 downto 0);
          thresh    : out std_logic_vector(clk_width - 1 downto 0);
          high      : out std_logic_vector(data_width - 1 downto 0);
          low       : out std_logic_vector(data_width - 1 downto 0);
          waveform  : out std_logic_vector(1 downto 0);
          direction : out std_logic);
  end component CONFIG_INTERFACE;

  component GEN_MUX is
    generic(data_width : natural := 4);
    port (sel   : in  std_logic_vector(1 downto 0) := (others => '0');
          d_in0 : in  std_logic_vector(data_width - 1 downto 0);
          d_in1 : in  std_logic_vector(data_width - 1 downto 0);
          d_in2 : in  std_logic_vector(data_width - 1 downto 0);
          d_in3 : in  std_logic_vector(data_width - 1 downto 0);
          d_out : out std_logic_vector(data_width - 1 downto 0));
  end component GEN_MUX;

  component GEN_CONSTANT is
    generic(data_width : natural := 12);
    port (high  : in  std_logic_vector(data_width - 1 downto 0);
          CE    : in  std_logic;
          y_out : out std_logic_vector(data_width -1 downto 0)
          );
  end component GEN_CONSTANT;

  component SQUARE_SIGNAL is
    generic(data_width          : natural := 8;
            clk_width           : natural := 24;
            clk_ticks_per_count : natural := 64);
    port (clk       : in  std_logic;
          CE        : in  std_logic;
          cyc_ticks : in  std_logic_vector (clk_width - 1 downto 0);
          thresh    : in  std_logic_vector (clk_width - 1 downto 0);
          high      : in  std_logic_vector (data_width - 1 downto 0);
          low       : in  std_logic_vector (data_width - 1 downto 0);
          y_out     : out std_logic_vector (data_width - 1 downto 0));
  end component SQUARE_SIGNAL;

  component GEN_RAMP is
    generic(data_width          : natural := 8;
            clk_width           : natural := 24;
            clk_ticks_per_count : natural := 64);
    port (clk       : in  std_logic;
          CE        : in  std_logic;
          DIR       : in  std_logic;
          cyc_ticks : in  std_logic_vector (clk_width - 1 downto 0);
          HIGH      : in  std_logic_vector (data_width - 1 downto 0);
          LOW       : in  std_logic_vector (data_width - 1 downto 0);
          y_out     : out std_logic_vector (data_width - 1 downto 0));
  end component GEN_RAMP;

  component GEN_ZIGZAG is
    generic(data_width          : natural := 8;
            clk_width           : natural := 24;
            clk_ticks_per_count : natural := 64);
    port (clk       : in  std_logic;
          CE        : in  std_logic;
          cyc_ticks : in  std_logic_vector(clk_width - 1 downto 0);
          HIGH      : in  std_logic_vector(data_width - 1 downto 0);
          LOW       : in  std_logic_vector(data_width - 1 downto 0);
          y_out     : out std_logic_vector(data_width - 1 downto 0));
  end component GEN_ZIGZAG;

  component DIGITAL_ANALOG_CONVERTER is  
    generic(clk_ticks_per_bit : natural := 4
            );
    port (CLK       : in  std_logic;
          CE        : in  std_logic;
          DATA_in_A : in  std_logic_vector(11 downto 0);
          DATA_in_B : in  std_logic_vector(11 downto 0);
          JA        : out std_logic_vector(3 downto 0)
          );
  end component DIGITAL_ANALOG_CONVERTER;

  -- clock signals
  -- function component CLK:
  -- signal FUNC_CLK_EN : std_logic;
  -- digital to analog converter CLK:
 -- signal DAC_CLK_EN  : std_logic;

  -- function parameter signals
  -- cyc_ticks:
  signal cts  : std_logic_vector(clk_width - 1 downto 0);
  -- threshhold_signal:
  signal ths  : std_logic_vector(clk_width - 1 downto 0);
  -- high_signal:
  signal hs   : std_logic_vector(data_width - 1 downto 0);
  -- low_signal:
  signal ls   : std_logic_vector(data_width - 1 downto 0);
  -- waveform_signal:
  signal wvs  : std_logic_vector(1 downto 0);
  -- direction_signal:
  signal dirs : std_logic;

  -- internal wiring between function and multiplexer
  signal funcmuxout_dacin    : std_logic_vector(data_width - 1 downto 0) := (others => '0');
  signal constfuncout_muxin  : std_logic_vector(data_width - 1 downto 0) := (others => '0');
  signal squarefuncout_muxin : std_logic_vector(data_width - 1 downto 0) := (others => '0');
  signal zzfuncout_muxin     : std_logic_vector(data_width - 1 downto 0) := (others => '0');
  signal rampfuncout_muxin   : std_logic_vector(data_width - 1 downto 0) := (others => '0');

  -- PMOD port JA
  signal JA_s : std_logic_vector(3 downto 0) := (others => '0');

begin

  -- show the digital value of the function on the onboard LEDS
  LED <= funcmuxout_dacin;

  -----------------------------------------------------------------------------------
  -- configuration of the function generator including the UART interface
  -----------------------------------------------------------------------------------

  config : CONFIG_INTERFACE
    generic map(data_width => data_width,
                CLK_width  => CLK_WIDTH,

                cyc_ticks_default => CONST_CYC_TICKS,
                dutycycle_default => CONST_DUTYCYCLE,
                high_default      => CONST_HIGH,
                low_default       => CONST_LOW,
                waveform_default  => CONST_WAVEFORM,
                direction_default => CONST_DIR,

                baud_clk_ticks => 868
                )
    port map(CLK       => CLK100MHZ,
             CE        => '0',
             Rx        => RsRx,
             Tx        => RsTx,
             cyc_ticks => cts,
             high      => hs,
             low       => ls,
             thresh    => ths,
             waveform  => wvs,
             direction => dirs
             );

  -----------------------------------------------------------------------------------
  -- function components
  -----------------------------------------------------------------------------------

  -- multiplexes one of the function signals to output, depending on current waveform
  funcsig_mx : GEN_MUX
    generic map(data_width => data_width)
    port map(sel   => wvs,
             d_out => funcmuxout_dacin,
             d_in0 => constfuncout_muxin,
             d_in1 => squarefuncout_muxin,
             d_in2 => zzfuncout_muxin,
             d_in3 => rampfuncout_muxin
             );

  -- component for constant value output
  constfuncsig : GEN_CONSTANT
    generic map(data_width => data_width)
    port map(high  => hs,
             CE    => '0',
             y_out => constfuncout_muxin
             );

  -- component for pwm / square signal output
  squarefuncsig : SQUARE_SIGNAL
    generic map(CLK_WIDTH           => CLK_WIDTH,
                data_width          => data_width,
                clk_ticks_per_count => FUNC_DIV)
    port map(CLK       => CLK100MHZ,
             CE        => '0',
             cyc_ticks => cts,
             high      => hs,
             low       => ls,
             thresh    => ths,
             y_out     => squarefuncout_muxin
             );

  -- component for zigzag signal output
  zzfuncsig : GEN_ZIGZAG
    generic map(CLK_WIDTH           => CLK_WIDTH,
                data_width          => data_width,
                clk_ticks_per_count => FUNC_DIV)
    port map(CLK       => CLK100MHZ,
             CE        => '0',
             cyc_ticks => cts,
             HIGH      => hs,
             LOW       => ls,
             y_out     => zzfuncout_muxin
             );

  -- component for ramp signal output
  rampfuncsig : GEN_RAMP
    generic map(CLK_WIDTH           => CLK_WIDTH,
                data_width          => data_width,
                clk_ticks_per_count => FUNC_DIV)
    port map(CLK       => CLK100MHZ,
             CE        => '0',
             dir       => dirs,
             cyc_ticks => cts,
             HIGH      => hs,
             LOW       => ls,
             y_out     => rampfuncout_muxin
             );

  -----------------------------------------------------------------------------------
  -- digital to analog converter
  -----------------------------------------------------------------------------------

  -- JA are the pmod headers for the DAC including:
  -- JA0 <= SYNC
  -- JA1 <= DINA: seriell DATA to DAC-channel A
  -- JA2 <= DINB: seriell DATA to DAC-channel B
  -- JA3 <= CLK
  -- where DINA and DINB is the seriell DATA that goes into channel A and B
  DAC : DIGITAL_ANALOG_CONVERTER
    generic map(clk_ticks_per_bit => DAC_DIV
                )
    port map(CLK       => CLK100MHZ,
             CE        => '0',
             DATA_in_A => funcmuxout_dacin,
             DATA_in_B => x"000",
             JA        => JA
             );

end Behavioral;
