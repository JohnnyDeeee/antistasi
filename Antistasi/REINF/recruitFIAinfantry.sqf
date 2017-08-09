#include "../macros.hpp"
params ["_type"];
private ["_enemiesClose","_cost","_moneyAvailable","_unit"];

if (not([player] call isMember)) exitWith {hint "Only server members can recruit AI units"};

if (!allowPlayerRecruit) exitWith {hint "Server is very loaded. \nWait one minute or change FPS settings in order to fulfill this request"};

if (player != player getVariable ["owner",player]) exitWith {hint "You cannot buy units while you are controlling AI"};

if (player != leader group player) exitWith {hint "You cannot recruit units as you are not your group leader"};

_enemiesClose = false;
{
	if (((side _x == side_red) or (side _x == side_green)) and (_x distance player < 500) and (not(captive _x))) exitWith {_enemiesClose = true};
} forEach allUnits;
if (_enemiesClose) exitWith {Hint "You cannot recruit units with enemies nearby"};

if (AS_P("hr") < 1) exitWith {hint "You do not have enough HR for this request"};

_cost = AS_data_allCosts getVariable _type;
if (!isMultiPlayer) then {
	_moneyAvailable = AS_P("resourcesFIA");
} else {
	_moneyAvailable = player getVariable "money";
};

if (_cost > _moneyAvailable) exitWith {hint format ["You do not have enough money for this kind of unit (%1 € needed)",_cost]};

if ((count units group player) + (count units MIASquadUnits) > 9) exitWith {hint "Your squad is full or you have too many scattered units with no radio contact"};

private _equipment = [_type] call AS_fnc_getBestEquipment;

_equipment params ["_vest", "_helmet", "_googles", "_backpack", "_primaryWeapon", "_primaryMags", "_secondaryWeapon", "_secondaryMags", "_scope", "_uniformItems", "_backpackItems", "_primaryWeaponItems"];

if (_type == "Sniper" and (_primaryWeapon == "" or ([_primaryMags] call AS_fnc_getTotalCargo) < 6 or _scope == "")) exitWith {
    hint "No snipers, ammo or scopes to equip a sniper.";
};
if (_type == "Grenadier" and _primaryWeapon == "") exitWith {
    // todo: check existence of enough grenades.
    hint "No grenade launchers or ammo to equip a grenadier.";
};
if (_type in ["AA Specialist", "AT Specialist"] and _secondaryWeapon == "") exitWith {
    // todo: check existence of enough rockets
    // todo: check existence of AA/AT launchers
    hint "No launchers.";
};

////////////////////// Checks completed //////////////////////

_unit = group player createUnit [[_type] call AS_fnc_getFIAUnitClass, position player, [], 0, "NONE"];

[_unit, true, nil, _equipment] spawn AS_fnc_initUnitFIA;

if (!isMultiPlayer) then {
	[-1, - _cost] remoteExec ["resourcesFIA",2];
}
else {
	[-1, 0] remoteExec ["resourcesFIA",2];
	[-_cost] call resourcesPlayer;
	hint "Soldier Recruited.\n\nRemember: if you use the group menu to switch groups you will lose control of your recruited AI";
};

_unit disableAI "AUTOCOMBAT";

[] spawn {
    sleep 1;
    petros directSay "SentGenReinforcementsArrived";
};
