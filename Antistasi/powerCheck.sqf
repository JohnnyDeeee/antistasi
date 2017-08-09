#include "macros.hpp"
params ["_location"];

private _power = ["powerplant" call AS_fnc_location_T, _location call AS_fnc_location_position] call BIS_fnc_nearestPosition;

if (_power in AS_P("destroyedLocations")) exitWith {false};

(_location call AS_fnc_location_side) == (_power call AS_fnc_location_side)
