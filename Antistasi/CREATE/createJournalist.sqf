#include "../macros.hpp"
params ["_location", "_grupos"];

private _position = _location call AS_fnc_location_position;
private _size = _location call AS_fnc_location_size;

private _journalist = objNull;
if ((random 100 < ((AS_P("NATOsupport") + AS_P("CSATsupport"))/10)) and (_location call AS_fnc_location_spawned)) then {
	_pos = [];
	_grupo = createGroup civilian;
	while {true} do {
		_pos = [_position, round (random _size), random 360] call BIS_Fnc_relPos;
		if (!surfaceIsWater _pos) exitWith {};
	};
	_journalist = _grupo createUnit ["C_journalist_F", _pos, [],0, "NONE"];
	[_journalist] spawn AS_fnc_initUnitCIV;
	_grupos pushBack _grupo;
	[_journalist, _location, "SAFE", "SPAWNED","NOFOLLOW", "NOVEH2","NOSHARE","DoRelax"] execVM "scripts\UPSMON.sqf";
};

_journalist
