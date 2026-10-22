# J61 Nutanix Scripts

PowerShell scripts for shutting down the J61 Mill Nutanix cluster (**MPMSNTXB**) at the MPM Mine site.

## Repository layout

```
ShutdownMill/
├── ShutdownMill.ps1          # Main orchestrator script - run first
├── J61-MillClusterSvc.ps1    # Helper: stops the Nutanix cluster service
├── MPMSNTXB01-CVM.ps1        # Helper: shuts down CVM on node 1 (J61NTXB01A)
├── MPMSNTXB02-CVM.ps1        # Helper: shuts down CVM on node 2 (J61NTXB01B)
├── MPMSNTXB03-CVM.ps1        # Helper: shuts down CVM on node 3 (J61NTXB02A)
├── MPMSNTXB04-CVM.ps1        # Helper: shuts down CVM on node 4 (J61NTXB02B)
└── MPMJMP01-Use/
    └── StopMillNodes.ps1     # Run last, from MPMJMP01 - IPMI power-down of the physical nodes
```

## Where things run

| Script | Run from | Network |
|---|---|---|
| `ShutdownMill.ps1` (and its helper scripts in `ShutdownMill/`) | **J61Tools01** | SCADA |
| `MPMJMP01-Use\StopMillNodes.ps1` | **MPMJMP01** | Corporate |

All VM, cluster, and CVM shutdown steps are performed from **J61Tools01 inside SCADA**. The final step — powering down the physical nodes via IPMI — must be run separately from **MPMJMP01 in the corporate environment**, since IPMI/PCSV management is only reachable from there.

## What it does

1. **`ShutdownMill.ps1`** (run on J61Tools01):
   - Prompts for the Prism Central local admin credential (Bitwarden: `mpm mine prism central admin`).
   - Connects to Prism Central and powers off all user VMs on the `MPMSNTXB` cluster (CVMs are skipped).
   - Launches `J61-MillClusterSvc.ps1` in a new window, which SSHes to a CVM so you can run `cluster stop` / `cluster status`.
   - Launches each of `MPMSNTXB01-CVM.ps1` through `MPMSNTXB04-CVM.ps1` in turn, each SSHing to its CVM so you can run `sudo shutdown now`.
2. **`MPMJMP01-Use\StopMillNodes.ps1`** (run on MPMJMP01, after the above is complete):
   - Prompts for the IPMI credential (Bitwarden: `mpm mill (mpmsntxb) IPMI access`).
   - Powers off all four physical nodes via IPMI and waits for each to confirm it is powered down.

## Prerequisites

- PowerShell 7 (required for the Nutanix cmdlets).
- Nutanix cmdlets module, installed on J61Tools01 by running (as an elevated admin):
  ```
  E:\Nutanix\cmdlets\Install-NutanixCmdlets.ps1
  ```
- OpenSSH client capability (`Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0`).
- An admin (ring 2) account on J61Tools01 / MPMJMP01.
- Bitwarden access to the credentials referenced above — this requires membership in the Entra group **`EA - Bitwarden - IT Nutanix`**.

## Usage

See the Confluence runbook for the step-by-step shutdown procedure.
