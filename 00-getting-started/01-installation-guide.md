# 📘 Installation Guide

Welcome to SQL Fundamentals to Advanced!

This guide will help you set up everything you need to start learning SQL using **Microsoft SQL Server**.

---

## 🎯 What You Will Learn
- How to install Microsoft SQL Server (Windows, Mac, Linux)
- How to install SQL Server Management Studio (SSMS) or Azure Data Studio
- How to verify your installation

---

## ✅ Step 1: Install Microsoft SQL Server

### Windows
1. Go to the [SQL Server Downloads page](https://www.microsoft.com/en-us/sql-server/sql-server-downloads).
2. Download the **Developer** or **Express** edition (both are free).
3. Run the installer and follow the prompts (choose "Basic" for a quick setup).
4. Set a password for the `sa` (system administrator) account when prompted.

### Mac & Linux
- Microsoft SQL Server runs natively on Linux, but not on Mac. For Mac, use Docker.

#### Linux (Ubuntu example)
```sh
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo add-apt-repository "$(curl -sSL https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/mssql-server-2019.list)"
sudo apt-get update
sudo apt-get install -y mssql-server
sudo /opt/mssql/bin/mssql-conf setup
```

#### Mac (using Docker)
1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/).
2. Run this command:
   ```sh
   docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=YourStrong!Passw0rd' -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
   ```
3. Connect using `localhost`, user `sa`, and the password you set.

---

## ✅ Step 2: Install a SQL Client

- **SQL Server Management Studio (SSMS)** (Windows only): [Download here](https://aka.ms/ssms)
- **Azure Data Studio** (Windows, Mac, Linux): [Download here](https://aka.ms/azuredatastudio)

Choose one and install it. Both are free.

---

## ✅ Step 3: Verify Installation

1. Open your SQL client (SSMS or Azure Data Studio).
2. Connect to your local SQL Server (server: `localhost`, user: `sa`, password: the one you set).
3. Run this test query:

```sql
SELECT @@VERSION;
```

You should see the SQL Server version info.

---

## 🧠 Notes & Tips
- Remember your `sa` password!
- If you have issues, check the official docs or ask for help in the course community.
- You can uninstall/reinstall SQL Server at any time if needed.

---

Ready? Move on to the next step: [Database Setup](./02-database-setup.md)
