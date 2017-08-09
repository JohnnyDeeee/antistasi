/*
    Code that only runs on the server of a multiplayer game.
*/
if (!isMultiplayer) exitWith {};
if (!(isNil "serverInitDone")) exitWith {};

call compile preprocessFileLineNumbers "debug\init.sqf";
diag_log "[AS] Server MP: starting";
call compile preprocessFileLineNumbers "initFuncs.sqf";
diag_log "[AS] Server MP: initFuncs done";
call compile preprocessFileLineNumbers "initLocations.sqf";
diag_log "[AS] Server MP: initLocations done";
call compile preprocessFileLineNumbers "initVar.sqf";
diag_log "[AS] Server MP: initVar done";

["Initialize"] call BIS_fnc_dynamicGroups;

// tell every client that the server is ready to receive players (see initPlayerLocal.sqf)
serverInitVarsDone = true; publicVariable "serverInitVarsDone";
diag_log "[AS] Server MP: serverInitVarsDone";

waitUntil {(count playableUnits) > 0};
waitUntil {({(isPlayer _x) and (!isNull _x) and (_x == _x)} count allUnits) == (count playableUnits)};//ya estamos todos
[] execVM "modBlacklist.sqf";

addMissionEventHandler ["HandleDisconnect",{[_this select 0] call onPlayerDisconnect;false}];

maxPlayers = playableSlotsNumber west;
AS_commander = playableUnits select 0;
AS_commander setUnitRank "CORPORAL";
publicVariable "AS_commander";

if (serverName in servidoresOficiales) then {
    [] execVM "serverAutosave.sqf";
};
diag_log "[AS] Server MP: players are in";
publicVariable "maxPlayers";

hcArray = [];

//{if (owner _x != owner server) then {hcArray pushBack _x}} forEach entities "HeadlessClient_F";

if (!isNil "HC1") then {hcArray pushBack HC1};
if (!isNil "HC2") then {hcArray pushBack HC2};
if (!isNil "HC3") then {hcArray pushBack HC3};

HCciviles = 2;
HCgarrisons = 2;
HCattack = 2;
if (count hcArray > 0) then
    {
    HCciviles = hcArray select 0;
    HCgarrisons = hcArray select 0;
    HCattack = hcArray select 0;
    diag_log "[AS] Server MP: Headless Client 1 detected";
    if (count hcArray > 1) then
        {
        HCciviles = hcArray select 1;
        HCattack = hcArray select 1;
        diag_log "[AS] Server MP: Headless Client 2 detected";
        if (count hcArray > 2) then
            {
            HCciviles = hcArray select 2;
            diag_log "[AS] Server MP: Headless Client 3 detected";
            };
        };
    };

publicVariable "HCciviles";
publicVariable "HCgarrisons";
publicVariable "HCattack";
publicVariable "hcArray";

serverInitDone = true; publicVariable "serverInitDone";
diag_log "[AS] Server MP: serverInitDone";
