-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
--[[
This documentation describes the behavior and methods of writing user profiles 
]]

-------------------------------------------------------------------------------
-- Conception and Basics
-------------------------------------------------------------------------------
--[[
TellMeWhen initiates the frame editor with self API, and 'The Action' loads own API

API (Application Programming Interface)
Both TellMeWhen and The Action API's are used for profiles and they are shared betwen themselves
You can't edit these addons (but you can edit API through own snippets) because if you will make changes then in the next time of update through ProfileInstall they will be overwritten by github version
If you want to use github updates and at same time own changed API then you will need use global 'Snippets' (look about that below, in title 'About profile')

About TMW.db
This is DataBase is used to store your profile and his settings for TellMeWhen 

About DataBase 
DataBase stores on the following path **World of Warcraft\WTF\Account\YOUR ACCOUNT NAME\SavedVariables\TellMeWhen.lua** which is used to Export and share your all profiles, settings with other people by ProfileInstall and they can Import it by your exported file (we will return to this moment at the end of the documentation steps)

About profile 
---
When you login in game you can open TMW by chat command /tmw options and enter in TMW interface. Then go to 'General' tab then 'Main Options' (or 'Main Settings') and here is at the top you will see dropdown menu with current name of profile and below options 'Write Name' (to create new profile), 'Copy', 'Delete'. This is TMW.db
Also there are 'LUA Snippets' (or just 'Snippets') tab which will be used for 'The Action' and you're not limited to use it only for that, you can use it for HeroLib API (if it's available for Classic) and any your own lua. This is optional because you can create profile without known lua skills 
Snippets are 'Profile Snippets' and 'Global Snippets':
* 'Profile Snippets' is local which means what they are attached only for CURRENT profile 
* 'Global Snippets' is super global (TMW.db.global) which means they are attached for EACH profile. If you want to use custom API then use global 

Profile must have specific one local group. The groups are same like 'Snippets' - local and global
That specific group must be named "Shown Main" without quotes, it must contain 8 icons inside and should be in the upper left corner of the screen, like [1][2][3][4][5][6][7][8] ([1]-[8] columns in the single one row), type of group must be "Icon"
* [1] is AntiFake CC rotation (limited, usually is single color like 0x00FF00 which is green)
* [2] is AntiFake Kick rotation (racial, primary specialization interrupt spell)
* [3] is Rotation (supports all actions)
* [4] is Secondary rotation (supports all actions)
* [5] is Trinket rotation (racial, specialization spells which can remove CC)
* [6] is Passive rotation (limited actions, usually @player, @party1, @raid1, @arena1)
* [7] is Passive rotation (limited actions, usually @party2, @raid2, @arena2)
* [8] is Passive rotation (limited actions, usually @party3, @raid3, @arena3)
Passive rotation doesn't require START button use like it does [1] -> [5] rotations 
"Shown Main" in group settings must have x-29, y12, scale 60% and both padding to the left upper corner 

This group must be first group at the top of group list e.g. TellMeWhen_Group1 ("Shown Main"). Rest after that doesn't matter at all, you can use own groups like to display at the middle of the center on your screen next rotation action to use with graphic mode PvE PvP and etc 
Each icon in this group must be as 'meta icon' type (this is green eye)

Also your name of profile must be different than that ProfileInstall Import (from server) has, because if your name will be same it will be overwritten by server version, use own name, like [GGL] My Profile 
---

Hard to figure? 
Let's make it easier, I prepared template profile named '[GGL] Basic', you can create new profile with own name and then use 'Copy' from '[GGL] Basic' which will make for you prepared for 'The Action' API that group. So when that is done you can build own routine now.
]]

-------------------------------------------------------------------------------
-- Summarize
-------------------------------------------------------------------------------
--[[
Begin starts by profile create: Write in chat /tmw options go to 'General' then 'Main Options' (or 'Main Settings') and there are at the top you will see dropdown menu with current name of profile and below options 'Write Name' (to create new profile), 'Copy'

Use template profile named '[GGL] Basic' with own name either keep in mind and follow by the next tips:
1. Your profile name must be different than it has loaded from ProfileInstall > Import TellMeWhen (from server)
2. Your profile must have first group with name "Shown Main"
3. "Shown Main" must have 8 icons with type "meta icon" and group type "Icon" in only 1 row at the left upper corner of your screen
4. "Shown Main" in group settings must have x-29, y12, scale 60% and both paddings to the left upper corner 
]]