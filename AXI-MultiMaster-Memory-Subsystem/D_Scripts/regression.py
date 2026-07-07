import subprocess
from pathlib import Path

vivado = r"C:\vivado\2025.1\Vivado\bin\vivado.bat"

project_dir = Path(r"C:\vivado\vending\AXI_SOC")

tcl_script = project_dir / "scripts" / "run.tcl"

log_file = project_dir / "simulation.log"

print("=" * 50)
print("      AXI SOC AUTOMATION")
print("=" * 50)
print("Starting Vivado...\n")

with open(log_file, "w") as log:
    result = subprocess.run(
        [
            vivado,
            "-mode",
            "batch",
            "-source",
            str(tcl_script)
        ],
        cwd=str(project_dir),
        stdout=log,
        stderr=subprocess.STDOUT,
        text=True
    )

print("\nSimulation Finished")
print("Simulation Log :", log_file)

if result.returncode == 0:
    print("STATUS : PASS")
else:
    print("STATUS : FAIL")

print("=" * 50)
