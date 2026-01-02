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
        G_PWM_N     : natural := 32     -- Número máximo de módulos PWM. Si hay más de 32 hay que añadir más registros (*)
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
    end component config_error;

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    constant C_CEROS    : std_logic_vector(31 downto 0) := (others => '0');
    constant C_UNOS     : std_logic_vector(31 downto 0) := (others => '1');

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
    signal s_unlocked       : std_logic_vector((G_PWM_N - 1) downto 0);

    -- Máquina de estados
    type fsm is (S_IDLE, S_SHUTDOWN, S_APAGAR, S_ACTUALIZAR, S_CONFIGURAR, S_UNKOWN);
    signal s_estado         : fsm;
    signal r_wr_addr        : unsigned((PWM_TOP_INPUTS_O(0).wr_addr'length - 1) downto 0);
    signal s_status         : std_logic_vector(2 downto 0);
    signal s_invalid_n_addr : std_logic;
    signal s_pwm_activos    : std_logic_vector((G_PWM_N - 1) downto 0);
    signal s_pwm_apagando   : std_logic_vector((G_PWM_N - 1) downto 0);
    signal s_pwm_apagados   : std_logic_vector((G_PWM_N - 1) downto 0);
    
    -- Detección de flancos
    signal s_estado_d1      : fsm;

    -------------------------------------------------
    -- ILA
    -------------------------------------------------
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of r_direcciones       : signal is "true";
    attribute MARK_DEBUG of r_control           : signal is "true";
    attribute MARK_DEBUG of r_wr_data           : signal is "true";
    attribute MARK_DEBUG of r_wr_data_valid     : signal is "true";
    attribute MARK_DEBUG of r_n_addr            : signal is "true";
    attribute MARK_DEBUG of r_n_tot_cyc         : signal is "true";
    attribute MARK_DEBUG of r_pwm_init          : signal is "true";
    attribute MARK_DEBUG of r_redundancias      : signal is "true";
    attribute MARK_DEBUG of r_errores           : signal is "true";
    attribute MARK_DEBUG of r_status            : signal is "true";
    attribute MARK_DEBUG of r_pwm_top_inputs    : signal is "true";
    attribute MARK_DEBUG of s_config_error      : signal is "true";
    attribute MARK_DEBUG of s_unlocked          : signal is "true";
    attribute MARK_DEBUG of s_estado            : signal is "true";
    attribute MARK_DEBUG of r_wr_addr           : signal is "true";
    attribute MARK_DEBUG of s_status            : signal is "true";
    attribute MARK_DEBUG of s_invalid_n_addr    : signal is "true";
    attribute MARK_DEBUG of s_pwm_activos       : signal is "true";
    attribute MARK_DEBUG of s_pwm_apagando      : signal is "true";
    attribute MARK_DEBUG of s_pwm_apagados      : signal is "true";
    attribute MARK_DEBUG of s_estado_d1         : signal is "true";

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    gen_config_err : for i in 0 to (G_PWM_N - 1) generate
        config_err_i : component config_error
            generic map (
                G_RST_POL           => C_RST_POL,
                G_MEM_SIZE_MAX_L2   => C_MEM_SIZE_MAX_L2,
                G_PERIOD_MAX_L2     => C_PERIOD_MAX_L2
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

    -- Estado propio de cada PWM
    gen_pwm_states : for i in 0 to (G_PWM_N - 1) generate
    begin
        s_pwm_activos(i)    <= '1' when (PWM_TOP_OUTPUTS_I(i).status = "11") else '0';
        s_pwm_apagando(i)   <= '1' when (PWM_TOP_OUTPUTS_I(i).status = "01") else '0';
        s_pwm_apagados(i)   <= '1' when (PWM_TOP_OUTPUTS_I(i).status = "00") else '0';
    end generate gen_pwm_states;

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
            r_wr_data_valid <= REG_WR_DATA_VALID_I(0);  -- Se resetea desde el wrapper AXI
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
                r_errores(i)        <= s_config_error(i) or (not s_unlocked(i)) or s_invalid_n_addr;
            end loop;
            r_status(2 downto 0)    <= s_status;
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
            r_wr_addr           <= (others => '0');
            s_status            <= "000";
            s_invalid_n_addr    <= '0';
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
                        end if;
                    end loop;

                    if (s_pwm_activos /= C_CEROS) then
                        s_status <= "011";
                    elsif (s_pwm_apagando /= C_CEROS) then
                        s_status <= "001";
                    elsif (s_pwm_apagados = C_UNOS) then
                        s_status <= "000";
                    end if;

                when S_APAGAR =>
                    -- for i in 0 to (G_PWM_N - 1) loop
                    --     if (r_direcciones(i) = '1') then
                    --         r_pwm_top_inputs(i).en <= '0';
                    --     end if;
                    -- end loop;
                    for i in 0 to (G_PWM_N - 1) loop
                        if (r_direcciones(i) = '1') then
                            r_pwm_top_inputs(i).en        <= '0';
                            r_pwm_top_inputs(i).upd_mem   <= '0';
                            r_pwm_top_inputs(i).wr_en     <= '0';
                            r_pwm_top_inputs(i).wr_addr   <= (others => '0');
                            r_pwm_top_inputs(i).wr_data   <= (others => '0');
                            r_pwm_top_inputs(i).n_addr    <= (others => '0');
                            r_pwm_top_inputs(i).n_tot_cyc <= (others => '0');
                            r_pwm_top_inputs(i).pwm_init  <= '0';
                        end if;
                    end loop;

                    if (s_pwm_activos /= C_CEROS) then
                        s_status <= "011";
                    elsif (s_pwm_apagando /= C_CEROS) then
                        s_status <= "001";
                    elsif (s_pwm_apagados = C_UNOS) then
                        s_status <= "000";
                    end if;

                when S_ACTUALIZAR =>
                    for i in 0 to (G_PWM_N - 1) loop
                        if (r_direcciones(i) = '1') then
                            -- Flanco de subida
                            if (s_estado_d1 /= S_ACTUALIZAR) then
                                if ((r_errores = C_CEROS) and (r_redundancias = C_CEROS)) then
                                    r_pwm_top_inputs(i).upd_mem <= '1';
                                    s_status    <= "011";
                                else
                                    s_status    <= "100";
                                end if;
                                r_wr_addr       <= (others => '0');
                            else
                                r_pwm_top_inputs(i).upd_mem <= '0';
                            end if;
                        end if;
                    end loop;

                when S_CONFIGURAR =>
                    if (to_integer(unsigned(r_n_addr)) > 1) then
                        s_invalid_n_addr <= '0';
                        for i in 0 to (G_PWM_N - 1) loop
                            if (r_direcciones(i) = '1') then
                                if (s_unlocked(i) = '1') then
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
                        s_status <= "010";
                    -- No debe permitir escribir en la memoria si N_ADDR < 2
                    else
                        s_invalid_n_addr    <= '1';
                    end if;
                            

                when others =>
                    s_status <= "100";

            end case;
        end if;
    end process P_FSM;

    -- Habilitación de configuraciones (combinacional)
    gen_pwm_outputs : for i in 0 to (G_PWM_N - 1) generate
    begin
        s_unlocked(i) <= PWM_TOP_OUTPUTS_I(i).unlocked and PWM_TOP_OUTPUTS_I(i).unlocked_red_1 and PWM_TOP_OUTPUTS_I(i).unlocked_red_2;
    end generate gen_pwm_outputs;

end architecture beh;