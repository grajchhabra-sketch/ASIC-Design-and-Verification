import subprocess

vivado_cmd = [
    r"C:\vivado\2025.1\Vivado\bin\vivado.bat",
    "-mode",
    "batch",
    "-source",
    "run_soc.tcl"
]

print("Running Vivado TCL automation...")

result = subprocess.run(
    vivado_cmd,
    capture_output=True,
    text=True
)

print(result.stdout)

with open("vivado_log.txt", "w") as f:
    f.write(result.stdout)

print("Done.")
