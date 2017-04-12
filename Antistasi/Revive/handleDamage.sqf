params ["_unit", "_part", "_dam", "_injurer"];

if (!alive _unit and !isPlayer _unit) exitWith {
	_unit removeAllEventHandlers "HandleDamage";
	1
};

if (_dam > 0.95) then {
	private _damAccum = _unit getVariable ["damAccum", 0];
	_damAccum = _damAccum + _dam;
	_unit setVariable ["damAccum", _damAccum, true];

	_dam = 0.95;

	if (_unit getVariable ["inconsciente", false]) then {
		_unit setVariable ["finishedoff",_injurer,true];
	} else {
		if (!((vehicle _unit == _unit) and
			 (vehicle _injurer != _injurer))
			 ) then {
			_unit setVariable ["inconsciente", true, true];
			[_unit, _part, _injurer] spawn inconsciente;
		};
	};
};

if (_unit getVariable ["inconsciente", false]) then {
	_dam = 0.95;
};

_dam
