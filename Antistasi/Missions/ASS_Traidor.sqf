params ["_mission"];
private _location = _mission call AS_fnc_mission_location;
private _position = _location call AS_fnc_location_position;

private _size = _location call AS_fnc_location_size;

private _tiempolim = 60;
private _fechalim = [date select 0, date select 1, date select 2, date select 3, (date select 4) + _tiempolim];
private _fechalimnum = dateToNumber _fechalim;

private _casas = nearestObjects [_position, ["house"], _size];
private _poscasa = [];
private _casa = _casas select 0;
while {count _poscasa < 3} do
	{
	_casa = _casas call BIS_Fnc_selectRandom;
	_poscasa = [_casa] call BIS_fnc_buildingPositions;
	if (count _poscasa < 3) then {_casas = _casas - [_casa]};
	};

private _max = (count _poscasa) - 1;
private _rnd = floor random _max;
private _postraidor = _poscasa select _rnd;
private _posSol1 = _poscasa select (_rnd + 1);
private _posSol2 = (_casa buildingExit 0);

private _grptraidor = createGroup side_red;

private _arraybases = ["base", "AAF"] call AS_fnc_location_TS;
private _base = [_arraybases, _position] call BIS_Fnc_nearestPosition;
private _posBase = _base call AS_fnc_location_position;

private _traidor = ([_postraidor, 0, opI_OFF2, _grptraidor] call bis_fnc_spawnvehicle) select 0;
_traidor allowDamage false;
([_posSol1, 0, opI_SL, _grptraidor] call bis_fnc_spawnvehicle) select 0;
([_posSol2, 0, opI_RFL1, _grptraidor] call bis_fnc_spawnvehicle) select 0;
_grptraidor selectLeader _traidor;

{[_x] call CSATinit; _x allowFleeing 0} forEach units _grptraidor;
private _posVeh = [];
private _dirVeh = 0;
private _roads = [];
private _radius = 20;
while {count _roads == 0} do {
	_roads = (getPos _casa) nearRoads _radius;
	_radius = _radius + 10;
};
private _road = _roads select 0;

private _roadcon = roadsConnectedto _road;
private _posroad = getPos _road;
private _posrel = getPos (_roadcon select 0);
private _dirveh = [_posroad,_posrel] call BIS_fnc_DirTo;
_posVeh = [_posroad, 3, _dirveh + 90] call BIS_Fnc_relPos;

private _veh = opMRAPu createVehicle _posVeh;
_veh allowDamage false;
_veh setDir _dirVeh;
_veh allowDamage true;
_traidor allowDamage true;
[_veh, "CSAT"] call AS_fnc_initVehicle;
{_x disableAI "MOVE"; _x setUnitPos "UP"} forEach units _grptraidor;

private _mrk = createMarkerLocal [format ["%1patrolarea", floor random 100], getPos _casa];
_mrk setMarkerShapeLocal "RECTANGLE";
_mrk setMarkerSizeLocal [50,50];
_mrk setMarkerTypeLocal "hd_warning";
_mrk setMarkerColorLocal "ColorRed";
_mrk setMarkerBrushLocal "DiagGrid";
_mrk setMarkerAlphaLocal 0;

private _tipoGrupo = [infSquad, side_green] call fnc_pickGroup;
private _grupo = [_position, side_green, _tipogrupo] call BIS_Fnc_spawnGroup;
if (random 10 < 2.5) then {
	private _perro = _grupo createUnit ["Fin_random_F",_position,[],0,"FORM"];
	[_perro] spawn guardDog;
};
[leader _grupo, _mrk, "SAFE","SPAWNED", "NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";
{[_x, false] spawn AS_fnc_initUnitAAF} forEach units _grupo;


private _posTsk = (position _casa) getPos [random 100, random 360];
private _tskTitle = localize "STR_tsk_ASSTraitor";
private _tskDesc = format [localize "STR_tskDesc_ASSTraitor",[_location] call localizar,numberToDate [2035,_fechalimnum] select 3,numberToDate [2035,_fechalimnum] select 4];

private _task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_location],_posTsk,"CREATED",5,true,true,"Kill"] call BIS_fnc_setTask;

private _fnc_clean = {
	[[_grupo, _grptraidor], [_veh], [_mrk]] call AS_fnc_cleanResources;
	sleep 30;
    [_task] call BIS_fnc_deleteTask;
    _mission call AS_fnc_mission_completed;
};

private _fnc_missionFailedCondition = {dateToNumber date > _fechalimnum or {_traidor distance _posBase < 50}};

private _fnc_missionFailed = {
	_task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_location],_traidor,"FAILED",5,true,true,"Kill"] call BIS_fnc_setTask;
	[-10,AS_commander] call playerScoreAdd;
	[-2,-2000] remoteExec ["resourcesFIA",2];
	call _fnc_clean;
};

private _fnc_missionSuccessfulCondition = {(not alive _traidor)};

private _fnc_missionSuccessful = {
	_task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_location],_traidor,"SUCCEEDED",5,true,true,"Kill"] call BIS_fnc_setTask;
	[0,-2] remoteExec ["prestige",2];
	{
		if (!isPlayer _x) then {
			[10,_x] call playerScoreAdd;
		};
	} forEach ([_size,0,_position,"BLUFORSpawn"] call distanceUnits);
	[5,AS_commander] call playerScoreAdd;
	["mis"] remoteExec ["fnc_BE_XP", 2];

	call _fnc_clean;
};

waitUntil {sleep 5; ({_traidor knowsAbout _x > 1.4} count ([500,0,_traidor,"BLUFORSpawn"] call distanceUnits) > 0) or _fnc_missionFailedCondition or _fnc_missionSuccessfulCondition};

if (call _fnc_missionFailedCondition) exitWith _fnc_missionFailed;
if (call _fnc_missionSuccessfulCondition) exitWith _fnc_missionSuccessful;

// traitor tries to escape
_task = [_mission,[side_blue,civilian],[_tskDesc,_tskTitle,_location],_traidor,"CREATED",5,true,true,"Kill"] call BIS_fnc_setTask;
{_x enableAI "MOVE"} forEach units _grptraidor;
_traidor assignAsDriver _veh;
[_traidor] orderGetin true;
private _wp0 = _grptraidor addWaypoint [_posVeh, 0];
_wp0 setWaypointType "GETIN";
private _wp1 = _grptraidor addWaypoint [_posBase,1];
_wp1 setWaypointType "MOVE";
_wp1 setWaypointBehaviour "CARELESS";
_wp1 setWaypointSpeed "FULL";

[_fnc_missionFailedCondition, _fnc_missionFailed, _fnc_missionSuccessfulCondition, _fnc_missionSuccessful] call AS_fnc_oneStepMission;
