/*
*   Copyright (C) {2015}  {Victor Klafke, Charles TheHouse}
*
*   This program is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program.  If not, see [http://www.gnu.org/licenses/].
*
*   Contact at: victor.klafke@ecomp.ufsm.br
*/
#ifndef __CUSER__
#define __CUSER__

#include "..\Basedef.h"
#include "..\CPSock.h"

#define USER_EMPTY       0
#define USER_ACCEPT      1
#define USER_LOGIN       2
#define USER_SELCHAR     11
#define USER_CHARWAIT    12
#define USER_WAITDB      13
#define USER_PLAY        22
#define USER_SAVING4QUIT 24

class CUser
{
public:
	char AccountName[ACCOUNTNAME_LENGTH];
	int Slot;
	unsigned int IP;
	int IsAutoTrading;
	int chave1;
	int chave2;
	int chave3;
	int chave4;
	int Keys[50];

	struct
	{
		time_t VipTime;
		time_t RwdTime;
		time_t Time1;
		time_t Time2;
		time_t Time3;
		time_t Time4;
		time_t Time5;
		time_t Time6;
	} Timer;

	int CountMob1;
	int CountMob2;
	int CountMob3;
	int QuestAtiva;
	time_t LastQuestDay;
	int Mode;
	int TradeMode;
	CPSock cSock;
	char Unk2[400];
	int Unk3;
	STRUCT_ITEM Cargo[MAX_CARGO];
	int Coin;
	unsigned short cProgress;
	short Unk_1498;
	bool WaitDB;
	MSG_Trade Trade;
	MSG_SendAutoTrade AutoTrade;
	int LastAttack;
	int LastAttackTick;
	int LastMove;
	int LastAction;
	int LastActionTick;
	int LastIllusionTick;
	int NumError;
	int Unk_1816;
	STRUCT_SELCHAR SelChar;
	char LastChat[16];
	int IsBillConnect;
	char Unk5[36];
	unsigned char CharShortSkill[16];
	int GemaX;
	int GemaY;
	int Whisper;
	int Guildchat;
	int PartyChat;
	int Chatting;
	char Unk_2648[24];
	int PKMode;
	int ReqHp;
	int ReqMp;
	int Unk_2688;
	char MacAddress[18];
	int Unk_2708;
	int RankingTarget;
	int RankingType;
	int LastReceiveTime;
	int Admin;
	int Unk_2728;
	unsigned int Unk_2732;
	int Unk_2736;
	int Range;
	int CastleStatus;
	char Unk9[400];
	int Donate;
	int Honra;
	int BossLocal1;
	int MuteChat;
	int KingChat;
	unsigned int UseItemTime;
	unsigned int Message;
	unsigned int DroplistTime;
	unsigned int AttackTime;
	unsigned int LastClientTick;
	ULONGLONG PotionTime;
	unsigned int PergaState;
	unsigned int PergaCount;
	unsigned int MoveItemTime;
	unsigned int Lasclick;
	ULONGLONG EventDelay;
	ULONGLONG CaptchaDelay;
	unsigned int Carptcha;
	unsigned int Territorio;
	time_t TempoDiario;
	ULONGLONG Atraso;
	ULONGLONG FiltroDelay;
	ULONGLONG MailItemDelay;
	ULONGLONG SendMailItemDelay;
	ULONGLONG RankingDelay;
	ULONGLONG TowerWarDelay;
	ULONGLONG DonateDelay;
	ULONGLONG DonateShopDelay;
	ULONGLONG RequestShopDelay;
	ULONGLONG DropListDelay;
	unsigned int QuestDiaria;
	unsigned int DiariaState;
	ULONGLONG AtrasocharLogout;
	int NumCreated;
	int OnlyTrade;
	int TimeLojinha;
	STRUCT_ACCOUNTFILE File;
	int Vidas;

	struct _Ingame
	{
		struct
		{
			unsigned int IntervalTime;
		} Skill[103];
		int AttackMode;
		unsigned int LastAttackTime;
		char PartyPassword[6];
		char PassWord[16];
		char Login[16];
		bool autoStore;
		bool GrupoAceitarSolicitacao;
		int CheckPista;
		int CheckPesa;
		int CheckAgua;
		int DonateBuyItem;
		bool MobDonateStore;
		bool CanBuy;
		char MobName[10][16];
		int MobFace[10];
		int MobEffect[10];
		int Window;
		int MarketState;
	} Ingame;

public:
	CUser();
	~CUser();
	int AcceptUser(int ListenSocket);
	int CloseUser();
};

#endif