# J61 Mill Nutanix Cluster (MPMSNTXB) Shutdown Procedure

**Owner:** Michael Becker (mbecker@mpmaterials.com)
**Applies to:** J61 Mill Nutanix Cluster, MPMSNTXB, MPM Mine site
**Scripts:** [J61-Nutanix-Scripts repo](https://github.com/Mainframe79) — `ShutdownMill/`

## Overview

This is the procedure for shutting down the J61 Mill Nutanix cluster. It has two parts:

1. **Cluster and VM shutdown** — run entirely from **J61Tools01**, inside the **SCADA** network.
2. **Physical node power-down (IPMI)** — run from **MPMJMP01**, inside the **corporate** network. This step cannot be done from SCADA; IPMI/PCSV management of the nodes is only reachable from the corporate network.

Do not start part 2 until part 1 has fully completed.

## Access requirements

Before you begin, confirm you have:

- An admin (ring 2) account usable on both J61Tools01 and MPMJMP01.
- Membership in the Entra group **`EA - Bitwarden - IT Nutanix`**. This is required to retrieve the credentials used below from Bitwarden. If you are not in this group, request access before starting the shutdown.
- The following Bitwarden entries accessible to you:
  - `mpm mine prism central admin` — Prism Central local admin credential.
  - `mpm mill (mpmsntxb) IPMI access` — IPMI/PCSV credential for the physical nodes.

## Part 1 — Stop the cluster and VMs (run from J61Tools01, SCADA)

1. Log on to **J61Tools01**.
2. Open **PowerShell 7** (required — the Nutanix cmdlets do not work in Windows PowerShell 5.1).
3. Navigate to the `ShutdownMill` folder from the repo and run:
   ```
   .\ShutdownMill.ps1
   ```
4. When prompted, enter the Prism Central local admin credential from Bitwarden (`mpm mine prism central admin`).
5. The script connects to Prism Central and powers off all user VMs on the MPMSNTXB cluster. CVMs are intentionally left running at this point.
6. The script opens a new window and connects by SSH to a CVM. In that window:
   - Run `cluster stop` to stop the Nutanix cluster service.
   - Run `cluster status` to confirm the cluster has stopped.
   - Type `exit`, then close the window. The main script resumes once this window is closed.
7. The script then opens four more windows in sequence, one per node CVM (J61NTXB01A, J61NTXB01B, J61NTXB02A, J61NTXB02B). In **each** window:
   - Run `sudo shutdown now`.
   - Close the window once the CVM has shut down. The script moves to the next CVM only after the window is closed.
8. Once all four CVMs are shut down, the script will pause. Confirm in Prism/console that all four CVMs are powered off before continuing.

Part 1 is now complete. Do not proceed to Part 2 until all VMs, the cluster service, and all four CVMs are confirmed down.

## Part 2 — Power down the physical nodes via IPMI (run from MPMJMP01, corporate)

1. Log on to **MPMJMP01** (corporate network).
2. Open **PowerShell 7**.
3. Navigate to the `ShutdownMill\MPMJMP01-Use` folder from the repo and run:
   ```
   .\StopMillNodes.ps1
   ```
4. When prompted, enter the IPMI credential from Bitwarden (`mpm mill (mpmsntxb) IPMI access`).
5. The script issues an IPMI power-off command to all four physical nodes (192.168.210.15–18) and polls each one until it confirms power-off, printing a confirmation per node as it completes.

Once all four nodes report powered off, the J61 Mill cluster shutdown is complete.

## Rollback / notes

- If any step fails partway through, do not proceed to the next part — resolve the failure (e.g. confirm connectivity to the affected CVM/node) before continuing.
- Powering the cluster back on is a separate procedure and is not covered by these scripts.
