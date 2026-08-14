#include "../../Code/Basedef.h"

#include <cstddef>

namespace wyd::protocol::contracts
{
    static_assert(sizeof(short) == 2, "Legacy protocol requires 16-bit short.");
    static_assert(sizeof(unsigned int) == 4, "Legacy protocol requires 32-bit unsigned int.");

    static_assert(sizeof(MSG_STANDARD) == 12, "MSG_STANDARD wire size changed.");
    static_assert(offsetof(MSG_STANDARD, Size) == 0, "MSG_STANDARD::Size offset changed.");
    static_assert(offsetof(MSG_STANDARD, KeyWord) == 2, "MSG_STANDARD::KeyWord offset changed.");
    static_assert(offsetof(MSG_STANDARD, CheckSum) == 3, "MSG_STANDARD::CheckSum offset changed.");
    static_assert(offsetof(MSG_STANDARD, Type) == 4, "MSG_STANDARD::Type offset changed.");
    static_assert(offsetof(MSG_STANDARD, ID) == 6, "MSG_STANDARD::ID offset changed.");
    static_assert(offsetof(MSG_STANDARD, ClientTick) == 8, "MSG_STANDARD::ClientTick offset changed.");

    static_assert(sizeof(MSG_STANDARDPARM) == 16, "MSG_STANDARDPARM wire size changed.");
    static_assert(offsetof(MSG_STANDARDPARM, Parm) == 12, "MSG_STANDARDPARM::Parm offset changed.");

    static_assert(sizeof(MSG_STANDARDPARM2) == 20, "MSG_STANDARDPARM2 wire size changed.");
    static_assert(offsetof(MSG_STANDARDPARM2, Parm1) == 12, "MSG_STANDARDPARM2::Parm1 offset changed.");
    static_assert(offsetof(MSG_STANDARDPARM2, Parm2) == 16, "MSG_STANDARDPARM2::Parm2 offset changed.");

    static_assert(sizeof(MSG_STANDARDSHORTPARM2) == 16, "MSG_STANDARDSHORTPARM2 wire size changed.");
    static_assert(offsetof(MSG_STANDARDSHORTPARM2, Parm1) == 12, "MSG_STANDARDSHORTPARM2::Parm1 offset changed.");
    static_assert(offsetof(MSG_STANDARDSHORTPARM2, Parm2) == 14, "MSG_STANDARDSHORTPARM2::Parm2 offset changed.");

    static_assert(sizeof(MSG_STANDARDPARM3) == 24, "MSG_STANDARDPARM3 wire size changed.");
    static_assert(offsetof(MSG_STANDARDPARM3, Parm1) == 12, "MSG_STANDARDPARM3::Parm1 offset changed.");
    static_assert(offsetof(MSG_STANDARDPARM3, Parm2) == 16, "MSG_STANDARDPARM3::Parm2 offset changed.");
    static_assert(offsetof(MSG_STANDARDPARM3, Parm3) == 20, "MSG_STANDARDPARM3::Parm3 offset changed.");

    static_assert(FLAG_GAME2CLIENT == 0x0100, "FLAG_GAME2CLIENT changed.");
    static_assert(FLAG_CLIENT2GAME == 0x0200, "FLAG_CLIENT2GAME changed.");
    static_assert(FLAG_DB2GAME == 0x0400, "FLAG_DB2GAME changed.");
    static_assert(FLAG_GAME2DB == 0x0800, "FLAG_GAME2DB changed.");

    static_assert(ACCOUNTPASS_LENGTH == 12, "Legacy account password field length changed.");
    static_assert(ACCOUNTNAME_LENGTH == 16, "Legacy account login field length changed.");
    static_assert(_MSG_AccountLogin == 0x020D, "Account login packet type changed.");
    static_assert(_MSG_CNFAccountLogin == 0x010A, "Account login confirmation packet type changed.");

    static_assert(sizeof(MSG_AccountLogin) == 58, "MSG_AccountLogin wire size changed.");
    static_assert(offsetof(MSG_AccountLogin, Size) == 0, "MSG_AccountLogin::Size offset changed.");
    static_assert(offsetof(MSG_AccountLogin, Type) == 4, "MSG_AccountLogin::Type offset changed.");
    static_assert(offsetof(MSG_AccountLogin, ID) == 6, "MSG_AccountLogin::ID offset changed.");
    static_assert(offsetof(MSG_AccountLogin, ClientTick) == 8, "MSG_AccountLogin::ClientTick offset changed.");
    static_assert(offsetof(MSG_AccountLogin, AccountPassword) == 12, "MSG_AccountLogin::AccountPassword offset changed.");
    static_assert(offsetof(MSG_AccountLogin, AccountLogin) == 24, "MSG_AccountLogin::AccountLogin offset changed.");
    static_assert(offsetof(MSG_AccountLogin, MacAddres) == 40, "MSG_AccountLogin::MacAddres offset changed.");
}
