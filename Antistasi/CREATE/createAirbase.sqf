#include "../macros.hpp"
params ["_location"];
if (!isServer and hasInterface) exitWith{};

private _soldados = [];
private _grupos = [];
private _vehiculos = [];

private _posicion = _location call AS_fnc_location_position;
private _size = _location call AS_fnc_location_size;
private _frontera = _location call isFrontline;
private _busy = _location call AS_fnc_location_busy;


// spawn flag
private _flag = createVehicle [cFlag, _posicion, [],0, "CAN_COLLIDE"];
_flag allowDamage false;
_vehiculos pushBack _flag;

// spawn crate
private _veh = "I_supplyCrate_F" createVehicle _posicion;
[_veh, "Airbase"] call AS_fnc_fillCrateAAF;
_vehiculos pushBack _veh;

// spawn AT road block
private _grupo = createGroup side_green;
_grupos append _grupo;
if ((_location call AS_fnc_location_spawned) and _frontera) then {
	([_posicion, _grupo] call AS_fnc_spawnAAF_roadAT) params ["_units1", "_vehicles1"];
	_soldados append _units1;
	_vehiculos append _vehicles1;
};

// spawn 4 patrols
// _mrk => to be deleted at the end
([_location, 4] call AS_fnc_spawnAAF_patrol) params ["_units1", "_groups1", "_mrk"];
_grupos append _groups1;

// spawn parked air vehicles
if (!_busy) then {
	private _buildings = nearestObjects [_posicion, ["Land_LandMark_F"], _size / 2];
	if (count _buildings > 1) then {
		private _pos1 = getPos (_buildings select 0);
		private _pos2 = getPos (_buildings select 1);
		private _ang = [_pos1, _pos2] call BIS_fnc_DirTo;

		private _pos = [_pos1, 5,_ang] call BIS_fnc_relPos;
		private _grupo = createGroup side_green;
		_grupos pushBack _grupo;

		private _possible_vehicles = (["planes", "armedHelis", "transportHelis"] call AS_fnc_AAFarsenal_all);
		for "_i" from 1 to 5 do {
			if !(_location call AS_fnc_location_spawned) exitWith {};
			if (count _possible_vehicles == 0) exitWith {};

			private _tipoveh = selectRandom _possible_vehicles;
			_possible_vehicles deleteAt (_possible_vehicles find _tipoveh);
			private _veh = createVehicle [_tipoveh, _pos, [],3, "NONE"];
			_veh setDir (_ang + 90);
			sleep 1;
			_vehiculos pushBack _veh;
			[_veh, "AAF"] call AS_fnc_initVehicle;
			private _pos = [_pos, 20,_ang] call BIS_fnc_relPos;
			private _unit = ([_posicion, 0, infPilot, _grupo] call bis_fnc_spawnvehicle) select 0;
			[_unit, false] spawn AS_fnc_initUnitAAF;
			_soldados pushBack _unit;
		};
		[leader _grupo, _location, "SAFE","SPAWNED","NOFOLLOW","NOVEH"] execVM "scripts\UPSMON.sqf";
		sleep 1;
	};
};

// spawn parked land vehicles
private _groupCount = round (_size/60);
private _possible_vehicles = (["trucks", "apcs"] call AS_fnc_AAFarsenal_all);
for "_i" from 1 to _groupCount do {
	if (!(_location call AS_fnc_location_spawned) or diag_fps < AS_P("minimumFPS")) exitWith {};
	if (count _possible_vehicles == 0) exitWith {};

	private _tipoveh = selectRandom _possible_vehicles;
	_possible_vehicles deleteAt (_possible_vehicles find _tipoveh);
	private _pos = [_posicion, 10, _size/2, 10, 0, 0.3, 0] call BIS_Fnc_findSafePos;
	_veh = createVehicle [_tipoVeh, _pos, [], 0, "NONE"];
	_veh setDir random 360;
	_vehiculos pushBack _veh;
	[_veh, "AAF"] call AS_fnc_initVehicle;
	sleep 1;
};

// spawn guarding squads
if (_frontera) then {_groupCount = _groupCount * 2};
([_location, 1 + _groupCount] call AS_fnc_spawnAAF_patrolSquad) params ["_units1", "_groups1"];
_soldados append _units1;
_grupos append _groups1;

private _journalist = [_location, _grupos] call AS_fnc_createJournalist;

//////////////////////////////////////////////////////////////////
////////////////////////// END SPAWNING //////////////////////////
//////////////////////////////////////////////////////////////////

waitUntil {sleep 1;
	(not (_location call AS_fnc_location_spawned)) or
	(({(not(vehicle _x isKindOf "Air"))} count ([_size,0,_posicion,"BLUFORSpawn"] call distanceUnits)) >
	 3*({(alive _x) and (!(captive _x)) and (_x distance _posicion < _size)} count _soldados))};

if ((_location call AS_fnc_location_spawned) and (_location call AS_fnc_location_side == "AAF")) then {
	[_location] remoteExec ["AS_fnc_location_win",2];
};

waitUntil {sleep 1; not (_location call AS_fnc_location_spawned)};

deleteMarker _mrk;
{if (alive _x) then {deleteVehicle _x}} forEach _soldados;
if (!isNull _journalist) then {deleteVehicle _journalist};
{deleteGroup _x} forEach _grupos;
{if (!([AS_P("spawnDistance")-_size,1,_x,"BLUFORSpawn"] call distanceUnits)) then {deleteVehicle _x}} forEach _vehiculos;
