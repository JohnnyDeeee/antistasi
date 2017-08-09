#include "../macros.hpp"
params ["_location"];
if (!isServer and hasInterface) exitWith{};

private _soldados = [];
private _grupos = [];
private _vehiculos = [];
private _soldadosFIA = [];
private _gruposFIA = [];

private _posicion = _location call AS_fnc_location_position;
private _size = _location call AS_fnc_location_size;
private _prestigio = AS_P("NATOsupport")/100;
private _estaticas = AS_P("vehicles") select {_x distance _posicion < _size};

private _buildings = nearestObjects [_posicion, listMilBld, _size*1.5];

_grupo = createGroup side_blue;
_grupos = _grupos + [_grupo];

([_location, side_blue, _grupo] call AS_fnc_populateMilBuildings) params ["_gunners", "_vehicles"];
_soldados append _gunners;
_vehiculos append _vehicles;

// create flag
_veh = createVehicle [bluFlag, _posicion, [],0, "CAN_COLLIDE"];
_veh allowDamage false;
[[_veh,"unit"],"AS_fnc_addAction"] call BIS_fnc_MP;
[[_veh,"vehicle"],"AS_fnc_addAction"] call BIS_fnc_MP;
[[_veh,"garage"],"AS_fnc_addAction"] call BIS_fnc_MP;
_vehiculos pushBack _veh;

private _nVeh = round ((_size / 30)*_prestigio);
if (_nVeh > 4) then {_nVeh = 4;};

for "_i" from 1 to _nVeh do {
	if !(_location call AS_fnc_location_spawned) exitWith {};
	private _pos = [_posicion, random (_size / 2),random 360] call BIS_fnc_relPos;
	_pos = [_posicion] call mortarPos;
	_veh = selectRandom bluStatMortar createVehicle _pos;
	[_veh] execVM "scripts\UPSMON\MON_artillery_add.sqf";
	private _unit = ([_posicion, 0, bluGunner, _grupo] call bis_fnc_spawnvehicle) select 0;
	_unit moveInGunner _veh;
	[_unit] call NATOinit;

	_soldados pushBack _unit;
	_vehiculos pushBack _veh;
	[_veh, "NATO"] call AS_fnc_initVehicle;
};

_nVeh = round ((_size/30)*_prestigio);
if (_nVeh < 1) then {_nVeh = 1};

private _pos = _posicion;
for "_i" from 1 to _nVeh do {
	if (!(_location call AS_fnc_location_spawned) or diag_fps < AS_P("minimumFPS")) exitWith {};

	_pos = [_posicion, 10, _size/2, 10, 0, 0.3, 0] call BIS_Fnc_findSafePos;

	_veh = createVehicle [vehNATO call BIS_fnc_selectRandom, _pos, [], 0, "NONE"];
	_veh setDir random 360;

	[_veh, "NATO"] call AS_fnc_initVehicle;
	_vehiculos pushBack _veh;
};

private _tipoGrupo = [bluSquad, side_blue] call fnc_pickGroup;
private _grupo = [_posicion, side_blue, _tipoGrupo] call BIS_Fnc_spawnGroup;
[leader _grupo, _location, "SAFE", "RANDOMUP","SPAWNED", "NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";
_grupos pushBack _grupo;
{[_x] spawn NATOinit; _soldados pushBack _x} forEach units _grupo;

for "_i" from 1 to _nVeh do {
	if (!(_location call AS_fnc_location_spawned) or diag_fps < AS_P("minimumFPS")) exitWith {};
	while {true} do {
		_pos = [_posicion, random _size,random 360] call BIS_fnc_relPos;
		if (!surfaceIsWater _pos) exitWith {};
	};
	_tipoGrupo = [bluSquad, side_blue] call fnc_pickGroup;
	_grupo = [_pos,side_blue, _tipoGrupo] call BIS_Fnc_spawnGroup;
	sleep 1;
	if (_i == 0) then {
		[leader _grupo, _location, "SAFE","SPAWNED","FORTIFY","NOVEH","NOFOLLOW"] execVM "scripts\UPSMON.sqf";
	} else {
		[leader _grupo, _location, "SAFE","SPAWNED", "RANDOM","NOVEH", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";
	};
	_grupos pushBack _grupo;
	{[_x] spawn NATOinit; _soldados pushBack _x} forEach units _grupo;
};

// Create FIA garrison
(_location call AS_fnc_createFIAgarrison) params ["_soldados1", "_grupos1", "_vehiculos1"];
_soldadosFIA append _soldados1;
_gruposFIA append _grupos1;
_vehiculos append _vehiculos1;

private _journalist = [_location, _grupos] call AS_fnc_createJournalist;

waitUntil {sleep 1;
	(not (_location call AS_fnc_location_spawned)) or
	(({not(vehicle _x isKindOf "Air")} count ([_size,0,_posicion,"OPFORSpawn"] call distanceUnits)) >
	3*(({alive _x} count _soldados) + count ([_size,0,_posicion,"BLUFORSpawn"] call distanceUnits)))};

if (_location call AS_fnc_location_spawned) then {
	[_location] remoteExec ["AS_fnc_location_lose",2];
};

waitUntil {sleep 1; not (_location call AS_fnc_location_spawned)};

[_buildings] remoteExec ["AS_fnc_updateDestroyedBuildings", 2];

{
	if (_location call AS_fnc_location_side == "FIA") then {
		([_x, true] call AS_fnc_getUnitArsenal) params ["_cargo_w", "_cargo_m", "_cargo_i", "_cargo_b"];
		[caja, _cargo_w, _cargo_m, _cargo_i, _cargo_b, true] call AS_fnc_populateBox;
	};
	if (alive _x) then {
		deleteVehicle _x;
	};
} forEach _soldadosFIA;

if (!isNull _journalist) then {deleteVehicle _journalist};
{deleteGroup _x} forEach _gruposFIA;
{if (not(_x in AS_P("vehicles"))) then {deleteVehicle _x}} forEach _vehiculos;
{if (alive _x) then {deleteVehicle _x}} forEach _soldados;
{deleteGroup _x} forEach _grupos;
