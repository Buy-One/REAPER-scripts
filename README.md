# REAPER-scripts
Lua scripts for Cockos' REAPER
</br>
</br>
[Complete list (323)](https://github.com/Buy-One/REAPER-scripts/wiki/SCRIPT-LIST)
</br>
</br>
**Many scripts feature user settings. Almost all include guide or description of features. Be sure to check those out and configure to your liking.**

## Ways to install the entire repo

#### Manual  
1. Download the repo zip archive via [THIS LINK](https://github.com/Buy-One/REAPER-scripts/raw/refs/heads/main/BuyOne%20Scripts.zip)
2. Unpack into the REAPER `/Scripts` directory.  
3. Import the scripts per script category folder into the `Main` section of the `Action list` via `New action -> Load ReaScript...` (the labels may differ depending on REAPER version).   
Scripts in the `MIDI Editor` folder are meant for use in the MIDI Editor thus must be imported into the `MIDI Editor` section of the `Action list` exclusively or in addition to their import into the `Main` section.  
Scripts in the `Media Explorer` folder are meant for use in the `Media Explorer` and must be imported into the `Media Explorer` section of the `Action list` exclusively or in addition to their import into the `Main` section.


#### Via REAPER package manager  
Supported since REAPER build 7.86. Only useful for the first ever install or if, when updating, you don't care about transferring your settings from the older to the newer versions of the scripts.  
1. Download [BuyOne Scripts.ReaperPkg](https://github.com/Buy-One/REAPER-scripts/raw/refs/heads/main/BuyOne%20Scripts.ReaperPkg) file (a zip archive with a custom extension).  
2. Drop it into REAPER and install via the package manager interface which will open automatically. 


#### Semi-automated  
Allows script batch installation and transfer of per script user settings from their older versions to the newer ones before updating the actual files. The only reliable way of updating scripts and retaining your user settings in scripts that include them. The scripts will be imported into the sections of the `Action list` designated for them by their author.  
1. Download the repo zip archive via [THIS LINK](https://github.com/Buy-One/REAPER-scripts/raw/refs/heads/main/BuyOne%20Scripts.zip)
2. Extract `BuyOne_Script updater and installer.lua` script from it and import into the `Main` section of the `Action list` via `New action -> Load ReaScript...` (the labels may differ depending on REAPER version).  
3. Refer to the detailed instructions inside that script.

</br>
</br>

To download an individual script:    
1. Enter the folder    
2. Click the script link  
3. Click "Raw" button in the upper right corner of the script window  
4. Download as normal  
5. Remove the .txt extension only leaving .lua  
6. Or use the download button which has appeared in the updated interface

</br>

If you don't use `BuyOne_Script updater and installer.lua` to transfer user settings to newer versions of scripts, then before manually updating scripts which include USER SETTINGS, in order to retain them overwrite the entire USER SETTINGS section in the newer version of the script with the one from the old one and only then overwrite the actual file.

</br>

**Scripts containinig META suffix in their name, when executed export individual scripts included in the META package into the directory they themeslves reside in AND automatically import them into the `Action list`.**

</br>

**Since this repo isn't compatible with ReaPack, if you have a Gihub account you can subscribe to the repo under the *Watch* button to be able to receive updates. To only get updates regarding new scripts and newer versions, under *Custom* submenu of the *Watch* menu enable only options *Pull requests* and *Releases*.** 

</br>
</br>
</br>

_REAPER is a DAW able to mimic the look and feel of other DAWs. If you so wish, with the ReaScript API, scheduled ProTools crashes can again be made integral part of your workflow._  
_I vibe code, i mean i code when i get a vibe._

