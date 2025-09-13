# Automation Systems

This section documents critical workflow automations (HW & SW), scripts, and bots that support business operations.

---

## PulseBox

PulseBox is A general-purpose gearbox scaler for encoders, that can used in machines to match sensors with the exact requirements of controllers. This is currently installed at TOP 4, EGA Iron Sheet line.

Find details [here](./PulseBox/)

---

## TOP ID

TOP ID is a batch ID generation and entry automation system.

Find details [here](./TOP%20ID/)

---

## Kashear

Kashear is an automation bridge between Odoo, CNET, and POS that eliminates errors, speeds up processes, and transforms finance staff from clerks into strategic contributors. It enables accurate, scalable, and future-ready sales operations.

Watch Kashear in action [here](https://youtube.com/shorts/5uMb_Zu7hSY)
Find details [here](./Kashear/)

---

## PeachPal

PeachPal is an automation toolkit for Peachtree that bridges import limitations, accelerates system setup, and eliminates clerical manual posting.
Current implementation supports:

- Customer Beginning Balance Entry
- Vendor Beginning Balance Entry
- Inventory Balance Entry
- Trial Balance Entry

Watch PeachPal in action [here](https://youtu.be/Naj-vUEagPI)
Find details [here](./PeachPal/)

---

## Blink

Blink is an instant link between banks and ERP, that makes financial data flow seamlessly into your system. It cuts down entry time from 6-8 hours down to just 3 minutes.

Watch Blink in action [here](https://youtu.be/g9lDs_T_Biw)
Find details [here](./Blink/)

---

## Loj SO Engine

Loj SO Engine is a Sales Order (SO) digitizer, authorizer, reformatter, and printer automation tool. It listens to quotations issued for print, grabs their details (from an .xml file generated), generates an SO with a digital signature of the issuer (salesperson) and stamp of the company, makes copies for Finance & Store and sends it to a configured printer directly.

Find details [here](./Loj%20SO%20Engine/)
Add Issuers' Digital Signatures to SO Engine [here](https://youtu.be/sE7V-jnQYKo)
Loj SO Engine can also be used to generate (not print) an SO Sketch (for new customers) like [this](https://youtu.be/5R37gigpQQU). **NOTE:** to do this, the value of plate number must be exactly `#####`

---

## Loj Insights

Loj Insights analyzes sales data & seamlessly integrates with Odoo to generate actionable reports automatically. It's a hands-free, automatic, seamless, organized, accurate, and super fast report generation that includes details like product, partner, volume, and revenue.

Find details [here](./Loj%20Insights/)
Note: Task Scheduler is used to run Loj Insights through a [script](./Loj%20Insights/script/run_loj_insights.bat)

---

## TOP Insights

TOP Insights is a manufacturing productivity system that captures real-time machine data from sensors installed on machines in production line and intelliently translates it into actionable insights to optimize operations and identify bottlenecks, using continuous monitoring and analytics to highlight inefficiencies and guide improvements.

Find details [here](./TOP%20Insights/)
Note: You'll need to extract [node_modules](./TOP%20Insights/Code/ti-server/node_modules.zip) before use.

---

## TOP CAM

TOP CAM is a Cabinet Access Management SW & HW primarily intended to secure electrical cabinets.

Find details [here](./TOP%20CAM/)

---

## AutoPal

AutoPal is an automation solution for Hollow Steel Welder which makes use of manual mode switches (Forward, Reverse, Cut) to turn the operation to Automatic.

Note: Should only be used if the gantry holding the cutter can move while the cutter can move up and down simultaneously.

Find details [here](./AutoPal/)

---

## Fleet Fuel Log Analyzer

Fleet Fuel Log Analyzer analyzes fuel log exported from MaYet systems to estimate probable fuel filling instances and sudden fuel drops.

Note: Don't assume the figures to be 100% accurate unless the input logs are just as accurate.

Find details [here](./Fleet%20Fuel%20Log%20Analyzer/)

---
