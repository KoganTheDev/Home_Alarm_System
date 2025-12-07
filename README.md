# 🏠🔔 Home Alarm System – VHDL Implementation  
**Altera–Quartus II v20.1 | ModelSim-Altera | Embedded Systems Project**

## ✨ Overview
This project implements a modular **Home Alarm System** using **VHDL** as part of the *Embedded Computer Systems* course

The system simulates a realistic home-security mechanism composed of several hardware modules:
- Debounced sensor reading  
- Intrusion detection logic  
- User button press interpretation (short/long → bit generation)  
- Code register for alarm cancelation  
- 7-segment display state output  

All modules include:
- A clean VHDL implementation  
- A dedicated Test Bench  
- Verified functionality via ModelSim-Altera  
- Asynchronous reset support  

---

## 🧩 Features
- ✔️ Debounce logic with configurable filter window  
- ✔️ Detection of intrusion when **two or more sensors** are triggered  
- ✔️ Measurement of button press duration to generate bits  
- ✔️ N-bit secret code validation  
- ✔️ State output to 7-segment display  
- ✔️ Gate-level simulation support  
- ✔️ Modular project structure suitable for FPGA synthesis  

---

## 📚 Table of Contents
1. [Project Structure](#project-structure)  
2. [System Architecture](#system-architecture)  
3. [Authors](#authors)  

---

## 📁 Project Structure

---

## 🖼 System Architecture

### **Complete Alarm System Block Diagram**

```
 ┌────────────────────────┐
 │      Sensors_logic     │
 │ (Debounce + Detection) │
 └──────────┬─────────────┘
            │ detected
            ▼
 ┌────────────────────────┐
 │ Press_duration_measure │
 │ (Short=0, Long=1)      │
 └──────────┬─────────────┘
            │ bit + valid
            ▼
 ┌────────────────────────┐
 │     Code_register      │
 │  (N-bit code storage)  │
 └──────────┬─────────────┘
            │ state_code
            ▼
 ┌────────────────────────┐
 │     Display_data       │
 │   (7-seg conversion)   │
 └────────────────────────┘
```

The system architecture is fully modular, allowing each component to be tested independently before integration.

---

# 🧪 Simulation Examples

(*Place ModelSim screenshots here in your submission PDF*)

Recommended screenshots:

* Debounce waveform
* Intrusion detection
* Short vs long press timing
* N-bit code collection
* Correct/incorrect code match
* 7-segment display output transitions

---

# 👥 Authors

* **Yuval Kogan**
* **Roni Shifrin**