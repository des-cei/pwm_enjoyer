-- Módulo: pwm_generator
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 02.06.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.my_pkg.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity pwm_generator_tb is
end entity pwm_generator_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_generator_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component pwm_generator is
        generic (
            G_PARAM_MAX_N   : integer := 10;
            G_PARAMS_N      : integer := 4
        );
        port (
            CLK_I       : in std_logic;
            RST_I       : in std_logic;                                         -- Reset asíncrono por nivel alto
            SET_I       : in std_logic;                                         -- Señal para aplicar la configuración de entrada
            PARAM_1_I   : in std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);   -- Número pulsos a nivel alto del PARAM_1
            PARAM_2_I   : in std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);   -- Número pulsos a nivel alto del PARAM_2
            PARAM_3_I   : in std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);   -- Número pulsos a nivel alto del PARAM_3
            PARAM_4_I   : in std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);   -- Número pulsos a nivel alto del PARAM_4
            PWM_O       : out std_logic
        );
    end component pwm_generator;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
    -- signal sim          : string(1 downto 6) := (others => '0');
    signal sim          : std_logic_vector(47 downto 0) := (others => '0');

    -- Port map
    signal CLK_I        : std_logic;
    signal RST_I        : std_logic;                                      
    signal SET_I        : std_logic;                                      
    signal PARAM_1_I    : std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);
    signal PARAM_2_I    : std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);
    signal PARAM_3_I    : std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);
    signal PARAM_4_I    : std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);
    signal PWM_O        : std_logic;

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- Wait
    procedure p_wait (
        constant period : in time
    ) is
    begin
        wait for 0.99*period;
        wait until rising_edge(CLK_I);
    end procedure p_wait;

    -- Reset
    procedure reset (
        signal rst  : out std_logic;
        signal set  : out std_logic;
        signal p_1  : out std_logic_vector;
        signal p_2  : out std_logic_vector;
        signal p_3  : out std_logic_vector;
        signal p_4  : out std_logic_vector
    ) is
    begin
        rst <= '1';
        set <= '0';
        p_1 <= (others => '0');
        p_2 <= (others => '0');
        p_3 <= (others => '0');
        p_4 <= (others => '0');
        p_wait(clk_period);
        rst <= '0';
    end procedure reset;

    -- Presentar tabla
    procedure prep_tabla (
        constant p1 : in integer;
        constant p2 : in integer;
        constant p3 : in integer;
        constant p4 : in integer;
        signal p_1  : out std_logic_vector;
        signal p_2  : out std_logic_vector;
        signal p_3  : out std_logic_vector;
        signal p_4  : out std_logic_vector
    ) is
    begin
        p_1 <= std_logic_vector(to_unsigned(p1, p_1'length));
        p_2 <= std_logic_vector(to_unsigned(p2, p_2'length));
        p_3 <= std_logic_vector(to_unsigned(p3, p_3'length));
        p_4 <= std_logic_vector(to_unsigned(p4, p_4'length));
    end procedure prep_tabla;

    -- Set
    procedure set (
        signal set  : out std_logic
    ) is
    begin
        set <= '1';
        p_wait(clk_period);
        set <= '0';
    end procedure set;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_generator
        generic map (
            G_PARAM_MAX_N   => G_PARAM_MAX_N,
            G_PARAMS_N      => G_PARAMS_N   
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            SET_I       => SET_I,
            PARAM_1_I   => PARAM_1_I,
            PARAM_2_I   => PARAM_2_I,
            PARAM_3_I   => PARAM_3_I,
            PARAM_4_I   => PARAM_4_I,
            PWM_O       => PWM_O
        );

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Reloj
    P_CLK : process
    begin
        CLK_I <= '0';
        wait for clk_period/2;
        CLK_I <= '1';
        wait for clk_period/2;
    end process;

    -------------------------------------------------
    -- Estímulos
    -------------------------------------------------
    P_STIM : process
    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        -- sim <= "INIT  ";
        sim <= x"49_4E_49_54_20_20";
        reset(RST_I, SET_I, PARAM_1_I, PARAM_2_I, PARAM_3_I, PARAM_4_I);

        p_wait(100*clk_period);

        ------------------------------
        -- Set 1
        ------------------------------
        -- sim <= "SET 1 ";
        sim <= x"53_45_54_20_31_20";
        prep_tabla(4, 2, 7, 3, PARAM_1_I, PARAM_2_I, PARAM_3_I, PARAM_4_I);

        p_wait(43*clk_period);
        set(SET_I);
        p_wait(100*clk_period);

        ------------------------------
        -- Set 2
        ------------------------------
        -- sim <= "SET 2 ";
        sim <= x"53_45_54_20_32_20";
        prep_tabla(5, 3, 10, 1, PARAM_1_I, PARAM_2_I, PARAM_3_I, PARAM_4_I);

        p_wait(13*clk_period);
        set(SET_I);
        p_wait(143*clk_period);

        ------------------------------
        -- Set 3
        ------------------------------
        -- sim <= "SET 3 ";
        sim <= x"53_45_54_20_33_20";
        prep_tabla(2, 2, 7, 5, PARAM_1_I, PARAM_2_I, PARAM_3_I, PARAM_4_I);

        p_wait(79*clk_period);
        set(SET_I);
        p_wait(202*clk_period);

        ------------------------------
        -- End
        ------------------------------
        -- sim <= "ENDING";
        sim <= x"45_4E_44_49_4E_47";
        reset(RST_I, SET_I, PARAM_1_I, PARAM_2_I, PARAM_3_I, PARAM_4_I);
        p_wait(100*clk_period);
        
        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;