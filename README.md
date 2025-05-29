# VHDL Template for DES-CEI Students

This repository provides a simple VHDL template for students, offering a starting point for RTL simulation or Field-Programmable Gate Array (FPGA) implementation. Whether you are new to VHDL or looking for a quick setup, this template aims to streamline the process of creating and organizing VHDL projects with Git.

## Getting Started

To use this VHDL template, follow the instructions based on your operating system: Linux or Windows.

### Build the Vivado project in Linux (recommended)

Before using the Make tool you need to export Vivado to the path doing:

```bash
    source ./<pathToXilinxInstallation>/Vivado/<version>/settings64.sh
```

1. Open a terminal and navigate to the repository directory.
2. Run the following command to create and open the Vivado project:

    ```bash
    make
    ```

3. Vivado will be launched, and a new project named 'VHDL_project' will be created and opened.

Run the help command to display the available make rules:

```bash
    make help
```

### Build the Vivado project in Windows

1. Create a folder named 'build' in the repository directory.
2. Open Vivado and navigate to the 'build' folder using the TCL Console on the botton left:

    ```tcl
    cd C:\<pathToRepository>/build/
    ```

3. In the Vivado Tcl Console, execute the following command to create the project:

    ```tcl
    source ../scripts/create_project.tcl
    ```

4. Vivado closes after the project is created.
5. Reopen Vivado and open the project named 'VHDL_project'.

## Project Structure

The template follows a structured layout to enhance organization and ease of use. Key directories include:

- **rtl:** Contains VHDL source files.
- **tb:** Includes simulation-related files.
- **scripts:** Holds scripts for project creation and any additional automation.
- **build:** Used for project-related files and outputs.

Feel free to modify the template based on your project requirements.

## How to add new files to the project

1. Create the new file in the corresponding folder (`rtl/`, `tb/`, or `constr/`).
2. Include the file in `scripts/create_project.tcl`.
3. Do `make clean` (Linux) or delete the `build/` folder.
4. Rebuild the project.
