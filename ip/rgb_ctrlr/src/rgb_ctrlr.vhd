-- Módulo: rgb_ctrlr basado en salidas pwm
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 23.11.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity rgb_ctrlr is
    generic (
        G_SYS_CLK_HZ    : integer := 125_000_000;
        G_RST_POL       : std_logic := '1';
        G_PERIOD_MAX_US : integer := 1_000_000
    );
    port (
        CLK_I   : in std_logic;
        RST_I   : in std_logic;
        MODE_I  : in std_logic_vector(2 downto 0);
        RED_O   : out std_logic;
        GREEN_O : out std_logic;
        BLUE_O  : out std_logic
        
    );
end entity rgb_ctrlr;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of rgb_ctrlr is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component pwm is
        generic (
            G_SYS_CLK_HZ    : integer := 125_000_000;
            G_RST_POL       : std_logic := '1';
            G_PERIOD_MAX_US : integer := 1_000_000
        );
        port (
            CLK_I       : in std_logic;
            RST_I       : in std_logic;
            DUTY_I      : in integer range 0 to 100;                -- Duty cycle [%]
            PERIOD_US_I : in integer range 0 to G_PERIOD_MAX_US;    -- Period [us]
            PWM_O       : out std_logic
        );
    end component pwm;

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    type t_color is (NONE, RED, GREEN, BLUE, YELLOW, ORANGE, VIOLET, CIAN);
    type t_params is record
        duty    : integer range 0 to 100;
        period  : integer range 0 to G_PERIOD_MAX_US;
        pwm     : std_logic;
    end record t_params;

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    constant C_PERIOD_US : integer := 255;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    signal r_mode   : std_logic_vector((MODE_I'length - 1) downto 0);
    signal s_color  : t_color;
    signal s_red    : t_params;
    signal s_green  : t_params;
    signal s_blue   : t_params;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    red_i : component pwm
        generic map (
            G_SYS_CLK_HZ    => G_SYS_CLK_HZ,
            G_RST_POL       => G_RST_POL,
            G_PERIOD_MAX_US => G_PERIOD_MAX_US
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            DUTY_I      => s_red.duty,
            PERIOD_US_I => s_red.period,
            PWM_O       => s_red.pwm
        );

    green_i : component pwm
        generic map (
            G_SYS_CLK_HZ    => G_SYS_CLK_HZ,
            G_RST_POL       => G_RST_POL,
            G_PERIOD_MAX_US => G_PERIOD_MAX_US
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            DUTY_I      => s_green.duty,
            PERIOD_US_I => s_green.period,
            PWM_O       => s_green.pwm
        );

    blue_i : component pwm
        generic map (
            G_SYS_CLK_HZ    => G_SYS_CLK_HZ,
            G_RST_POL       => G_RST_POL,
            G_PERIOD_MAX_US => G_PERIOD_MAX_US
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            DUTY_I      => s_blue.duty,
            PERIOD_US_I => s_blue.period,
            PWM_O       => s_blue.pwm
        );

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    RED_O   <= s_red.pwm;
    GREEN_O <= s_green.pwm;
    BLUE_O  <= s_blue.pwm;

    -- USER : Map mode-color
    with r_mode select
        s_color <=  BLUE    when "000", -- Apagados
                    CIAN    when "001", -- Apagando
                    YELLOW  when "010", -- Configurando
                    GREEN   when "011", -- Activos
                    RED     when "100", -- Fallo
                    NONE    when others;
    -- USER ----------------

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Registro de entradas
    P_REG : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_mode <= (others => '0');
        elsif rising_edge(CLK_I) then
            r_mode <= MODE_I;
        end if;
    end process P_REG;

    -- Configuración de los PWM
    P_PWMS : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            s_red.duty      <= 0;
            s_red.period    <= 0;
            s_green.duty    <= 0;
            s_green.period  <= 0;
            s_blue.duty     <= 0;
            s_blue.period   <= 0;
        elsif rising_edge(CLK_I) then
            case s_color is
                when RED =>
                    -- R
                    s_red.duty      <= 100;
                    s_red.period    <= C_PERIOD_US;
                    -- G
                    s_green.duty    <= 0;
                    s_green.period  <= C_PERIOD_US;
                    -- B
                    s_blue.duty     <= 0;
                    s_blue.period   <= C_PERIOD_US;

                when GREEN =>
                    -- R
                    s_red.duty      <= 0;
                    s_red.period    <= C_PERIOD_US;
                    -- G
                    s_green.duty    <= 100;
                    s_green.period  <= C_PERIOD_US;
                    -- B
                    s_blue.duty     <= 0;
                    s_blue.period   <= C_PERIOD_US;

                when BLUE =>
                    -- R
                    s_red.duty      <= 0;
                    s_red.period    <= C_PERIOD_US;
                    -- G
                    s_green.duty    <= 0;
                    s_green.period  <= C_PERIOD_US;
                    -- B
                    s_blue.duty     <= 100;
                    s_blue.period   <= C_PERIOD_US;

                when YELLOW =>
                    -- R
                    s_red.duty      <= 100;
                    s_red.period    <= C_PERIOD_US;
                    -- G
                    s_green.duty    <= 100;
                    s_green.period  <= C_PERIOD_US;
                    -- B
                    s_blue.duty     <= 0;
                    s_blue.period   <= C_PERIOD_US;

                when ORANGE =>
                    -- R
                    s_red.duty      <= 100;
                    s_red.period    <= C_PERIOD_US;
                    -- G
                    s_green.duty    <= 65;
                    s_green.period  <= C_PERIOD_US;
                    -- B
                    s_blue.duty     <= 0;
                    s_blue.period   <= C_PERIOD_US;

                when VIOLET =>
                    -- R
                    s_red.duty      <= 58;
                    s_red.period    <= C_PERIOD_US;
                    -- G
                    s_green.duty    <= 0;
                    s_green.period  <= C_PERIOD_US;
                    -- B
                    s_blue.duty     <= 83;
                    s_blue.period   <= C_PERIOD_US;

                when CIAN =>
                    -- R
                    s_red.duty      <= 0;
                    s_red.period    <= C_PERIOD_US;
                    -- G
                    s_green.duty    <= 100;
                    s_green.period  <= C_PERIOD_US;
                    -- B
                    s_blue.duty     <= 100;
                    s_blue.period   <= C_PERIOD_US;

                when NONE =>
                    -- R
                    s_red.duty      <= 0;
                    s_red.period    <= C_PERIOD_US;
                    -- G
                    s_green.duty    <= 0;
                    s_green.period  <= C_PERIOD_US;
                    -- B
                    s_blue.duty     <= 0;
                    s_blue.period   <= C_PERIOD_US;

            end case;
        end if;
    end process P_PWMS;

end architecture beh;