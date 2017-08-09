/*
Relevant functions of this module:
	"Server" side:
		- AS_fnc_savePlayers: saves all players.

	"Client" side:
		- AS_fnc_loadLocalPlayer: loads player data.
		- AS_fnc_saveLocalPlayer: saves player on the server.
*/
#include "../macros.hpp"

// The ids and data of the players. Everyone has this list locally because
// games can be saved by anyone (as anyone can be a commander).
AS_profileIDs = [];
AS_profileID_data = [];

// client function. Maps local data into an array.
AS_fnc_serializeLocalPlayer = {
	private _result = [];
	if isMultiplayer then {
		private _score = player getVariable "score";
		private _rank = player getVariable "rank";
		private _money = player getVariable "money";
		{
		private _hired = _x;
		if ((!isPlayer _hired) and (alive _hired)) then {
			_money = _money + (AS_data_allCosts getVariable ([_x] call AS_fnc_getFIAUnitNameType));
			if (vehicle _hired != _hired) then {
				private _veh = vehicle _hired;
				private _tipoVeh = typeOf _veh;
				if (not(_veh in AS_P("vehicles"))) then {
					if ((_veh isKindOf "StaticWeapon") or (driver _veh == _hired)) then {
						_money = _money + ([_tipoVeh] call FIAvehiclePrice);
						if (count attachedObjects _veh != 0) then {{_money = _money + ([typeOf _x] call FIAvehiclePrice)} forEach attachedObjects _veh};
					};
				};
			};
		};
		} forEach units group player;
		_result = [_score, _rank, _money, personalGarage];
	};
	_result
};

// client function. Sends the data to the requester (or server).
AS_fnc_saveLocalPlayerData = {
	if (_this isEqualTo []) then {
		_this = 2;
	};
	[AS_profileID, [] call AS_fnc_serializeLocalPlayer] remoteExec ["AS_fnc_receivePlayerData", _this];
};

// Triggers everyone to send data to itself.
AS_fnc_getPlayersData = {
	(owner player) remoteExec ["AS_fnc_saveLocalPlayerData", 0];  // to every client.
};

// Stores profile data received from a client.
AS_fnc_receivePlayerData = {
	params ["_profileID", "_data"];
    private _index = AS_profileIDs find _profileID;
    if (_index == -1) then {
        AS_profileIDs pushback _profileID;
        AS_profileID_data pushback _data;
    } else {
        AS_profileID_data set [_index, _data];
    };
};

// Saves all profiles.
AS_fnc_savePlayers = {
    params ["_saveName"];
    for "_i" from 0 to count AS_profileIDs - 1 do {
        [_saveName, AS_profileIDs select _i, AS_profileID_data select _i] call AS_fnc_SaveStat;
    };
};

// Asks all clients to load profiles.
AS_fnc_loadPlayers = {
    (owner player) remoteExec ["AS_fnc_loadLocalPlayer", 0];  // to every client (including server-client)
    diag_log '[AS] Server: asked clients to load profiles.';
};

// Sends request to get saved data from the client that asked for it, or the server.
AS_fnc_loadLocalPlayer = {
	params ["_server"];
	if (isNil "_server") then {
		_server = 2;
	};
    diag_log format ['[AS] Client "%1": asking for saved data from client "%2".', owner player, _server];
	[AS_profileID, owner player] remoteExec ["AS_fnc_sendPlayerData", _server];
};

// Loads data from profile id and sends it back for loading, if it exists.
AS_fnc_sendPlayerData = {
	params ["_profileID", "_clientID"];

    private _text = format ['[AS] Server: received request for profile data from "%1". ', _profileID];

    if (AS_currentSave != "") then {
        private _data = [AS_currentSave, _profileID] call AS_fnc_LoadStat;
        if (!isNil "_data") then {
            diag_log (_text + 'It was sent');
            [_data] remoteExec ["AS_fnc_setPlayerData", _clientID];
        } else {
            diag_log (_text + 'Save exists but profile does not exist.');
        };
    } else {
        diag_log (_text + 'There is no current save.');
    };
};

// client function. Loads the data
AS_fnc_setPlayerData = {
	params ["_data"];
    diag_log format ['[AS] Client "%1": received data. Loading player.', AS_profileID];
    [_data] call AS_fnc_deserializeLocalPlayer;
};

// client function. Maps an array to local data.
AS_fnc_deserializeLocalPlayer = {
    params ["_data"];
	if isMultiplayer then {
		player setVariable ["score", _data select 0, true];
		player setVariable ["rank", _data select 1, true];
		player setUnitRank (_data select 1);
		player setVariable ["money", _data select 2, true];
		personalGarage = _data select 3;
        hint "Profile loaded."
	};
};
