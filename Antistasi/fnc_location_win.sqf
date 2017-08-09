#include "macros.hpp"
AS_SERVER_ONLY("fnc_location_win.sqf");
params ["_location", ["_player", objnull]];

if (_location call AS_fnc_location_side == "FIA") exitWith {
	diag_log format ["[AS] Error: AS_fnc_location_win called from FIA location '%1'", _location];
};
private _posicion = _location call AS_fnc_location_position;
private _type = _location call AS_fnc_location_type;
private _size = _location call AS_fnc_location_size;

{
	if (isPlayer _x) then {
		[5,_x] call AS_fnc_changePlayerScore;
		[[_location], "intelFound.sqf"] remoteExec ["execVM", _x];
		if (captive _x) then {[_x,false] remoteExec ["setCaptive",_x]};
	}
} forEach ([_size,0,_posicion,"BLUFORSpawn"] call distanceUnits);

private _flag = objNull;
private _dist = 10;
while {isNull _flag} do {
	_dist = _dist + 10;
	_flag = (nearestObjects [_posicion, ["FlagCarrier"], _dist]) select 0;
};
[[_flag,"remove"],"AS_fnc_addAction"] call BIS_fnc_MP;
_flag setFlagTexture "\A3\Data_F\Flags\Flag_FIA_CO.paa";

sleep 5;
[[_flag,"unit"],"AS_fnc_addAction"] call BIS_fnc_MP;
[[_flag,"vehicle"],"AS_fnc_addAction"] call BIS_fnc_MP;
[[_flag,"garage"],"AS_fnc_addAction"] call BIS_fnc_MP;

[_location,"side","FIA"] call AS_fnc_location_set;

[_location] remoteExec ["patrolCA", HCattack];

if (_type == "airfield") then {
	[0,10,_posicion] remoteExec ["citySupportChange",2];
	[["TaskSucceeded", ["", "Airport Taken"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
	[20,10] call AS_fnc_changeForeignSupport;
   	["con_bas"] remoteExec ["fnc_BE_XP", 2];
};
if (_type == "base") then {
	[0,10,_posicion] remoteExec ["citySupportChange",2];
	[["TaskSucceeded", ["", "Base Taken"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
	[20,10] call AS_fnc_changeForeignSupport;
	["con_bas"] remoteExec ["fnc_BE_XP", 2];

	// discover nearby minefields
	{
		if ((_x call AS_fnc_location_position) distance _posicion < 400) then {
			[_x,"found",true] call AS_fnc_location_set;
		};
	} forEach (["minefield", "AAF"] call AS_fnc_location_TS);
};

if (_type == "powerplant") then {
	[["TaskSucceeded", ["", "Powerplant Taken"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
	[0,5] call AS_fnc_changeForeignSupport;
	["con_ter"] remoteExec ["fnc_BE_XP", 2];
	[_location] call powerReorg;
};
if (_type == "outpost") then {
	[["TaskSucceeded", ["", "Outpost Taken"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
	["con_ter"] remoteExec ["fnc_BE_XP", 2];
};
if (_type == "seaport") then {
	[["TaskSucceeded", ["", "Seaport Taken"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
	[10,10] call AS_fnc_changeForeignSupport;
	["con_ter"] remoteExec ["fnc_BE_XP", 2];
	[[_flag,"seaport"],"AS_fnc_addAction"] call BIS_fnc_MP;
};
if (_type in ["factory", "resource"]) then {
	if (_type == "factory") then {[["TaskSucceeded", ["", "Factory Taken"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;};
	if (_type == "resource") then {[["TaskSucceeded", ["", "Resource Taken"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;};
	["con_ter"] remoteExec ["fnc_BE_XP", 2];
	[0,10] call AS_fnc_changeForeignSupport;
	private _powerpl = ["powerplant" call AS_fnc_location_T, _posicion] call BIS_fnc_nearestPosition;
	if (_powerpl call AS_fnc_location_side == "AAF") then {
		sleep 5;
		[["TaskFailed", ["", "Resource out of Power"]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
		[_location, false] call AS_fnc_changeStreetLights;
	} else {
		[_location, true] call AS_fnc_changeStreetLights;
	};
};

waitUntil {sleep 1;
	(not (_location call AS_fnc_location_spawned)) or
	(({(not(vehicle _x isKindOf "Air")) and (alive _x) and (!fleeing _x)} count ([_size,0,_posicion,"OPFORSpawn"] call distanceUnits)) >
	 3*({(alive _x)} count ([_size,0,_posicion,"BLUFORSpawn"] call distanceUnits)))};

if (_location call AS_fnc_location_spawned) then {
	[_location] spawn AS_fnc_location_lose;
} else {
	_location call AS_fnc_location_removeRoadblocks;
};
