# Industrial Machine Software

This section documents software solutions, installation guides, and configurations for industrial machinery, including tools and utilities for managing and operating equipment in manufacturing and production environments.

---

## TOP 1 Packer Machine Resources: Software and CF Card Image Creation

- **Issue**: Setting up or restoring the TOP 1 Packer machine requires correctly flashing a CompactFlash (CF) card with the proper firmware image.
- **Solution**: Use the PVITransfer tool to create a bootable CF card from the provided `.pil` firmware file.
  - **[Installation Guide (Video)](./TOP%201%20Packer%20Machine/TOP%201%20-%20Packer%20Machine%20Software%20-%20Compact%20Flash%20Disk%20Generation.mp4)**
  - **[Software](./TOP%201%20Packer%20Machine/B1740010PRO.rar)**
  - **Software Required**: `PVITransfer` (included in `B1740010PRO` package)
  - **Steps**:
    1. Extract the `B1740010PRO` archive to a local folder.
    2. Navigate to the `PVITransfer` folder and **Run PVITransfer.exe as Administrator**.
    3. Select the option: **"Create a Compact Flash"**.
    4. Under **Source file (.pil)**, click **Browse**.
    5. Navigate to the `B1740010PRO` folder and select `Transfer.pil`, then click **Open**.
    6. Under **Current disk**, click **Select disk** and choose the target CF card.
    7. Click **Generate disk**.
    8. Confirm any warning dialogs — **all data on the CF card will be erased**.
  - Once complete, insert the CF card into the TOP 1 Packer machine and power on.

---

## TOP 1 Encoder Machine Configuration

- **Issue**: Configuring the TOP 1 Encoder Machine requires proper software setup and IP address selection.
- **Solution**: Install and run the configuration software as administrator, then apply settings with the specified password and IP address.
  - **[Software](./TOP%201%20Encoder%20Machine/Software/Smartgraph_10.17.zip)**
  - **[Images](./TOP%201%20Encoder%20Machine/Images/)**
  - **[Installation Guide (Video)](./TOP%201%20Encoder%20Machine/Videos/LASER%20Encoder%20Machine%20-%20SmartGraph%20Software%20Operation%20-%20Date%20&%20Time%20Setting.mp4)**
  - **Software Required**: TOP 1 Encoder Machine configuration tool
  - **Password**: `2222`
  - **Steps**:
    1. Extract the `top1_encoder_software.zip` archive to a local folder.
    2. Navigate to the extracted folder and run the configuration tool executable **as Administrator**.
    3. Log in using the password: `2222`.
    4. Go to **File** > Select IP address (default: `192.168.1.1`).
    5. Navigate to **Template**, make necessary edits, and click **Save**.
    6. Click **Start** to apply the configuration.
  - **Note**: Ensure the machine is connected to the network with the selected IP address before starting.

---
