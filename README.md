# ALU-8bit

An 8-bit Arithmetic Logic Unit implemented in Verilog.  
This project supports various arithmetic operations including **addition, subtraction, multiplication, and division**, designed using advanced architectures like **Carry Lookahead Adders (CLA)**, **Booth’s multiplier**, and **SRT division**.

---

## 🧠 Features

### ✔️ Supported Operations:
- ➕ **Addition**: Implemented using a **ML-CLA (Multi-Level Carry Lookahead Adder)**.
- ➖ **Subtraction**: Built using a **1-bit adder cell**.
- ✖️ **Multiplication**: Utilizes **Booth’s radix-4 algorithm**.
- ➗ **Division**: Uses **SRT radix-2 division algorithm**.
- 🔁 **Control Unit**: Handles operation selection via control signals.

---

## 📁 Project Structure

| File / Folder          | Description |
|------------------------|-------------|
| `alu.v`                | Top-level ALU module with operation control |
| `alu.v.bak`            | Backup of ALU with earlier implementation |
| `mlcla.v`              | Multi-level Carry Lookahead Adder module |
| `mlcla.v.bak`          | Backup of `mlcla.v` |
| `_9bitadder.v`         | 9-bit adder module used in CLA |
| `multiplier8bit.v`     | Trial Multiplier based on Booth’s algorithm |
| `multiplier8bit.bak`   | Backup version of trial Booth multiplier |
| `newbooth.v`           | Booth’s radix-4 implementation |
| `newbooth.v.bak`       | Earlier prototype of Booth module |
| `sr2.v`                | SRT division module |
| `sr2.v.bak`            | Backup of division unit |
| `cu.v`                 | Control unit for operation selection |
| `design.png`           | High-level architecture block diagram |
| `README.md`            | Project documentation |


---

## ⚙️ Operation Control

The ALU takes in an **opcode** to determine the operation:

| Opcode | Operation      |
|--------|----------------|
| 000    | Addition        |
| 001    | Subtraction     |
| 010    | Multiplication  |
| 011    | Division        |
| ...    | Extendable      |

The control unit (`cu.v`) decodes the opcode and routes signals to the proper module.

