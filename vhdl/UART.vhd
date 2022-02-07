-- simple UART Interface
-- source:
-- https://projects.digilentinc.com/alexey-sudbin/uart-interface-in-vhdl-for-basys3-board-eef170
-- from 04 Feb 2022

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


use IEEE.NUMERIC_STD.ALL;



entity UART is
    generic(
            BAUD_CLK_TICKS : integer := 868
            );
    port(
        CLK            : in  std_logic;
        CE             : in  std_logic;
        reset          : in  std_logic;
        tx_start       : in  std_logic;

        data_in        : in  std_logic_vector (7 downto 0);
        data_out       : out std_logic_vector (7 downto 0);

        rx             : in  std_logic;
        rx_uart_rdy    : out std_logic;
        tx             : out std_logic
        );
end UART;


architecture Behavioral of UART is

    -- constant BAUD_x16_CLK_TICKS : integer := BAUD_CLK_TICKS / 16;

    component UART_tx
        generic(
                BAUD_CLK_TICKS: integer := 868);
                -- clk/baud_rate  (50 000 000 / 115 200 = 434.0277)
                -- clk/baud_rate (100 000 000 / 115 200 = 868.0555)
    
        port(
             CLK            : in  std_logic;
             CE             : in  std_logic;
             reset          : in  std_logic;
             tx_start       : in  std_logic;
             tx_data_in     : in  std_logic_vector (7 downto 0);
             tx_data_out    : out std_logic
             );
    end component;


    component UART_rx
        generic(
            BAUD_X16_CLK_TICKS: integer := 27
            -- Ticks for oversampled clock
        ); 
        port(
            clk            : in  std_logic;
            CE             : in  std_logic;
            reset          : in  std_logic;
            rx_data_in     : in  std_logic;
            rx_data_out    : out std_logic_vector (7 downto 0);
            rx_byte_rdy    : out std_logic
            );
    end component;

begin

    transmitter: UART_tx
    port map(
            clk            => clk,
            CE             => CE,
            reset          => reset,
            tx_start       => tx_start,
            tx_data_in     => data_in,
            tx_data_out    => tx
            );


    receiver: UART_rx
    generic map(
                BAUD_X16_CLK_TICKS => BAUD_CLK_TICKS / 16
               )
    port map(
            clk            => clk,
            CE             => CE,
            reset          => reset,
            rx_byte_rdy    => rx_uart_rdy,
            rx_data_in     => rx,
            rx_data_out    => data_out
            );


end Behavioral;
