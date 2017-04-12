params ["_unit", "_unitSide"];

private _rangeConst = 150;

private _distanceMin = _rangeConst;
private _medico = objNull;
private _medicoCurrent = _unit getVariable ["medic_from",objNull];

{
	private _nearUnit = _x select 4;
	private _nearUnitSide = _x select 2;

	private _medicIsBeazi = false;
	private _medicTo = _nearUnit getVariable "medic_to";

	if (!isNil "_medicTo" and !isNull _medicTo and _medicTo != _unit) then {
		_medicIsBeazi = true;
	};

	// try to find a viable medic closer
	if (!_medicIsBeazi and
		([_nearUnitSide, _unitSide] call BIS_fnc_sideIsFriendly) and
		(_nearUnit != _unit) and
		(_nearUnit != Petros) and
		!(_nearUnit getVariable ["inconsciente", false]) and
		!(isPlayer _nearUnit) and
		(alive _nearUnit) and
		([_nearUnit] call AS_fnc_getFIAUnitType == "Medic" or _nearUnit == sol_MED) and
		((_nearUnit distance _unit) < _distanceMin ) ) then {
		_distanceMin = _nearUnit distance _unit;
		_medico = _nearUnit;
	};
} forEach (_unit nearTargets _rangeConst);

// if it is a different medic and valid, make medic help him
if (_medico != _medicoCurrent and (!isNull _medico)) then {
	[_unit,_medico] spawn ayudar;
};

_medico
