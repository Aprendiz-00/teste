#pragma once

// Transitional compatibility shim. Legacy TMSrv/DBSrv include this path while
// the implementation and ownership live in the modern platform layer.
#include "../Modern/Platform/Configuration/DatabaseConfig.h"

namespace wyd::legacy
{
	namespace database = ::wyd::platform::database;
}
