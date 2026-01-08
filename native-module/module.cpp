#include "GarrysMod/Lua/Interface.h"
#include <stdio.h>

using namespace GarrysMod::Lua;

LUA_FUNCTION(native) {
    LUA->PushString("native");
    return 1;
}

GMOD_MODULE_OPEN() {
    LUA->PushSpecial(SPECIAL_GLOB);
    LUA->CreateTable();
    LUA->PushCFunction(native);
    LUA->SetField(-2, "native");
    LUA->SetField(-2, "projectile_native");
    LUA->Pop();
    
    return 0;
}

GMOD_MODULE_CLOSE() {
    return 0;
}
