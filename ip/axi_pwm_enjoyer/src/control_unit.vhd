-- Módulo: control_unit
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 25.10.2025

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
entity control_unit is
    generic (
        G_RST_POL   : std_logic := '1';
        G_PWM_N     : integer := 32     -- Número máximo de módulos PWM. Si hay más de 32 hay que añadir más registros (*)
    );
    port (
        CLK_I               : in std_logic;
        RST_I               : in std_logic;
        -- Registros
        REG_DIRECCIONES_I   : in std_logic_vector(31 downto 0);     -- (*)
        REG_CONTROL_I       : in std_logic_vector(31 downto 0);
        REG_WR_DATA_I       : in std_logic_vector(31 downto 0);
        REG_WR_DATA_VALID_I : in std_logic_vector(31 downto 0);
        REG_N_ADDR_I        : in std_logic_vector(31 downto 0);
        REG_N_TOT_CYC_I     : in std_logic_vector(31 downto 0);
        REG_PWM_INIT_I      : in std_logic_vector(31 downto 0);
        REG_REDUNDANCIAS_O  : out std_logic_vector(31 downto 0);    -- (*)
        REG_ERRORES_O       : out std_logic_vector(31 downto 0);    -- (*)
        REG_STATUS_O        : out std_logic_vector(31 downto 0);
        -- I/O de los módulos PWM
        PWM_TOP_INPUTS_O    : out modulo_pwm_in;    -- Array de G_PWM_N de las entradas a cada pwm_top
        PWM_TOP_OUTPUTS_I   : in modulo_pwm_out     -- Array de G_PWM_N de las salidas de cada pwm_top
    );
end entity control_unit;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of control_unit is

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
    -- Tipos
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    constant C_CEROS    : std_logic_vector(31 downto 0) := (others => '0');

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Registros
    signal r_direcciones    : std_logic_vector(31 downto 0);
    signal r_control        : std_logic_vector(3 downto 0);
    signal r_wr_data        : std_logic_vector(31 downto 0);
    signal r_wr_data_valid  : std_logic;
    signal r_n_addr         : std_logic_vector(31 downto 0);
    signal r_n_tot_cyc      : std_logic_vector(31 downto 0);
    signal r_pwm_init       : std_logic;
    signal r_redundancias   : std_logic_vector(31 downto 0);
    signal r_errores        : std_logic_vector(31 downto 0);
    signal r_status         : std_logic_vector(31 downto 0);

    -- Interconexiones
    signal r_pwm_top_inputs : modulo_pwm_in;
    signal s_config_error   : std_logic_vector((G_PWM_N - 1) downto 0);
    signal s_en_wr_config   : std_logic_vector((G_PWM_N - 1) downto 0);

    -- Máquina de estados
    type fsm is (S_IDLE, S_SHUTDOWN, S_APAGAR, S_ACTUALIZAR, S_CONFIGURAR, S_UNKOWN);
    signal s_estado     : fsm;
    signal r_wr_en      : std_logic;
    signal r_wr_addr    : unsigned((PWM_TOP_INPUTS_O(0).wr_addr'length - 1) downto 0);
    signal s_status     : std_logic_vector(1 downto 0);
    
    -- Detección de flancos
    signal s_estado_d1      : fsm;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    gen_config_err : for i in 0 to (G_PWM_N - 1) generate
        config_err_i : component config_error
            generic map (
                G_RST_POL   => G_RST_POL
            )
            port map (
                CLK_I               => CLK_I,
                RST_I               => RST_I,
                PWM_TOP_INPUTS_I    => r_pwm_top_inputs(i),
                CONFIG_ERROR_O      => s_config_error(i)
            );
    end generate gen_config_err;

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    -- Registros de lectura
    REG_REDUNDANCIAS_O  <= r_redundancias; 
    REG_ERRORES_O       <= r_errores;
    REG_STATUS_O        <= r_status;

    -- Salidas
    PWM_TOP_INPUTS_O    <= r_pwm_top_inputs;

    -- Control de la máquina de estados
    with r_control select
        s_estado <= S_SHUTDOWN      when "0001",
                    S_APAGAR        when "0010",
                    S_ACTUALIZAR    when "0100",
                    S_CONFIGURAR    when "1000",
                    S_IDLE          when others;

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Mapa de registros
    P_REG : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_direcciones   <= (others => '0');
            r_control       <= (others => '0');
            r_wr_data       <= (others => '0');
            r_wr_data_valid <= '0';
            r_n_addr        <= (others => '0');
            r_n_tot_cyc     <= (others => '0');
            r_pwm_init      <= '0';
            r_redundancias  <= (others => '0');
            r_errores       <= (others => '0');
            r_status        <= (others => '0');
        elsif rising_edge(CLK_I) then
            -- Registros de escritura
            r_direcciones   <= REG_DIRECCIONES_I;
            r_control       <= REG_CONTROL_I(3 downto 0);
            r_wr_data       <= REG_WR_DATA_I;
            r_wr_data_valid <= REG_WR_DATA_VALID_I(0);
            if (r_wr_data_valid = '1') then
                r_wr_data_valid <= '0'; -- Reset automático del WR_DATA_EN
            end if;
            r_n_addr        <= REG_N_ADDR_I;
            r_n_tot_cyc     <= REG_N_TOT_CYC_I;
            r_pwm_init      <= REG_PWM_INIT_I(0);
            -- Registros de lectura
            for i in 0 to (G_PWM_N - 1) loop
                if (PWM_TOP_OUTPUTS_I(i).pwm = PWM_TOP_OUTPUTS_I(i).pwm_red_1) and (PWM_TOP_OUTPUTS_I(i).pwm = PWM_TOP_OUTPUTS_I(i).pwm_red_2) then
                    r_redundancias(i)   <= '0'; -- No hay disparidad
                else
                    r_redundancias(i)   <= '1'; -- Las salidas no coinciden
                end if;
                r_errores(i)        <= s_config_error(i);
            end loop;
            r_status(1 downto 0)    <= s_status;
        end if;
    end process P_REG;

    -- Detección de flancos
    P_EDGE : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            s_estado_d1     <= S_IDLE;
        elsif rising_edge(CLK_I) then
            s_estado_d1     <= s_estado;
        end if;
    end process P_EDGE;

    -- Máquina de estados (APAGAR, ACTULIZAR, CONFIGURAR)
    P_FSM : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_wr_en     <= '0';
            r_wr_addr   <= (others => '0');
            for i in 0 to (G_PWM_N - 1) loop
                r_pwm_top_inputs(i).en        <= '0';
                r_pwm_top_inputs(i).upd_mem   <= '0';
                r_pwm_top_inputs(i).wr_en     <= '0';
                r_pwm_top_inputs(i).wr_addr   <= (others => '0');
                r_pwm_top_inputs(i).wr_data   <= (others => '0');
                r_pwm_top_inputs(i).n_addr    <= (others => '0');
                r_pwm_top_inputs(i).n_tot_cyc <= (others => '0');
                r_pwm_top_inputs(i).pwm_init  <= '0';
            end loop;
            s_status    <= "00";
        elsif rising_edge(CLK_I) then
            case s_estado is

                when S_IDLE =>
                    -- Nada que hacer

                when S_SHUTDOWN =>
                    for i in 0 to (G_PWM_N - 1) loop
                        -- Flanco de subida
                        if (s_estado_d1 /= S_SHUTDOWN) then
                            r_pwm_top_inputs(i).en        <= '0';
                            r_pwm_top_inputs(i).upd_mem   <= '0';
                            r_pwm_top_inputs(i).wr_en     <= '0';
                            r_pwm_top_inputs(i).wr_addr   <= (others => '0');
                            r_pwm_top_inputs(i).wr_data   <= (others => '0');
                            r_pwm_top_inputs(i).n_addr    <= (others => '0');
                            r_pwm_top_inputs(i).n_tot_cyc <= (others => '0');
                            r_pwm_top_inputs(i).pwm_init  <= '0';
                            s_status <= "00";
                        end if;
                    end loop;

                when S_APAGAR =>
                    for i in 0 to (G_PWM_N - 1) loop
                        if (r_direcciones(i) = '1') then
                            r_pwm_top_inputs(i).en <= '0';
                        end if;
                    end loop;

                when S_ACTUALIZAR =>
                    for i in 0 to (G_PWM_N - 1) loop
                        if (r_direcciones(i) = '1') then
                            -- Flanco de subida
                            if (s_estado_d1 /= S_ACTUALIZAR) then
                                if ((r_errores = C_CEROS) and (r_redundancias = C_CEROS)) then
                                    r_pwm_top_inputs(i).upd_mem <= '1';
                                    s_status <= "10";
                                else
                                    s_status <= "11";
                                end if;
                            else
                                r_pwm_top_inputs(i).upd_mem <= '0';
                            end if;
                        end if;
                    end loop;

                when S_CONFIGURAR =>
                    for i in 0 to (G_PWM_N - 1) loop
                        if (r_direcciones(i) = '1') then
                            if (s_en_wr_config(i) = '1') then
                                r_pwm_top_inputs(i).en          <= '1';
                                r_pwm_top_inputs(i).wr_en       <= '0';
                                r_pwm_top_inputs(i).n_addr      <= r_n_addr((r_pwm_top_inputs(i).n_addr'length - 1) downto 0);
                                r_pwm_top_inputs(i).n_tot_cyc   <= r_n_tot_cyc((r_pwm_top_inputs(i).n_tot_cyc'length - 1) downto 0);
                                r_pwm_top_inputs(i).pwm_init    <= r_pwm_init;
                                
                                if (r_wr_data_valid = '1') then
                                    r_pwm_top_inputs(i).wr_en   <= '1';
                                    r_pwm_top_inputs(i).wr_addr <= std_logic_vector(r_wr_addr);
                                    r_pwm_top_inputs(i).wr_data <= r_wr_data((r_pwm_top_inputs(i).wr_data'length - 1) downto 0);
                                    if (r_wr_addr = (unsigned(r_n_addr) - 1)) then
                                        r_wr_addr   <= (others => '0');
                                    else
                                        r_wr_addr   <= r_wr_addr + 1;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end loop;
                    s_status <= "01";

                when others =>
                    s_status <= "11";

            end case;
        end if;
    end process P_FSM;

    -- Habilitación de configuraciones (combinacional)
    P_EN_WR_CONFIG : process
    begin
        for i in 0 to (G_PWM_N - 1) loop
            s_en_wr_config(i) <= PWM_TOP_OUTPUTS_I(i).en_wr_config and PWM_TOP_OUTPUTS_I(i).en_wr_config_red_1 and PWM_TOP_OUTPUTS_I(i).en_wr_config_red_2;
        end loop;
    end process P_EN_WR_CONFIG;

end architecture beh;