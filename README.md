# EToH XL Auto Publisher

> **read:** keep `.ROBLOSECURITY` and `ROBLOX_API_KEY` private
> **DO NOT POST THESE ANYWHERE!!!!!**

---

## how to use the auto publisher

### 1. setting up
press the green **code** button, and in the dropdown press **download zip** to download this repository

after downloading, unzip and open the folder
right click inside of it and press **open in terminal**

---

### 2. running the auto publisher
run these commands in powershell
```powershell
$env:ROBLOSECURITY = "blank"
$env:ROBLOX_API_KEY = "blank"
.\lune run publish.luau
