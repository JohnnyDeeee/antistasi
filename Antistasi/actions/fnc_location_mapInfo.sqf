#include "../macros.hpp"
AS_CLIENT_ONLY("fnc_location_mapInfo.sqf");

private _popFIA = 0;
private _popAAF = 0;
private _pop = 0;
{
	private _population = [_x, "population"] call AS_fnc_location_get;
	private _AAFsupport = [_x, "AAFsupport"] call AS_fnc_location_get;
	private _FIAsupport = [_x, "FIAsupport"] call AS_fnc_location_get;

	_popFIA = _popFIA + (_population * (_FIAsupport / 100));
	_popAAF = _popAAF + (_population * (_AAFsupport / 100));
	_pop = _pop + _population;
} forEach call AS_fnc_location_cities;
_popFIA = round _popFIA;
_popAAF = round _popAAF;
hint format ["Total pop: %1\nFIA Support: %2\nAAF SUpport: %3 \n\nDestroyed Cities: %4\n\nClick on the location",
	_pop, _popFIA, _popAAF, {_x in AS_P("destroyedLocations")} count (call AS_fnc_location_cities)];

openMap true;

posicionTel = [];
onMapSingleClick "posicionTel = _pos;";

while {visibleMap} do {
	if (count posicionTel > 0) then {
		private _location = posicionTel call AS_fnc_location_nearest;
		private _position = _location call AS_fnc_location_position;
		private _type = _location call AS_fnc_location_type;
		private _side = _location call AS_fnc_location_side;
		private _texto = "Click on a location";
		if (_location == "FIA_HQ") then {
			_texto = format ["FIA HQ%1",[_location] call garrisonInfo];
		};
		if (_type == "city") then {
			_texto = format ["%1\n\nPop %2\nAAF Support: %3 %5\nFIA Support: %4 %5",
				[_location,false] call AS_fnc_getLocationName,
				[_location, "population"] call AS_fnc_location_get,
				[_location, "AAFsupport"] call AS_fnc_location_get,
				[_location, "FIAsupport"] call AS_fnc_location_get,
				"%"
			];
			if ([_location] call powerCheck) then {_texto = format ["%1\nPowered",_texto]} else {_texto = format ["%1\nNot Powered",_texto]};
			if (_side == "AAF") then {if (_position call radioCheck) then {_texto = format ["%1\nRadio Comms ON",_texto]} else {_texto = format ["%1\nRadio Comms OFF",_texto]}};
			if (_location in AS_P("destroyedLocations")) then {_texto = format ["%1\nDESTROYED",_texto]};
		};
		if (_type == "airfield") then {
			if (_side == "AAF") then {
				_texto = "AAF Airport";
				private _busy = _location call AS_fnc_location_busy;
				if (_position call radioCheck) then {_texto = format ["%1\n\nRadio Comms ON",_texto]} else {_texto = format ["%1\n\nRadio Comms OFF",_texto]};
				if (!_busy) then {_texto = format ["%1\nStatus: Idle",_texto]} else {_texto = format ["%1\nStatus: Busy",_texto]};
			} else {
				_texto = format ["FIA Airport%1",[_location] call garrisonInfo];
			};
		};
		if (_type == "base") then {
			if (_side == "AAF") then {
				_texto = "AAF Base";
				private _busy = _location call AS_fnc_location_busy;
				if (_position call radioCheck) then {_texto = format ["%1\n\nRadio Comms ON",_texto]} else {_texto = format ["%1\n\nRadio Comms OFF",_texto]};
				if (!_busy) then {_texto = format ["%1\nStatus: Idle",_texto]} else {_texto = format ["%1\nStatus: Busy",_texto]};
			} else {
				_texto = format ["FIA Base%1",[_location] call garrisonInfo];
			};
		};
		if (_type == "powerplant") then {
			if (_side == "AAF") then {
				_texto = "AAF Powerplant";
				if (_position call radioCheck) then {_texto = format ["%1\n\nRadio Comms ON",_texto]} else {_texto = format ["%1\n\nRadio Comms OFF",_texto]};
			} else {
				_texto = format ["FIA Powerplant%1",[_location] call garrisonInfo];
			};
			if (_location in AS_P("destroyedLocations")) then {_texto = format ["%1\nDESTROYED",_texto]};
		};
		if (_type == "resource") then {
			if (_side == "AAF") then {
				_texto = "AAF Resources";
			} else {
				_texto = format ["FIA Resources%1",[_location] call garrisonInfo];
			};
			if ([_location] call powerCheck) then {_texto = format ["%1\n\nPowered",_texto]} else {_texto = format ["%1\n\nNo Powered",_texto]};
			if (_side == "AAF") then {if (_position call radioCheck) then {_texto = format ["%1\nRadio Comms ON",_texto]} else {_texto = format ["%1\nRadio Comms OFF",_texto]}};
			if (_location in AS_P("destroyedLocations")) then {_texto = format ["%1\nDESTROYED",_texto]};
		};
		if (_type == "factory") then {
			if (_side == "AAF") then {
				_texto = "AAF Factory";
			} else {
				_texto = format ["FIA Factory%1",[_location] call garrisonInfo];
			};
			if ([_location] call powerCheck) then {_texto = format ["%1\n\nPowered",_texto]} else {_texto = format ["%1\n\nNo Powered",_texto]};
			if (_side == "AAF") then {if (_position call radioCheck) then {_texto = format ["%1\nRadio Comms ON",_texto]} else {_texto = format ["%1\nRadio Comms OFF",_texto]}};
			if (_location in AS_P("destroyedLocations")) then {_texto = format ["%1\nDESTROYED",_texto]};
			};
		if (_type in ["outpost", "outpostAA"]) then {
			if (_side == "AAF") then {
				_texto = "AAF Outpost";
				if (_position call radioCheck) then {
					_texto = format ["%1\n\nRadio Comms ON",_texto]
				} else {
					_texto = format ["%1\n\nRadio Comms OFF",_texto]
				};
			} else {
				_texto = format ["FIA Outpost%1",[_location] call garrisonInfo];
			};
		};
		if (_type == "seaport") then {
			if (_side == "AAF") then {
				_texto = "AAF Seaport";
				if (_position call radioCheck) then {_texto = format ["%1\n\nRadio Comms ON",_texto]} else {_texto = format ["%1\n\nRadio Comms OFF",_texto]};
			} else {
				_texto = format ["FIA Seaport%1",[_location] call garrisonInfo];
			};
		};
		hint format ["%1",_texto];
		};
	posicionTel = [];
	sleep 1;
};
onMapSingleClick "";
