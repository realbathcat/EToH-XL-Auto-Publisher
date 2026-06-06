# EToH XL Auto Publisher

> keep `ROBLOSECURITY` and `ROBLOX_API_KEY` private. 
> **DO NOT POST THESE ANYWHERE!!!!!**

---

## how to use the auto publisher

### 1. setting up
press the green **code** button, and in the dropdown press **download zip** to download this repository

after downloading, unzip and open the folder
right click inside of it and press **open in terminal**

---

### 2. running the auto publisher
#### using powershell

```powershell
$env:ROBLOSECURITY = "blank"
$env:ROBLOX_API_KEY = "blank"
.\lune run publish.luau
```

#### using command prompt

```cmd
set ROBLOSECURITY = blank
set ROBLOX_API_KEY = blank
.\lune run publish.luau
```

`blank` is supposed to be replaced
