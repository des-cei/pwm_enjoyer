-- Módulo: pwm_counter test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 24.06.2025

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
entity pwm_counter_tb is
end entity pwm_counter_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_counter_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component pwm_counter is
        generic (
            G_RST_POL   : std_logic := '1'
        );
        port (
            CLK_I       : in std_logic;
            RST_I       : in std_logic;
            EN_I        : in std_logic;                                         -- Señal de habilitación                                         
            CNT_LEN_I   : in std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);   -- Número de pulsos del estado actual
            PWM_INIT_I  : in std_logic;                                         -- Valor inicial
            PWM_O       : out std_logic;                                        -- Salida del PWM
            CNT_END_O   : out std_logic                                         -- Indicador de final de estado
        );
    end component pwm_counter;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I       : std_logic;
    signal RST_I       : std_logic;                                        
    signal EN_I        : std_logic;                                         
    signal CNT_LEN_I   : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);
    signal PWM_INIT_I  : std_logic;                                      
    signal PWM_O       : std_logic;                                     
    signal CNT_END_O   : std_logic;                                     

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
        signal rst      : out std_logic;
        signal en       : out std_logic;
        signal cnt_len  : out std_logic_vector;
        signal pwm_init : out std_logic
    ) is
    begin
        rst         <= '1';
        en          <= '0';
        cnt_len     <= (others => '0');
        pwm_init    <= '0';
        p_wait(clk_period);
        rst     <= '0';
    end procedure reset;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_counter
        generic map (
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            EN_I        => EN_I,
            CNT_LEN_I   => CNT_LEN_I,
            PWM_INIT_I  => PWM_INIT_I,
            PWM_O       => PWM_O,
            CNT_END_O   => CNT_END_O
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

        variable v_duracion : integer range 0 to G_STATE_MAX_N := 0;

    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        sim <= x"49_4E_49_54_20_20";
        reset(RST_I, EN_I, CNT_LEN_I, PWM_INIT_I);
        p_wait(10*clk_period);

        ------------------------------
        -- Test 1
        --  4 estados: 5-1-1-3, empieza en '1'
        --  2 repeticiones
        ------------------------------
        sim         <= x"54_45_53_54_20_31";
        PWM_INIT_I  <= '1';
        p_wait(clk_period);
        EN_I        <= '1';

        for i in 0 to 1 loop
            -- 1.1
            v_duracion  := 5;
            CNT_LEN_I   <= std_logic_vector(to_unsigned(v_duracion, CNT_LEN_I'length));
            p_wait(v_duracion*clk_period);

            -- 1.2
            v_duracion  := 1;
            CNT_LEN_I   <= std_logic_vector(to_unsigned(v_duracion, CNT_LEN_I'length));
            p_wait(v_duracion*clk_period);

            -- 1.3
            v_duracion  := 1;
            CNT_LEN_I   <= std_logic_vector(to_unsigned(v_duracion, CNT_LEN_I'length));
            p_wait(v_duracion*clk_period);

            -- 1.4
            v_duracion  := 3;
            CNT_LEN_I   <= std_logic_vector(to_unsigned(v_duracion, CNT_LEN_I'length));
            p_wait(v_duracion*clk_period);
        end loop;

        ------------------------------
        -- Test 2
        --  2 estados: 6-6, empieza en '0'
        --  3 repeticiones
        ------------------------------
        -- Cambio
        sim         <= x"43_41_4D_42_49_4F";
        EN_I        <= '0';
        PWM_INIT_I  <= '0';
        p_wait(10*clk_period);
        EN_I        <= '1';

        sim         <= x"54_45_53_54_20_32";
        for i in 0 to 2 loop
            -- 2.1
            v_duracion  := 6;
            CNT_LEN_I   <= std_logic_vector(to_unsigned(v_duracion, CNT_LEN_I'length));
            p_wait(v_duracion*clk_period);

            -- 2.2
            v_duracion  := 6;
            CNT_LEN_I   <= std_logic_vector(to_unsigned(v_duracion, CNT_LEN_I'length));
            p_wait(v_duracion*clk_period);        
        end loop;

        ------------------------------
        -- End
        ------------------------------
        sim     <= x"45_4E_44_49_4E_47";
        EN_I    <= '0';
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;