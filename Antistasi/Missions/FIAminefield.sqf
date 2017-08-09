params ["_mission"];

private _mineType = [_mission, "mine_type"] call AS_fnc_mission_get;
private _mapPosition = [_mission, "position"] call AS_fnc_mission_get;
private _minesPositions = [_mission, "positions"] call AS_fnc_mission_get;
private _vehType = [_mission, "vehicle"] call AS_fnc_mission_get;
private _cost = [_mission, "cost"] call AS_fnc_mission_get;

private _tskTitle = "Minefield Deploy";
private _tskDesc = format ["An Engineer Team has been deployed at your High command. Once they reach the position, they will start to deploy %1 mines in the area. Cover them in the meantime.",count _minesPositions];

// marker for the task.
private _mrk = createMarker [_mission, _mapPosition];
_mrk setMarkerShape "ELLIPSE";
_mrk setMarkerSize [100,100];
_mrk setMarkerColor "ColorRed";
_mrk setMarkerAlpha 0;

private _task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_mrk],_mapPosition,"CREATED",5,true,true,"map"] call BIS_fnc_setTask;

private _groups = [];
private _vehicles = [];

private _fnc_clean = {
	[[],[], [_mrk]] call AS_fnc_cleanResources;
	{
		private _group = _x;
		{
			if (alive _x) then {
				([_x, true] call AS_fnc_getUnitArsenal) params ["_cargo_w", "_cargo_m", "_cargo_i", "_cargo_b"];
				[caja, _cargo_w, _cargo_m, _cargo_i, _cargo_b, true] call AS_fnc_populateBox;
				deleteVehicle _x;
			};
		} forEach units _group;
		AS_commander hcRemoveGroup _group;
		deleteGroup _group
	} forEach _groups;
	{deleteVehicle _x} forEach _vehicles;

	sleep 30;
    [_task] call BIS_fnc_deleteTask;
    _mission call AS_fnc_mission_completed;
};

private _tam = 10;
private _roads = [];
while {count _roads == 0} do {
	_roads = getMarkerPos "FIA_HQ" nearRoads _tam;
	_tam = _tam + 10;
};

private _pos = position (_roads select 0) findEmptyPosition [1,30,_vehType];

private _vehType = (AS_FIArecruitment getVariable "land_vehicles") select 0;
private _truck = _vehType createVehicle _pos;
[_truck, "FIA"] call AS_fnc_initVehicle;
_vehicles pushBack _truck;

private _group = createGroup side_blue;
_groups pushBack _group;
AS_commander hcSetGroup [_group];
_group setVariable ["isHCgroup", true, true];
_group setGroupId ["MineF"];

_group addVehicle _truck;
_group createUnit [["Explosives Specialist"] call AS_fnc_getFIAUnitClass, getMarkerPos "FIA_HQ", [], 0, "NONE"];
_group createUnit [["Explosives Specialist"] call AS_fnc_getFIAUnitClass, getMarkerPos "FIA_HQ", [], 0, "NONE"];
{[_x] spawn AS_fnc_initUnitFIA; [_x] orderGetIn true} forEach units _group;
leader _group setBehaviour "SAFE";
_truck allowCrewInImmobile true;

private _arrivedSafely = false;
waitUntil {sleep 1;
	_arrivedSafely = (_truck distance _mapPosition < 100) and ({alive _x} count units _group > 0);
	(!alive _truck) or _arrivedSafely
};

if (_arrivedSafely) then {
	if (isPlayer leader _group) then {
		private _owner = player getVariable ["owner",player];
		selectPlayer _owner;
		(leader _group) setVariable ["owner",player,true];
		{[_x] joinsilent group player} forEach units group player;
		group player selectLeader player;
		hint "";
	};
	[[petros,"globalChat","Engineers are now deploying the mines."],"commsMP"] call BIS_fnc_MP;
	[leader _group, _mrk, "SAFE","SPAWNED", "SHOWMARKER"] execVM "scripts\UPSMON.sqf";

	// simulates putting mines.
	sleep (20*(count _minesPositions));

	if ((alive _truck) and ({alive _x} count units _group > 0)) then {
		// create minefield
		private _minesData = [];
		{
			_minesData pushBack [_mineType, _x, random 360];
		} forEach _minesPositions;
		[_mapPosition, "FIA", _minesData] call AS_fnc_addMinefield;

		_task = ["Mines",[side_blue,civilian],[_tskDesc,_tskTitle,_mrk],_mapPosition,"SUCCEEDED",5,true,true,"Map"] call BIS_fnc_setTask;
		[{alive _x} count units _group,_cost] remoteExec ["resourcesFIA",2];  // recover the costs

		[_mission] remoteExec ["AS_fnc_mission_success", 2];
	} else {
		_task = ["Mines",[side_blue,civilian],[_tskDesc,_tskTitle,_mrk],_mapPosition,"FAILED",5,true,true,"Map"] call BIS_fnc_setTask;
		[_mission] remoteExec ["AS_fnc_mission_fail", 2];
	};
} else {
	_task = ["Mines",[side_blue,civilian],[_tskDesc,_tskTitle,_mrk],_mapPosition,"FAILED",5,true,true,"Map"] call BIS_fnc_setTask;
	[_mission] remoteExec ["AS_fnc_mission_fail", 2];
};

call _fnc_clean;
