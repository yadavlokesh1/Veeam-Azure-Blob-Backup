# Veeam -> Azure Blob Backup Automation

> **The problem**: Storing backups on the same cloud as your workload means a single provider outage takes down both your production environment and your recovery point — leaving you with nothing to restore from.
> **The solution:** A scheduled, automated pipeline that takes Veeam file-level backups on an AWS EC2 instance and ships them to Azure Blob Storage — cross-cloud, zero human intervention.

---

## Why This Exists

In enterprise environments, backup jobs run on-prem or on a single cloud. If that environment goes down, so does your recovery point. This project solves a real operational risk: **what happens when your backup target is in the same environment as your failure?**

This pipeline separates the backup source (AWS EC2) from the backup target (Azure Blob Storage) — two different cloud providers, two different failure domains.

---

## Architecture

```
┌─────────────────────┐         ┌──────────────────────────┐
│   AWS EC2 (Windows) │         │   Azure Blob Storage     │
│                     │         │                          │
│  Veeam Agent        │─AzCopy─▶│  Container: veeam-backups│
│  ↓                  │  HTTPS  │                          │
│  C:\BackUp-Folder\  │         │  Cool Access Tier        │
└─────────────────────┘         └──────────────────────────┘
         ↑
  Task Scheduler
  (Daily trigger)
```

**Stack:** Veeam Agent for Windows · AzCopy v10 · PowerShell · Azure Blob Storage (Cool tier) · AWS EC2 Windows Server 2022

---

## What the Script Does

1. Veeam Agent takes a file-level backup to a local folder on EC2
2. PowerShell script invokes AzCopy to sync that folder to Azure Blob
3. Timestamped log written locally for audit trail
4. Task Scheduler triggers this daily — no manual steps

---

## Setup

### Prerequisites
- Veeam Agent for Windows (free tier works)
- AzCopy v10 installed on the Windows host
- Azure Storage Account with a Blob container
- SAS token with Read, Write, List, Create permissions

### Configuration

Clone the repo and create a `config.ps1` file (not committed — see `.gitignore`):

```powershell
$AZCOPY_PATH = "C:\Tools\azcopy.exe"
$BACKUP_SOURCE = "C:\BackUp-Folder\"
$BLOB_SAS_URL = "https://YOUR_STORAGE.blob.core.windows.net/veeam-backups?YOUR_SAS_TOKEN"
```

### Run Manually

```powershell
.\Veeam-AzureBlob-Sync.ps1
```

### Schedule It

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\Projects\Veeam-Azure-Backup\Veeam-AzureBlob-Sync.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2:30PM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "VeeamAzureSync" -RunLevel Highest
```

---

## Security Notes

- SAS token is scoped to a single container — not the entire storage account
- IP restriction applied on SAS token (EC2 public IP only)
- Token expiry set — rotate before expiry
- Credentials never hardcoded in committed files

---

## Results

- Backup files successfully transferred cross-cloud (AWS → Azure)
- Verified via Azure Portal — files visible in `veeam-backups` container
- AzCopy transfer logs confirm 0 failures

---

## Author

**Lokesh Yadav** — Infrastructure Specialist | Windows Server · VMware · Nutanix · Azure  
