-- Módulo: config_error test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 26.10.2025

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
entity config_error_tb is
end entity config_error_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of config_error_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component config_error is
        generic (
            G_RST_POL   : std_logic := '1'
        );
        port (
            CLK_I               : in std_logic;
            RST_I               : in std_logic;
            PWM_TOP_INPUTS_I    : in pwm_top_in;
            CONFIG_ERROR_O      : out std_logic
        );
    end component config_error;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I            : std_logic;
    signal RST_I            : std_logic;
    signal PWM_TOP_INPUTS_I : pwm_top_in;
    signal CONFIG_ERROR_O   : std_logic;

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
        signal pwm_in   : out pwm_top_in
    ) is
    begin
        rst                 <= G_RST_POL;
        pwm_in.en           <= '0';
        pwm_in.upd_mem      <= '0';
        pwm_in.wr_en        <= '0';
        pwm_in.wr_addr      <= (others => '0');
        pwm_in.wr_data      <= (others => '0');
        pwm_in.n_addr       <= (others => '0');
        pwm_in.n_tot_cyc    <= (others => '0');
        pwm_in.pwm_init     <= '0';
        p_wait(clk_period);
        rst         <= not G_RST_POL;
    end procedure reset;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component config_error
        generic map (
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I               => CLK_I,
            RST_I               => RST_I,
            PWM_TOP_INPUTS_I    => PWM_TOP_INPUTS_I,
            CONFIG_ERROR_O      => CONFIG_ERROR_O
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
        sim <= x"49_4E_49_54_20_20";    -- INIT
        reset(RST_I, PWM_TOP_INPUTS_I);
        p_wait(10*clk_period);

        -- TODO: CASOS A COMPROBAR

        -- Configuración correcta
        -- Se programan más estados que N_ADDR
        -- Se programan menos estados que N_ADDR
        -- Se programan más ciclos que N_TOT_CYC
        -- Se programan menos ciclos que N_TOT_CYC
        -- Combinaciones y secuencias de estos

        ------------------------------
        -- CONFIG 1 OK
        ------------------------------
        sim <= x"31_20_4F_4B_20_20";    -- 1 OK 

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(5, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(19, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(4, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(4, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(7, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(4, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';
        
        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 2 OK
        ------------------------------
        sim <= x"32_20_4F_4B_20_20";    -- 2 OK 

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(7, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(5, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';
        

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 3 OK sin enable
        ------------------------------
        sim <= x"33_20_7E_45_4E_20";    -- 3 ~EN 

        PWM_TOP_INPUTS_I.en         <= '0';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(17, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(11, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(6, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 4 cnt < N_ADDR
        ------------------------------
        sim <= x"34_20_6E_3C_4E_20";    -- 4 c<N 

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(4, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(8, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(4, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 5 OK
        ------------------------------
        sim <= x"35_20_4F_4B_20_20";    -- 5 OK  

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 6 cnt > N_ADDR
        ------------------------------
        sim <= x"36_20_63_3E_4E_20";    -- 6 c>N 

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(15, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(5, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(5, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(5, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 7 OK
        ------------------------------
        sim <= x"37_20_4F_4B_20_20";    -- 7 OK  

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 8 cnt < N_TOT
        ------------------------------
        sim <= x"38_20_63_3C_54_20";    -- 8 c<T 

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(5, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(11, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(4, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 9 OK
        ------------------------------
        sim <= x"39_20_4F_4B_20_20";    -- 9 OK  

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 10 cnt > N_TOT
        ------------------------------
        sim <= x"31_30_20_63_3E_54";    -- 10 c>T 

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(5, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(12, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(4, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 11 OK = CONFIG 10
        ------------------------------
        sim <= x"31_31_20_3D_31_30";    -- 11 =10 

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(5, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(12, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(1, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(4, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- CONFIG 12 ERR
        ------------------------------
        sim <= x"31_32_20_45_52_52";    -- 12 ERR

        PWM_TOP_INPUTS_I.en         <= '1';
        p_wait(5*clk_period);
        -- N_ADDR y N_TOT_CYC
        PWM_TOP_INPUTS_I.n_addr     <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.n_addr'length));
        PWM_TOP_INPUTS_I.n_tot_cyc  <= std_logic_vector(to_unsigned(2, PWM_TOP_INPUTS_I.n_tot_cyc'length));
        p_wait(5*clk_period);
        -- WR_EN, WR_ADDR, WR_DATA
        PWM_TOP_INPUTS_I.wr_en      <= '1';
        PWM_TOP_INPUTS_I.wr_addr    <= std_logic_vector(to_unsigned(0, PWM_TOP_INPUTS_I.wr_addr'length));
        PWM_TOP_INPUTS_I.wr_data    <= std_logic_vector(to_unsigned(3, PWM_TOP_INPUTS_I.wr_data'length));
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.wr_en      <= '0';
        p_wait(clk_period);
        -- UPDATE
        PWM_TOP_INPUTS_I.upd_mem    <= '1';
        p_wait(clk_period);
        PWM_TOP_INPUTS_I.upd_mem    <= '0';

        p_wait(30*clk_period);

        ------------------------------
        -- Reset
        ------------------------------
        sim <= x"52_45_53_45_54_20";    -- RESET
        reset(RST_I, PWM_TOP_INPUTS_I);
        p_wait(10*clk_period);

        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;