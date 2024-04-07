// dllmain.cpp : Définit le point d'entrée de l'application DLL.
#include "pch.h"
#include "main.h"
#include "script.h"


BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
		Script::Initialize();
		scriptRegister(hModule, Script::Run);
		break;
	case DLL_PROCESS_DETACH:
		scriptUnregister(hModule);
		break;
	}
    return TRUE;
}
