-- Módulo: config_error
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
entity config_error is
    generic (
        G_RST_POL           : std_logic := '1';
        G_MEM_SIZE_MAX_L2   : natural := 32;    -- Tamaño del vector del número máximo de estados
        G_PERIOD_MAX_L2     : natural := 32     -- Tamaño del vector del número máximo de periodos de reloj de una configuración
    );
    port (
        CLK_I               : in std_logic;
        RST_I               : in std_logic;
        PWM_TOP_INPUTS_I    : in pwm_top_in;
        CONFIG_ERROR_O      : out std_logic
    );
end entity config_error;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of config_error is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    constant C_CEROS    : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0) := (others => '0');

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Errores
    signal s_error      : std_logic;    -- Cualquier error
    signal s_err_n_addr : std_logic;    -- Error en el número de direcciones
    signal s_err_n_tot  : std_logic;    -- Error en la suma total de estados

    -- Contadores
    signal r_cnt_n_addr  : unsigned((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal r_cnt_n_tot   : unsigned((G_PERIOD_MAX_L2 - 1) downto 0);

    -- Delays
    signal r_wr_en_d1   : std_logic;
    signal r_wr_en_d2   : std_logic;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    -- Salida
    CONFIG_ERROR_O  <= s_error;

    -- Errores
    s_error         <= (s_err_n_addr or s_err_n_tot) when (PWM_TOP_INPUTS_I.en = '1') else '0';
    s_err_n_addr    <= '1' when (r_cnt_n_addr /= unsigned(PWM_TOP_INPUTS_I.n_addr)) else '0';
    s_err_n_tot     <= '1' when (r_cnt_n_tot /= unsigned(PWM_TOP_INPUTS_I.n_tot_cyc)) else '0';

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Detección de flancos
    P_EDGE : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_wr_en_d1 <= '0';
            r_wr_en_d2 <= '0';
        elsif rising_edge(CLK_I) then
            r_wr_en_d1 <= PWM_TOP_INPUTS_I.wr_en;
            r_wr_en_d2 <= r_wr_en_d1;
        end if;
    end process P_EDGE;

    -- Sumador de estados
    P_SUM : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_cnt_n_addr    <= (others => '0');
            r_cnt_n_tot     <= (others => '0');
        elsif rising_edge(CLK_I) then
            -- Reset de contadores
            if ((PWM_TOP_INPUTS_I.wr_en = '1') and (r_wr_en_d1 = '0') and (PWM_TOP_INPUTS_I.wr_addr = C_CEROS)) then
                r_cnt_n_addr    <= (others => '0');
                r_cnt_n_tot     <= (others => '0');
            elsif (PWM_TOP_INPUTS_I.en = '1') then
                -- Aumenta contadores con cada WR_EN
                if ((r_wr_en_d1 = '1') and (r_wr_en_d2 = '0')) then
                    r_cnt_n_addr    <= r_cnt_n_addr + 1;
                    r_cnt_n_tot     <= r_cnt_n_tot + unsigned(PWM_TOP_INPUTS_I.wr_data);
                end if;
            else
                r_cnt_n_addr    <= (others => '0');
                r_cnt_n_tot     <= (others => '0');
            end if;
        end if;
    end process P_SUM;

end architecture beh;