//////////////////////////////////////////////////////////////////////////////////
// Módulo: pwm_enjoyer_axi_tb
// Autor: Alejandro Martínez Salgado
// Fecha de creación: 14.12.2025
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

// import axi_vip_pkg::*;  // NOTE : En Vivado 2024.2 esta librería está enlazada directamente
import pwm_enjoyer_axi_vip_bd_axi_vip_0_0_pkg::*;

module pwm_enjoyer_axi_tb();

    // Puertos
    bit         aclk_i;
    bit         aresetn_i;
    bit[31:0]   pwms_o;
    bit[2:0]    status_o;

    // Reloj
    time clk_period = 8ns;

    // Señales
    typedef enum logic [4:0] {
        IDLE,
        TEST_1_1,
        TEST_1_2,
        TEST_2,
        TEST_3,
        TEST_4_1,
        TEST_4_2,
        TEST_5,
        TEST_6,
        TEST_7,
        TEST_8,
        TEST_9_1,
        TEST_9_2,
        TEST_10_1,
        TEST_10_2,
        TEST_11_1,
        TEST_11_2,
        TEST_11_3,
        TEST_12,
        TEST_13,
        TEST_14
    } test_t;
    test_t              test = IDLE;
    bit[1:0] 	        resp;
    parameter bit[31:0] addr_direcciones    = 32'h0000_0000;
    parameter bit[31:0] addr_control        = 32'h0000_0004;
    parameter bit[31:0] addr_wr_data        = 32'h0000_0008;
    parameter bit[31:0] addr_wr_data_valid  = 32'h0000_000C;
    parameter bit[31:0] addr_n_addr         = 32'h0000_0010;
    parameter bit[31:0] addr_n_tot_cyc      = 32'h0000_0014;
    parameter bit[31:0] addr_pwm_init       = 32'h0000_0018;
    parameter bit[31:0] addr_redundancias   = 32'h0000_001C;
    parameter bit[31:0] addr_errores        = 32'h0000_0020;
    parameter bit[31:0] addr_status         = 32'h0000_0024;

    // UUT
    pwm_enjoyer_axi_vip_bd_wrapper UUT (
        .aclk_i     (aclk_i),
        .aresetn_i  (aresetn_i),
        .pwms_o     (pwms_o),
        .status_o   (status_o)
        );

    // Declaración del Agente VIP
    pwm_enjoyer_axi_vip_bd_axi_vip_0_0_mst_t   master_agent;
    
    // Reloj
    always #(clk_period/2) aclk_i = ~aclk_i;

    // Reset inicial
    initial begin
        aresetn_i = 0;
        #100ns
        aresetn_i = 1;
    end

    // Stimuli
    initial begin

        // Nuevo agente
        master_agent = new("Master VIP Agent",UUT.pwm_enjoyer_axi_vip_bd_i.axi_vip_0.inst.IF);

        // Inicio agente
        master_agent.start_master();

        // Esperar al reset
        wait (aresetn_i == 1'b1);
        #100ns

        /////////////////////////////////////////////////////////////////////////////
        // Test 1.1: Procedimiento normal (1 configuración)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_1_1;
        // PWM_0, 4 estados {1,5,3,1}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Apagar
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 1.2: Procedimiento normal (3 configuraciones)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_1_2;
        // PWM_0, 4 estados {1,5,3,1}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // PWM_0, 5 estados {1,1,10,4,1}, empezando a '0':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_0011, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0000, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // PWM_0, 3 estados {10,20,15}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_002D, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0014, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000F, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Apagar
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 2: Valores mínimos
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_2;
        // PWM_0, 2 estados {1,1}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0002, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_0002, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Apagar
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 3: Valores por debajo de mínimos
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_3;
        // PWM_0, 1 estados {1}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Apagar
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 4.1: Valores máximos (en N_ADDR)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_4_1;
        // PWM_0, 128 estados {desde 1 hasta 128}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0080, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_2040, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        for (int i = 0; i < 128; i++) begin
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001 + i, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
        end
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #1ms
        // Apagar
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        #500us

        /////////////////////////////////////////////////////////////////////////////
        // Test 4.2: Valores máximos (en N_TOT_CYC)
        // NOTE : Demasiado largo para el simulador
        // TODO : Probar
        /////////////////////////////////////////////////////////////////////////////
        // test = TEST_4_2;
        // // PWM_0, 2 estados {FFFF_0000, 0000_FFFF}, empezando a '1':
        // master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0002, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'hFFFF_FFFF, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'hFFFF_0000, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        // #(clk_period)
        // master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_FFFF, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        // #(clk_period)
        // // Actualizar
        // master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        // #60s
        // // Apagar
        // master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        // #60s

        /////////////////////////////////////////////////////////////////////////////
        // Test 5: Valores por encima de máximos: supera N_ADDR
        // NOTE : Salta error de compilador
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        // test = TEST_5;
        // // PWM_0, 129 estados {desde 1 hasta 129}, empezando a '1':
        // master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0081, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_20C1, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        // for (int i = 0; i < 129; i++) begin
        //     master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001 + i, resp);
        //     master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        //     #(clk_period);
        // end
        // // Actualizar
        // master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        // #1ms
        // // Apagar
        // master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        // master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        // #500us

        /////////////////////////////////////////////////////////////////////////////
        // Test 6: Puesta en marcha y apagado simultáneos
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_6;
        // PWM_0, PWM_1 y PWM_2, 100 estados {desde 100 hasta 1}, empezando a '0':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0007, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0064, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_13BA, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0000, resp);
        for (int i = 100; i > 0; i--) begin
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0000 + i, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
        end
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #1ms
        // Apagar
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0007, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        #500us

        /////////////////////////////////////////////////////////////////////////////
        // Test 7: Puesta en marcha y apagado secuenciales
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_7;
        for (int i = 0; i < 4; i++) begin
            // PWM_i, 4 estados {1,5,3,1}, empezando a '1':
            master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0000 + 2**i, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000A, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
            // Actualizar
            master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
            #(clk_period);
        end
        #50us
        for (int i = 0; i < 4; i++) begin 
            // Apagar
            master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0000 + 2**i, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
            #(clk_period);
        end
        #50us;

        /////////////////////////////////////////////////////////////////////////////
        // Test 8: Shutdown
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_8;
        for (int i = 0; i < 4; i++) begin
            // PWM_i, 4 estados {1,5,3,1}, empezando a '1':
            master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0000 + 2**i, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000A, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
            master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
            #(clk_period);
            // Actualizar
            master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
            #(clk_period);
        end
        #50us
        // Apagar todo
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0001, resp);
        #50us;

        /////////////////////////////////////////////////////////////////////////////
        // Test 9.1: Configuración incoherente por N_ADDR (menor de lo esperado)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_9_1;
        // PWM_0, 3 estados {1,5,3}, aunque se esperan 4, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_0009, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 9.2: Configuración incoherente por N_ADDR (mayor de lo esperado)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_9_2;
        // PWM_0, 5 estados {1,5,3,3,1}, aunque se esperan 4, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000D, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 10.1: Configuración incoherente por N_TOT_CYC (menor de lo esperado)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_10_1;
        // PWM_0, 4 estados {1,5,3,1}, empezando a '1'. Suma escrita =  11:
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000B, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 10.2: Configuración incoherente por N_TOT_CYC (mayor de lo esperado)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_10_2;
        // PWM_0, 4 estados {1,5,3,1}, empezando a '1'. Suma escrita =  9:
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_0009, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 11.1: Secuencia de programación incorrecta (config > update > update > config > update)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_11_1;
        // PWM_0, 4 estados {1,5,3,1}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Actualizar (anticipado)
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // PWM_0, 3 estados {10,20,15}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_002D, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0014, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000F, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Apagar
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 11.2: Secuencia de programación incorrecta (config > update > con//update//fig > update)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_11_2;
        // PWM_0, 4 estados {1,5,3,1}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // PWM_0, 3 estados {10,20,15}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_002D, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0014, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
            // Actualizar (anticipado)
            master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
            #50us
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000F, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Apagar
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 11.3: Secuencia de programación incorrecta (config > update > config//update)
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_11_3;
        // PWM_0, 4 estados {1,5,3,1}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // PWM_0, 3 estados {10,20,15}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_002D, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0014, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000F, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        // Actualizar (sin wait clk_period previo)
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Apagar
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0002, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 12: Carga de configuraciones seguidas sin actualización intermedia
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_12;
        // PWM_0, 4 estados {1,5,3,1}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        #50us
        // PWM_0, 3 estados {10,20,15}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_002D, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0014, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000F, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us

        /////////////////////////////////////////////////////////////////////////////
        // Test 13: Redundancias
        // TODO : TBD
        /////////////////////////////////////////////////////////////////////////////

        /////////////////////////////////////////////////////////////////////////////
        // Test 14: Reset
        // * PASSED
        /////////////////////////////////////////////////////////////////////////////
        test = TEST_14;
        // PWM_0, 4 estados {1,5,3,1}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0004, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0005, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us
        // Reset
        aresetn_i = 0;
        #(clk_period)
        aresetn_i = 1;
        #50us
        // PWM_0, 3 estados {10,20,15}, empezando a '1':
        master_agent.AXI4LITE_WRITE_BURST(addr_direcciones,      0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0008, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_addr,           0, 32'h0000_0003, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_n_tot_cyc,        0, 32'h0000_002D, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_pwm_init,         0, 32'h0000_0001, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000A, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_0014, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data,          0, 32'h0000_000F, resp);
        master_agent.AXI4LITE_WRITE_BURST(addr_wr_data_valid,    0, 32'h0000_0001, resp);
        #(clk_period)
        // Actualizar
        master_agent.AXI4LITE_WRITE_BURST(addr_control,          0, 32'h0000_0004, resp);
        #50us

        $finish;
    end

endmodule